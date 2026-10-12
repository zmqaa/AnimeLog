import 'dart:convert';
import 'dart:typed_data';

import 'package:animelog/core/backup/backup_document.dart';
import 'package:animelog/core/backup/backup_codec.dart';

const animeUuid = 'a6f1a5b0-9314-4d7a-8c90-2d7e2cda8d13';
const otherUuid = 'a6f1a5b0-9314-4d7a-8c90-2d7e2cda8d14';
const historyUuid = 'b6f1a5b0-9314-4d7a-8c90-2d7e2cda8d13';
const noteUuid = 'c6f1a5b0-9314-4d7a-8c90-2d7e2cda8d13';
const episodeNoteUuid = 'c6f1a5b0-9314-4d7a-8c90-2d7e2cda8d14';
const time = '2026-10-10T04:00:00.000Z';

Map<String, dynamic> newBackup() => {
  'format': 'anime-log',
  'formatVersion': 1,
  'exportedAt': time,
  'anime': [
    {
      'uuid': animeUuid,
      'metadata': {
        'title': '中文动画',
        'totalEpisodes': null,
        'sourceProvider': 'bangumi',
        'sourceId': '100',
        'coverUrl': 'https://example.org/cover.jpg',
      },
      'status': 'watching',
      'progress': 0,
      'score': 0,
      'notes': '总体备注',
      'tags': ['日常', '二刷'],
      'rewatchCount': 2,
      'startDate': '2026-10-01',
      'startDateSource': 'manual',
      'endDate': null,
      'createdAt': time,
      'updatedAt': time,
    },
  ],
  'watchHistory': [
    {
      'uuid': historyUuid,
      'animeUuid': animeUuid,
      'episode': 3,
      'watchedOn': '2026-10-02',
      'watchedAt': null,
      'createdAt': time,
    },
  ],
  'notes': [
    {
      'uuid': noteUuid,
      'animeUuid': animeUuid,
      'episode': null,
      'content': '总体备注',
      'notedOn': '2026-10-01',
      'createdAt': time,
      'updatedAt': time,
    },
    {
      'uuid': episodeNoteUuid,
      'animeUuid': animeUuid,
      'episode': 3,
      'content': '分集中文备注',
      'notedOn': '2026-10-02',
      'createdAt': time,
      'updatedAt': time,
    },
  ],
};
Uint8List encodeJson(Object value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(value)));
BackupDocument sampleBackup() => decodeBackup(encodeJson(newBackup()));
