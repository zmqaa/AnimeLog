import 'package:flutter/material.dart';

import '../../application/metadata_completion.dart';
import '../../core/anime_log_core.dart';
import '../../core/api/ai_intake.dart';
import '../shared/anime_cover.dart';
import 'metadata_completion_controller.dart';
import '../shared/app_theme.dart';

class MetadataCompletionPage extends StatefulWidget {
  final String uuid;
  final MetadataCompletionService service;
  final CoverStore? covers;
  const MetadataCompletionPage({
    super.key,
    required this.uuid,
    required this.service,
    this.covers,
  });
  @override
  State<MetadataCompletionPage> createState() => _MetadataCompletionPageState();
}

class _MetadataCompletionPageState extends State<MetadataCompletionPage> {
  late final c = MetadataCompletionController(widget.uuid, widget.service);
  @override
  void initState() {
    super.initState();
    c.load();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    try {
      final count = await c.apply();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(appSnackBar(context, content: Text('已补全 $count 个资料字段')));
      Navigator.pop(context, true);
    } catch (_) {
      /* Controller retains the recoverable error and preview. */
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => PopScope(
      canPop: !c.applying,
      child: Scaffold(
        appBar: AppBar(title: const Text('补全缺失资料')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const PageHeading(
                    title: '让作品资料更完整',
                    subtitle: '从 Bangumi 查找真实资料，预览后由你确认。',
                  ),
                  const SectionCard(
                    title: '只补空缺资料',

                    children: [
                      Text('标题与已填写资料保持原样，进度、状态、评分、刷次和备注均保留。此操作无需配置 AI。'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (c.lookup != null)
                    Text(
                      '当前记录：${c.lookup!.title}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  if (c.busy) ...[
                    const LinearProgressIndicator(),
                    TextButton(onPressed: c.cancel, child: const Text('取消查询')),
                  ],
                  if (c.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: FeedbackPanel(message: '${c.error}', error: true),
                    ),
                  if (!c.busy && !c.applying)
                    TextButton(
                      key: const Key('retry-metadata'),
                      onPressed: c.load,
                      child: const Text('重新查询'),
                    ),
                  if (c.lookup != null && c.lookup!.preview == null) ...[
                    Text(
                      c.lookup!.candidates.isEmpty
                          ? '没有找到候选，请返回详情手动编辑资料。'
                          : '确认这条记录对应的具体作品：',
                    ),
                    for (final candidate in c.lookup!.candidates)
                      Card(
                        child: ListTile(
                          key: Key('completion-candidate-${candidate.id}'),
                          title: Text(candidate.title),
                          subtitle: Text(
                            '${candidate.originalTitle ?? ''}\n${candidate.entryType?.name.toUpperCase() ?? '形式未知'} · '
                            '${candidate.season == null ? '季度未知' : '第 ${candidate.season} 季'} · ${candidate.premiereDate ?? '首播未知'} · Bangumi #${candidate.id}',
                          ),
                          onTap: c.busy || c.applying
                              ? null
                              : () => c.choose(candidate.id),
                        ),
                      ),
                  ],
                  if (c.preview != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      '来源作品：${c.preview!.source.title}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (c.preview!.source.coverUrl != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: AnimeCover(
                          url: c.preview!.source.coverUrl,
                          store: widget.covers,
                          width: 120,
                          height: 168,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      c.preview!.result.changes.isEmpty
                          ? '没有可补全的空缺字段。'
                          : '本次只补全以下字段：',
                    ),
                    for (final change in c.preview!.result.changes.entries)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _label(change.key),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            SelectableText(_value(change.value)),
                          ],
                        ),
                      ),
                    for (final warning in c.preview!.result.warnings)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(warning),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('confirm-metadata-completion'),
                      onPressed:
                          c.busy ||
                              c.applying ||
                              c.preview!.result.changes.isEmpty
                          ? null
                          : _apply,
                      child: Text(c.applying ? '正在补全…' : '确认补全缺失资料'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _label(String field) => switch (field) {
  'originalTitle' => '原名',
  'season' => '季度',
  'entryType' => '作品形式',
  'sourceProvider' => '资料来源',
  'sourceId' => '来源 ID',
  'totalEpisodes' => '总集数',
  'durationMinutes' => '单集时长（分钟）',
  'summary' => '简介',
  'coverUrl' => '封面地址',
  'premiereDate' => '首播日期',
  'isFinished' => '完结情况',
  _ => field,
};
String _value(Object value) => switch (value) {
  AnimeEntryType type => type.name.toUpperCase(),
  bool finished => finished ? '已完结' : '未完结',
  _ => value.toString(),
};
