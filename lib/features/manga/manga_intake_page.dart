import 'package:flutter/material.dart';

import '../../application/manga_intake.dart';
import '../../core/api/ai_intake.dart';
import '../../core/anime_log_core.dart';
import '../../core/domain/manga_models.dart';
import '../shared/anime_cover.dart';
import '../shared/app_theme.dart';
import '../shared/form_controls.dart';

class MangaLookupPanel extends StatefulWidget {
  final MangaIntake intake;
  final CoverStore? covers;

  const MangaLookupPanel({super.key, required this.intake, this.covers});

  @override
  State<MangaLookupPanel> createState() => _MangaLookupPanelState();
}

class _MangaLookupPanelState extends State<MangaLookupPanel> {
  final query = TextEditingController();
  RequestScope? scope;
  MangaIntakeStage? stage;
  MangaLookupResult? result;
  MangaMetadataCandidate? selected;
  Object? error;

  bool get busy => stage != null;

  @override
  void dispose() {
    scope?.cancel();
    query.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final input = query.text.trim();
    if (input.isEmpty || busy) return;
    final request = RequestScope();
    scope?.cancel();
    setState(() {
      scope = request;
      stage = MangaIntakeStage.searching;
      result = null;
      selected = null;
      error = null;
    });
    try {
      final found = await widget.intake.lookup(
        input,
        request,
        onStage: (value) {
          if (mounted && identical(scope, request)) {
            setState(() => stage = value);
          }
        },
      );
      if (mounted && identical(scope, request)) {
        setState(() {
          result = found;
          stage = null;
        });
      }
    } catch (failure) {
      if (failure is NetworkFailure &&
          failure.kind == NetworkFailureKind.cancelled) {
        return;
      }
      if (mounted && identical(scope, request)) {
        setState(() {
          error = failure;
          stage = null;
        });
      }
    } finally {
      request.cancel();
      if (identical(scope, request)) scope = null;
    }
  }

  void _continue() {
    final candidate = selected;
    if (candidate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(appSnackBar(context, content: const Text('请先选择一条漫画候选')));
      return;
    }
    Navigator.pop(context, candidate.toDraft());
  }

  void _manual() {
    final input = query.text.trim();
    if (input.isEmpty || busy) return;
    Navigator.pop(context, MangaDraft(title: input));
  }

  @override
  Widget build(BuildContext context) => FormPanel(
    title: '添加漫画',
    subtitle: '先从 Bangumi 找到真实候选，卷数和章节数仅作为可修改的来源资料。',
    onSave: _continue,
    saveLabel: selected == null ? '选择候选后继续' : '继续填写',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: '01 · 查询资料',
          children: [
            TextField(
              controller: query,
              enabled: !busy,
              maxLength: 200,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _lookup(),
              decoration: const InputDecoration(
                labelText: '漫画名称',
                hintText: '例如：葬送的芙莉莲',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy || query.text.trim().isEmpty ? null : _lookup,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('查询资料'),
                ),
                if (busy)
                  TextButton(
                    onPressed: () => scope?.cancel(),
                    child: const Text('取消查询'),
                  ),
                OutlinedButton(
                  onPressed: busy || query.text.trim().isEmpty ? null : _manual,
                  child: const Text('仅用标题手动添加'),
                ),
              ],
            ),
          ],
        ),
        if (busy) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            stage == MangaIntakeStage.choosing
                ? '正在整理候选…'
                : '正在查询 Bangumi 漫画资料…',
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            '查询失败：$error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (result != null) ...[
          const SizedBox(height: 20),
          SectionCard(
            title: '02 · 确认作品',
            subtitle: result!.reason,
            children: [
              if (result!.warning != null) ...[
                Text(
                  'AI 建议暂不可用：${result!.warning}，仍可手动选择真实候选。',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (result!.candidates.isEmpty)
                const Text('没有可确认的候选，可以使用上面的「仅用标题手动添加」。')
              else
                for (final candidate in result!.candidates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _candidate(candidate),
                  ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _candidate(MangaMetadataCandidate candidate) {
    final isSelected = selected?.id == candidate.id;
    final isRecommended = result?.recommendation?.id == candidate.id;
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: isSelected ? colors.primaryContainer : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : () => setState(() => selected = candidate),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimeCover(
                url: candidate.coverUrl,
                store: widget.covers,
                title: candidate.title,
                width: 58,
                height: 82,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          candidate.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (isRecommended)
                          Chip(
                            label: const Text('推荐'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    if (candidate.originalTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        candidate.originalTitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _description(candidate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSelected ? '已选择，点击底部按钮继续填写' : '点击选择这部漫画',
                      style: TextStyle(
                        color: isSelected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : null,
                      ),
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

  String _description(MangaMetadataCandidate candidate) {
    final counts = [
      if (candidate.volumeCount != null) '卷 ${candidate.volumeCount}',
      if (candidate.chapterCount != null) '话 ${candidate.chapterCount}',
      if (candidate.releaseDate != null) candidate.releaseDate!,
    ];
    final people = candidate.authors.isEmpty
        ? null
        : '作者：${candidate.authors.take(2).join('、')}';
    final details = <String>[
      ?people,
      if (counts.isNotEmpty) counts.join(' · '),
      if (candidate.isFinished == true) '已完结',
      if (candidate.isFinished == false) '连载中',
    ];
    return details.isEmpty ? '资料较少，可继续手动补充' : details.join(' · ');
  }
}
