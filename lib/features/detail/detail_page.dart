import 'package:flutter/material.dart';

import '../shared/watch_history_dialog.dart';
import '../shared/form_controls.dart';
import '../shared/history_time.dart';

import '../../application/manual_library.dart';
import '../../core/anime_log_core.dart';
import '../intake/editor_controller.dart';
import '../intake/editor_page.dart';
import '../library/library_controller.dart';
import 'detail_controller.dart';
import '../../core/api/ai_intake.dart';
import '../../core/api/library_repository.dart';
import '../shared/anime_cover.dart';
import '../shared/app_theme.dart';
import '../shared/page_state.dart';
import 'episode_note_dialog.dart';
import '../../application/metadata_completion.dart';
import 'metadata_completion_page.dart';

class DetailPage extends StatefulWidget {
  final String uuid;
  final ManualLibrary useCases;
  final CoverStore? covers;
  final MetadataCompletionService? metadataCompletion;
  const DetailPage({
    super.key,
    required this.uuid,
    required this.useCases,
    this.covers,
    this.metadataCompletion,
  });
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final c = DetailController(widget.uuid, widget.useCases.records);
  int noteLimit = 3;
  int historyLimit = 8;
  @override
  void initState() {
    super.initState();
    c.reload();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _action(Future<void> Function() action) async {
    try {
      await c.perform(action);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(context, error: true, content: Text('操作未完成：$error')),
        );
      }
    }
  }

  Future<void> _noteDialog([AnimeNote? note]) async {
    final values = await showFormPanel<EpisodeNoteValues>(
      context: context,
      builder: (_) => EpisodeNoteDialog(note: note),
    );
    if (values == null || !mounted) return;
    String? savedUuid;
    await _action(() async {
      savedUuid = await c.repository.saveEpisodeNote(
        widget.uuid,
        noteUuid: note?.uuid,
        episode: values.episode,
        content: values.content,
        notedOn: values.notedOn,
      );
    });
    if (mounted && savedUuid != null && c.error == null) {
      final index = c.notes.indexWhere((note) => note.uuid == savedUuid);
      if (index >= noteLimit) setState(() => noteLimit = index + 1);
    }
  }

  Future<void> _deleteNote(AnimeNote note) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条分集备注？'),
        content: Text('第 ${note.episode} 集 · ${note.notedOn}\n${note.content}'),
        scrollable: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm-delete-note'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除备注'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await _action(
        () => c.repository.deleteEpisodeNote(widget.uuid, note.uuid),
      );
    }
  }

  Future<void> _edit() async {
    await Navigator.push<String>(
      context,
      MaterialPageRoute(
        allowSnapshotting: false,
        builder: (_) => EditRecordPage(
          uuid: widget.uuid,
          useCases: widget.useCases,
          covers: widget.covers,
        ),
      ),
    );
    await c.reload();
  }

  Future<void> _completeMetadata() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        allowSnapshotting: false,
        builder: (_) => MetadataCompletionPage(
          uuid: widget.uuid,
          service: widget.metadataCompletion!,
          covers: widget.covers,
        ),
      ),
    );
    if (mounted) await c.reload();
  }

  Future<void> _delete() async {
    try {
      final counts = await c.repository.deletionSummary(widget.uuid);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('删除这条动漫记录？'),
          content: Text(
            '「${c.record!.metadata.title}」及其 ${counts.historyCount} 条观看历史、'
            '${counts.noteCount} 条备注将被删除。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认删除'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await c.perform(() => c.repository.delete(widget.uuid, counts));
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(context, error: true, content: Text('删除未完成：$error')),
        );
      }
    }
  }

  Future<void> _historyDialog([WatchHistoryRecord? event]) async {
    final record = c.record;
    if (record == null || c.busy) return;
    final value = await showFormPanel<WatchHistoryValues>(
      context: context,
      builder: (_) => WatchHistoryDialog(record: record, event: event),
    );
    if (value == null || !mounted) return;
    var saved = false;
    await _action(() async {
      if (event == null) {
        await c.repository.addHistory(
          widget.uuid,
          value.episode,
          value.watchedOn,
          watchedAt: value.watchedAt,
        );
      } else {
        await c.repository.correctHistory(
          event.uuid,
          value.episode,
          value.watchedOn,
          watchedAt: value.watchedAt,
          clearTime: value.watchedAt == null,
        );
      }
      saved = true;
    });
    if (mounted && saved && c.error == null) {
      final index = c.events.indexWhere(
        (history) => event == null
            ? history.episode == value.episode &&
                  history.watchedOn == value.watchedOn &&
                  history.watchedAt == value.watchedAt
            : history.uuid == event.uuid,
      );
      if (index >= historyLimit) setState(() => historyLimit = index + 1);
    }
  }

  Future<void> _deleteEvent(WatchHistoryRecord event) async {
    if (c.busy) return;
    late final HistoryUndoPreview preview;
    try {
      preview = await c.repository.previewHistoryUndo(event.uuid);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(context, error: true, content: Text('操作未完成：$error')),
        );
      }
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
          '第 ${selectedEvent.episode} 集 · ${historyMomentLabel(selectedEvent)}。\n'
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
      await _action(
        () => c.repository.deleteHistory(event.uuid, confirmed: preview),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final record = c.record;
      return Scaffold(
        appBar: AppBar(title: const Text('动漫详情')),
        body: c.loading
            ? const PageStatePanel(title: '正在读取作品资料', loading: true)
            : c.error != null
            ? PageStatePanel(
                title: '暂时无法读取记录',
                details: c.error.toString(),
                error: true,
                action: FilledButton(
                  onPressed: c.retry,
                  child: const Text('重试'),
                ),
              )
            : record == null
            ? PageStatePanel(
                title: '记录已不存在',
                action: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('返回动漫库'),
                ),
              )
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1600),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(
                        MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
                      ),
                      child: _content(record),
                    ),
                  ),
                ),
              ),
      );
    },
  );

  Widget _content(AnimeRecord record) => LayoutBuilder(
    builder: (context, size) {
      final wide =
          size.maxWidth >= 1100 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3;
      final main = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _overview(record, compact: !wide),
          if (!wide) _coverStats(record),
          _bodyColumns(record),
        ],
      );
      if (!wide) return main;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: (size.maxWidth * .25).clamp(260.0, 400.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_coverPanel(record), _coverStats(record)],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(child: main),
        ],
      );
    },
  );

  Widget _coverPanel(AnimeRecord record) => Card(
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, size) => AnimeCover(
            title: record.metadata.title,
            url: record.metadata.coverUrl,
            store: widget.covers,
            width: size.maxWidth,
            height: size.maxWidth * 1.5,
            borderRadius: BorderRadius.zero,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel(record.status),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _coverStats(AnimeRecord record) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: _metrics([
        _metric('评分', record.score?.toString() ?? '未评分'),
        _metric('总集数', record.metadata.totalEpisodes?.toString() ?? '未知'),
        _metric(
          '单集时长',
          record.metadata.durationMinutes == null
              ? '未知'
              : '${record.metadata.durationMinutes} 分钟',
        ),
      ], minimum: 76),
    ),
  );

  Widget _overview(AnimeRecord record, {required bool compact}) => SectionCard(
    title: '作品概览',
    children: [
      LayoutBuilder(
        builder: (context, size) {
          final title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                AnimeCover(
                  title: record.metadata.title,
                  url: record.metadata.coverUrl,
                  store: widget.covers,
                  width: 88,
                  height: 132,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.metadata.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (record.metadata.originalTitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        record.metadata.originalTitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.metadataCompletion != null)
                OutlinedButton(
                  key: const Key('complete-metadata'),
                  onPressed: c.busy ? null : _completeMetadata,
                  child: const Text('补全资料'),
                ),
              OutlinedButton(
                onPressed: c.busy ? null : _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('删除记录'),
              ),
              FilledButton(
                key: const Key('edit-record'),
                onPressed: c.busy ? null : _edit,
                child: const Text('编辑记录'),
              ),
            ],
          );
          if (size.maxWidth < 760 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 20), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: 24),
              SizedBox(width: 320, child: actions),
            ],
          );
        },
      ),
      if (record.tags.isNotEmpty) ...[
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in record.tags)
              RecordBadge(
                label: '#$tag',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ],
      const SizedBox(height: 24),
      _metrics([
        _metric(
          '观看状态',
          statusLabel(record.status),
          detail: _sourceStatus(record),
        ),
        _metric(
          '当前进度',
          '${record.progress} / ${record.metadata.totalEpisodes ?? '?'} 集',
          detail: _completion(record),
        ),
        _metric(
          '最近编辑',
          localTimestampLabel(record.updatedAt),
          detail:
              '创建于 ${localTimestampLabel(record.createdAt).split(' ').first}',
        ),
      ]),
    ],
  );

  Widget _bodyColumns(AnimeRecord record) => LayoutBuilder(
    builder: (context, size) {
      final primary = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_progress(record), _summary(record), _historySection()],
      );
      final secondary = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dates(record),
          _cast(record),
          _personalNotes(record),
          _metadata(record),
        ],
      );
      if (size.maxWidth < 800 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _progress(record),
            _summary(record),
            _dates(record),
            _cast(record),
            _personalNotes(record),
            _historySection(),
            _metadata(record),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: primary),
          const SizedBox(width: 24),
          Expanded(flex: 5, child: secondary),
        ],
      );
    },
  );

  Widget _progress(AnimeRecord record) => SectionCard(
    title: '观看进度',
    subtitle:
        '${record.progress} / ${record.metadata.totalEpisodes ?? '?'} 集 · ${_completion(record)}',
    children: [
      Semantics(
        label: '观看进度',
        value:
            '${record.progress} / ${record.metadata.totalEpisodes ?? '未知'} 集',
        child: LinearProgressIndicator(
          value: record.metadata.totalEpisodes == null
              ? 0
              : (record.progress / record.metadata.totalEpisodes!).clamp(
                  0.0,
                  1.0,
                ),
          minHeight: 9,
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton(
            key: const Key('detail-increment'),
            onPressed:
                c.busy ||
                    (record.metadata.totalEpisodes != null &&
                        record.progress >= record.metadata.totalEpisodes!)
                ? null
                : _increment,
            child: const Text('进度 +1'),
          ),
          OutlinedButton(
            key: const Key('detail-decrement'),
            onPressed: c.busy || record.progress == 0 ? null : _decrement,
            child: const Text('进度 −1'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _metrics([
        _metric('首播', record.metadata.premiereDate ?? '未记录'),
        _metric('作品形式', record.metadata.entryType?.name.toUpperCase() ?? '未知'),
        _metric('片源状态', _sourceStatus(record)),
      ], minimum: 140),
    ],
  );

  Widget _summary(AnimeRecord record) => SectionCard(
    title: '简介 / 剧情',
    children: [
      if (record.metadata.summary != null)
        SelectableText(
          record.metadata.summary!,
          style: const TextStyle(height: 1.8),
        )
      else
        Text(
          '暂无作品简介，可以通过补全资料或编辑记录添加。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ],
  );

  Widget _dates(AnimeRecord record) => SectionCard(
    title: '观看日期',
    children: [
      _detailRow('开始观看', record.startDate ?? '未记录'),
      _detailRow('看完日期', record.endDate ?? '未记录'),
      _detailRow('首播日期', record.metadata.premiereDate ?? '未记录'),
      _detailRow('放送状态', _sourceStatus(record)),
    ],
  );

  Widget _cast(AnimeRecord record) => SectionCard(
    title: '声优阵容',
    subtitle: record.metadata.cast.isEmpty
        ? null
        : '${record.metadata.cast.length} 名',
    children: [
      if (record.metadata.cast.isEmpty)
        Text('暂未记录声优信息。', style: Theme.of(context).textTheme.bodySmall)
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in record.metadata.cast) RecordBadge(label: name),
          ],
        ),
    ],
  );

  Widget _personalNotes(AnimeRecord record) => SectionCard(
    title: '个人备注',
    children: [
      Text('总体感受', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 12),
      if (record.notes != null)
        SelectableText(record.notes!, style: const TextStyle(height: 1.8))
      else
        TextButton(onPressed: c.busy ? null : _edit, child: const Text('写下感想')),
      const SizedBox(height: 24),
      SectionHeading(
        title: '分集备注（${c.notes.length}）',
        action: TextButton(
          key: const Key('add-episode-note'),
          onPressed: c.busy ? null : _noteDialog,
          child: const Text('添加分集备注'),
        ),
      ),
      const SizedBox(height: 12),
      if (c.notes.isEmpty)
        Text('记录某一集的感想。', style: Theme.of(context).textTheme.bodySmall),
      for (final note in c.notes.take(noteLimit))
        Container(
          key: Key('note-${note.uuid}'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '第 ${note.episode} 集',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  PopupMenuButton<String>(
                    key: Key('note-actions-${note.uuid}'),
                    enabled: !c.busy,
                    tooltip: '备注操作',
                    onSelected: (value) =>
                        value == 'edit' ? _noteDialog(note) : _deleteNote(note),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑备注')),
                      PopupMenuItem(value: 'delete', child: Text('删除备注')),
                    ],
                  ),
                ],
              ),
              Text(note.notedOn, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              SelectableText(note.content),
            ],
          ),
        ),
      if (c.notes.length > noteLimit)
        TextButton(
          onPressed: () => setState(() => noteLimit += 10),
          child: Text('显示更多备注（还有 ${c.notes.length - noteLimit} 条）'),
        ),
      if (noteLimit > 3 && c.notes.length > 3)
        TextButton(
          onPressed: () => setState(() => noteLimit = 3),
          child: const Text('收起备注'),
        ),
    ],
  );

  Widget _historySection() => SectionCard(
    title: '观看历史（${c.events.length}）',
    action: TextButton(
      onPressed: c.busy ? null : _historyDialog,
      child: const Text('记录一集'),
    ),
    children: [
      if (c.events.isEmpty)
        Text(
          '还没有观看历史。可以用进度 +1 记录今天，也可以补记集数与时间。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      for (final event in c.events.take(historyLimit))
        ListTile(
          key: Key('detail-history-${event.uuid}'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          title: Text('第 ${event.episode} 集'),
          subtitle: Text(historyMomentLabel(event)),
          onTap: c.busy ? null : () => _historyDialog(event),
          trailing: PopupMenuButton<String>(
            enabled: !c.busy,
            tooltip: '历史操作',
            onSelected: (action) =>
                action == 'edit' ? _historyDialog(event) : _deleteEvent(event),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('修改集数与时间')),
              PopupMenuItem(value: 'delete', child: Text('撤销观看')),
            ],
          ),
        ),
      if (c.events.length > historyLimit)
        TextButton(
          onPressed: () => setState(() => historyLimit += 20),
          child: Text('显示更多历史（还有 ${c.events.length - historyLimit} 条）'),
        ),
      if (historyLimit > 8 && c.events.length > 8)
        TextButton(
          onPressed: () => setState(() => historyLimit = 8),
          child: const Text('收起历史'),
        ),
    ],
  );

  Widget _metadata(AnimeRecord record) => SectionCard(
    title: '更多作品资料',
    collapsible: true,
    children: [
      _info('作品形式', record.metadata.entryType?.name.toUpperCase()),
      _info('季度', record.metadata.season?.toString()),
      _info(
        '声优别名',
        record.metadata.castAliases.isEmpty
            ? null
            : record.metadata.castAliases.join('、'),
      ),
      _info('封面地址', record.metadata.coverUrl),
      if (record.metadata.sourceProvider != null)
        _info(
          '资料来源',
          '${record.metadata.sourceProvider} · ${record.metadata.sourceId}',
        ),
    ],
  );

  Widget _detailRow(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: LayoutBuilder(
      builder: (context, size) {
        if (size.maxWidth < 250 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              SelectableText(value),
            ],
          );
        }
        return Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 16),
            Expanded(child: SelectableText(value, textAlign: TextAlign.end)),
          ],
        );
      },
    ),
  );

  Widget _metric(String label, String value, {String? detail}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        if (detail != null) ...[
          const SizedBox(height: 6),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );

  Widget _metrics(List<Widget> children, {double minimum = 180}) =>
      LayoutBuilder(
        builder: (context, size) {
          final columns =
              ((size.maxWidth + 12) /
                      (minimum * MediaQuery.textScalerOf(context).scale(1) +
                          12))
                  .floor()
                  .clamp(1, children.length);
          return Column(
            children: [
              for (
                var row = 0;
                row < (children.length / columns).ceil();
                row++
              ) ...[
                if (row > 0) const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var column = 0; column < columns; column++) ...[
                        if (column > 0) const SizedBox(width: 12),
                        Expanded(
                          child: row * columns + column < children.length
                              ? children[row * columns + column]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      );

  String _sourceStatus(AnimeRecord record) => record.metadata.isFinished == null
      ? '完结情况未知'
      : record.metadata.isFinished!
      ? '已完结'
      : '未完结';

  String _completion(AnimeRecord record) =>
      record.metadata.totalEpisodes == null
      ? '总集数未记录'
      : '完成度 ${(record.progress / record.metadata.totalEpisodes! * 100).round()}%';

  Future<void> _increment() async {
    if (c.busy) return;
    try {
      late ProgressReceipt receipt;
      await c.perform(() async {
        receipt = await c.repository.increment(
          widget.uuid,
          DateTime.now().toIso8601String().substring(0, 10),
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        appSnackBar(
          context,
          duration: const Duration(seconds: 6),
          content: const Text('已看一集 · 已记录今天'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () => _action(() => c.repository.undoIncrement(receipt)),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(context, error: true, content: Text('操作未完成：$error')),
        );
      }
    }
  }

  Future<void> _decrement() async {
    if (c.busy) return;
    var saved = false;
    await _action(() async {
      await c.repository.decrement(widget.uuid);
      saved = true;
    });
    if (saved && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        appSnackBar(context, content: Text('进度 −1 · 已清理高于新进度的历史')),
      );
    }
  }

  Widget _info(String label, String? value) => value == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              SelectableText(value),
            ],
          ),
        );
}

/// Navigation carries only UUID; the editor loads its own immutable snapshot.
class EditRecordPage extends StatefulWidget {
  final String uuid;
  final ManualLibrary useCases;
  final CoverStore? covers;
  const EditRecordPage({
    super.key,
    required this.uuid,
    required this.useCases,
    this.covers,
  });
  @override
  State<EditRecordPage> createState() => _EditRecordPageState();
}

class _EditRecordPageState extends State<EditRecordPage> {
  late final future = widget.useCases.records.find(widget.uuid);
  @override
  Widget build(BuildContext context) => FutureBuilder<AnimeRecord?>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || snapshot.data == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('编辑记录')),
          body: const Center(child: Text('无法读取记录，请返回重试')),
        );
      }
      return _LoadedEditor(
        useCases: widget.useCases,
        record: snapshot.data!,
        covers: widget.covers,
      );
    },
  );
}

class _LoadedEditor extends StatefulWidget {
  final ManualLibrary useCases;
  final AnimeRecord record;
  final CoverStore? covers;
  const _LoadedEditor({
    required this.useCases,
    required this.record,
    this.covers,
  });
  @override
  State<_LoadedEditor> createState() => _LoadedEditorState();
}

class _LoadedEditorState extends State<_LoadedEditor> {
  late final controller = EditorController(
    useCases: widget.useCases,
    original: widget.record,
  );
  @override
  Widget build(BuildContext context) =>
      EditorPage(controller: controller, covers: widget.covers);
}
