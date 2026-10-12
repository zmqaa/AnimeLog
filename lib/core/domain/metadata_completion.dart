import 'quick_record_models.dart';
import 'quick_record_rules.dart';
import 'quick_record_text.dart';

class MetadataCompletionPreview {
  final String animeUuid;
  final String recordUpdatedAt;
  final AnimeMetadata source;
  final MetadataFill result;
  const MetadataCompletionPreview({
    required this.animeUuid,
    required this.recordUpdatedAt,
    required this.source,
    required this.result,
  });
}

class MetadataFill {
  final AnimeMetadata metadata;
  final Map<String, Object> changes;
  final List<String> warnings;
  const MetadataFill(this.metadata, this.changes, this.warnings);
}

/// Only source fields may be filled. Personal status, progress, score, notes,
/// tags and dates are read for constraints, never inferred or changed.
MetadataFill fillMissingAnimeMetadata(
  AnimeRecord record,
  AnimeMetadata source, {
  int largestHistoryEpisode = 0,
}) {
  validateAnimeCreationDraft(
    AnimeCreationDraft(draftId: 'source-validation', metadata: source),
  );
  final old = record.metadata;
  final hasIdentity = old.sourceProvider != null || old.sourceId != null;
  if (hasIdentity &&
      (old.sourceProvider != source.sourceProvider ||
          old.sourceId != source.sourceId)) {
    throw const QuickRecordValidationException('资料来源与已有记录不一致，请先手动纠正来源');
  }
  if (!hasIdentity &&
      ((old.season != null &&
              source.season != null &&
              old.season != source.season) ||
          (old.entryType != null &&
              source.entryType != null &&
              old.entryType != source.entryType))) {
    throw const QuickRecordValidationException('候选的季度或作品形式与已有记录冲突');
  }
  final changes = <String, Object>{};
  T? pick<T extends Object>(String name, T? current, T? incoming) {
    final missing =
        current == null || (current is String && current.trim().isEmpty);
    final present =
        incoming != null && (incoming is! String || incoming.trim().isNotEmpty);
    if (missing && present) {
      changes[name] = incoming;
      return incoming;
    }
    return current;
  }

  final warnings = <String>[];
  List<String> pickList(
    String name,
    List<String> current,
    List<String> incoming,
  ) {
    if (current.isEmpty && incoming.isNotEmpty) {
      changes[name] = incoming;
      return incoming;
    }
    return current;
  }

  var total = source.totalEpisodes;
  if (old.totalEpisodes == null &&
      total != null &&
      (total < record.progress ||
          total < largestHistoryEpisode ||
          (record.status == AnimeStatus.completed &&
              total != record.progress))) {
    warnings.add('来源总集数 $total 与现有进度、完成状态或历史冲突，本次保留总集数为空。');
    total = null;
  }
  final merged = AnimeMetadata(
    title: old.title,
    originalTitle: pick(
      'originalTitle',
      old.originalTitle,
      source.originalTitle,
    ),
    season: pick('season', old.season, source.season),
    entryType: pick('entryType', old.entryType, source.entryType),
    sourceProvider: pick(
      'sourceProvider',
      old.sourceProvider,
      source.sourceProvider,
    ),
    sourceId: pick('sourceId', old.sourceId, source.sourceId),
    totalEpisodes: pick('totalEpisodes', old.totalEpisodes, total),
    durationMinutes: pick(
      'durationMinutes',
      old.durationMinutes,
      source.durationMinutes,
    ),
    summary: pick('summary', old.summary, source.summary),
    coverUrl: pick('coverUrl', old.coverUrl, source.coverUrl),
    premiereDate: pick('premiereDate', old.premiereDate, source.premiereDate),
    isFinished: pick('isFinished', old.isFinished, source.isFinished),
    cast: pickList('cast', old.cast, source.cast),
    castAliases: pickList('castAliases', old.castAliases, source.castAliases),
  );
  return MetadataFill(
    merged,
    Map.unmodifiable(changes),
    List.unmodifiable(warnings),
  );
}

void validateEpisodeNote(int episode, String content, String notedOn) {
  if (episode <= 0 || episode > 9223372036854775807) {
    throw const QuickRecordValidationException('备注集数必须是有效的正整数');
  }
  if (content.trim().isEmpty) {
    throw const QuickRecordValidationException('备注内容不能为空');
  }
  // Imported calendar dates retain their meaning; editing never guesses a time.
  if (normalizeDateString(notedOn) != notedOn) {
    throw const QuickRecordValidationException('备注日期必须是有效的 YYYY-MM-DD');
  }
}
