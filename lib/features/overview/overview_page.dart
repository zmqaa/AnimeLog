import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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

class OverviewPage extends StatefulWidget {
  final List<AnimeRecord> records;
  final LibraryRepository repository;
  final CoverStore? covers;
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;
  final VoidCallback onAdd;
  final void Function(AnimeRecord) onOpen;
  final void Function(AnimeStatus?) onLibrary;

  const OverviewPage({
    super.key,
    required this.records,
    required this.repository,
    required this.onAdd,
    required this.onOpen,
    required this.onLibrary,
    this.covers,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with WidgetsBindingObserver {
  StreamSubscription<List<WatchHistoryRecord>>? subscription;
  List<WatchHistoryRecord> history = [];
  Object? historyError;
  bool historyLoading = true;
  ActivityRange range = ActivityRange.week;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen();
  }

  void _listen() {
    final repository = widget.repository;
    if (repository is! LibraryInsightsRepository) {
      historyLoading = false;
      historyError = '当前数据源未提供观看历史统计';
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
            if (mounted) {
              setState(() {
                historyError = error;
                historyLoading = false;
              });
            }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const PageStatePanel(
        title: '正在整理观看总览',
        message: '正在读取本机收藏。',
        loading: true,
      );
    }
    if (widget.error != null) {
      return PageStatePanel(
        title: '暂时无法读取收藏',
        message: '重试后会重新整理观看总览。',
        details: widget.error.toString(),
        error: true,
        action: widget.onRetry == null
            ? null
            : FilledButton(onPressed: widget.onRetry, child: const Text('重试')),
      );
    }
    final stats = LibraryStatistics(widget.records);
    final recordIds = widget.records.map((a) => a.uuid).toSet();
    final events = history
        .where((h) => recordIds.contains(h.animeUuid))
        .toList();
    final activity = ActivityStatistics.fromHistory(
      events,
      range,
      DateTime.now(),
    );
    final watching =
        widget.records.where((a) => a.status == AnimeStatus.watching).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return LayoutBuilder(
      builder: (context, size) {
        final compact =
            size.maxWidth < 700 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4;
        final wide =
            size.maxWidth >= 1080 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.4;
        final main = Column(
          children: [
            _activity(activity),
            _continueWatching(watching, limit: compact ? 2 : 3),
          ],
        );
        final side = Column(
          children: [
            _statuses(stats),
            SectionCard(
              title: '类型排行',
              collapsible: !wide,
              subtitle: '使用最多的 8 个类型，按独立记录计数。',
              children: stats.tags.isEmpty
                  ? [
                      const PageStatePanel(
                        title: '还没有类型记录',
                        message: '给记录添加类型后，可在这里查看分布。',
                        compact: true,
                      ),
                    ]
                  : [
                      for (final b in stats.tags)
                        _distribution(b.label, b.count, widget.records.length),
                    ],
            ),
          ],
        );
        return ListView(
          primary: false,
          key: const PageStorageKey('overview-scroll'),
          padding: EdgeInsets.all(size.maxWidth < 600 ? 20 : 32),
          children: [
            if (compact)
              PageHeading(title: '观看总览', subtitle: '把看过的故事，慢慢积累成自己的轨迹。')
            else
              _welcome(),
            if (compact) _quickSummary(stats) else _summary(stats),
            if (widget.records.isEmpty)
              PageStatePanel(
                title: '从第一部作品开始',

                message: '添加记录后，这里会展示你的观看进度与统计。',
                action: FilledButton(
                  onPressed: widget.onAdd,
                  child: const Text('添加动漫'),
                ),
              )
            else if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: main),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: side),
                ],
              )
            else ...[
              main,
              side,
            ],
          ],
        );
      },
    );
  }

  Widget _quickSummary(LibraryStatistics stats) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        RecordBadge(label: '收藏 ${widget.records.length} 条'),
        RecordBadge(label: '在看 ${stats.countStatus(AnimeStatus.watching)} 条'),
        RecordBadge(label: '累计 ${stats.episodes} 集'),
      ],
    ),
  );

  Widget _welcome() => PageHeading(
    title: '观看总览',
    subtitle: '查看观看进度与观看节奏',
    action: FilledButton(onPressed: widget.onAdd, child: const Text('添加动漫')),
  );

  Widget _summary(LibraryStatistics stats) {
    final colors = Theme.of(context).colorScheme;
    final values = [
      (
        '收藏记录',
        '${widget.records.length}',
        '包含普通与重刷记录',
        Icons.video_library_outlined,
      ),
      (
        '已经看完',
        '${stats.countStatus(AnimeStatus.completed)}',
        '按看完状态统计',
        Icons.task_alt,
      ),
      ('重刷记录', '${stats.rewatchRecords}', '明确标记为二刷及以上', Icons.replay_rounded),
      ('累计进度', '${stats.episodes} 集', '全部记录的当前进度之和', Icons.play_circle_outline),
      (
        '已知观看时长',
        '${(stats.knownMinutes / 60).toStringAsFixed(1)} 小时',
        '${stats.unknownDurationEpisodes} 集缺少时长，未计入',
        Icons.schedule,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: LayoutBuilder(
        builder: (context, size) {
          final minWidth = MediaQuery.textScalerOf(context).scale(162);
          final columns = math.max(
            1,
            math.min(5, ((size.maxWidth + 12) / (minWidth + 12)).floor()),
          );
          final width = (size.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in values)
                SizedBox(
                  width: width,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.$2,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  letterSpacing: -.5,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$3,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: colors.onSurfaceVariant,
                                ),
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

  Widget _continueWatching(
    List<AnimeRecord> watching, {
    int limit = 3,
  }) => SectionCard(
    title: '继续观看',

    subtitle: '最近更新的在看记录，点击继续记录进度。',
    children: [
      if (watching.isEmpty)
        const PageStatePanel(
          title: '下一段故事，等你挑选',
          message: '暂时没有在看的记录，可以去动漫库挑一部想看的作品。',
          compact: true,
        ),
      for (final a in watching.take(limit))
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              mouseCursor: WidgetStateMouseCursor.clickable,
              onTap: () => widget.onOpen(a),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    AnimeCover(
                      title: a.metadata.title,
                      url: a.metadata.coverUrl,
                      store: widget.covers,
                      width: 46,
                      height: 66,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.metadata.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${a.progress} / ${a.metadata.totalEpisodes ?? '?'} 集',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value:
                                a.metadata.totalEpisodes != null &&
                                    a.metadata.totalEpisodes! > 0
                                ? (a.progress / a.metadata.totalEpisodes!)
                                      .clamp(0.0, 1.0)
                                : 0,
                            minHeight: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      TextButton(
        onPressed: () => widget.onLibrary(AnimeStatus.watching),
        child: const Text('查看全部在看'),
      ),
    ],
  );

  Widget _activity(ActivityStatistics activity) => SectionCard(
    title: '观看趋势',

    subtitle: '仅按已保存的单集观看历史统计，手动填写进度不会补出历史。',
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in [
            (ActivityRange.week, '近 7 日'),
            (ActivityRange.month, '近 30 日'),
            (ActivityRange.year, '今年'),
          ])
            ChoiceChip(
              mouseCursor: WidgetStateMouseCursor.clickable,
              label: Text(item.$2),
              selected: range == item.$1,
              onSelected: (_) => setState(() => range = item.$1),
            ),
        ],
      ),
      const SizedBox(height: 20),
      if (historyLoading)
        const PageStatePanel(title: '正在读取观看趋势', loading: true, compact: true)
      else if (historyError != null) ...[
        PageStatePanel(
          title: '暂时无法读取观看历史',
          message: '重试后会重新统计观看趋势。',
          details: historyError.toString(),
          error: true,
          compact: true,
          action: OutlinedButton(onPressed: _retry, child: const Text('重试')),
        ),
      ] else ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            RecordBadge(label: '${activity.events} 次单集观看'),
            RecordBadge(label: '${activity.activeDays} 个活跃日'),
            RecordBadge(
              label:
                  '日均 ${(activity.events / activity.days).toStringAsFixed(1)} 集',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (activity.events == 0)
          const PageStatePanel(
            title: '这段时间还没有观看历史',
            message: '使用进度 +1 或在详情补记后，这里会出现趋势。',
            compact: true,
          )
        else
          _BarChart(buckets: activity.buckets, unit: '集'),
      ],
    ],
  );

  Widget _statuses(LibraryStatistics stats) => SectionCard(
    title: '观看状态',

    subtitle: '点击状态，进入对应的动漫库筛选。',
    children: [
      _StatusPieChart(
        slices: [
          for (final entry in AnimeStatus.values.indexed)
            _StatusSlice(
              entry.$2,
              stats.countStatus(entry.$2),
              [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.error,
                Theme.of(context).colorScheme.tertiary,
              ][entry.$1],
            ),
        ],
        total: widget.records.length,
        onSelected: widget.onLibrary,
      ),
    ],
  );

  Widget _distribution(
    String label,
    int count,
    int total, {
    bool percent = false,
  }) => ChartHoverRegion(
    message:
        '$label\n$count 条记录 · ${total == 0 ? 0 : (count / total * 100).round()}%',
    child: Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              const SizedBox(width: 12),
              Text(
                percent
                    ? '${total == 0 ? 0 : (count / total * 100).round()}% · $count 条'
                    : '$count 条',
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total == 0 ? 0 : count / total,
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ),
  );
}

/// Native bars retain labels/values and scroll instead of shrinking text.
class _BarChart extends StatelessWidget {
  final List<StatisticBucket> buckets;
  final String unit;
  const _BarChart({required this.buckets, required this.unit});

  @override
  Widget build(BuildContext context) {
    final peak = buckets.fold<int>(1, (n, b) => math.max(n, b.count));
    final colors = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, size) {
        final width = math.max(
          size.maxWidth,
          buckets.length * 46.0 * textScale,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bucket in buckets)
                  Expanded(
                    child: ChartHoverRegion(
                      key: ValueKey(bucket.periodLabel ?? bucket.label),
                      message: statisticTooltip(bucket, unit: unit),
                      child: Semantics(
                        label: statisticTooltip(bucket, unit: unit),
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${bucket.count}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 112,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: bucket.count == 0
                                        ? 2
                                        : math.max(
                                            5,
                                            bucket.count / peak * 112,
                                          ),
                                    width: 22,
                                    decoration: BoxDecoration(
                                      color: bucket.count == 0
                                          ? colors.outlineVariant
                                          : colors.primary,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bucket.label,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusSlice {
  final AnimeStatus status;
  final int count;
  final Color color;

  const _StatusSlice(this.status, this.count, this.color);
}

class _StatusPieChart extends StatefulWidget {
  final List<_StatusSlice> slices;
  final int total;
  final ValueChanged<AnimeStatus> onSelected;

  const _StatusPieChart({
    required this.slices,
    required this.total,
    required this.onSelected,
  });

  @override
  State<_StatusPieChart> createState() => _StatusPieChartState();
}

class _StatusPieChartState extends State<_StatusPieChart> {
  AnimeStatus? hovered;
  List<_StatusSlice> get slices => widget.slices;
  int get total => widget.total;

  void _hover(AnimeStatus? status) {
    if (hovered != status) setState(() => hovered = status);
  }

  String _sliceTooltip(_StatusSlice slice) =>
      '${statusLabel(slice.status)}\n${slice.count} 条记录 · ${total == 0 ? 0 : (slice.count / total * 100).round()}%';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final chartSize = math.min(190.0, math.max(140.0, size.maxWidth * .46));
      final activeSlice = slices
          .where((slice) => slice.status == hovered)
          .firstOrNull;
      final chart = SizedBox(
        width: chartSize,
        height: chartSize,
        child: ChartHoverRegion(
          message: activeSlice == null ? '' : _sliceTooltip(activeSlice),
          highlight: false,
          cursor: hovered == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onPositionChanged: (point) =>
              _hover(point == null ? null : _sliceAt(point, chartSize)),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final status = _sliceAt(details.localPosition, chartSize);
              if (status != null) widget.onSelected(status);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _StatusPiePainter(
                    slices: slices,
                    total: total,
                    background: Theme.of(context).colorScheme.surface,
                    hovered: hovered,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${activeSlice?.count ?? total}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        activeSlice == null
                            ? '部作品'
                            : statusLabel(activeSlice.status),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final legend = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final slice in slices)
            ChartHoverRegion(
              message: _sliceTooltip(slice),
              highlight: false,
              cursor: SystemMouseCursors.click,
              child: InkWell(
                mouseCursor: WidgetStateMouseCursor.clickable,
                borderRadius: BorderRadius.circular(8),
                onTap: () => widget.onSelected(slice.status),
                onHover: (active) => _hover(active ? slice.status : null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: slice.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(statusLabel(slice.status))),
                      Text('${slice.count} 条'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
      if (size.maxWidth < 360) {
        return Column(children: [chart, const SizedBox(height: 12), legend]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          chart,
          const SizedBox(width: 18),
          Expanded(child: legend),
        ],
      );
    },
  );

  AnimeStatus? _sliceAt(Offset point, double size) {
    final center = Offset(size / 2, size / 2);
    final delta = point - center;
    if (total == 0 ||
        delta.distance < size * .23 ||
        delta.distance > size * .47) {
      return null;
    }
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += math.pi * 2;
    final target = angle / (math.pi * 2) * total;
    var cursor = 0;
    for (final slice in slices) {
      cursor += slice.count;
      if (slice.count > 0 && target < cursor) {
        return slice.status;
      }
    }
    return null;
  }
}

class _StatusPiePainter extends CustomPainter {
  final List<_StatusSlice> slices;
  final int total;
  final Color background;
  final AnimeStatus? hovered;

  const _StatusPiePainter({
    required this.slices,
    required this.total,
    required this.background,
    this.hovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .34;
    final strokeWidth = size.shortestSide * .22;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = background.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.count == 0) continue;
      final sweep = math.pi * 2 * slice.count / total;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = hovered == slice.status
            ? strokeWidth * 1.12
            : strokeWidth;
      canvas.drawArc(
        rect,
        start + .015,
        math.max(0, sweep - .03),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusPiePainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.slices != slices ||
      oldDelegate.hovered != hovered ||
      oldDelegate.background != background;
}
