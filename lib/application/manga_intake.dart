import '../core/ai/manga_lookup_prompt.dart';
import '../core/api/ai_intake.dart';
import '../core/api/manga_intake.dart';
import '../core/domain/manga_models.dart';
import '../core/domain/quick_record_text.dart';
import 'ai_settings.dart';

class MangaIntake {
  final AiSettings settings;
  final MangaMetadataSource source;

  MangaIntake(this.settings, this.source);

  Future<MangaLookupResult> lookup(
    String input,
    RequestScope scope, {
    void Function(MangaIntakeStage)? onStage,
  }) async {
    final query = input.trim();
    if (query.isEmpty || query.length > 200) {
      throw const FormatException('请填写漫画名称（最多 200 字符）');
    }

    onStage?.call(MangaIntakeStage.searching);
    final candidates = await source.search(query, scope);
    if (candidates.isEmpty) {
      return MangaLookupResult(
        input: query,
        candidates: const [],
        recommendation: null,
        reason: 'Bangumi 没有返回可靠的漫画候选，可以仅用标题手动添加。',
      );
    }

    onStage?.call(MangaIntakeStage.choosing);
    final exact = _findExactCandidates(query, candidates);
    MangaMetadataCandidate? recommendation;
    Object? warning;
    String reason;

    if (exact.length == 1) {
      recommendation = exact.single;
      reason = '已命中 Bangumi 标题或别名，请确认候选后继续。';
    } else {
      final aiSelection = await _askAiToSelect(query, candidates, scope);
      recommendation = aiSelection.candidate;
      warning = aiSelection.warning;
      reason = recommendation == null
          ? exact.length > 1
                ? '有多个候选使用了相同标题或别名，请根据封面、作者和简介确认。'
                : '已找到候选，请根据封面、作者和简介确认。'
          : 'AI 仅在真实 Bangumi 候选中给出建议，仍请你确认后再继续。';
    }

    final visible = <MangaMetadataCandidate>[
      ?recommendation,
      ...candidates.where((candidate) => candidate.id != recommendation?.id),
    ].take(5).toList(growable: false);
    return MangaLookupResult(
      input: query,
      candidates: visible,
      recommendation: recommendation,
      reason: reason,
      warning: warning,
    );
  }

  List<MangaMetadataCandidate> _findExactCandidates(
    String input,
    List<MangaMetadataCandidate> candidates,
  ) {
    final normalized = normalizeTitleToken(input);
    if (normalized.isEmpty) return const [];
    return candidates
        .where(
          (candidate) => [
            candidate.title,
            candidate.originalTitle,
            ...candidate.aliases,
          ].any((value) => normalizeTitleToken(value) == normalized),
        )
        .toList(growable: false);
  }

  Future<({MangaMetadataCandidate? candidate, Object? warning})> _askAiToSelect(
    String query,
    List<MangaMetadataCandidate> candidates,
    RequestScope scope,
  ) async {
    try {
      final configuration = await scope.guard(settings.configurations.load());
      if (configuration == null) {
        return (
          candidate: null,
          warning: const NetworkFailure(NetworkFailureKind.unconfigured),
        );
      }
      final key = await scope.guard(
        settings.keys.read(endpoint: configuration.endpoint.toString()),
      );
      final result = await settings.client.complete(
        configuration,
        key,
        buildMangaCandidateSelectionMessages(
          userTitle: query,
          candidates: candidates,
        ),
        scope,
      );
      final selectedId = _selectedId(result);
      final selected = selectedId == null
          ? null
          : candidates.cast<MangaMetadataCandidate?>().firstWhere(
              (candidate) => candidate!.id == selectedId,
              orElse: () => null,
            );
      return (candidate: selected, warning: null);
    } on NetworkFailure catch (failure) {
      if (failure.kind == NetworkFailureKind.cancelled) rethrow;
      return (candidate: null, warning: failure);
    } on FormatException catch (failure) {
      return (candidate: null, warning: failure);
    }
  }

  int? _selectedId(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final raw = value['selectedId'];
    if (raw is int && raw > 0) return raw;
    if (raw is num && raw.isFinite && raw > 0 && raw == raw.roundToDouble()) {
      return raw.toInt();
    }
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }
}
