import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/api/backup_repository.dart';
import '../../core/anime_log_core.dart';
import '../../core/backup/backup_codec.dart';
import '../../core/backup/backup_document.dart';
import 'app_database.dart';

class SqliteBackupRepository implements BackupRepository {
  final AppDatabase db;
  final void Function()? onImported;
  SqliteBackupRepository(this.db, {this.onImported});

  @override
  Future<BackupDocument> snapshot() => db.transaction(_snapshot);

  Future<BackupDocument> _snapshot() async {
    final anime = await db.select(db.anime).get();
    final history = await db.select(db.watchHistory).get();
    final notes = await db.select(db.animeNotes).get();
    final manga = await db.select(db.manga).get();
    // Validate our own snapshot as well; corruption must not become a success.
    return parseAnimeLog({
      'format': 'anime-log',
      'formatVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'anime': anime
          .map(
            (a) => <String, dynamic>{
              'uuid': a.uuid,
              'metadata': {
                'title': a.title,
                'originalTitle': a.originalTitle,
                'season': a.season,
                'entryType': a.entryType,
                'sourceProvider': a.sourceProvider,
                'sourceId': a.sourceId,
                'totalEpisodes': a.totalEpisodes,
                'durationMinutes': a.durationMinutes,
                'summary': a.summary,
                'coverUrl': a.coverUrl != null && isRemoteUrl(a.coverUrl!)
                    ? a.coverUrl
                    : null,
                'premiereDate': a.premiereDate,
                'isFinished': a.isFinished,
                'cast': jsonDecode(a.cast),
                'castAliases': jsonDecode(a.castAliases),
              },
              'status': a.status,
              'progress': a.progress,
              'score': a.score,
              'notes': a.notes,
              'tags': jsonDecode(a.tags),
              'rewatchCount': a.rewatchCount,
              'startDate': a.startDate,
              'startDateSource': a.startDateSource,
              'endDate': a.endDate,
              'createdAt': a.createdAt,
              'updatedAt': a.updatedAt,
            },
          )
          .toList(),
      'watchHistory': history
          .map(
            (h) => <String, dynamic>{
              'uuid': h.uuid,
              'animeUuid': h.animeUuid,
              'episode': h.episode,
              'watchedOn': h.watchedOn,
              'watchedAt': h.watchedAt,
              'createdAt': h.createdAt,
            },
          )
          .toList(),
      'notes': notes
          .map(
            (n) => <String, dynamic>{
              'uuid': n.uuid,
              'animeUuid': n.animeUuid,
              'episode': n.episode,
              'content': n.content,
              'notedOn': n.notedOn,
              'createdAt': n.createdAt,
              'updatedAt': n.updatedAt,
            },
          )
          .toList(),
      'manga': manga
          .map(
            (m) => <String, dynamic>{
              'uuid': m.uuid,
              'bangumiId': m.bangumiId,
              'title': m.title,
              'originalTitle': m.originalTitle,
              'aliases': jsonDecode(m.aliases),
              'coverUrl': m.coverUrl != null && isRemoteUrl(m.coverUrl!)
                  ? m.coverUrl
                  : null,
              'status': m.status,
              'publicationStatus': m.publicationStatus,
              'score': m.score,
              'currentVolume': m.currentVolume,
              'currentChapter': m.currentChapter,
              'totalVolumes': m.totalVolumes,
              'totalChapters': m.totalChapters,
              'notes': m.notes,
              'tags': jsonDecode(m.tags),
              'summary': m.summary,
              'authors': jsonDecode(m.authors),
              'illustrators': jsonDecode(m.illustrators),
              'publishers': jsonDecode(m.publishers),
              'serializations': jsonDecode(m.serializations),
              'startDate': m.startDate,
              'endDate': m.endDate,
              'releaseDate': m.releaseDate,
              'createdAt': m.createdAt,
              'updatedAt': m.updatedAt,
            },
          )
          .toList(),
    });
  }

  @override
  Future<ImportPreview> preview(
    BackupDocument document,
    ImportMode mode,
  ) async {
    final current = await snapshot();
    return previewFor(document, current, mode);
  }

  static ImportPreview previewFor(
    BackupDocument document,
    BackupDocument current,
    ImportMode mode,
  ) {
    final existing = current.anime.map((a) => a.uuid).toSet();
    final currentByUuid = {for (final a in current.anime) a.uuid: a};
    final existingManga = current.manga.map((m) => m.uuid).toSet();
    final selected = document.anime
        .where((a) => mode == ImportMode.replace || !existing.contains(a.uuid))
        .map((a) => a.uuid)
        .toSet();
    final selectedManga = document.manga
        .where(
          (m) => mode == ImportMode.replace || !existingManga.contains(m.uuid),
        )
        .map((m) => m.uuid)
        .toSet();
    final filledCast = mode == ImportMode.append
        ? document.anime.where((a) {
            final old = currentByUuid[a.uuid];
            if (old == null) return false;
            return (old.metadata.cast.isEmpty && a.metadata.cast.isNotEmpty) ||
                (old.metadata.castAliases.isEmpty &&
                    a.metadata.castAliases.isNotEmpty);
          }).length
        : 0;
    return ImportPreview(
      mode: mode,
      newAnime: selected.length,
      newHistory: document.history
          .where((h) => selected.contains(h.animeUuid))
          .length,
      newNotes: document.notes
          .where((n) => selected.contains(n.animeUuid))
          .length,
      newManga: selectedManga.length,
      filledCast: filledCast,
      skippedAnime: document.anime.length - selected.length,
      skippedManga: document.manga.length - selectedManga.length,
      replacedAnime: mode == ImportMode.replace ? current.anime.length : 0,
      replacedHistory: mode == ImportMode.replace ? current.history.length : 0,
      replacedNotes: mode == ImportMode.replace ? current.notes.length : 0,
      replacedManga: mode == ImportMode.replace ? current.manga.length : 0,
      currentDigest: backupStateDigest(current),
    );
  }

  @override
  Future<void> importAtomically(
    BackupDocument document,
    ImportPreview confirmed,
  ) async {
    // Re-validate caller-provided domain values before starting any writes.
    final valid = parseAnimeLog(document.toJson());
    await db.transaction(() async {
      final current = await _snapshot();
      final actual = previewFor(valid, current, confirmed.mode);
      if (actual.currentDigest != confirmed.currentDigest ||
          actual.newAnime != confirmed.newAnime ||
          actual.newHistory != confirmed.newHistory ||
          actual.newNotes != confirmed.newNotes ||
          actual.newManga != confirmed.newManga ||
          actual.filledCast != confirmed.filledCast ||
          actual.skippedAnime != confirmed.skippedAnime ||
          actual.skippedManga != confirmed.skippedManga) {
        throw const BackupValidationException('导入预览', '本机数据已经变化，请重新预览和确认');
      }
      final existing = current.anime.map((a) => a.uuid).toSet();
      final incoming = valid.anime
          .where(
            (a) =>
                confirmed.mode == ImportMode.replace ||
                !existing.contains(a.uuid),
          )
          .toList();
      final allowed = incoming.map((a) => a.uuid).toSet();
      final currentByUuid = {for (final a in current.anime) a.uuid: a};
      final existingManga = current.manga.map((m) => m.uuid).toSet();
      final incomingManga = valid.manga
          .where(
            (m) =>
                confirmed.mode == ImportMode.replace ||
                !existingManga.contains(m.uuid),
          )
          .toList();
      if (confirmed.mode == ImportMode.replace) {
        await db.delete(db.anime).go();
        await db.delete(db.manga).go();
        await db.delete(db.intakeCommits).go();
        await db.delete(db.legacyImports).go();
      }
      for (final a in incoming) {
        final m = a.metadata;
        await db
            .into(db.anime)
            .insert(
              AnimeCompanion(
                uuid: Value(a.uuid),
                title: Value(m.title),
                originalTitle: Value(m.originalTitle),
                season: Value(m.season),
                entryType: Value(m.entryType?.wireValue),
                sourceProvider: Value(m.sourceProvider),
                sourceId: Value(m.sourceId),
                totalEpisodes: Value(m.totalEpisodes),
                durationMinutes: Value(m.durationMinutes),
                summary: Value(m.summary),
                coverUrl: Value(m.coverUrl),
                premiereDate: Value(m.premiereDate),
                isFinished: Value(m.isFinished),
                cast: Value(jsonEncode(m.cast)),
                castAliases: Value(jsonEncode(m.castAliases)),
                status: Value(a.status.wireValue),
                progress: Value(a.progress),
                score: Value(a.score),
                tags: Value(jsonEncode(a.tags)),
                rewatchCount: Value(a.rewatchCount),
                notes: Value(a.notes),
                startDate: Value(a.startDate),
                startDateSource: Value(a.startDateSource),
                endDate: Value(a.endDate),
                createdAt: Value(a.createdAt),
                updatedAt: Value(a.updatedAt),
              ),
            );
      }
      for (final m in incomingManga) {
        await db
            .into(db.manga)
            .insert(
              MangaCompanion(
                uuid: Value(m.uuid),
                bangumiId: Value(m.bangumiId),
                title: Value(m.title),
                originalTitle: Value(m.originalTitle),
                aliases: Value(jsonEncode(m.aliases)),
                coverUrl: Value(m.coverUrl),
                status: Value(m.status.wireValue),
                publicationStatus: Value(m.publicationStatus.wireValue),
                score: Value(m.score),
                currentVolume: Value(m.currentVolume),
                currentChapter: Value(m.currentChapter),
                totalVolumes: Value(m.totalVolumes),
                totalChapters: Value(m.totalChapters),
                notes: Value(m.notes),
                tags: Value(jsonEncode(m.tags)),
                summary: Value(m.summary),
                authors: Value(jsonEncode(m.authors)),
                illustrators: Value(jsonEncode(m.illustrators)),
                publishers: Value(jsonEncode(m.publishers)),
                serializations: Value(jsonEncode(m.serializations)),
                startDate: Value(m.startDate),
                endDate: Value(m.endDate),
                releaseDate: Value(m.releaseDate),
                createdAt: Value(m.createdAt),
                updatedAt: Value(m.updatedAt),
              ),
            );
      }
      if (confirmed.mode == ImportMode.append) {
        for (final a in valid.anime) {
          final old = currentByUuid[a.uuid];
          if (old == null) continue;
          final cast = old.metadata.cast.isEmpty && a.metadata.cast.isNotEmpty
              ? a.metadata.cast
              : old.metadata.cast;
          final aliases =
              old.metadata.castAliases.isEmpty &&
                  a.metadata.castAliases.isNotEmpty
              ? a.metadata.castAliases
              : old.metadata.castAliases;
          if (cast == old.metadata.cast &&
              aliases == old.metadata.castAliases) {
            continue;
          }
          await (db.update(
            db.anime,
          )..where((row) => row.uuid.equals(a.uuid))).write(
            AnimeCompanion(
              cast: Value(jsonEncode(cast)),
              castAliases: Value(jsonEncode(aliases)),
              updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
            ),
          );
        }
      }
      for (final h in valid.history.where(
        (h) => allowed.contains(h.animeUuid),
      )) {
        await db
            .into(db.watchHistory)
            .insert(
              WatchHistoryCompanion.insert(
                uuid: h.uuid,
                animeUuid: h.animeUuid,
                episode: h.episode,
                watchedOn: h.watchedOn,
                watchedAt: Value(h.watchedAt),
                createdAt: h.createdAt,
              ),
            );
      }
      for (final n in valid.notes.where((n) => allowed.contains(n.animeUuid))) {
        await db
            .into(db.animeNotes)
            .insert(
              AnimeNotesCompanion.insert(
                uuid: n.uuid,
                animeUuid: n.animeUuid,
                episode: Value(n.episode),
                content: n.content,
                notedOn: n.notedOn,
                createdAt: n.createdAt,
                updatedAt: n.updatedAt,
              ),
            );
      }
      if (document.legacyFingerprint != null) {
        await db
            .into(db.legacyImports)
            .insert(
              LegacyImportsCompanion.insert(
                fingerprint: document.legacyFingerprint!,
                importedAt: DateTime.now().toUtc().toIso8601String(),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
    onImported?.call();
  }
}
