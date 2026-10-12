import 'dart:async';

import 'package:flutter/material.dart';

import '../shared/form_controls.dart';
import '../shared/history_time.dart';

import '../../application/manual_library.dart';
import '../../application/metadata_completion.dart';
import '../../core/anime_log_core.dart';
import '../../core/api/library_repository.dart';
import '../../core/api/ai_intake.dart';
import '../../core/api/library_insights.dart';
import '../detail/detail_page.dart';
import '../library/library_controller.dart';
import '../shared/app_theme.dart';
import '../shared/page_state.dart';
import '../shared/pagination.dart';
import '../shared/watch_history_dialog.dart';

enum _ManagementTab { records, history }

class DataManagementPage extends StatefulWidget {
  final ManualLibrary useCases;
  final CoverStore? covers;
  final MetadataCompletionService? metadataCompletion;
  final VoidCallback? onLibrary;

  const DataManagementPage({
    super.key,
    required this.useCases,
    this.covers,
    this.metadataCompletion,
    this.onLibrary,
  });

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  late final c = LibraryController(
    widget.useCases.records,
    pageSize: managementPageSize,
  );
  final search = TextEditingController();
  final scroll = ScrollController();
  StreamSubscription<List<WatchHistoryRecord>>? historySubscription;
  List<WatchHistoryRecord> history = [];
  _ManagementTab tab = _ManagementTab.records;
  bool historyLoading = true;
  Object? historyError;
  int historyPage = 0;
  String? selectedHistory;
  String? selectedRecord;
  final Set<String> busy = {};

  @override
  void initState() {
    super.initState();
    _listenHistory();
  }

  void _listenHistory() {
    final repository = widget.useCases.records;
    if (repository is! LibraryInsightsRepository) {
      historyLoading = false;
      historyError = '当前数据源未提供全部观看历史';
      return;
    }
    historySubscription = (repository as LibraryInsightsRepository)
        .watchAllHistory()
        .listen(
          (value) {
            if (!mounted) return;
            setState(() {
              history = value;
              historyLoading = false;
              historyError = null;
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              historyLoading = false;
              historyError = error;
            });
          },
        );
  }

  Future<void> _retryHistory() async {
    if (historyLoading) return;
    setState(() {
      historyLoading = true;
      historyError = null;
    });
    await historySubscription?.cancel();
    if (mounted) {
      setState(_listenHistory);
    }
  }

  @override
  void dispose() {
    historySubscription?.cancel();
    search.dispose();
    scroll.dispose();
    c.dispose();
    super.dispose();
  }

  void _failure(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      appSnackBar(context, error: true, content: Text('操作未完成：$error')),
    );
  }

  Future<void> _perform(
    String key,
    Future<void> Function() action,
    String message,
  ) async {
    if (busy.contains(key)) return;
    setState(() => busy.add(key));
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(appSnackBar(context, content: Text(message)));
    } catch (error) {
      _failure(error);
    } finally {
      if (mounted) setState(() => busy.remove(key));
    }
  }

  Future<void> _openDetail(AnimeRecord record) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      allowSnapshotting: false,
      builder: (_) => DetailPage(
        uuid: record.uuid,
        useCases: widget.useCases,
        covers: widget.covers,
        metadataCompletion: widget.metadataCompletion,
      ),
    ),
  );

  Future<void> _editAnime(AnimeRecord record) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      allowSnapshotting: false,
      builder: (_) => EditRecordPage(
        uuid: record.uuid,
        useCases: widget.useCases,
        covers: widget.covers,
      ),
    ),
  );

  Future<void> _historyDialog(
    AnimeRecord record, [
    WatchHistoryRecord? event,
  ]) async {
    final key = event?.uuid ?? record.uuid;
    if (busy.contains(key)) return;
    final values = await showFormPanel<WatchHistoryValues>(
      context: context,
      builder: (_) => WatchHistoryDialog(record: record, event: event),
    );
    if (values == null || !mounted) return;
    await _perform(
      key,
      () => event == null
          ? c.repository.addHistory(
              record.uuid,
              values.episode,
              values.watchedOn,
              watchedAt: values.watchedAt,
            )
          : c.repository.correctHistory(
              event.uuid,
              values.episode,
              values.watchedOn,
              watchedAt: values.watchedAt,
              clearTime: values.watchedAt == null,
            ),
      event == null ? '观看历史已记录' : '观看历史已纠正，当前进度保留',
    );
  }

  Future<void> _deleteHistory(
    AnimeRecord record,
    WatchHistoryRecord event,
  ) async {
    late final HistoryUndoPreview preview;
    try {
      preview = await c.repository.previewHistoryUndo(event.uuid);
    } catch (error) {
      _failure(error);
      return;
    }
    if (!mounted) return;
    final selectedEvent = preview.events.singleWhere(
      (item) => item.uuid == event.uuid,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('撤销这次观看？'),
        content: Text(
          '「${record.metadata.title}」第 ${selectedEvent.episode} 集 · '
          '${historyMomentLabel(selectedEvent)}。\n'
          '${historyUndoImpactLabel(preview)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认撤销'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _perform(
        event.uuid,
        () => c.repository.deleteHistory(event.uuid, confirmed: preview),
        '观看进度与后续历史已同步',
      );
    }
  }

  Future<void> _deleteAnime(AnimeRecord record) async {
    try {
      final counts = await c.repository.deletionSummary(record.uuid);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('删除这条番剧记录？'),
          content: Text(
            '「${record.metadata.title}」及其 ${counts.historyCount} 条观看历史、${counts.noteCount} 条备注将被删除。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除记录'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await _perform(
          record.uuid,
          () => c.repository.delete(record.uuid, counts),
          '番剧记录已删除',
        );
      }
    } catch (error) {
      _failure(error);
    }
  }

  void _changePage(int value) {
    setState(() {
      selectedHistory = null;
      selectedRecord = null;
    });
    if (tab == _ManagementTab.records) {
      c.selectPage(value);
    } else {
      setState(() => historyPage = value);
    }
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final recordsByUuid = {
        for (final record in c.records) record.uuid: record,
      };
      final needle = search.text.trim().toLowerCase();
      final events = history.where((event) {
        final record = recordsByUuid[event.animeUuid];
        return record != null &&
            '${record.metadata.title} ${record.metadata.originalTitle ?? ''} ${historyMomentLabel(event)} 第 ${event.episode} 集'
                .toLowerCase()
                .contains(needle);
      }).toList();
      final isHistory = tab == _ManagementTab.history;
      final records = c.visible;
      final total = isHistory ? events.length : records.length;
      final page = isHistory
          ? boundedPage(historyPage, total, managementPageSize)
          : c.page;
      final pageRecords = records
          .skip(page * managementPageSize)
          .take(managementPageSize)
          .toList();
      final pageEvents = events
          .skip(page * managementPageSize)
          .take(managementPageSize)
          .toList();
      final loading = c.loading || (isHistory && historyLoading);
      final error = c.error ?? (isHistory ? historyError : null);
      return LayoutBuilder(
        builder: (context, size) {
          final inset = size.maxWidth < 600 ? 16.0 : 32.0;
          final inspector =
              size.maxWidth >= 1000 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3;
          final tableWidth = size.maxWidth - inset * 2 - (inspector ? 344 : 0);
          final wideRows =
              tableWidth >= 580 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3;
          final list = _recordList(
            isHistory: isHistory,
            loading: loading,
            error: error,
            total: total,
            page: page,
            records: pageRecords,
            events: pageEvents,
            recordsByUuid: recordsByUuid,
            wide: wideRows,
            inspector: inspector,
          );
          Widget side = SectionCard(
            title: isHistory ? '观看详情' : '番剧详情',
            children: [
              Text('选择一条记录', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(
                isHistory
                    ? '点击左侧观看记录，可查看具体时间、纠正集数或撤销观看并回退进度。'
                    : '点击左侧番剧，可编辑记录、补记观看或打开详情。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
          if (isHistory) {
            final selected = pageEvents
                .where((event) => event.uuid == selectedHistory)
                .firstOrNull;
            if (selected != null) {
              side = _inspectorPanel(
                recordsByUuid[selected.animeUuid]!,
                event: selected,
              );
            }
          } else {
            final selected = pageRecords
                .where((record) => record.uuid == selectedRecord)
                .firstOrNull;
            if (selected != null) side = _inspectorPanel(selected);
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(inset, 24, inset, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeading(title: '数据管理', subtitle: '管理番剧条目和观看记录'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<_ManagementTab>(
                    key: const Key('management-tabs'),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: _ManagementTab.records,
                        label: Text('番剧记录'),
                      ),
                      ButtonSegment(
                        value: _ManagementTab.history,
                        label: Text('观看历史'),
                      ),
                    ],
                    selected: {tab},
                    onSelectionChanged: (value) {
                      setState(() {
                        tab = value.single;
                        selectedHistory = null;
                        selectedRecord = null;
                      });
                      if (scroll.hasClients) scroll.jumpTo(0);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: inspector
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: list),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 320,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: side,
                              ),
                            ),
                          ],
                        )
                      : list,
                ),
              ],
            ),
          );
        },
      );
    },
  );

  Widget _recordList({
    required bool isHistory,
    required bool loading,
    required Object? error,
    required int total,
    required int page,
    required List<AnimeRecord> records,
    required List<WatchHistoryRecord> events,
    required Map<String, AnimeRecord> recordsByUuid,
    required bool wide,
    required bool inspector,
  }) => ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
    child: CustomScrollView(
      primary: false,
      controller: scroll,
      key: const Key('data-management-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('data-management-search'),
                controller: search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: isHistory ? '搜索番剧、集数、日期或时分' : '搜索标题、原名、声优或标签',
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空搜索',
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                ),
                onChanged: (value) {
                  c.search(value);
                  setState(() {
                    historyPage = 0;
                    selectedHistory = null;
                    selectedRecord = null;
                  });
                },
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 16),
              if (!isHistory) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      mouseCursor: WidgetStateMouseCursor.clickable,
                      label: const Text('全部状态'),
                      selected: c.filter == null,
                      onSelected: (_) => _filter(null),
                    ),
                    for (final status in AnimeStatus.values)
                      ChoiceChip(
                        mouseCursor: WidgetStateMouseCursor.clickable,
                        label: Text(statusLabel(status)),
                        selected: c.filter == status,
                        onSelected: (_) => _filter(status),
                      ),
                    PopupMenuButton<LibrarySort>(
                      tooltip: '排序',
                      initialValue: c.sort,
                      onSelected: (sort) {
                        c.selectSort(sort);
                        setState(() => selectedRecord = null);
                      },
                      itemBuilder: (_) => [
                        for (final sort in LibrarySort.values)
                          PopupMenuItem(
                            value: sort,
                            child: Text(sortLabel(sort)),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('排序：${sortLabel(c.sort)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        if (loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: PageStatePanel(title: '正在读取记录', loading: true),
          )
        else if (error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: PageStatePanel(
              title: '暂时无法读取记录',
              error: true,
              details: '$error',
              action: FilledButton(
                onPressed: c.error != null ? c.retry : _retryHistory,
                child: const Text('重试'),
              ),
            ),
          )
        else if (total == 0)
          SliverFillRemaining(
            hasScrollBody: false,
            child: PageStatePanel(
              title:
                  search.text.trim().isNotEmpty ||
                      (!isHistory && c.filter != null)
                  ? '没有符合条件的记录'
                  : isHistory
                  ? '还没有观看历史'
                  : '还没有番剧记录',
              message: isHistory
                  ? '在番剧详情中补记，或用进度 +1 记录今天。'
                  : '在动漫库添加后，可以在这里编辑。',
              action:
                  search.text.trim().isNotEmpty ||
                      (!isHistory && c.filter != null)
                  ? TextButton(
                      onPressed: _clearSearch,
                      child: const Text('清除搜索与筛选'),
                    )
                  : widget.onLibrary == null
                  ? null
                  : TextButton(
                      onPressed: widget.onLibrary,
                      child: const Text('打开动漫库'),
                    ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  if (wide) ...[
                    _tableHeader(isHistory),
                    const Divider(height: 1),
                  ],
                  if (isHistory)
                    for (final item in events.indexed) ...[
                      if (item.$1 > 0) const Divider(height: 1),
                      _historyRow(
                        recordsByUuid[item.$2.animeUuid]!,
                        item.$2,
                        wide,
                        inspector,
                      ),
                    ]
                  else
                    for (final item in records.indexed) ...[
                      if (item.$1 > 0) const Divider(height: 1),
                      _recordRow(item.$2, wide, inspector),
                    ],
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: PaginationControls(
                      total: total,
                      page: page,
                      pageSize: managementPageSize,
                      onChanged: _changePage,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    ),
  );

  void _clearSearch() {
    search.clear();
    c.resetFilters();
    setState(() {
      historyPage = 0;
      selectedHistory = null;
      selectedRecord = null;
    });
  }

  void _filter(AnimeStatus? status) {
    c.selectStatus(status);
    setState(() => selectedRecord = null);
  }

  Widget _tableHeader(bool isHistory) => Container(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    child: DefaultTextStyle(
      style: Theme.of(context).textTheme.bodySmall!,
      child: Row(
        children: [
          Expanded(
            flex: isHistory ? 3 : 5,
            child: Text(isHistory ? '观看记录' : '番剧'),
          ),
          if (!isHistory) const Expanded(flex: 2, child: Text('状态')),
          Expanded(flex: 2, child: Text(isHistory ? '观看时间' : '进度')),
        ],
      ),
    ),
  );

  Widget _title(AnimeRecord record, {String? subtitle}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        record.metadata.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      if (subtitle != null || record.metadata.originalTitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle ?? record.metadata.originalTitle!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ],
  );

  Widget _recordRow(
    AnimeRecord record,
    bool wide,
    bool inspector,
  ) => _rowSurface(
    rowKey: Key('manage-record-${record.uuid}'),
    selected: selectedRecord == record.uuid,
    onTap: () {
      setState(() => selectedRecord = record.uuid);
      if (!inspector) _showInspector(record);
    },
    child: wide
        ? Row(
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _title(record),
                ),
              ),
              Expanded(flex: 2, child: Text(statusLabel(record.status))),
              Expanded(
                flex: 2,
                child: Text(
                  '${record.progress} / ${record.metadata.totalEpisodes ?? '?'} 集',
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Expanded(child: _title(record))]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  RecordBadge(label: statusLabel(record.status)),
                  Text(
                    '${record.progress} / ${record.metadata.totalEpisodes ?? '?'} 集',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
  );

  Widget _historyRow(
    AnimeRecord record,
    WatchHistoryRecord event,
    bool wide,
    bool inspector,
  ) => _rowSurface(
    rowKey: Key('manage-history-${event.uuid}'),
    selected: selectedHistory == event.uuid,
    onTap: () {
      setState(() => selectedHistory = event.uuid);
      if (!inspector) _showInspector(record, event: event);
    },
    child: wide
        ? Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _title(record, subtitle: '第 ${event.episode} 集'),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  historyMomentLabel(event),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _title(record, subtitle: '第 ${event.episode} 集'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                historyMomentLabel(event),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
  );

  Widget _rowSurface({
    required Key rowKey,
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) => Semantics(
    selected: selected,
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: .45)
          : Colors.transparent,
      child: InkWell(
        key: rowKey,
        mouseCursor: WidgetStateMouseCursor.clickable,
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    ),
  );

  Future<void> _showInspector(
    AnimeRecord record, {
    WatchHistoryRecord? event,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxWidth: 640,
      maxHeight: MediaQuery.sizeOf(context).height * .9,
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: _inspectorPanel(
          record,
          event: event,
          close: () => Navigator.pop(sheetContext),
        ),
      ),
    ),
  );

  Widget _inspectorPanel(
    AnimeRecord record, {
    WatchHistoryRecord? event,
    VoidCallback? close,
  }) {
    final locked = busy.contains(event?.uuid ?? record.uuid);
    VoidCallback action(VoidCallback callback) => () {
      close?.call();
      callback();
    };
    return SectionCard(
      title: event == null ? '番剧详情' : '观看详情',
      children: [
        Text(
          record.metadata.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (event != null) ...[
          const SizedBox(height: 8),
          Text(
            '第 ${event.episode} 集',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else if (record.metadata.originalTitle != null) ...[
          const SizedBox(height: 8),
          Text(
            record.metadata.originalTitle!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        if (event == null && record.tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in record.tags) RecordBadge(label: '#$tag'),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (event != null) ...[
          _inspectorValue('记录 ID', '#${event.id}'),
          _inspectorValue('番剧 ID', '#${record.id}'),
          _inspectorValue('观看集数', '第 ${event.episode} 集'),
          _inspectorValue('观看时间', historyMomentLabel(event)),
          _inspectorValue(
            '当前进度',
            '${record.progress} / ${record.metadata.totalEpisodes ?? '?'} 集',
          ),
          if (event.watchedAt == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '此条历史没有具体时刻，可以补充。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ] else ...[
          _inspectorValue('记录 ID', '#${record.id}'),
          _inspectorValue('观看状态', statusLabel(record.status)),
          _inspectorValue(
            '当前进度',
            '${record.progress} / ${record.metadata.totalEpisodes ?? '?'} 集',
          ),
          _inspectorValue('最近编辑', localTimestampLabel(record.updatedAt)),
          _inspectorValue('开始日期', record.startDate ?? '未记录'),
          _inspectorValue('完成日期', record.endDate ?? '未记录'),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: event == null
                ? Key('edit-anime-${record.uuid}')
                : Key('edit-history-${event.uuid}'),
            onPressed: locked
                ? null
                : action(() {
                    if (event == null) {
                      _editAnime(record);
                    } else {
                      _historyDialog(record, event);
                    }
                  }),
            child: Text(event == null ? '编辑记录' : '修改集数与时间'),
          ),
        ),
        if (event == null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: locked ? null : action(() => _historyDialog(record)),
              child: const Text('记录一集'),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: action(() => _openDetail(record)),
              child: const Text('打开番剧详情'),
            ),
            TextButton(
              key: event == null
                  ? Key('delete-anime-${record.uuid}')
                  : Key('delete-history-${event.uuid}'),
              onPressed: locked
                  ? null
                  : action(() {
                      if (event == null) {
                        _deleteAnime(record);
                      } else {
                        _deleteHistory(record, event);
                      }
                    }),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(event == null ? '删除记录' : '撤销观看'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _inspectorValue(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, size) =>
          size.maxWidth < 250 || MediaQuery.textScalerOf(context).scale(1) > 1.3
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                SelectableText(value),
              ],
            )
          : Row(
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(value, textAlign: TextAlign.end),
                ),
              ],
            ),
    ),
  );
}
