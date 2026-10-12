import '../core/anime_log_core.dart';
import '../core/api/ai_intake.dart';
import 'ai_settings.dart';

class IntakeRecognition {
  final ParsedAnimeTitleIntent title;
  final List<AnimeTitleCandidate> candidates;
  final AnimeTitleCandidate? recommendation;
  final NetworkFailure? warning;
  const IntakeRecognition(
    this.title,
    this.candidates,
    this.recommendation, {
    this.warning,
  });
}

/// Recognition and source lookup have no write repository and cannot save.
class AiIntake {
  final AiSettings settings;
  final SourceProvider source;
  AiIntake(this.settings, this.source);

  Future<IntakeRecognition> recognize(
    String input,
    RequestScope scope, {
    void Function(AnimeIntakeStage)? onStage,
  }) async {
    final query = input.trim();
    if (query.isEmpty || query.length > 200) {
      throw const FormatException('请填写一部作品名称（最多 200 字符）');
    }
    onStage?.call(AnimeIntakeStage.recognizing);
    final configuration = await scope.guard(settings.configurations.load());
    if (configuration == null) {
      throw const NetworkFailure(NetworkFailureKind.unconfigured);
    }
    final key = await scope.guard(
      settings.keys.read(endpoint: configuration.endpoint.toString()),
    );
    final payload = await settings.client.complete(
      configuration,
      key,
      buildQuickRecordAiMessages(query),
      scope,
    );
    final title = parseSingleAnimeTitlePayload(payload);
    if (title == null) {
      throw const NetworkFailure(NetworkFailureKind.invalidResponse);
    }
    scope.check();
    onStage?.call(AnimeIntakeStage.searching);
    final byId = <int, AnimeTitleCandidate>{};
    NetworkFailure? warning;
    for (final text in {query, title.animeTitle}) {
      try {
        for (final candidate in await source.search(text, scope)) {
          byId.putIfAbsent(candidate.id, () => candidate);
        }
      } on NetworkFailure catch (failure) {
        if (scope.isCancelled || failure.kind == NetworkFailureKind.cancelled) {
          rethrow;
        }
        warning = failure;
      }
    }
    scope.check();
    onStage?.call(AnimeIntakeStage.choosing);
    final candidates = byId.values.take(40).toList();
    final intent = AnimeCandidateIntent(
      userTitle: query,
      recognizedTitle: title.animeTitle,
      recognizedOriginalTitle: title.originalTitle,
      expectedSeason: title.season,
      expectedEntryType: title.entryType,
    );
    // The shortcut requires a UNIQUE strict full-title match. Core's broader
    // season fallback remains useful after the single candidate AI attempt.
    final tokens = [
      query,
      title.animeTitle,
      title.originalTitle,
    ].map(normalizeTitleToken).where((t) => t.isNotEmpty).toSet();
    final strict = candidates
        .where(
          (c) =>
              isAnimeCandidateCompatible(c, intent) &&
              (tokens.contains(normalizeTitleToken(c.title)) ||
                  tokens.contains(normalizeTitleToken(c.originalTitle))),
        )
        .toList();
    AnimeTitleCandidate? recommended;
    if (strict.length == 1) {
      recommended = strict.single;
    } else if (candidates.isNotEmpty) {
      recommended = await selectAnimeCandidate(
        candidates: candidates,
        intent: intent,
        requestSelectedId: () async {
          try {
            final result = await settings.client.complete(
              configuration,
              key,
              buildAnimeCandidateSelectionMessages(
                userTitle: query,
                recognizedTitle: title.animeTitle,
                recognizedOriginalTitle: title.originalTitle,
                expectedSeason: title.season,
                expectedEntryType: title.entryType,
                candidates: candidates,
              ),
              scope,
            );
            final id = result is Map<String, dynamic>
                ? result['selectedId']
                : null;
            return id is int ? id : null;
          } on NetworkFailure catch (failure) {
            warning = failure;
            rethrow;
          }
        },
      );
    }
    // Candidate AI errors preserve the returned real choices. A timeout closed
    // the scope so no more requests are started on this chain.
    if (scope.isCancelled) {
      if (warning?.kind != NetworkFailureKind.timeout) scope.check();
      recommended = null;
    }
    // Keep the recommendation visible even when source relevance placed it
    // below the first five results. Remaining choices retain source order.
    final visibleCandidates = [
      ?recommended,
      ...candidates.where((candidate) => candidate.id != recommended?.id),
    ].take(5).toList(growable: false);
    return IntakeRecognition(
      title,
      visibleCandidates,
      recommended,
      warning: warning,
    );
  }

  Future<AnimeMetadata> details(
    AnimeTitleCandidate candidate,
    RequestScope scope,
  ) => source.details(candidate.id, scope);
}
