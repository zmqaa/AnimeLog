import 'quick_record_models.dart';
import 'quick_record_text.dart';

class QuickRecordValidationException implements Exception {
  final String message;

  const QuickRecordValidationException(this.message);

  @override
  String toString() => message;
}

String? rewatchLabel(int? count) {
  if (count == null) return null;
  if (count < 2) {
    throw const QuickRecordValidationException('重刷次数必须至少为 2');
  }
  return '${toChineseNumberToken(count)}刷';
}

/// 重刷标签由确认后的次数生成，不由 AI 提供。
List<String> buildCreationTags(Iterable<String> tags, int? rewatchCount) {
  final reservedTag = RegExp(r'^([0-9]+|[一二两三四五六七八九十百零〇]+)刷$');
  final values = tags
      .where((tag) => !reservedTag.hasMatch(tag.trim()))
      .toList();
  final label = rewatchLabel(rewatchCount);
  if (label != null) values.add(label);
  return List<String>.unmodifiable(uniqueStrings(values));
}

bool _hasSourceIdentity(AnimeMetadata metadata) =>
    (metadata.sourceProvider?.trim().isNotEmpty ?? false) &&
    (metadata.sourceId?.trim().isNotEmpty ?? false);

bool _sameSourceIdentity(AnimeMetadata left, AnimeMetadata right) =>
    left.sourceProvider!.trim() == right.sourceProvider!.trim() &&
    left.sourceId!.trim() == right.sourceId!.trim();

bool _possiblySameTitle(AnimeMetadata left, AnimeMetadata right) {
  if (left.season != null &&
      right.season != null &&
      left.season != right.season) {
    return false;
  }
  if (left.entryType != null &&
      right.entryType != null &&
      left.entryType != right.entryType) {
    return false;
  }
  final leftTitles = <String>{
    normalizeTitleToken(left.title),
    normalizeTitleToken(left.originalTitle),
  }..remove('');
  final rightTitles = <String>{
    normalizeTitleToken(right.title),
    normalizeTitleToken(right.originalTitle),
  }..remove('');
  return leftTitles.intersection(rightTitles).isNotEmpty;
}

int _recordRewatchCount(AnimeRecord record) {
  // 新数据以结构字段为准，旧数据没有结构字段时兼容显式刷次标签。
  if (record.rewatchCount != null && record.rewatchCount! >= 2) {
    return record.rewatchCount!;
  }
  var count = 1;
  for (final tag in record.tags) {
    final token = RegExp(r'^([0-9]+|[一二两三四五六七八九十百零〇]+)刷$')
        .firstMatch(tag.trim())
        ?.group(1);
    final parsed = token == null
        ? null
        : int.tryParse(token) ?? parseChineseNumberToken(token);
    if (parsed != null && parsed > count) count = parsed;
  }
  return count;
}

/// 已确认同一作品且已有记录全部看完时，建议最高刷次加一。
/// 不把记录条数当作刷次；未知身份或尚未看完时保留人工判断。
RewatchSuggestion resolveRewatchSuggestion({
  required AnimeMetadata metadata,
  required Iterable<AnimeRecord> existingRecords,
  Iterable<String> confirmedRecordUuids = const <String>[],
}) {
  final confirmed = confirmedRecordUuids.toSet();
  final unique = <String, AnimeRecord>{};
  for (final record in existingRecords) {
    unique.putIfAbsent(record.uuid, () => record);
  }
  final related = <AnimeRecord>[];
  final uncertain = <AnimeRecord>[];
  for (final record in unique.values) {
    if (_hasSourceIdentity(metadata) && _hasSourceIdentity(record.metadata)) {
      if (_sameSourceIdentity(metadata, record.metadata)) related.add(record);
      continue;
    }
    if (!_possiblySameTitle(metadata, record.metadata)) continue;
    if (confirmed.contains(record.uuid)) {
      related.add(record);
    } else {
      uncertain.add(record);
    }
  }
  final uuids = List<String>.unmodifiable(
    <AnimeRecord>[...related, ...uncertain].map((record) => record.uuid),
  );
  if (uncertain.isNotEmpty) {
    return RewatchSuggestion(
      reason: RewatchSuggestionReason.identityNeedsConfirmation,
      relatedRecordUuids: uuids,
    );
  }
  if (related.isEmpty) {
    return const RewatchSuggestion(
      reason: RewatchSuggestionReason.noPreviousRecord,
    );
  }
  if (related.any((record) => record.status != AnimeStatus.completed)) {
    return RewatchSuggestion(
      reason: RewatchSuggestionReason.unfinishedRecord,
      relatedRecordUuids: uuids,
    );
  }
  var highest = 1;
  for (final record in related) {
    final count = _recordRewatchCount(record);
    if (count > highest) highest = count;
  }
  return RewatchSuggestion(
    suggestedCount: highest + 1,
    reason: RewatchSuggestionReason.completedRecords,
    relatedRecordUuids: uuids,
  );
}

/// 标题识别后仅生成新建草稿。程序可建议刷次，进度始终从零开始。
AnimeCreationDraft buildAnimeCreationDraft({
  required String draftId,
  required AnimeMetadata metadata,
  int? rewatchCount,
  Iterable<AnimeRecord> existingRecords = const <AnimeRecord>[],
  Iterable<String> confirmedRecordUuids = const <String>[],
  bool useRewatchSuggestion = true,
}) {
  final count =
      rewatchCount ??
      (useRewatchSuggestion
          ? resolveRewatchSuggestion(
              metadata: metadata,
              existingRecords: existingRecords,
              confirmedRecordUuids: confirmedRecordUuids,
            ).suggestedCount
          : null);
  final draft = AnimeCreationDraft(
    draftId: draftId,
    metadata: metadata,
    rewatchCount: count,
    tags: buildCreationTags(const <String>[], count),
  );
  validateAnimeCreationDraft(draft);
  return draft;
}

void validateAnimeCreationDraft(AnimeCreationDraft draft) {
  void require(bool condition, String message) {
    if (!condition) throw QuickRecordValidationException(message);
  }

  final metadata = draft.metadata;
  require(draft.draftId.trim().isNotEmpty, '缺少草稿 ID');
  require(metadata.title.trim().isNotEmpty, '作品标题不能为空');
  require(metadata.title.length <= 200, '作品标题过长');
  require(metadata.season == null || metadata.season! > 0, '季度必须是正整数');
  require(
    metadata.totalEpisodes == null || metadata.totalEpisodes! > 0,
    '总集数必须是正整数',
  );
  require(
    metadata.durationMinutes == null || metadata.durationMinutes! > 0,
    '单集时长必须是正整数',
  );
  require(draft.progress >= 0, '进度不能为负数');
  require(
    metadata.totalEpisodes == null || draft.progress <= metadata.totalEpisodes!,
    '进度不能超过总集数',
  );
  require(
    draft.score == null ||
        (draft.score!.isFinite && draft.score! >= 0 && draft.score! <= 10),
    '评分必须在 0–10 之间',
  );
  require(
    draft.rewatchCount == null || draft.rewatchCount! >= 2,
    '重刷次数必须至少为 2',
  );
  final hasProvider = metadata.sourceProvider?.trim().isNotEmpty ?? false;
  final hasSourceId = metadata.sourceId?.trim().isNotEmpty ?? false;
  require(hasProvider == hasSourceId, '资料来源和来源 ID 必须成对保存');
  require(
    metadata.premiereDate == null ||
        normalizeDateString(metadata.premiereDate) != null,
    '首播日期无效',
  );
  require(
    draft.startDate == null || normalizeDateString(draft.startDate) != null,
    '开始日期无效',
  );
  require(
    draft.endDate == null || normalizeDateString(draft.endDate) != null,
    '完成日期无效',
  );
  require(
    draft.startDate == null ||
        draft.endDate == null ||
        draft.startDate!.compareTo(draft.endDate!) <= 0,
    '完成日期不能早于开始日期',
  );
  require(
    draft.status != AnimeStatus.planToWatch || draft.progress == 0,
    '想看记录的进度必须为零',
  );
  require(
    draft.status != AnimeStatus.completed ||
        metadata.totalEpisodes == null ||
        draft.progress == metadata.totalEpisodes,
    '已看完记录的进度应等于已知总集数',
  );
  require(
    draft.status == AnimeStatus.completed || draft.endDate == null,
    '只有已看完记录可以填写完成日期',
  );
  final expectedTags = buildCreationTags(draft.tags, draft.rewatchCount);
  require(_sameStrings(draft.tags, expectedTags), '重刷标签必须与选择的重刷次数一致，标签不能重复或为空');
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
