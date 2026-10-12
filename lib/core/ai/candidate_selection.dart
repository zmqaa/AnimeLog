import '../domain/title_matching.dart';

typedef CandidateIdRequester = Future<int?> Function();
typedef CandidateSelectionReporter = void Function(
  CandidateSelectionEvent event,
);

sealed class CandidateSelectionEvent {
  const CandidateSelectionEvent();
}

class CandidateSelectionSelected extends CandidateSelectionEvent {
  final AnimeTitleCandidate candidate;
  final bool fromAi;

  const CandidateSelectionSelected({
    required this.candidate,
    required this.fromAi,
  });
}

class CandidateSelectionNone extends CandidateSelectionEvent {
  const CandidateSelectionNone();
}

/// 最多调用一次 AI；校验候选 ID、明确季度和作品形式。
/// 失败后仅允许保守精确匹配，否则交给用户选择。
Future<AnimeTitleCandidate?> selectAnimeCandidate({
  required List<AnimeTitleCandidate> candidates,
  required AnimeCandidateIntent intent,
  required CandidateIdRequester requestSelectedId,
  CandidateSelectionReporter? report,
}) async {
  final visibleCandidates = candidates.take(20).toList();
  if (visibleCandidates.isEmpty) {
    report?.call(const CandidateSelectionNone());
    return null;
  }
  AnimeTitleCandidate? selected;
  try {
    final selectedId = await requestSelectedId();
    for (final candidate in visibleCandidates) {
      if (candidate.id == selectedId &&
          isAnimeCandidateCompatible(candidate, intent)) {
        selected = candidate;
        break;
      }
    }
  } catch (_) {
    // 调用方的网络层负责错误诊断；这里保留人工选取路径。
  }
  if (selected != null) {
    report?.call(CandidateSelectionSelected(candidate: selected, fromAi: true));
    return selected;
  }
  final fallback = pickHighConfidenceAnimeCandidate(visibleCandidates, intent);
  if (fallback != null) {
    report?.call(
      CandidateSelectionSelected(candidate: fallback, fromAi: false),
    );
    return fallback;
  }
  report?.call(const CandidateSelectionNone());
  return null;
}
