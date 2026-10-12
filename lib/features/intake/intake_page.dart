import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/manual_library.dart';
import '../../core/api/ai_intake.dart';
import '../../core/anime_log_core.dart';
import '../settings/ai_settings_page.dart';
import '../shared/anime_cover.dart';
import '../shared/app_theme.dart';
import 'editor_controller.dart';
import 'editor_page.dart';
import 'intake_controller.dart';

class IntakePage extends StatefulWidget {
  final IntakeController controller;
  final ManualLibrary useCases;
  final CoverStore? covers;
  const IntakePage({
    super.key,
    required this.controller,
    required this.useCases,
    this.covers,
  });
  @override
  State<IntakePage> createState() => _IntakePageState();
}

class _IntakePageState extends State<IntakePage> {
  IntakeController get c => widget.controller;
  late final query = TextEditingController(text: c.query);
  bool leaving = false;
  bool leaveAllowed = false;
  bool opening = false;
  @override
  void dispose() {
    query.dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> _editor({bool titleOnly = false}) async {
    if (opening || c.query.trim().isEmpty) return;
    setState(() => opening = true);
    try {
      final data = await c.prepareEditor(titleOnly: titleOnly);
      if (!mounted) return;
      final uuid = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          allowSnapshotting: false,
          builder: (_) => EditorPage(
            controller: EditorController(
              useCases: widget.useCases,
              store: c.store,
              restored: data,
            ),
            covers: widget.covers,
          ),
        ),
      );
      if (!mounted) return;
      // The editor now owns this draft; leaving it preserves every user field.
      setState(() => leaveAllowed = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, uuid);
    } catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(context, error: true, content: Text('草稿未保留：$failure')),
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => PopScope(
      canPop: leaveAllowed,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || leaving || opening) return;
        leaving = true;
        c.cancel();
        try {
          await c.flush();
          if (mounted) {
            setState(() => leaveAllowed = true);
            await WidgetsBinding.instance.endOfFrame;
            if (context.mounted) Navigator.pop(context);
          }
        } catch (failure) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              appSnackBar(
                context,
                error: true,
                content: Text('草稿未保留：$failure'),
              ),
            );
          }
        }
        leaving = false;
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
            if (c.metadata != null) {
              _editor();
            } else {
              c.recognize();
            }
          },
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('添加一部动漫')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(24),
                  children: [
                    const PageHeading(
                      title: '下一部，想记什么？',
                      subtitle: '输入作品名称，查找资料，再填写你的观看记录。也可以直接手动添加。',
                    ),
                    SectionCard(
                      title: '01 · 查找作品',
                      subtitle: '可附带季度、剧场版或 OVA，帮助区分具体作品。',

                      children: [
                        TextField(
                          key: const Key('intake-query'),
                          controller: query,
                          enabled: !opening,
                          maxLength: 200,
                          textInputAction: TextInputAction.search,
                          onChanged: c.changeQuery,
                          onSubmitted: (_) => c.recognize(),
                          decoration: const InputDecoration(
                            labelText: '作品名称',
                            hintText: '例如：某动画 第二季',
                          ),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              key: const Key('recognize-title'),
                              onPressed:
                                  c.busy || opening || c.query.trim().isEmpty
                                  ? null
                                  : c.recognize,
                              child: const Text('识别并查询资料'),
                            ),
                            if (c.busy)
                              TextButton(
                                onPressed: c.cancel,
                                child: const Text('取消识别'),
                              ),
                            OutlinedButton(
                              key: const Key('manual-intake'),
                              onPressed: opening || c.query.trim().isEmpty
                                  ? null
                                  : () => _editor(titleOnly: true),
                              child: const Text('手动添加 / 仅用标题'),
                            ),
                            TextButton(
                              onPressed: opening || c.busy
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AiSettingsPage(
                                          service: c.service.settings,
                                        ),
                                      ),
                                    ),
                              child: const Text('接口设置'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (c.busy) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(switch (c.stage) {
                        AnimeIntakeStage.recognizing => '正在识别标题…',
                        AnimeIntakeStage.searching => '正在查询 Bangumi 资料…',
                        _ => '正在推荐候选…',
                      }),
                    ],
                    if (c.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text('${c.error}'),
                      ),
                    if (c.draftError != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('草稿保存失败，请重试后再返回。'),
                      ),
                    if (c.result != null) ...[
                      const SizedBox(height: 24),
                      Text('识别标题：${c.result!.title.animeTitle}'),
                      if (c.result!.warning != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('${c.result!.warning}'),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        c.result!.candidates.isEmpty
                            ? '没有找到可靠候选，可以仅用标题继续。'
                            : '选择具体作品（推荐仍需你确认）：',
                      ),
                      for (final candidate in c.result!.candidates)
                        Card(
                          child: ListTile(
                            key: Key('candidate-${candidate.id}'),
                            contentPadding: const EdgeInsets.all(16),
                            selected:
                                c.metadata?.sourceId == candidate.id.toString(),
                            title: Text(
                              '${candidate.title}${c.result!.recommendation?.id == candidate.id ? ' · 推荐' : ''}',
                            ),
                            subtitle: Text(
                              [
                                if (candidate.originalTitle != null)
                                  candidate.originalTitle!,
                                '${candidate.entryType?.name.toUpperCase() ?? '形式未知'} · '
                                    '${candidate.season == null ? '季度未知' : '第 ${candidate.season} 季'} · '
                                    '${candidate.premiereDate ?? '首播未知'} · ${candidate.totalEpisodes ?? '?'} 集',
                                'Bangumi #${candidate.id}',
                              ].join('\n'),
                            ),
                            isThreeLine: false,
                            onTap: c.busy || opening
                                ? null
                                : () => c.choose(candidate),
                            trailing:
                                c.metadata?.sourceId == candidate.id.toString()
                                ? const Text('已选择')
                                : null,
                          ),
                        ),
                    ],
                    if (c.metadata != null) ...[
                      const SizedBox(height: 24),
                      SectionCard(
                        title: '02 · 确认作品',

                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AnimeCover(
                              url: c.metadata!.coverUrl,
                              store: widget.covers,
                              width: 120,
                              height: 168,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            c.metadata!.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (c.metadata!.originalTitle != null)
                            Text(c.metadata!.originalTitle!),
                          Text(
                            '${c.metadata!.entryType?.name.toUpperCase() ?? '形式未知'} · '
                            '${c.metadata!.season == null ? '季度未知' : '第 ${c.metadata!.season} 季'} · '
                            '首播 ${c.metadata!.premiereDate ?? '未知'} · ${c.metadata!.totalEpisodes ?? '?'} 集',
                          ),
                          if (c.metadata!.summary != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(c.metadata!.summary!),
                            ),
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('confirm-metadata'),
                            onPressed: opening ? null : () => _editor(),
                            child: const Text('确认资料，填写新记录'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
