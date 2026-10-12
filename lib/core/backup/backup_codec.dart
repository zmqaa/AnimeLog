import 'dart:convert';
import 'dart:typed_data';

import '../anime_log_core.dart';
import 'backup_document.dart';
import 'legacy_backup_adapter.dart';

const maxBackupBytes = 50 * 1024 * 1024;

BackupDocument decodeBackup(Uint8List bytes) {
  if (bytes.length > maxBackupBytes) fail('文件', '超过 50 MiB 上限');
  Object? value;
  try {
    var source = utf8.decode(bytes);
    if (source.startsWith('\ufeff')) source = source.substring(1);
    value = jsonDecode(source);
  } on FormatException {
    fail('文件', '不是有效的 UTF-8 JSON');
  }
  final root = object(value, r'$');
  if (root['format'] == 'anime-log') return parseAnimeLog(root);
  if (!root.containsKey('format') && root['formatVersion'] == 5) {
    return convertLegacyBackup(root, bytes);
  }
  fail(r'$.format', '不支持的格式或版本（仅支持 AnimeLog v1 / AnimeTrack v5）');
}

BackupDocument parseAnimeLog(
  Map<String, dynamic> root, {
  List<String> warnings = const [],
  String? legacyFingerprint,
}) {
  if (root['formatVersion'] != 1 || root['format'] != 'anime-log') {
    fail(r'$.formatVersion', '只支持 AnimeLog v1');
  }
  final exportedAt = timestamp(root['exportedAt'], r'$.exportedAt');
  final records = <AnimeRecord>[];
  var repairs = 0;
  for (final indexed in array(root['anime'], r'$.anime').indexed) {
    final path =
        r'$.anime['
        '${indexed.$1}]';
    final a = object(indexed.$2, path);
    final m = object(a['metadata'], '$path.metadata');
    final type = animeEntryTypeFromWire(m['entryType']);
    if (m['entryType'] != null && type == null) {
      fail('$path.metadata.entryType', '作品形式无效');
    }
    final status = animeStatusFromWire(a['status']);
    if (status == null) fail('$path.status', '状态无效');
    final meta = AnimeMetadata(
      title: string(m['title'], '$path.metadata.title'),
      originalTitle: nullableString(
        m['originalTitle'],
        '$path.metadata.originalTitle',
      ),
      season: optionalInt(m['season'], '$path.metadata.season'),
      entryType: type,
      sourceProvider: nullableString(
        m['sourceProvider'],
        '$path.metadata.sourceProvider',
      ),
      sourceId: nullableString(m['sourceId'], '$path.metadata.sourceId'),
      totalEpisodes: optionalInt(
        m['totalEpisodes'],
        '$path.metadata.totalEpisodes',
      ),
      durationMinutes: optionalInt(
        m['durationMinutes'],
        '$path.metadata.durationMinutes',
      ),
      summary: nullableString(m['summary'], '$path.metadata.summary'),
      coverUrl: nullableString(m['coverUrl'], '$path.metadata.coverUrl'),
      premiereDate: optionalDate(
        m['premiereDate'],
        '$path.metadata.premiereDate',
      ),
      isFinished: optionalBool(m['isFinished'], '$path.metadata.isFinished'),
      cast: stringArray(m['cast'], '$path.metadata.cast', missingAsEmpty: true),
      castAliases: stringArray(
        m['castAliases'],
        '$path.metadata.castAliases',
        missingAsEmpty: true,
      ),
    );
    if (meta.coverUrl != null && !isRemoteUrl(meta.coverUrl!)) {
      fail('$path.metadata.coverUrl', '仅支持完整 HTTP(S) 远程地址');
    }
    final rawTags = array(
      a['tags'],
      '$path.tags',
    ).map((t) => string(t, '$path.tags')).toList();
    if (rawTags.toSet().length != rawTags.length) fail('$path.tags', '标签重复');
    if (rawTags.any((tag) => tag.trim() != tag)) {
      fail('$path.tags', '标签两端不能有空白');
    }
    final rewatch = optionalInt(
      a['rewatchCount'],
      '$path.rewatchCount',
      min: 2,
    );
    final tags = buildCreationTags(rawTags, rewatch);
    if (jsonEncode(rawTags) != jsonEncode(tags)) repairs++;
    final progress = integer(a['progress'], '$path.progress', min: 0);
    final score = optionalNumber(a['score'], '$path.score');
    final start = optionalDate(a['startDate'], '$path.startDate');
    final end = optionalDate(a['endDate'], '$path.endDate');
    final source = nullableString(
      a['startDateSource'],
      '$path.startDateSource',
    );
    if (source != null &&
        (source != 'manual' && source != 'history' || start == null)) {
      fail('$path.startDateSource', '日期来源无效或缺少开始日期');
    }
    final notes = nullableString(a['notes'], '$path.notes');
    try {
      validateAnimeCreationDraft(
        AnimeCreationDraft(
          draftId: 'backup-validation',
          metadata: meta,
          status: status,
          progress: progress,
          score: score,
          notes: notes,
          tags: tags,
          rewatchCount: rewatch,
          startDate: start,
          endDate: end,
        ),
      );
    } on QuickRecordValidationException catch (e) {
      fail(path, e.message);
    }
    records.add(
      AnimeRecord(
        id: 0,
        uuid: uuid(a['uuid'], '$path.uuid'),
        metadata: meta,
        status: status,
        progress: progress,
        score: score,
        notes: notes,
        tags: tags,
        rewatchCount: rewatch,
        startDate: start,
        startDateSource: source,
        endDate: end,
        createdAt: timestamp(a['createdAt'], '$path.createdAt'),
        updatedAt: timestamp(a['updatedAt'], '$path.updatedAt'),
      ),
    );
  }
  uniqueIds(records.map((r) => r.uuid), r'$.anime');
  final byUuid = {for (final a in records) a.uuid: a};
  final history = <WatchHistoryRecord>[];
  for (final indexed in array(
    root['watchHistory'],
    r'$.watchHistory',
  ).indexed) {
    final path =
        r'$.watchHistory['
        '${indexed.$1}]';
    final h = object(indexed.$2, path);
    final parent = uuid(h['animeUuid'], '$path.animeUuid');
    if (!byUuid.containsKey(parent)) fail('$path.animeUuid', '关联动漫不在文件内');
    final episode = integer(h['episode'], '$path.episode');
    history.add(
      WatchHistoryRecord(
        id: 0,
        uuid: uuid(h['uuid'], '$path.uuid'),
        animeUuid: parent,
        episode: episode,
        watchedOn: date(h['watchedOn'], '$path.watchedOn'),
        watchedAt: h['watchedAt'] == null
            ? null
            : timestamp(h['watchedAt'], '$path.watchedAt'),
        createdAt: timestamp(h['createdAt'], '$path.createdAt'),
      ),
    );
  }
  uniqueIds(history.map((h) => h.uuid), r'$.watchHistory');
  final notes = <AnimeNote>[];
  final overall = <String, AnimeNote>{};
  for (final indexed in array(root['notes'], r'$.notes').indexed) {
    final path =
        r'$.notes['
        '${indexed.$1}]';
    final n = object(indexed.$2, path);
    final parent = uuid(n['animeUuid'], '$path.animeUuid');
    if (!byUuid.containsKey(parent)) fail('$path.animeUuid', '关联动漫不在文件内');
    final note = AnimeNote(
      uuid: uuid(n['uuid'], '$path.uuid'),
      animeUuid: parent,
      episode: optionalInt(n['episode'], '$path.episode'),
      content: string(n['content'], '$path.content'),
      notedOn: date(n['notedOn'], '$path.notedOn'),
      createdAt: timestamp(n['createdAt'], '$path.createdAt'),
      updatedAt: timestamp(n['updatedAt'], '$path.updatedAt'),
    );
    if (note.episode == null && overall.containsKey(parent)) {
      fail(path, '一条动漫只能有一条总体备注');
    }
    if (note.episode == null) overall[parent] = note;
    notes.add(note);
  }
  uniqueIds(notes.map((n) => n.uuid), r'$.notes');
  for (final a in records) {
    if (a.notes != overall[a.uuid]?.content) {
      fail(r'$.notes', '动漫 ${a.uuid} 的总体备注与结构化备注不一致');
    }
  }
  final manga = <MangaRecord>[];
  for (final indexed in array(root['manga'] ?? const [], r'$.manga').indexed) {
    final path =
        r'$.manga['
        '${indexed.$1}]';
    final m = object(indexed.$2, path);
    final status = mangaReadingStatusFromWire(m['status']);
    if (status == null) fail('$path.status', '阅读状态无效');
    final publication = mangaPublicationStatusFromWire(m['publicationStatus']);
    if (publication == null) {
      fail('$path.publicationStatus', '连载状态无效');
    }
    final score = optionalNumber(m['score'], '$path.score');
    if (score != null && (score < 0 || score > 10)) {
      fail('$path.score', '评分必须在 0 到 10 之间');
    }
    final cover = nullableString(m['coverUrl'], '$path.coverUrl');
    if (cover != null && !isRemoteUrl(cover)) {
      fail('$path.coverUrl', '仅支持完整 HTTP(S) 远程地址');
    }
    manga.add(
      MangaRecord(
        id: 0,
        uuid: uuid(m['uuid'], '$path.uuid'),
        bangumiId: optionalInt(m['bangumiId'], '$path.bangumiId'),
        title: string(m['title'], '$path.title'),
        originalTitle: nullableString(
          m['originalTitle'],
          '$path.originalTitle',
        ),
        aliases: stringArray(
          m['aliases'],
          '$path.aliases',
          missingAsEmpty: true,
        ),
        coverUrl: cover,
        status: status,
        publicationStatus: publication,
        score: score,
        currentVolume: optionalInt(
          m['currentVolume'],
          '$path.currentVolume',
          min: 0,
        ),
        currentChapter: optionalInt(
          m['currentChapter'],
          '$path.currentChapter',
          min: 0,
        ),
        totalVolumes: optionalInt(m['totalVolumes'], '$path.totalVolumes'),
        totalChapters: optionalInt(m['totalChapters'], '$path.totalChapters'),
        notes: nullableString(m['notes'], '$path.notes'),
        tags: stringArray(m['tags'], '$path.tags', missingAsEmpty: true),
        summary: nullableString(m['summary'], '$path.summary'),
        authors: stringArray(
          m['authors'],
          '$path.authors',
          missingAsEmpty: true,
        ),
        illustrators: stringArray(
          m['illustrators'],
          '$path.illustrators',
          missingAsEmpty: true,
        ),
        publishers: stringArray(
          m['publishers'],
          '$path.publishers',
          missingAsEmpty: true,
        ),
        serializations: stringArray(
          m['serializations'],
          '$path.serializations',
          missingAsEmpty: true,
        ),
        startDate: optionalDate(m['startDate'], '$path.startDate'),
        endDate: optionalDate(m['endDate'], '$path.endDate'),
        releaseDate: optionalDate(m['releaseDate'], '$path.releaseDate'),
        createdAt: timestamp(m['createdAt'], '$path.createdAt'),
        updatedAt: timestamp(m['updatedAt'], '$path.updatedAt'),
      ),
    );
  }
  uniqueIds(manga.map((m) => m.uuid), r'$.manga');
  return BackupDocument(
    exportedAt: exportedAt,
    anime: records,
    history: history,
    notes: notes,
    manga: manga,
    repairedTags: repairs,
    warnings: warnings,
    legacyFingerprint: legacyFingerprint,
  );
}

Never fail(String path, String message) =>
    throw BackupValidationException(path, message);
Map<String, dynamic> object(Object? v, String p) =>
    v is Map<String, dynamic> ? v : fail(p, '必须是对象');
List<dynamic> array(Object? v, String p) => v is List ? v : fail(p, '必须是数组');
List<String> stringArray(Object? v, String p, {bool missingAsEmpty = false}) {
  if (v == null && missingAsEmpty) return const <String>[];
  return array(
    v,
    p,
  ).indexed.map((item) => string(item.$2, '$p[${item.$1}]')).toList();
}

String string(Object? v, String p) =>
    v is String && v.trim().isNotEmpty ? v : fail(p, '必须是非空字符串');
String? nullableString(Object? v, String p) => v == null ? null : string(v, p);
int integer(Object? v, String p, {int min = 1}) =>
    v is int && v >= min ? v : fail(p, '必须是 ≥$min 的整数');
int? optionalInt(Object? v, String p, {int min = 1}) =>
    v == null ? null : integer(v, p, min: min);
double? optionalNumber(Object? v, String p) => v == null
    ? null
    : v is num && v.isFinite
    ? v.toDouble()
    : fail(p, '必须是有限数字');
bool? optionalBool(Object? v, String p) => v == null
    ? null
    : v is bool
    ? v
    : fail(p, '必须是布尔值');
String date(Object? v, String p) => v is String && normalizeDateString(v) == v
    ? v
    : fail(p, '必须是有效的 YYYY-MM-DD');
String? optionalDate(Object? v, String p) => v == null ? null : date(v, p);
String timestamp(Object? v, String p) {
  if (v is! String ||
      !RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,6})?Z$').hasMatch(v)) {
    fail(p, '必须是 UTC ISO 时间（以 Z 结尾）');
  }
  validateClock(v, p);
  return v;
}

void validateClock(String v, String p) {
  date(v.substring(0, 10), p);
  if (int.parse(v.substring(11, 13)) > 23 ||
      int.parse(v.substring(14, 16)) > 59 ||
      int.parse(v.substring(17, 19)) > 59 ||
      DateTime.tryParse(v) == null) {
    fail(p, '时间无效');
  }
}

String uuid(Object? v, String p) =>
    v is String &&
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(v)
    ? v
    : fail(p, 'UUID 无效（须为规范小写 UUID）');
void uniqueIds(Iterable<String> values, String p) {
  final seen = <String>{};
  for (final v in values) {
    if (!seen.add(v)) fail(p, 'UUID 重复：$v');
  }
}

bool isRemoteUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}
