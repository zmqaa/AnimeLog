import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shared/history_time.dart';
import '../shared/chart_tooltip.dart';

import '../../core/api/ai_intake.dart';
import '../../core/api/library_insights.dart';
import '../../core/api/library_repository.dart';
import '../../core/domain/library_statistics.dart';
import '../../core/domain/quick_record_models.dart';
import '../library/library_controller.dart';
import '../shared/anime_cover.dart';
import '../shared/app_theme.dart';
import '../shared/page_state.dart';
import '../shared/pagination.dart';

enum _TimelineViewMode { timeline, list }

enum _TimelineGrouping { day, week, month }

enum _TimelineSort { newest, oldest }

/// A reading-friendly history page for both desktop and narrow screens.
///
/// The desktop layout keeps the recent-work ranking alongside the timeline;
/// on Android that same panel naturally moves below the records.
class TimelinePage extends StatefulWidget {
  final List<AnimeRecord> records;
  final LibraryRepository repository;
  final CoverStore? covers;
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;
  final void Function(AnimeRecord) onOpen;

  const TimelinePage({
    super.key,
    required this.records,
    required this.repository,
    required this.onOpen,
    this.covers,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  StreamSubscription<List<WatchHistoryRecord>>? subscription;
  List<WatchHistoryRecord> history = [];
  Object? historyError;
  bool historyLoading = true;
  ActivityRange range = ActivityRange.week;
  _TimelineViewMode viewMode = _TimelineViewMode.timeline;
  _TimelineGrouping grouping = _TimelineGrouping.day;
  _TimelineSort sort = _TimelineSort.newest;
  final search = TextEditingController();
  static const _historyPageSize = 4;
  static const _recentPageSize = 10;
  int historyPage = 0;
  int recentPage = 0;
  String? selectedDate;
  final historyAnchor = GlobalKey();

  void _resetPages() {
    historyPage = 0;
    recentPage = 0;
  }

  void _changeHistoryPage(int value) {
    setState(() => historyPage = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchor = historyAnchor.currentContext;
      if (anchor != null && mounted) {
        Scrollable.ensureVisible(
          anchor,
          duration: const Duration(milliseconds: 180),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    final repository = widget.repository;
    if (repository is! LibraryInsightsRepository) {
      historyLoading = false;
      historyError = '当前数据源未提供观看历史';
      return;
    }
    subscription = (repository as LibraryInsightsRepository)
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

  Future<void> _retry() async {
    await subscription?.cancel();
    if (!mounted) return;
    setState(() {
      historyLoading = true;
      historyError = null;
    });
    _listen();
  }

  @override
  void dispose() {
    subscription?.cancel();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const PageStatePanel(
        title: '正在整理观看时间轴',
        message: '正在读取本机收藏。',
        loading: true,
      );
    }
    if (widget.error != null) {
      return PageStatePanel(
        title: '暂时无法读取收藏',
        message: '重试后会重新整理观看时间轴。',
        details: widget.error.toString(),
        error: true,
        action: widget.onRetry == null
            ? null
            : FilledButton(onPressed: widget.onRetry, child: const Text('重试')),
      );
    }

    final recordsByUuid = {
      for (final record in widget.records) record.uuid: record,
    };
    final events = _filteredEvents(recordsByUuid);
    historyPage = boundedPage(historyPage, events.length, _historyPageSize);
    final allEvents = history
        .where((event) => recordsByUuid.containsKey(event.animeUuid))
        .toList();
    final activity = ActivityStatistics.fromHistory(
      allEvents,
      range,
      DateTime.now(),
    );

    return LayoutBuilder(
      builder: (context, size) {
        final inset = size.maxWidth < 600 ? 20.0 : 32.0;
        final wide =
            size.maxWidth >= 1080 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.4;
        final content = ListView(
          primary: false,
          key: const PageStorageKey('timeline-scroll'),
          padding: EdgeInsets.fromLTRB(inset, 28, inset, 32),
          children: [
            const PageHeading(title: '观看时间轴', subtitle: '按观看日期回顾作品与进度。'),
            _summaryCards(allEvents),
            _trend(activity, allEvents),
            _heatmap(allEvents),
            _historySection(events, recordsByUuid, wide: wide),
          ],
        );
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: content,
        );
      },
    );
  }

  List<WatchHistoryRecord> _filteredEvents(
    Map<String, AnimeRecord> recordsByUuid,
  ) {
    final needle = search.text.trim().toLowerCase();
    final result = history.where((event) {
      final record = recordsByUuid[event.animeUuid];
      if (record == null) return false;
      if (selectedDate != null && event.watchedOn != selectedDate) return false;
      if (needle.isEmpty) return true;
      final haystack = [
        record.metadata.title,
        record.metadata.originalTitle ?? '',
        event.watchedOn,
        'EP ${event.episode}',
        '第 ${event.episode} 集',
      ].join(' ').toLowerCase();
      return haystack.contains(needle);
    }).toList();
    result.sort((a, b) => _compareEvents(a, b, sort));
    return result;
  }

  Widget _summaryCards(List<WatchHistoryRecord> events) {
    final days = events.map((event) => event.watchedOn).toSet();
    final works = events.map((event) => event.animeUuid).toSet();
    final timeBuckets = <String, int>{};
    for (final event in events) {
      final label = _timeBucket(event.watchedAt);
      if (label != null) {
        timeBuckets.update(label, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final peakTime = timeBuckets.entries.isEmpty
        ? null
        : (timeBuckets.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;
    final values = [
      ('已记录观看', '${events.length}', 'EP', Icons.play_circle_outline),
      ('涉及作品', '${works.length}', '部', Icons.video_library_outlined),
      ('记录活跃天数', '${days.length}', '天', Icons.calendar_month_outlined),
      (
        '记录日均',
        days.isEmpty ? '0.0' : (events.length / days.length).toStringAsFixed(1),
        'EP',
        Icons.bar_chart_rounded,
      ),
      (
        '高频记录时段',
        peakTime?.key ?? '暂无',
        peakTime == null ? '' : '×${peakTime.value}',
        Icons.schedule_outlined,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: LayoutBuilder(
        builder: (context, size) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final minWidth = scale > 1.3 ? 190.0 * scale : 156.0;
          final columns = math.max(
            1,
            math.min(5, ((size.maxWidth + 12) / (minWidth + 12)).floor()),
          );
          final width = (size.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final value in values)
                SizedBox(
                  width: width,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value.$1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  value.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (value.$3.isNotEmpty)
                            Text(
                              value.$3,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _trend(
    ActivityStatistics activity,
    List<WatchHistoryRecord> events,
  ) => SectionCard(
    title: '观看趋势',
    subtitle: '按观看日期统计已保存的单集记录。',
    action: SegmentedButton<ActivityRange>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      ),
      segments: const [
        ButtonSegment(value: ActivityRange.week, label: Text('周')),
        ButtonSegment(value: ActivityRange.month, label: Text('月')),
        ButtonSegment(value: ActivityRange.year, label: Text('年')),
      ],
      selected: {range},
      onSelectionChanged: (value) => setState(() => range = value.single),
    ),
    children: [
      if (historyLoading)
        const PageStatePanel(title: '正在读取观看趋势', loading: true, compact: true)
      else if (historyError != null)
        PageStatePanel(
          title: '暂时无法读取观看历史',
          message: '重试后会重新统计观看趋势。',
          details: historyError.toString(),
          error: true,
          compact: true,
          action: OutlinedButton(onPressed: _retry, child: const Text('重试')),
        )
      else ...[
        _trendHighlights(activity),
        const SizedBox(height: 18),
        if (events.isEmpty)
          const PageStatePanel(
            title: '还没有观看历史',
            message: '使用进度 +1 或在详情补记后，这里会出现趋势。',
            compact: true,
          )
        else
          _TimelineLineChart(buckets: activity.buckets),
      ],
    ],
  );

  Widget _trendHighlights(ActivityStatistics activity) {
    final peak = activity.buckets.fold<StatisticBucket?>(
      null,
      (current, item) =>
          current == null || item.count > current.count ? item : current,
    );
    final coverage = activity.days == 0
        ? 0
        : (activity.activeDays / activity.days * 100).round();
    return LayoutBuilder(
      builder: (context, size) {
        final columns = size.maxWidth >= 700 ? 3 : 1;
        final width = columns == 1
            ? size.maxWidth
            : (size.maxWidth - 16) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in [
              (
                '峰值日',
                peak == null ? '—' : peak.label,
                '${peak?.count ?? 0} EP',
              ),
              ('活跃度', '${activity.activeDays}', '天'),
              ('覆盖率', '$coverage%', _rangeLabel(activity.days)),
            ])
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.$1,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      Text(
                        item.$2,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.$3,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _heatmap(List<WatchHistoryRecord> events) => SectionCard(
    title: '观看热力图',
    subtitle: '过去 12 个月 · 悬停或点按查看日期、作品数和集数。',
    children: [
      if (historyLoading)
        const PageStatePanel(title: '正在读取热力图', loading: true, compact: true)
      else if (historyError != null)
        PageStatePanel(
          title: '暂时无法读取热力图',
          error: true,
          compact: true,
          action: OutlinedButton(onPressed: _retry, child: const Text('重试')),
        )
      else
        _WatchHeatmap(events: events),
    ],
  );

  Widget _historySection(
    List<WatchHistoryRecord> events,
    Map<String, AnimeRecord> recordsByUuid, {
    required bool wide,
  }) {
    final pageEvents = events
        .skip(historyPage * _historyPageSize)
        .take(_historyPageSize)
        .toList();
    final groups = _groups(pageEvents);
    final groupCounts = {
      for (final group in _groups(events)) group.key: group.events.length,
    };
    final recent = _recentWorks(events, recordsByUuid);
    recentPage = boundedPage(recentPage, recent.length, _recentPageSize);
    final main = Column(
      key: historyAnchor,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('观看记录', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '${events.length} 条记录 · ${viewMode == _TimelineViewMode.timeline ? '按${_groupingLabel(grouping)}查看' : '列表查看'} · 每页 $_historyPageSize 条',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _historyToolbar(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(
              viewMode == _TimelineViewMode.timeline ? 18 : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (historyLoading)
                  const PageStatePanel(
                    title: '正在读取观看记录',
                    loading: true,
                    compact: true,
                  )
                else if (historyError != null)
                  PageStatePanel(
                    title: '暂时无法读取观看记录',
                    message: '重试后会重新读取本机观看历史。',
                    error: true,
                    compact: true,
                    action: OutlinedButton(
                      onPressed: _retry,
                      child: const Text('重试'),
                    ),
                  )
                else if (events.isEmpty)
                  PageStatePanel(
                    title: search.text.trim().isEmpty && selectedDate == null
                        ? '还没有观看记录'
                        : '没有符合条件的记录',
                    message: search.text.trim().isEmpty && selectedDate == null
                        ? '从动漫库的进度 +1 开始，时间轴会记录每一次观看。'
                        : '调整日期或搜索条件试试。',
                    compact: true,
                  )
                else if (viewMode == _TimelineViewMode.timeline)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final group in groups)
                        _TimelineGroupView(
                          group: group,
                          totalCount: groupCounts[group.key]!,
                          recordsByUuid: recordsByUuid,
                          covers: widget.covers,
                          onOpen: widget.onOpen,
                        ),
                    ],
                  )
                else
                  _HistoryTable(
                    events: pageEvents,
                    recordsByUuid: recordsByUuid,
                    onOpen: widget.onOpen,
                    sort: sort,
                    onSort: () => setState(() {
                      sort = sort == _TimelineSort.newest
                          ? _TimelineSort.oldest
                          : _TimelineSort.newest;
                      historyPage = 0;
                    }),
                  ),
                if (!historyLoading &&
                    historyError == null &&
                    events.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PaginationControls(
                      total: events.length,
                      page: historyPage,
                      pageSize: _historyPageSize,
                      alignEnd: true,
                      onChanged: _changeHistoryPage,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
    final side = _recentWorksView(recent);
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [main, const SizedBox(height: 20), side],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: main),
        const SizedBox(width: 20),
        Expanded(child: side),
      ],
    );
  }

  Future<void> _pickHistoryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(selectedDate ?? '') ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      helpText: '筛选观看日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (date == null || !mounted) return;
    setState(() {
      selectedDate = _dateKey(date);
      _resetPages();
    });
  }

  Widget _historyToolbar() => LayoutBuilder(
    builder: (context, constraints) {
      final searchField = TextField(
        controller: search,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 20),
          hintText: '搜索番剧、原名或集数…',
          suffixIcon: search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: '清空搜索',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    search.clear();
                    _resetPages();
                  }),
                ),
        ),
        onChanged: (_) => setState(_resetPages),
        textInputAction: TextInputAction.search,
      );
      final controls = Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<_TimelineViewMode>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(
                value: _TimelineViewMode.timeline,
                icon: Icon(Icons.timeline_rounded, size: 16),
                label: Text('时间线'),
              ),
              ButtonSegment(
                value: _TimelineViewMode.list,
                icon: Icon(Icons.view_list_rounded, size: 16),
                label: Text('列表'),
              ),
            ],
            selected: {viewMode},
            onSelectionChanged: (value) => setState(() {
              viewMode = value.single;
              historyPage = 0;
            }),
          ),
          if (viewMode == _TimelineViewMode.timeline)
            SegmentedButton<_TimelineGrouping>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(value: _TimelineGrouping.day, label: Text('按天')),
                ButtonSegment(value: _TimelineGrouping.week, label: Text('按周')),
                ButtonSegment(
                  value: _TimelineGrouping.month,
                  label: Text('按月'),
                ),
              ],
              selected: {grouping},
              onSelectionChanged: (value) => setState(() {
                grouping = value.single;
                historyPage = 0;
              }),
            ),
          OutlinedButton.icon(
            onPressed: _pickHistoryDate,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(selectedDate ?? '全部日期'),
          ),
          if (selectedDate != null)
            IconButton(
              tooltip: '清空日期筛选',
              onPressed: () => setState(() {
                selectedDate = null;
                _resetPages();
              }),
              icon: const Icon(Icons.close, size: 18),
            ),
          PopupMenuButton<_TimelineSort>(
            initialValue: sort,
            tooltip: '排序',
            onSelected: (value) => setState(() {
              sort = value;
              historyPage = 0;
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _TimelineSort.newest, child: Text('最新优先')),
              PopupMenuItem(value: _TimelineSort.oldest, child: Text('最早优先')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(sort == _TimelineSort.newest ? '最新优先' : '最早优先'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          if (constraints.maxWidth >= 1050)
            SizedBox(width: 260, child: searchField),
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          controls,
          if (constraints.maxWidth < 1050) ...[
            const SizedBox(height: 12),
            searchField,
          ],
        ],
      );
    },
  );

  Widget _recentWorksView(List<_RecentWork> recent) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedDate == null ? '最近观看作品' : '当日观看作品',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${recent.length} 部作品 · 按最近观看时间排序 · 第 ${recentPage + 1}/${pageCount(recent.length, _recentPageSize)} 页',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (recent.isEmpty)
          const PageStatePanel(title: '暂无符合条件的观看作品', compact: true),
        for (final item
            in recent
                .skip(recentPage * _recentPageSize)
                .take(_recentPageSize)) ...[
          const Divider(height: 1),
          InkWell(
            mouseCursor: WidgetStateMouseCursor.clickable,
            onTap: () => widget.onOpen(item.record),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimeCover(
                    title: item.record.metadata.title,
                    url: item.record.metadata.coverUrl,
                    store: widget.covers,
                    width: 42,
                    height: 60,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '#${item.rank}  ',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              TextSpan(text: item.record.metadata.title),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (item.record.metadata.originalTitle?.isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.record.metadata.originalTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${item.latest.watchedOn} · ${item.count} 条记录',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              '最近 EP ${item.latest.episode}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            RecordBadge(label: statusLabel(item.record.status)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (recent.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PaginationControls(
              total: recent.length,
              page: recentPage,
              pageSize: _recentPageSize,
              alignEnd: true,
              onChanged: (value) => setState(() => recentPage = value),
            ),
          ),
      ],
    ),
  );

  List<_TimelineGroup> _groups(List<WatchHistoryRecord> events) {
    final grouped = <String, _TimelineGroup>{};
    for (final event in events) {
      final date = _calendarDate(event.watchedOn);
      final key = _groupKey(date, event.watchedOn);
      final group = grouped.putIfAbsent(
        key,
        () => _TimelineGroup(key, _groupLabel(date, event.watchedOn)),
      );
      group.events.add(event);
    }
    final values = grouped.values.toList();
    for (final group in values) {
      group.events.sort((a, b) => _compareEvents(a, b, sort));
    }
    values.sort((a, b) {
      final comparison = a.key.compareTo(b.key);
      return sort == _TimelineSort.newest ? -comparison : comparison;
    });
    return values;
  }

  List<_RecentWork> _recentWorks(
    List<WatchHistoryRecord> events,
    Map<String, AnimeRecord> recordsByUuid,
  ) {
    final grouped = <String, List<WatchHistoryRecord>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.animeUuid, () => []).add(event);
    }
    final works = <_RecentWork>[];
    for (final entry in grouped.entries) {
      final record = recordsByUuid[entry.key];
      if (record == null) continue;
      final values = entry.value..sort(_compareEvents);
      works.add(_RecentWork(record, values.first, values.length));
    }
    works.sort((a, b) => _compareEvents(a.latest, b.latest));
    return [
      for (final item in works.indexed)
        _RecentWork(item.$2.record, item.$2.latest, item.$2.count, item.$1 + 1),
    ];
  }

  String _groupKey(DateTime? date, String fallback) {
    if (date == null) return fallback;
    final normalized = switch (grouping) {
      _TimelineGrouping.day => date,
      _TimelineGrouping.week => date.subtract(Duration(days: date.weekday - 1)),
      _TimelineGrouping.month => DateTime.utc(date.year, date.month),
    };
    return _dateKey(normalized);
  }

  String _groupLabel(DateTime? date, String fallback) {
    if (date == null) return fallback;
    return switch (grouping) {
      _TimelineGrouping.day => _fullDateLabel(date),
      _TimelineGrouping.week =>
        '${_fullDateLabel(date.subtract(Duration(days: date.weekday - 1)))} 起的一周',
      _TimelineGrouping.month => '${date.year}年${date.month}月',
    };
  }

  String _groupingLabel(_TimelineGrouping value) => switch (value) {
    _TimelineGrouping.day => '天',
    _TimelineGrouping.week => '周',
    _TimelineGrouping.month => '月',
  };

  String _rangeLabel(int days) => switch (days) {
    7 => '周',
    30 => '月',
    _ => '年',
  };
}

class _TimelineGroup {
  final String key;
  final String label;
  final List<WatchHistoryRecord> events = [];

  _TimelineGroup(this.key, this.label);
}

class _RecentWork {
  final AnimeRecord record;
  final WatchHistoryRecord latest;
  final int count;
  final int rank;

  _RecentWork(this.record, this.latest, this.count, [this.rank = 0]);
}

class _TimelineGroupView extends StatelessWidget {
  final _TimelineGroup group;
  final int totalCount;
  final Map<String, AnimeRecord> recordsByUuid;
  final CoverStore? covers;
  final void Function(AnimeRecord) onOpen;

  const _TimelineGroupView({
    required this.group,
    required this.totalCount,
    required this.recordsByUuid,
    required this.covers,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _TimelineNode(
        header: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 20),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RecordBadge(label: group.label),
              Text(
                totalCount == group.events.length
                    ? '$totalCount 集'
                    : '本页 ${group.events.length} / 共 $totalCount 集',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      for (final event in group.events)
        _TimelineNode(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${event.watchedOn.replaceAll('-', '/')}  ${_timeLabel(event)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                _TimelineEventView(
                  event: event,
                  record: recordsByUuid[event.animeUuid]!,
                  covers: covers,
                  onOpen: onOpen,
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _TimelineNode extends StatelessWidget {
  final Widget child;
  final bool header;
  const _TimelineNode({required this.child, this.header = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 15,
          child: Container(
            width: 2,
            color: colors.primary.withValues(alpha: .2),
          ),
        ),
        Padding(padding: const EdgeInsets.only(left: 46), child: child),
        Positioned(
          left: header ? 0 : 10,
          top: header ? 4 : 3,
          child: Container(
            width: header ? 32 : 12,
            height: header ? 32 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
              border: Border.all(
                color: colors.primary.withValues(alpha: .4),
                width: 2,
              ),
            ),
            child: header
                ? Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: colors.primary,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _TimelineEventView extends StatelessWidget {
  final WatchHistoryRecord event;
  final AnimeRecord record;
  final CoverStore? covers;
  final void Function(AnimeRecord) onOpen;

  const _TimelineEventView({
    required this.event,
    required this.record,
    required this.covers,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      mouseCursor: WidgetStateMouseCursor.clickable,
      onTap: () => onOpen(record),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimeCover(
              title: record.metadata.title,
              url: record.metadata.coverUrl,
              store: covers,
              width: 44,
              height: 64,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.metadata.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RecordBadge(label: 'EP ${event.episode}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _HistoryProgress(
                    episode: event.episode,
                    total: record.metadata.totalEpisodes,
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RecordBadge(label: statusLabel(record.status)),
                      if (record.metadata.originalTitle?.isNotEmpty ?? false)
                        Text(
                          record.metadata.originalTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HistoryProgress extends StatelessWidget {
  final int episode;
  final int? total;
  const _HistoryProgress({required this.episode, required this.total});

  @override
  Widget build(BuildContext context) {
    final known = total != null && total! > 0;
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (known) ...[
          Expanded(
            child: Semantics(
              label: '观看进度 $episode / $total 集',
              child: Container(
                height: 5,
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  widthFactor: (episode / total!).clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.tertiary],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          '$episode / ${known ? total : '?'}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _HistoryTable extends StatelessWidget {
  final List<WatchHistoryRecord> events;
  final Map<String, AnimeRecord> recordsByUuid;
  final void Function(AnimeRecord) onOpen;
  final _TimelineSort sort;
  final VoidCallback onSort;
  const _HistoryTable({
    required this.events,
    required this.recordsByUuid,
    required this.onOpen,
    required this.sort,
    required this.onSort,
  });

  Widget _cell(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: child,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final width = math.max(constraints.maxWidth, 640.0 * scale);
      final colors = Theme.of(context).colorScheme;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: FixedColumnWidth(140 * scale),
              1: const FlexColumnWidth(2),
              2: FixedColumnWidth(100 * scale),
              3: const FlexColumnWidth(1.5),
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: colors.outlineVariant.withValues(alpha: .5),
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(color: colors.surfaceContainerLow),
                children: [
                  InkWell(
                    mouseCursor: WidgetStateMouseCursor.clickable,
                    onTap: onSort,
                    child: _cell(
                      Row(
                        children: [
                          const Text('时间'),
                          const SizedBox(width: 6),
                          Icon(
                            sort == _TimelineSort.newest
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (final label in ['番剧', '集数', '进度'])
                    _cell(
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
              for (final event in events)
                TableRow(
                  children: [
                    _cell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.watchedOn.replaceAll('-', '/'),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timeLabel(event),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      mouseCursor: WidgetStateMouseCursor.clickable,
                      onTap: () => onOpen(recordsByUuid[event.animeUuid]!),
                      child: _cell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recordsByUuid[event.animeUuid]!.metadata.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (recordsByUuid[event.animeUuid]!
                                    .metadata
                                    .originalTitle
                                    ?.isNotEmpty ??
                                false) ...[
                              const SizedBox(height: 4),
                              Text(
                                recordsByUuid[event.animeUuid]!
                                    .metadata
                                    .originalTitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _cell(
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RecordBadge(label: 'EP ${event.episode}'),
                      ),
                    ),
                    _cell(
                      _HistoryProgress(
                        episode: event.episode,
                        total: recordsByUuid[event.animeUuid]!
                            .metadata
                            .totalEpisodes,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _TimelineLineChart extends StatefulWidget {
  final List<StatisticBucket> buckets;
  const _TimelineLineChart({required this.buckets});

  @override
  State<_TimelineLineChart> createState() => _TimelineLineChartState();
}

class _TimelineLineChartState extends State<_TimelineLineChart> {
  int? selected;

  @override
  void didUpdateWidget(_TimelineLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buckets != widget.buckets) selected = null;
  }

  void _select(Offset? point, double width) {
    final index = point == null || widget.buckets.isEmpty || width <= 16
        ? null
        : ((point.dx - 8) / (width - 16) * (widget.buckets.length - 1))
              .round()
              .clamp(0, widget.buckets.length - 1);
    if (selected != index) setState(() => selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, size) => ChartHoverRegion(
        message: selected == null
            ? ''
            : statisticTooltip(widget.buckets[selected!]),
        highlight: false,
        cursor: SystemMouseCursors.precise,
        onPositionChanged: (point) => _select(point, size.maxWidth),
        child: Semantics(
          label: '观看趋势折线图，共 ${widget.buckets.length} 个时间点；移动鼠标或点按查看日期与数量',
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _TimelineLinePainter(
                buckets: widget.buckets,
                selected: selected,
                lineColor: colors.primary,
                fillColor: colors.primary.withValues(alpha: .14),
                gridColor: colors.outlineVariant.withValues(alpha: .55),
                backgroundColor: colors.surface,
                labelStyle: Theme.of(context).textTheme.labelSmall!,
                textScaler: MediaQuery.textScalerOf(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineLinePainter extends CustomPainter {
  final List<StatisticBucket> buckets;
  final int? selected;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color backgroundColor;
  final TextStyle labelStyle;
  final TextScaler textScaler;

  const _TimelineLinePainter({
    required this.buckets,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.backgroundColor,
    required this.labelStyle,
    required this.textScaler,
    this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty || size.width <= 16 || size.height <= 44) return;
    const top = 12.0;
    const bottom = 32.0;
    final chart = Rect.fromLTRB(8, top, size.width - 8, size.height - bottom);
    final peak = buckets.fold<int>(
      1,
      (value, item) => math.max(value, item.count),
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var row = 0; row <= 3; row++) {
      final y = chart.bottom - chart.height * row / 3;
      _drawDashedLine(
        canvas,
        Offset(chart.left, y),
        Offset(chart.right, y),
        gridPaint,
      );
    }
    final points = [
      for (var index = 0; index < buckets.length; index++)
        Offset(
          buckets.length == 1
              ? chart.center.dx
              : chart.left + chart.width * index / (buckets.length - 1),
          chart.bottom - chart.height * buckets[index].count / peak,
        ),
    ];
    if (selected != null && selected! < points.length) {
      _drawDashedLine(
        canvas,
        Offset(points[selected!].dx, chart.top),
        Offset(points[selected!].dx, chart.bottom),
        Paint()
          ..color = lineColor.withValues(alpha: .6)
          ..strokeWidth = 1,
      );
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final midpoint = (previous.dx + current.dx) / 2;
      line.cubicTo(
        midpoint,
        previous.dy,
        midpoint,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    final fill = Path.from(line)
      ..lineTo(points.last.dx, chart.bottom)
      ..lineTo(points.first.dx, chart.bottom)
      ..close();
    canvas.drawPath(fill, Paint()..color = fillColor);
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final dotPaint = Paint()..color = lineColor;
    final innerPaint = Paint()..color = backgroundColor;
    for (final item in points.indexed) {
      canvas.drawCircle(item.$2, item.$1 == selected ? 7 : 5, dotPaint);
      canvas.drawCircle(item.$2, item.$1 == selected ? 3 : 2.2, innerPaint);
    }
    final maxLabels = math.max(
      2,
      (chart.width / (70 * textScaler.scale(1))).floor(),
    );
    final labelStep = math.max(
      1,
      ((buckets.length - 1) / (maxLabels - 1)).ceil(),
    );
    for (var index = 0; index < buckets.length; index += labelStep) {
      _drawLabel(
        canvas,
        buckets[index].label,
        points[index].dx,
        chart.bottom + 10,
        rightBound: size.width,
      );
    }
    if (buckets.length > 1 && (buckets.length - 1) % labelStep != 0) {
      _drawLabel(
        canvas,
        buckets.last.label,
        points.last.dx,
        chart.bottom + 10,
        alignRight: true,
        rightBound: size.width,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String value,
    double x,
    double y, {
    bool alignRight = false,
    required double rightBound,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout(maxWidth: 90);
    final left = alignRight ? x - painter.width : x - painter.width / 2;
    painter.paint(
      canvas,
      Offset(
        left.clamp(0, math.max(0, rightBound - painter.width)).toDouble(),
        y,
      ),
    );
    painter.dispose();
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 5.0;
    final length = (end - start).distance;
    final direction = (end - start) / length;
    for (var distance = 0.0; distance < length; distance += dash + gap) {
      final from = start + direction * distance;
      final to = start + direction * math.min(distance + dash, length);
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineLinePainter oldDelegate) =>
      oldDelegate.buckets != buckets ||
      oldDelegate.selected != selected ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.backgroundColor != backgroundColor;
}

class _WatchHeatmap extends StatelessWidget {
  final List<WatchHistoryRecord> events;

  const _WatchHeatmap({required this.events});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final end = DateTime.utc(now.year, now.month, now.day);
    final yearAgo = end.subtract(const Duration(days: 364));
    final first = yearAgo.subtract(Duration(days: yearAgo.weekday % 7));
    final last = end.add(Duration(days: 6 - end.weekday % 7));
    final weeks = last.difference(first).inDays ~/ 7 + 1;
    final counts = <String, int>{};
    final works = <String, Set<String>>{};
    for (final event in events) {
      final date = _calendarDate(event.watchedOn);
      if (date == null || date.isBefore(yearAgo) || date.isAfter(end)) continue;
      counts.update(event.watchedOn, (value) => value + 1, ifAbsent: () => 1);
      works.putIfAbsent(event.watchedOn, () => {}).add(event.animeUuid);
    }
    final peak = counts.values.fold<int>(1, math.max);
    final activeDays = counts.length;
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        const labelsWidth = 38.0;
        const minCellSize = 10.0;
        final cellSize = math.max(
          minCellSize,
          (constraints.maxWidth - labelsWidth - (weeks - 1) * gap) / weeks,
        );
        final gridWidth = weeks * (cellSize + gap) - gap;
        final content = SizedBox(
          width: labelsWidth + gridWidth,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: labelsWidth),
                child: SizedBox(
                  height: 22 * MediaQuery.textScalerOf(context).scale(1),
                  child: Stack(
                    children: [
                      for (var week = 0; week < weeks; week++)
                        if (_heatmapMonthLabel(first, week).isNotEmpty)
                          Positioned(
                            left: week * (cellSize + gap),
                            child: Text(
                              _heatmapMonthLabel(first, week),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: labelsWidth,
                    child: Column(
                      children: [
                        for (final item in const [
                          '日',
                          '',
                          '二',
                          '',
                          '四',
                          '',
                          '六',
                        ].indexed)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: item.$1 == 6 ? 0 : gap,
                            ),
                            child: SizedBox(
                              height: cellSize,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.$2,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (var week = 0; week < weeks; week++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: week == weeks - 1 ? 0 : gap,
                      ),
                      child: Column(
                        children: [
                          for (var day = 0; day < 7; day++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: day == 6 ? 0 : gap,
                              ),
                              child: _HeatmapCell(
                                date: first.add(Duration(days: week * 7 + day)),
                                start: yearAgo,
                                end: end,
                                size: cellSize,
                                count:
                                    counts[_dateKey(
                                      first.add(Duration(days: week * 7 + day)),
                                    )],
                                peak: peak,
                                works:
                                    works[_dateKey(
                                          first.add(
                                            Duration(days: week * 7 + day),
                                          ),
                                        )]
                                        ?.length ??
                                    0,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: content,
        );
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$activeDays / 365 天有记录 · 单日最多 ${counts.values.fold<int>(0, math.max)} 集',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: grid,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('少', style: Theme.of(context).textTheme.labelSmall),
            for (var level = 0; level <= 4; level++)
              _HeatmapLegendCell(level: level),
            Text('多', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final DateTime date;
  final DateTime start;
  final DateTime end;
  final double size;
  final int? count;
  final int peak;
  final int works;

  const _HeatmapCell({
    required this.date,
    required this.start,
    required this.end,
    required this.size,
    required this.count,
    required this.peak,
    required this.works,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final future = date.isAfter(end) || date.isBefore(start);
    if (future) return SizedBox(width: size, height: size);
    final level = count == null || count == 0
        ? 0
        : math.max(1, math.min(4, (count! / peak * 4).ceil()));
    final color = level == 0
        ? colors.surfaceContainerHighest.withValues(alpha: .65)
        : colors.primary.withValues(alpha: .18 + level * .18);
    return Semantics(
      label: '${_dateKey(date)}：$works 部作品，${count ?? 0} 集记录',
      excludeSemantics: true,
      child: ChartHoverRegion(
        key: ValueKey(_dateKey(date)),
        message: '${_fullDateLabel(date)}\n$works 部作品 · ${count ?? 0} 集记录',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _HeatmapLegendCell extends StatelessWidget {
  final int level;

  const _HeatmapLegendCell({required this.level});

  @override
  Widget build(BuildContext context) => Container(
    width: 13,
    height: 13,
    decoration: BoxDecoration(
      color: level == 0
          ? Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: .65)
          : Theme.of(context).colorScheme.primary
                .withValues(alpha: .18 + level * .18),
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

String _fullDateLabel(DateTime date) =>
    '${date.year}年${date.month}月${date.day}日 ${_weekdayLabel(date.weekday)}';

String _weekdayLabel(int weekday) => const {
  1: '周一',
  2: '周二',
  3: '周三',
  4: '周四',
  5: '周五',
  6: '周六',
  7: '周日',
}[weekday]!;

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime? _calendarDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final date = DateTime.tryParse('${value}T00:00:00Z');
  if (date == null) return null;
  return DateTime.utc(date.year, date.month, date.day);
}

int _compareEvents(
  WatchHistoryRecord a,
  WatchHistoryRecord b, [
  _TimelineSort sort = _TimelineSort.newest,
]) {
  final comparison = _eventMoment(a).compareTo(_eventMoment(b));
  if (comparison != 0) {
    return sort == _TimelineSort.newest ? -comparison : comparison;
  }
  return sort == _TimelineSort.newest
      ? b.createdAt.compareTo(a.createdAt)
      : a.createdAt.compareTo(b.createdAt);
}

DateTime _eventMoment(WatchHistoryRecord event) =>
    DateTime.tryParse(event.watchedAt ?? '') ??
    _calendarDate(event.watchedOn) ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

String? _timeBucket(String? value) {
  final date = DateTime.tryParse(value ?? '')?.toLocal();
  if (date == null) return null;
  return switch (date.hour) {
    >= 0 && < 6 => '凌晨',
    >= 6 && < 12 => '上午',
    >= 12 && < 18 => '下午',
    _ => '晚上',
  };
}

String _timeLabel(WatchHistoryRecord event) => historyTimeLabel(event);

String _heatmapMonthLabel(DateTime first, int week) {
  final date = first.add(Duration(days: week * 7));
  final previous = date.subtract(const Duration(days: 7));
  return week == 0 || date.month != previous.month ? '${date.month}月' : '';
}
