import 'dart:io';
import 'dart:convert';

import 'package:animelog/core/backup/backup_codec.dart';
import 'package:animelog/core/backup/backup_document.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_test_helpers.dart';

void main() {
  test('canonical JSON preserves Unicode, zero/null and calendar dates; excludes local identities', () {
    final backup = sampleBackup();
    final restored = decodeBackup(backup.encode());
    expect(restored.toJson(), backup.toJson());
    expect(restored.anime.single.score, 0);
    expect(restored.anime.single.progress, 0);
    expect(restored.history.single.watchedAt, isNull);
    expect(restored.history.single.watchedOn, '2026-10-02');
    expect(restored.anime.single.localCoverPath, isNull);
    expect(backup.anime.single.id, 0);
    expect(backup.toJson().toString(), isNot(contains('localCoverPath')));
  });

  test(
    'derived rewatch tag repairs are counted, explicit count is unchanged',
    () {
      final root = newBackup();
      root['anime'][0]['tags'] = ['日常', '三刷'];
      final result = decodeBackup(encodeJson(root));
      expect(result.repairedTags, 1);
      expect(result.anime.single.tags, ['日常', '二刷']);
      expect(result.anime.single.rewatchCount, 2);
    },
  );

  test(
    'backup accepts the same native 64-bit integer range as manual records',
    () {
      final root = newBackup();
      root['anime'][0]['progress'] = 4294967296;
      final decoded = decodeBackup(encodeJson(root));
      expect(decodeBackup(decoded.encode()).anime.single.progress, 4294967296);
    },
  );

  test('legacy invalid timezone offsets are rejected instead of normalized to a different day', () {
    final root = jsonDecode(
      File('test/fixtures/animetrack_v5.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    root['watchHistory']['records'][0]['watchedAt'] =
        '2026-10-10T18:30:00+25:00';
    expect(
      () => decodeBackup(encodeJson(root)),
      throwsA(isA<BackupValidationException>()),
    );
  });

  final cases = <String, void Function(Map<String, dynamic>)>{
    'future format': (r) => r['formatVersion'] = 2,
    'wrong format': (r) => r['format'] = 'other',
    'invalid UUID': (r) => r['anime'][0]['uuid'] = '1',
    'duplicate UUID': (r) =>
        r['anime'].add(<String, dynamic>{...r['anime'][0]}),
    'orphan history': (r) => r['watchHistory'][0]['animeUuid'] = otherUuid,
    'invalid date': (r) => r['watchHistory'][0]['watchedOn'] = '2026-02-30',
    'invalid clock': (r) => r['anime'][0]['createdAt'] = '2026-10-10T25:00:00Z',
    'non UTC timestamp': (r) =>
        r['anime'][0]['createdAt'] = '2026-10-10T04:00:00',
    'negative progress': (r) => r['anime'][0]['progress'] = -1,
    'out of range score': (r) => r['anime'][0]['score'] = 11,
    'half source': (r) => r['anime'][0]['metadata']['sourceId'] = null,
    'overall mismatch': (r) => r['notes'][0]['content'] = '冲突备注',
    'duplicate overall note': (r) =>
        r['notes'].add(<String, dynamic>{...r['notes'][0], 'uuid': otherUuid}),
    'bad tag': (r) => r['anime'][0]['tags'] = [' 日常 ', '二刷'],
    'bad array': (r) => r['watchHistory'] = {},
  };
  for (final c in cases.entries) {
    test('rejects ${c.key} with a field location before any writes', () {
      final root = newBackup();
      c.value(root);
      expect(
        () => decodeBackup(encodeJson(root)),
        throwsA(isA<BackupValidationException>()),
      );
    });
  }

  test('real exporter v5 shape preserves notes, times, unknown source and explicit legacy brush', () {
    final bytes = File('test/fixtures/animetrack_v5.json').readAsBytesSync();
    final backup = decodeBackup(bytes);
    expect(backup.anime, hasLength(2));
    expect(backup.manga, hasLength(1));
    expect(backup.manga.single.title, '不支持的漫画');
    expect(backup.notes, hasLength(3));
    final first = backup.anime.first;
    expect(first.score, 0);
    expect(first.rewatchCount, 3);
    expect(first.notes, '总备注中文');
    expect(first.startDate, '2026-09-01');
    expect(first.startDateSource, isNull);
    expect(first.metadata.sourceId, isNull);
    expect(first.metadata.coverUrl, isNull);
    expect(backup.anime.last.metadata.totalEpisodes, isNull);
    expect(backup.history.first.watchedOn, '2026-10-11');
    expect(backup.history.last.watchedOn, '2026-10-10');
    expect(backup.history.last.watchedAt, '2026-10-10T15:30:00.000Z');
    expect(backup.warnings.join(' '), isNot(contains('未导入类别 manga')));
    final retry = decodeBackup(bytes);
    expect(retry.toJson(), backup.toJson());
  });
}
