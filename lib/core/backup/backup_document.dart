import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../anime_log_core.dart';

enum ImportMode { append, replace }

String backupStateDigest(BackupDocument document) {
  final root = document.toJson()..remove('exportedAt');
  for (final key in ['anime', 'watchHistory', 'notes', 'manga']) {
    (root[key] as List).sort(
      (a, b) => (a['uuid'] as String).compareTo(b['uuid'] as String),
    );
  }
  return sha256.convert(utf8.encode(jsonEncode(root))).toString();
}

class BackupValidationException implements Exception {
  final String location;
  final String message;
  const BackupValidationException(this.location, this.message);
  @override
  String toString() => '$location：$message';
}

class BackupDocument {
  final String exportedAt;
  final List<AnimeRecord> anime;
  final List<WatchHistoryRecord> history;
  final List<AnimeNote> notes;
  final List<MangaRecord> manga;
  final List<String> warnings;
  final int repairedTags;
  final String? legacyFingerprint;
  BackupDocument({
    required this.exportedAt,
    required Iterable<AnimeRecord> anime,
    required Iterable<WatchHistoryRecord> history,
    required Iterable<AnimeNote> notes,
    Iterable<MangaRecord> manga = const <MangaRecord>[],
    Iterable<String> warnings = const [],
    this.repairedTags = 0,
    this.legacyFingerprint,
  }) : anime = List.unmodifiable(anime),
       history = List.unmodifiable(history),
       notes = List.unmodifiable(notes),
       manga = List.unmodifiable(manga),
       warnings = List.unmodifiable(warnings);

  Map<String, dynamic> toJson() => {
    'format': 'anime-log',
    'formatVersion': 1,
    'exportedAt': exportedAt,
    'anime': anime.map(animeToBackupJson).toList(),
    'watchHistory': history.map(historyToBackupJson).toList(),
    'notes': notes.map(noteToBackupJson).toList(),
    'manga': manga.map(mangaToBackupJson).toList(),
  };
  Uint8List encode() => Uint8List.fromList(
    utf8.encode(const JsonEncoder.withIndent('  ').convert(toJson())),
  );
}

Map<String, dynamic> animeToBackupJson(AnimeRecord r) => {
  'uuid': r.uuid,
  'metadata': {
    'title': r.metadata.title,
    'originalTitle': r.metadata.originalTitle,
    'season': r.metadata.season,
    'entryType': r.metadata.entryType?.wireValue,
    'sourceProvider': r.metadata.sourceProvider,
    'sourceId': r.metadata.sourceId,
    'totalEpisodes': r.metadata.totalEpisodes,
    'durationMinutes': r.metadata.durationMinutes,
    'summary': r.metadata.summary,
    'coverUrl': r.metadata.coverUrl,
    'premiereDate': r.metadata.premiereDate,
    'isFinished': r.metadata.isFinished,
    'cast': r.metadata.cast,
    'castAliases': r.metadata.castAliases,
  },
  'status': r.status.wireValue,
  'progress': r.progress,
  'score': r.score,
  'notes': r.notes,
  'tags': r.tags,
  'rewatchCount': r.rewatchCount,
  'startDate': r.startDate,
  'startDateSource': r.startDateSource,
  'endDate': r.endDate,
  'createdAt': r.createdAt,
  'updatedAt': r.updatedAt,
};
Map<String, dynamic> historyToBackupJson(WatchHistoryRecord h) => {
  'uuid': h.uuid,
  'animeUuid': h.animeUuid,
  'episode': h.episode,
  'watchedOn': h.watchedOn,
  'watchedAt': h.watchedAt,
  'createdAt': h.createdAt,
};
Map<String, dynamic> noteToBackupJson(AnimeNote n) => {
  'uuid': n.uuid,
  'animeUuid': n.animeUuid,
  'episode': n.episode,
  'content': n.content,
  'notedOn': n.notedOn,
  'createdAt': n.createdAt,
  'updatedAt': n.updatedAt,
};

Map<String, dynamic> mangaToBackupJson(MangaRecord m) => {
  'uuid': m.uuid,
  'bangumiId': m.bangumiId,
  'title': m.title,
  'originalTitle': m.originalTitle,
  'aliases': m.aliases,
  'coverUrl': m.coverUrl,
  'status': m.status.wireValue,
  'publicationStatus': m.publicationStatus.wireValue,
  'score': m.score,
  'currentVolume': m.currentVolume,
  'currentChapter': m.currentChapter,
  'totalVolumes': m.totalVolumes,
  'totalChapters': m.totalChapters,
  'notes': m.notes,
  'tags': m.tags,
  'summary': m.summary,
  'authors': m.authors,
  'illustrators': m.illustrators,
  'publishers': m.publishers,
  'serializations': m.serializations,
  'startDate': m.startDate,
  'endDate': m.endDate,
  'releaseDate': m.releaseDate,
  'createdAt': m.createdAt,
  'updatedAt': m.updatedAt,
};

class ImportPreview {
  final ImportMode mode;
  final int newAnime;
  final int newHistory;
  final int newNotes;
  final int newManga;
  final int filledCast;
  final int skippedAnime;
  final int skippedManga;
  final int replacedAnime;
  final int replacedHistory;
  final int replacedNotes;
  final int replacedManga;
  final String currentDigest;
  const ImportPreview({
    required this.mode,
    required this.newAnime,
    required this.newHistory,
    required this.newNotes,
    this.newManga = 0,
    this.filledCast = 0,
    required this.skippedAnime,
    this.skippedManga = 0,
    required this.replacedAnime,
    required this.replacedHistory,
    required this.replacedNotes,
    this.replacedManga = 0,
    required this.currentDigest,
  });
}
