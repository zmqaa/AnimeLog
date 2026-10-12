import 'quick_record_text.dart';

enum AnimeStatus { watching, completed, dropped, planToWatch }

extension AnimeStatusWire on AnimeStatus {
  String get wireValue => switch (this) {
    AnimeStatus.watching => 'watching',
    AnimeStatus.completed => 'completed',
    AnimeStatus.dropped => 'dropped',
    AnimeStatus.planToWatch => 'plan_to_watch',
  };
}

AnimeStatus? animeStatusFromWire(Object? value) => switch (value) {
  'watching' => AnimeStatus.watching,
  'completed' => AnimeStatus.completed,
  'dropped' => AnimeStatus.dropped,
  'plan_to_watch' => AnimeStatus.planToWatch,
  _ => null,
};

enum AnimeEntryType { tv, movie, ova, ona, special }

extension AnimeEntryTypeWire on AnimeEntryType {
  String get wireValue => name;
}

AnimeEntryType? animeEntryTypeFromWire(Object? value) => switch (value) {
  'tv' => AnimeEntryType.tv,
  'movie' => AnimeEntryType.movie,
  'ova' => AnimeEntryType.ova,
  'ona' => AnimeEntryType.ona,
  'special' => AnimeEntryType.special,
  _ => null,
};

enum QuickRecordTitleKind { official, genericSeason }

extension QuickRecordTitleKindWire on QuickRecordTitleKind {
  String get wireValue => switch (this) {
    QuickRecordTitleKind.official => 'official',
    QuickRecordTitleKind.genericSeason => 'generic-season',
  };
}

QuickRecordTitleKind? quickRecordTitleKindFromWire(Object? value) =>
    switch (value) {
      'official' => QuickRecordTitleKind.official,
      'generic-season' => QuickRecordTitleKind.genericSeason,
      _ => null,
    };

/// AI 只提供作品身份提示。没有进度、日期、状态、评分或重刷字段。
class ParsedAnimeTitleIntent {
  final String animeTitle;
  final String? originalTitle;
  final QuickRecordTitleKind? titleKind;
  final int? season;
  final AnimeEntryType? entryType;

  const ParsedAnimeTitleIntent({
    required this.animeTitle,
    this.originalTitle,
    this.titleKind,
    this.season,
    this.entryType,
  });

  static ParsedAnimeTitleIntent? tryParse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final rawTitle = _optionalString(value['animeTitle']);
    if (rawTitle == null || rawTitle.length > 200) return null;
    final rawSeason = value['season'];
    if (rawSeason != null && _positiveInt(rawSeason) == null) return null;
    final season = _positiveInt(rawSeason);
    final titleKind = quickRecordTitleKindFromWire(value['titleKind']);
    if (value['titleKind'] != null && titleKind == null) return null;
    final entryType = animeEntryTypeFromWire(value['entryType']);
    if (value['entryType'] != null && entryType == null) return null;
    if (value['originalTitle'] != null && value['originalTitle'] is! String) {
      return null;
    }
    final title = titleKind == QuickRecordTitleKind.genericSeason
        ? appendSeasonToTitle(rawTitle, season)
        : rawTitle;
    return ParsedAnimeTitleIntent(
      animeTitle: title,
      originalTitle: _optionalString(value['originalTitle']),
      titleKind: titleKind,
      season: season,
      entryType: entryType,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'animeTitle': animeTitle,
    'originalTitle': originalTitle,
    'titleKind': titleKind?.wireValue,
    'season': season,
    'entryType': entryType?.wireValue,
  };
}

/// 单条协议，不兼容旧批量协议，不静默取数组的第一项。
ParsedAnimeTitleIntent? parseSingleAnimeTitlePayload(Object? value) {
  if (value is! Map<String, dynamic> || value.containsKey('records')) {
    return null;
  }
  return ParsedAnimeTitleIntent.tryParse(value['record']);
}

/// 外部资料和个人记录分别建模，但第一版可存入同一张 anime 表。
/// AI 标题解析器不能填充这些源数据字段。
class AnimeMetadata {
  final String title;
  final String? originalTitle;
  final int? season;
  final AnimeEntryType? entryType;
  final String? sourceProvider;
  final String? sourceId;
  final int? totalEpisodes;
  final int? durationMinutes;
  final String? summary;
  final String? coverUrl;
  final String? premiereDate;
  final bool? isFinished;
  final List<String> cast;
  final List<String> castAliases;

  const AnimeMetadata({
    required this.title,
    this.originalTitle,
    this.season,
    this.entryType,
    this.sourceProvider,
    this.sourceId,
    this.totalEpisodes,
    this.durationMinutes,
    this.summary,
    this.coverUrl,
    this.premiereDate,
    this.isFinished,
    this.cast = const <String>[],
    this.castAliases = const <String>[],
  });
}

enum RewatchSuggestionReason {
  noPreviousRecord,
  completedRecords,
  unfinishedRecord,
  identityNeedsConfirmation,
}

/// 本地规则给出建议，最终次数由确认表单决定；不属于 AI 响应。
class RewatchSuggestion {
  final int? suggestedCount;
  final RewatchSuggestionReason reason;
  final List<String> relatedRecordUuids;

  const RewatchSuggestion({
    this.suggestedCount,
    required this.reason,
    this.relatedRecordUuids = const <String>[],
  });
}

/// 同一个 draftId 只能保存一次；保存前可由普通表单修改个人字段。
class AnimeCreationDraft {
  final String draftId;
  final AnimeMetadata metadata;
  final AnimeStatus status;
  final int progress;
  final double? score;
  final String? notes;
  final List<String> tags;
  final int? rewatchCount;
  final String? startDate;
  final String? endDate;

  const AnimeCreationDraft({
    required this.draftId,
    required this.metadata,
    this.status = AnimeStatus.watching,
    this.progress = 0,
    this.score,
    this.notes,
    this.tags = const <String>[],
    this.rewatchCount,
    this.startDate,
    this.endDate,
  });
}

/// 一条独立的个人记录；普通记录和重刷记录都具有自己的 UUID。
class AnimeRecord {
  final int id;
  final String uuid;
  final AnimeMetadata metadata;
  final AnimeStatus status;
  final int progress;
  final double? score;
  final String? notes;
  final List<String> tags;
  final int? rewatchCount;
  final String? localCoverPath;
  final String? startDate;
  final String? startDateSource;
  final String? endDate;
  final String createdAt;
  final String updatedAt;

  const AnimeRecord({
    required this.id,
    required this.uuid,
    required this.metadata,
    required this.status,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.score,
    this.notes,
    this.tags = const <String>[],
    this.rewatchCount,
    this.localCoverPath,
    this.startDate,
    this.startDateSource,
    this.endDate,
  });
}

/// watchedOn 是用户选择的日历日期；未知的精确时刻保持为空。
class WatchHistoryRecord {
  final int id;
  final String uuid;
  final String animeUuid;
  final int episode;
  final String watchedOn;
  final String? watchedAt;
  final String createdAt;

  const WatchHistoryRecord({
    required this.id,
    required this.uuid,
    required this.animeUuid,
    required this.episode,
    required this.watchedOn,
    required this.createdAt,
    this.watchedAt,
  });
}

class AnimeNote {
  final String uuid;
  final String animeUuid;
  final int? episode;
  final String content;
  final String notedOn;
  final String createdAt;
  final String updatedAt;

  const AnimeNote({
    required this.uuid,
    required this.animeUuid,
    required this.content,
    required this.notedOn,
    required this.createdAt,
    required this.updatedAt,
    this.episode,
  });
}

String? _optionalString(Object? value) {
  if (value is! String) return null;
  final result = value.trim();
  return result.isEmpty ? null : result;
}

int? _positiveInt(Object? value) {
  if (value is! num || !value.isFinite || value <= 0 || value > 999) {
    return null;
  }
  return value == value.roundToDouble() ? value.toInt() : null;
}
