import 'package:flutter/material.dart';

import '../../core/anime_log_core.dart';
import '../../core/api/ai_intake.dart';
import '../../core/api/manga_repository.dart';
import '../../core/domain/manga_models.dart';
import '../shared/anime_cover.dart';
import '../shared/app_theme.dart';
import '../shared/history_time.dart';
import '../shared/page_state.dart';

typedef MangaEditorLauncher = Future<MangaDraft?> Function(
  BuildContext context,
  MangaRecord record,
);

class MangaDetailPage extends StatefulWidget {
  final String uuid;
  final MangaRepository repository;
  final CoverStore? covers;
  final MangaEditorLauncher editor;

  const MangaDetailPage({
    super.key,
    required this.uuid,
    required this.repository,
    required this.editor,
    this.covers,
  });

  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  late Future<MangaRecord?> recordFuture;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    recordFuture = widget.repository.find(widget.uuid);
  }

  Future<void> _edit(MangaRecord record) async {
    if (busy) return;
    final draft = await widget.editor(context, record);
    if (draft == null || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.repository.edit(record.uuid, draft);
      if (!mounted) return;
      setState(() {
        busy = false;
        recordFuture = widget.repository.find(widget.uuid);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(appSnackBar(context, content: const Text('漫画已保存')));
    } catch (error) {
      if (mounted) {
        setState(() => busy = false);
        _failure(error);
      }
    }
  }

  Future<void> _delete(MangaRecord record) async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除漫画记录？'),
        content: Text('“${record.title}”的本地记录会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.repository.delete(record.uuid);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => busy = false);
        _failure(error);
      }
    }
  }

  void _retry() {
    setState(() => recordFuture = widget.repository.find(widget.uuid));
  }

  void _failure(Object error) => ScaffoldMessenger.of(context).showSnackBar(
    appSnackBar(context, error: true, content: Text('操作未完成：$error')),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('漫画详情')),
    body: FutureBuilder<MangaRecord?>(
      future: recordFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PageStatePanel(title: '正在读取作品资料', loading: true);
        }
        if (snapshot.hasError) {
          return PageStatePanel(
            title: '暂时无法读取记录',
            details: snapshot.error.toString(),
            error: true,
            action: FilledButton(onPressed: _retry, child: const Text('重试')),
          );
        }
        final record = snapshot.data;
        if (record == null) {
          return PageStatePanel(
            title: '记录已不存在',
            action: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回漫画库'),
            ),
          );
        }
        return SafeArea(
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
        );
      },
    ),
  );

  Widget _content(MangaRecord record) => LayoutBuilder(
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

  Widget _coverPanel(MangaRecord record) => Card(
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, size) => AnimeCover(
            title: record.title,
            url: record.coverUrl,
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
              record.status.label,
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

  Widget _coverStats(MangaRecord record) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: _metrics([
        _metric('评分', record.score?.toStringAsFixed(1) ?? '未评分'),
        _metric('总卷数', record.totalVolumes?.toString() ?? '未知'),
        _metric('总话数', record.totalChapters?.toString() ?? '未知'),
      ], minimum: 76),
    ),
  );

  Widget _overview(MangaRecord record, {required bool compact}) => SectionCard(
    title: '作品概览',
    children: [
      LayoutBuilder(
        builder: (context, size) {
          final title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                AnimeCover(
                  title: record.title,
                  url: record.coverUrl,
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
                      record.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (record.originalTitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        record.originalTitle!,
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
              OutlinedButton(
                onPressed: busy ? null : () => _delete(record),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('删除记录'),
              ),
              FilledButton(
                onPressed: busy ? null : () => _edit(record),
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
          '阅读状态',
          record.status.label,
          detail: record.publicationStatus.label,
        ),
        _metric('阅读进度', _progress(record), detail: _progressDetail(record)),
        _metric(
          '最近编辑',
          localTimestampLabel(record.updatedAt),
          detail:
              '创建于 ${localTimestampLabel(record.createdAt).split(' ').first}',
        ),
      ]),
    ],
  );

  Widget _bodyColumns(MangaRecord record) => LayoutBuilder(
    builder: (context, size) {
      final primary = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_progressSection(record), _summary(record), _notes(record)],
      );
      final secondary = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_dates(record), _people(record), _metadata(record)],
      );
      if (size.maxWidth < 800 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _progressSection(record),
            _summary(record),
            _dates(record),
            _people(record),
            _notes(record),
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

  Widget _progressSection(MangaRecord record) {
    final fraction = _progressFraction(record);
    return SectionCard(
      title: '阅读进度',
      subtitle: _progress(record),
      children: [
        if (fraction == null)
          Text(
            '还没有足够的总卷数或总话数来计算完成度。',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          Semantics(
            label: '阅读进度',
            value: '${(fraction * 100).round()}%',
            child: LinearProgressIndicator(value: fraction, minHeight: 9),
          ),
          const SizedBox(height: 20),
        ],
        _metrics([
          _metric('当前卷', record.currentVolume?.toString() ?? '未记录'),
          _metric('当前话', record.currentChapter?.toString() ?? '未记录'),
          _metric('完成度', _progressDetail(record)),
        ], minimum: 140),
      ],
    );
  }

  Widget _summary(MangaRecord record) => SectionCard(
    title: '简介 / 故事',
    children: [
      if (record.summary != null)
        SelectableText(record.summary!, style: const TextStyle(height: 1.8))
      else
        Text(
          '暂无作品简介，可以通过编辑记录添加。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ],
  );

  Widget _dates(MangaRecord record) => SectionCard(
    title: '出版与连载',
    children: [
      _detailRow('连载状态', record.publicationStatus.label),
      _detailRow('出版日期', record.releaseDate ?? '未记录'),
      _detailRow('开始连载', record.startDate ?? '未记录'),
      _detailRow('结束连载', record.endDate ?? '未记录'),
    ],
  );

  Widget _people(MangaRecord record) {
    final fields = <Widget>[
      _info('作者', _join(record.authors)),
      _info('作画', _join(record.illustrators)),
      _info('出版社', _join(record.publishers)),
      _info('连载杂志', _join(record.serializations)),
    ];
    final hasPeople =
        record.authors.isNotEmpty ||
        record.illustrators.isNotEmpty ||
        record.publishers.isNotEmpty ||
        record.serializations.isNotEmpty;
    return SectionCard(
      title: '作者与出版信息',
      children: [
        if (!hasPeople)
          Text('暂未记录作者或出版信息。', style: Theme.of(context).textTheme.bodySmall)
        else
          ...fields,
      ],
    );
  }

  Widget _notes(MangaRecord record) => SectionCard(
    title: '个人备注',
    children: [
      if (record.notes != null)
        SelectableText(record.notes!, style: const TextStyle(height: 1.8))
      else
        Text(
          '还没有写下阅读感受，可以通过编辑记录添加。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ],
  );

  Widget _metadata(MangaRecord record) => SectionCard(
    title: '更多作品资料',
    collapsible: true,
    children: [
      _info('原名', record.originalTitle),
      _info('别名', _join(record.aliases)),
      _info('封面地址', record.coverUrl),
      _info('Bangumi ID', record.bangumiId?.toString()),
      _info('创建时间', localTimestampLabel(record.createdAt)),
      _info('更新时间', localTimestampLabel(record.updatedAt)),
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

  Widget _info(String label, String? value) => value == null || value.isEmpty
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

  String? _join(List<String> values) =>
      values.isEmpty ? null : values.join('、');

  String _progress(MangaRecord record) {
    final volume = record.currentVolume == null && record.totalVolumes == null
        ? null
        : '卷 ${record.currentVolume ?? '?'} / ${record.totalVolumes ?? '?'}';
    final chapter =
        record.currentChapter == null && record.totalChapters == null
        ? null
        : '话 ${record.currentChapter ?? '?'} / ${record.totalChapters ?? '?'}';
    return [?volume, ?chapter].join(' · ').isEmpty
        ? '尚未记录'
        : [?volume, ?chapter].join(' · ');
  }

  double? _progressFraction(MangaRecord record) {
    if (record.currentChapter != null &&
        record.totalChapters != null &&
        record.totalChapters! > 0) {
      return (record.currentChapter! / record.totalChapters!).clamp(0.0, 1.0);
    }
    if (record.currentVolume != null &&
        record.totalVolumes != null &&
        record.totalVolumes! > 0) {
      return (record.currentVolume! / record.totalVolumes!).clamp(0.0, 1.0);
    }
    return null;
  }

  String _progressDetail(MangaRecord record) {
    final fraction = _progressFraction(record);
    return fraction == null ? '完成度未计算' : '完成度 ${(fraction * 100).round()}%';
  }
}
