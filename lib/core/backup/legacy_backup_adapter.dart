import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../anime_log_core.dart';
import 'backup_codec.dart';
import 'backup_document.dart';

/// Read-only conversion of the v5 contract from AnimeTrack's actual exporters.
BackupDocument convertLegacyBackup(
  Map<String, dynamic> root,
  Uint8List source,
) {
  final fingerprint = sha256.convert(source).toString();
  final warnings = <String>[
    '旧时间按 Asia/Shanghai（UTC+08:00）解释；有时区的时刻转为 UTC，观看日按该时区保留。',
    '旧文件使用内容指纹生成 UUID。不同文件的旧整数 ID 不能证明同一记录，搬移最新整份数据建议完整恢复。',
  ];
  final exported = legacyTime(root['exportedAt'], r'$.exportedAt');
  List<dynamic> group(String name, {bool optional = false}) {
    if (!root.containsKey(name) && optional) return [];
    final g = object(root[name], '\$.$name');
    final rows = array(g['records'], '\$.$name.records');
    if (g['count'] != null &&
        integer(g['count'], '\$.$name.count', min: 0) != rows.length) {
      fail('\$.$name.count', '数量与 records 不一致');
    }
    return rows;
  }

  final animeRows = group('anime');
  final historyRows = group('watchHistory', optional: true);
  final mangaRows = group('manga', optional: true);
  for (final key in root.keys.where(
    (k) => !{
      'formatVersion',
      'exportedAt',
      'datasets',
      'anime',
      'watchHistory',
      'manga',
    }.contains(k),
  )) {
    final v = root[key];
    final count = v is Map && v['records'] is List
        ? (v['records'] as List).length
        : v is List
        ? v.length
        : 1;
    warnings.add('未导入类别 $key：$count 项；原始文件保持不变。');
  }
  final mapped = <String, String>{};
  final records = <Map<String, dynamic>>[];
  final notes = <Map<String, dynamic>>[];
  final histories = <Map<String, dynamic>>[];
  final mangaRecords = <Map<String, dynamic>>[];
  String stable(String table, Object key) => const Uuid().v5(
    Namespace.url.value,
    'anime-log:legacy-v5:$fingerprint:$table:$key',
  );
  String keyOf(Object? value, String p) {
    if (value is int && value > 0 ||
        value is String && value.trim().isNotEmpty) {
      return value.toString();
    }
    fail(p, '旧 ID 必须是正整数或非空字符串');
  }

  String fallbackTime(Object? value, String fallback, String p) {
    if (value == null || value == '') {
      return fallback;
    }
    return legacyTime(value, p);
  }

  Object? number(Object? v, String p, {bool zeroUnknown = false}) {
    if (v == null || v == '') return null;
    final parsed = v is String ? num.tryParse(v) : v;
    if (parsed is! num || !parsed.isFinite) fail(p, '数值无效');
    if (zeroUnknown && parsed == 0) return null;
    return parsed == parsed.roundToDouble() ? parsed.toInt() : parsed;
  }

  String? text(Object? v, String p) =>
      v == null || v == '' ? null : nullableString(v, p);
  Object? boolean(Object? v, String p) {
    if (v == null || v == '') return null;
    if (v == true || v == 1 || v == '1' || v == 'true') return true;
    if (v == false || v == 0 || v == '0' || v == 'false') return false;
    fail(p, '布尔值无效');
  }

  List<dynamic> strings(Object? value, String p) {
    if (value == null) return <dynamic>[];
    final values = array(value, p);
    for (final indexed in values.indexed) {
      string(indexed.$2, '$p[${indexed.$1}]');
    }
    return values;
  }

  for (final item in animeRows.indexed) {
    final p =
        r'$.anime.records['
        '${item.$1}]';
    final r = object(item.$2, p);
    final oldKey = r['id'] == null
        ? 'position:${item.$1}'
        : keyOf(r['id'], '$p.id');
    if (mapped.containsKey(oldKey)) fail('$p.id', '旧动漫 ID 重复');
    final id = r['uuid'] == null
        ? stable('anime', oldKey)
        : uuid(r['uuid'], '$p.uuid');
    mapped[oldKey] = id;
    final created = fallbackTime(r['createdAt'], exported, '$p.createdAt');
    final updated = fallbackTime(r['updatedAt'], created, '$p.updatedAt');
    final rawTags = r['tags'] == null
        ? <dynamic>[]
        : array(r['tags'], '$p.tags');
    for (final t in rawTags) {
      string(t, '$p.tags');
    }
    int? count = r['rewatchCount'] == null
        ? null
        : optionalInt(
            number(r['rewatchCount'], '$p.rewatchCount'),
            '$p.rewatchCount',
            min: 2,
          );
    if (count == null) {
      for (final tag in rawTags.cast<String>()) {
        final token = RegExp(r'^([0-9]+|[一二两三四五六七八九十百零〇]+)刷$')
            .firstMatch(tag.trim())
            ?.group(1);
        final n = token == null
            ? null
            : int.tryParse(token) ?? parseChineseNumberToken(token);
        if (n != null && n >= 2 && (count == null || n > count)) count = n;
      }
    }
    final nestedNotes = r['notes'] is String
        ? <dynamic>[
            {'content': r['notes']},
          ]
        : r['notes'] == null
        ? <dynamic>[]
        : array(r['notes'], '$p.notes');
    String? overall;
    final noteKeys = <String>{};
    for (final indexed in nestedNotes.indexed) {
      final np = '$p.notes[${indexed.$1}]';
      final n = object(indexed.$2, np);
      final content = string(n['content'], '$np.content');
      final episode = optionalInt(
        number(n['episode'], '$np.episode'),
        '$np.episode',
      );
      if (episode == null && overall != null) fail(np, '总体备注重复');
      if (episode == null) overall = content;
      final noteKey = n['id'] == null
          ? 'position:${indexed.$1}'
          : keyOf(n['id'], '$np.id');
      if (!noteKeys.add(noteKey)) fail('$np.id', '旧备注 ID 重复');
      final noteCreated = fallbackTime(
        n['createdAt'],
        created,
        '$np.createdAt',
      );
      final noteUpdated = fallbackTime(
        n['updatedAt'],
        updated,
        '$np.updatedAt',
      );
      final noted = n['notedAt'] == null || n['notedAt'] == ''
          ? DateTime.parse(noteUpdated)
                .add(const Duration(hours: 8))
                .toIso8601String()
                .substring(0, 10)
          : date(n['notedAt'], '$np.notedAt');
      notes.add({
        'uuid': n['uuid'] == null
            ? stable('notes:$oldKey', noteKey)
            : uuid(n['uuid'], '$np.uuid'),
        'animeUuid': id,
        'episode': episode,
        'content': content,
        'notedOn': noted,
        'createdAt': noteCreated,
        'updatedAt': noteUpdated,
      });
    }
    final start = text(r['startDate'], '$p.startDate');
    final rawSource = text(r['startDateSource'], '$p.startDateSource');
    if (rawSource != null && rawSource != 'manual' && rawSource != 'history') {
      fail('$p.startDateSource', '日期来源无效');
    }
    final provider = text(r['sourceProvider'], '$p.sourceProvider');
    final sourceId = r['sourceId'] == null
        ? null
        : keyOf(r['sourceId'], '$p.sourceId');
    final cover = text(r['coverUrl'], '$p.coverUrl');
    records.add({
      'uuid': id,
      'metadata': {
        'title': r['title'],
        'originalTitle': text(r['originalTitle'], '$p.originalTitle'),
        'season': number(r['season'], '$p.season'),
        'entryType': text(r['entryType'], '$p.entryType'),
        'sourceProvider': provider,
        'sourceId': sourceId,
        'totalEpisodes': number(
          r['totalEpisodes'],
          '$p.totalEpisodes',
          zeroUnknown: true,
        ),
        'durationMinutes': number(
          r['durationMinutes'],
          '$p.durationMinutes',
          zeroUnknown: true,
        ),
        'summary': text(r['summary'], '$p.summary'),
        'coverUrl': cover != null && isRemoteUrl(cover) ? cover : null,
        'premiereDate': text(r['premiereDate'], '$p.premiereDate'),
        'isFinished': boolean(r['isFinished'], '$p.isFinished'),
        'cast': strings(r['cast'], '$p.cast'),
        'castAliases': strings(r['castAliases'], '$p.castAliases'),
      },
      'status': r['status'],
      'progress': number(r['progress'] ?? 0, '$p.progress'),
      'score': number(r['score'], '$p.score'),
      'tags': rawTags,
      'rewatchCount': count,
      'notes': overall,
      'startDate': start,
      'startDateSource': rawSource,
      'endDate': text(r['endDate'], '$p.endDate'),
      'createdAt': created,
      'updatedAt': updated,
    });
  }
  final mangaKeys = <String>{};
  for (final item in mangaRows.indexed) {
    final p =
        r'$.manga.records['
        '${item.$1}]';
    final r = object(item.$2, p);
    final oldKey = r['id'] == null
        ? 'position:${item.$1}'
        : keyOf(r['id'], '$p.id');
    if (!mangaKeys.add(oldKey)) fail('$p.id', '旧漫画 ID 重复');
    final id = r['uuid'] == null
        ? stable('manga', oldKey)
        : uuid(r['uuid'], '$p.uuid');
    final created = fallbackTime(r['createdAt'], exported, '$p.createdAt');
    final updated = fallbackTime(r['updatedAt'], created, '$p.updatedAt');
    final cover = text(r['coverUrl'], '$p.coverUrl');
    mangaRecords.add({
      'uuid': id,
      'bangumiId': number(r['bangumiId'], '$p.bangumiId', zeroUnknown: true),
      'title': r['title'],
      'originalTitle': text(r['originalTitle'], '$p.originalTitle'),
      'aliases': strings(r['aliases'], '$p.aliases'),
      'coverUrl': cover != null && isRemoteUrl(cover) ? cover : null,
      'status': r['status'] ?? 'plan_to_read',
      'publicationStatus': r['publicationStatus'] ?? 'unknown',
      'score': number(r['score'], '$p.score'),
      'currentVolume': number(
        r['currentVolume'],
        '$p.currentVolume',
        zeroUnknown: true,
      ),
      'currentChapter': number(
        r['currentChapter'],
        '$p.currentChapter',
        zeroUnknown: true,
      ),
      'totalVolumes': number(
        r['totalVolumes'],
        '$p.totalVolumes',
        zeroUnknown: true,
      ),
      'totalChapters': number(
        r['totalChapters'],
        '$p.totalChapters',
        zeroUnknown: true,
      ),
      'notes': text(r['notes'], '$p.notes'),
      'tags': strings(r['tags'], '$p.tags'),
      'summary': text(r['summary'], '$p.summary'),
      'authors': strings(r['authors'], '$p.authors'),
      'illustrators': strings(r['illustrators'], '$p.illustrators'),
      'publishers': strings(r['publishers'], '$p.publishers'),
      'serializations': strings(r['serializations'], '$p.serializations'),
      'startDate': text(r['startDate'], '$p.startDate'),
      'endDate': text(r['endDate'], '$p.endDate'),
      'releaseDate': text(r['releaseDate'], '$p.releaseDate'),
      'createdAt': created,
      'updatedAt': updated,
    });
  }
  final historyKeys = <String>{};
  for (final item in historyRows.indexed) {
    final p =
        r'$.watchHistory.records['
        '${item.$1}]';
    final h = object(item.$2, p);
    final parentKey = keyOf(h['animeId'], '$p.animeId');
    final parent = mapped[parentKey];
    if (parent == null) fail('$p.animeId', '旧关系未匹配，不能按标题猜测关联');
    final oldKey = h['id'] == null
        ? 'position:${item.$1}'
        : keyOf(h['id'], '$p.id');
    if (!historyKeys.add(oldKey)) fail('$p.id', '旧历史 ID 重复');
    final watched = legacyTime(h['watchedAt'], '$p.watchedAt');
    histories.add({
      'uuid': h['uuid'] == null
          ? stable('watchHistory', oldKey)
          : uuid(h['uuid'], '$p.uuid'),
      'animeUuid': parent,
      'episode': number(h['episode'], '$p.episode'),
      'watchedOn': DateTime.parse(watched)
          .add(const Duration(hours: 8))
          .toIso8601String()
          .substring(0, 10),
      'watchedAt': watched,
      'createdAt': fallbackTime(h['createdAt'], exported, '$p.createdAt'),
    });
  }
  return parseAnimeLog(
    {
      'format': 'anime-log',
      'formatVersion': 1,
      'exportedAt': exported,
      'anime': records,
      'watchHistory': histories,
      'notes': notes,
      'manga': mangaRecords,
    },
    warnings: warnings,
    legacyFingerprint: fingerprint,
  );
}

String legacyTime(Object? value, String path) {
  if (value is! String) fail(path, '缺少时间');
  final text = value.trim();
  if (!RegExp(
    r'^\d{4}-\d\d-\d\d[T ]\d\d:\d\d:\d\d(?:\.\d{1,6})?(?:Z|[+-]\d\d:\d\d)?$',
  ).hasMatch(text)) {
    fail(path, '旧时间无效');
  }
  final iso = text.replaceFirst(' ', 'T');
  final zoned = RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(iso)
      ? iso
      : '$iso+08:00';
  validateClock(zoned, path);
  final offset = RegExp(r'[+-](\d\d):(\d\d)$').firstMatch(zoned);
  if (offset != null &&
      (int.parse(offset.group(1)!) > 23 || int.parse(offset.group(2)!) > 59)) {
    fail(path, '时区偏移无效');
  }
  return DateTime.parse(zoned).toUtc().toIso8601String();
}
