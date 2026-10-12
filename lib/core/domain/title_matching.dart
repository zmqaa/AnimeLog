import 'quick_record_models.dart';
import 'quick_record_text.dart';

class AnimeTitleCandidate {
  final int id;
  final String title;
  final String? originalTitle;
  final int? season;
  final String? premiereDate;
  final int? totalEpisodes;
  final AnimeEntryType? entryType;

  const AnimeTitleCandidate({
    required this.id,
    required this.title,
    this.originalTitle,
    this.season,
    this.premiereDate,
    this.totalEpisodes,
    this.entryType,
  });
}

class AnimeCandidateIntent {
  final String userTitle;
  final String? recognizedTitle;
  final String? recognizedOriginalTitle;
  final int? expectedSeason;
  final AnimeEntryType? expectedEntryType;

  const AnimeCandidateIntent({
    required this.userTitle,
    this.recognizedTitle,
    this.recognizedOriginalTitle,
    this.expectedSeason,
    this.expectedEntryType,
  });
}

int? _candidateSeason(AnimeTitleCandidate candidate) {
  return candidate.season ??
      extractSeasonNumber(candidate.title) ??
      extractSeasonNumber(candidate.originalTitle);
}

bool isAnimeCandidateCompatible(
  AnimeTitleCandidate candidate,
  AnimeCandidateIntent intent,
) {
  final expectedSeason =
      intent.expectedSeason ?? extractSeasonNumber(intent.userTitle);
  final candidateSeason = _candidateSeason(candidate);
  if (expectedSeason != null &&
      candidateSeason != null &&
      expectedSeason != candidateSeason) {
    return false;
  }
  if (intent.expectedEntryType != null &&
      candidate.entryType != null &&
      intent.expectedEntryType != candidate.entryType) {
    return false;
  }
  return true;
}

class _WeightedTitle {
  final String token;
  final String baseToken;
  final int weight;

  const _WeightedTitle({
    required this.token,
    required this.baseToken,
    required this.weight,
  });
}

List<_WeightedTitle> _weightedTitles(
  List<({String? value, int weight})> values,
) {
  final byToken = <String, _WeightedTitle>{};
  for (final item in values) {
    final token = normalizeTitleToken(item.value);
    if (token.isEmpty) continue;
    final current = byToken[token];
    if (current == null || current.weight < item.weight) {
      byToken[token] = _WeightedTitle(
        token: token,
        baseToken: normalizeTitleToken(stripSeasonToken(item.value)),
        weight: item.weight,
      );
    }
  }
  return byToken.values.toList();
}

/// AI 没有选中候选时的保守兜底：只接受唯一的精确标题/原名匹配，
/// 或者在明确季度下接受唯一的基础标题匹配。绝不因为包含某个词就自动选第一条。
AnimeTitleCandidate? pickHighConfidenceAnimeCandidate(
  List<AnimeTitleCandidate> candidates,
  AnimeCandidateIntent intent,
) {
  if (candidates.isEmpty) return null;

  final expectedSeason =
      intent.expectedSeason ??
      extractSeasonNumber(intent.userTitle) ??
      extractSeasonNumber(intent.recognizedTitle) ??
      extractSeasonNumber(intent.recognizedOriginalTitle);
  final intentTitles = _weightedTitles(<({String? value, int weight})>[
    (value: intent.userTitle, weight: 300),
    (value: intent.recognizedTitle, weight: 220),
    (value: intent.recognizedOriginalTitle, weight: 200),
  ]);
  if (intentTitles.isEmpty) return null;

  final ranked = <({AnimeTitleCandidate candidate, int score})>[];
  for (final candidate in candidates) {
    if (!isAnimeCandidateCompatible(candidate, intent)) continue;
    final candidateSeason = _candidateSeason(candidate);
    if (expectedSeason != null &&
        candidateSeason != null &&
        candidateSeason != expectedSeason) {
      continue;
    }

    final candidateTitles = _weightedTitles(<({String? value, int weight})>[
      (value: candidate.title, weight: 20),
      (value: candidate.originalTitle, weight: 10),
    ]);
    var score = 0;
    for (final intentTitle in intentTitles) {
      for (final candidateTitle in candidateTitles) {
        if (intentTitle.token == candidateTitle.token) {
          final exactScore = 1000 + intentTitle.weight + candidateTitle.weight;
          if (score < exactScore) score = exactScore;
          continue;
        }
        if (expectedSeason != null &&
            candidateSeason == expectedSeason &&
            intentTitle.baseToken.isNotEmpty &&
            intentTitle.baseToken == candidateTitle.baseToken) {
          final seasonScore = 700 + intentTitle.weight + candidateTitle.weight;
          if (score < seasonScore) score = seasonScore;
        }
      }
    }

    if (score > 0) ranked.add((candidate: candidate, score: score));
  }

  ranked.sort((left, right) => right.score.compareTo(left.score));
  if (ranked.isEmpty) return null;
  if (ranked.length > 1 && ranked[1].score == ranked.first.score) return null;
  return ranked.first.candidate;
}
