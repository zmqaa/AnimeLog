import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/anime_log_core.dart';
import '../../core/api/library_repository.dart';
import '../../core/api/library_insights.dart';
import '../../core/domain/metadata_completion.dart';
import 'app_database.dart' hide AnimeNote;

class SqliteLibraryRepository
    implements
        AnimeCreationRepository,
        LibraryRepository,
        LibraryInsightsRepository {
  final AppDatabase db;
  final _uuid = const Uuid();
  final Map<String, _UndoState> _undo = {};
  SqliteLibraryRepository(this.db);

  void invalidateUndoReceipts() => _undo.clear();

  @override
  Stream<List<WatchHistoryRecord>> watchAllHistory() =>
      (db.select(db.watchHistory)..orderBy([
            (h) => OrderingTerm.desc(h.watchedOn),
            (h) => OrderingTerm.desc(h.watchedAt),
            (h) => OrderingTerm.desc(h.id),
          ]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (h) => WatchHistoryRecord(
                    id: h.id,
                    uuid: h.uuid,
                    animeUuid: h.animeUuid,
                    episode: h.episode,
                    watchedOn: h.watchedOn,
                    watchedAt: h.watchedAt,
                    createdAt: h.createdAt,
                  ),
                )
                .toList(),
          );

  @override
  Stream<List<AnimeRecord>> watchLibrary() =>
      (db.select(db.anime)..orderBy([(a) => OrderingTerm.desc(a.updatedAt)]))
          .watch()
          .map((rows) => rows.map(_record).toList());

  @override
  Future<List<AnimeRecord>> all() async =>
      (await db.select(db.anime).get()).map(_record).toList();

  @override
  Future<AnimeRecord?> find(String uuid) async {
    final row = await (db.select(
      db.anime,
    )..where((a) => a.uuid.equals(uuid))).getSingleOrNull();
    return row == null ? null : _record(row);
  }

  Future<AnimeRecord> _require(String uuid) async =>
      await find(uuid) ?? (throw const QuickRecordValidationException('记录不存在'));

  @override
  Future<AnimeCreationResult> createAtomically(AnimeCreationDraft draft) {
    validateAnimeCreationDraft(draft);
    return db.transaction(() async {
      final commit = await (db.select(
        db.intakeCommits,
      )..where((c) => c.draftId.equals(draft.draftId))).getSingleOrNull();
      if (commit != null) {
        return AnimeCreationResult(
          entry: await _require(commit.animeUuid),
          alreadySaved: true,
        );
      }
      final uuid = _uuid.v4();
      final now = _now();
      await db
          .into(db.anime)
          .insert(
            _values(draft).copyWith(
              uuid: Value(uuid),
              createdAt: Value(now),
              updatedAt: Value(now),
              startDateSource: Value(draft.startDate == null ? null : 'manual'),
            ),
          );
      await db
          .into(db.intakeCommits)
          .insert(
            IntakeCommitsCompanion.insert(
              draftId: draft.draftId,
              animeUuid: uuid,
            ),
          );
      await _overallNote(uuid, draft.notes, now);
      return AnimeCreationResult(entry: await _require(uuid));
    });
  }

  @override
  Future<void> edit(
    String uuid,
    AnimeCreationDraft values, {
    bool manualStartDate = false,
    HistoryTrimPreview? trimHistory,
  }) => db.transaction(() async {
    final old = await _require(uuid);
    if (trimHistory != null) {
      final current = await previewHistoryTrim(uuid, values.progress);
      if (trimHistory.animeUuid != uuid ||
          trimHistory.targetProgress != values.progress ||
          trimHistory.recordUpdatedAt != current.recordUpdatedAt ||
          _historySignature(trimHistory.events) !=
              _historySignature(current.events)) {
        throw const QuickRecordValidationException('进度或历史已变化，请重新确认批量删除范围');
      }
    }
    var draft = values;
    // Lowering a completed record's progress returns it to watching.
    if (old.status == AnimeStatus.completed &&
        draft.status == AnimeStatus.completed &&
        draft.metadata.totalEpisodes != null &&
        draft.progress < draft.metadata.totalEpisodes!) {
      draft = _draftWith(draft, status: AnimeStatus.watching, clearEnd: true);
    }
    validateAnimeCreationDraft(draft);
    final now = _now();
    final source = draft.startDate == null
        ? null
        : (!manualStartDate && draft.startDate == old.startDate
              ? old.startDateSource
              : 'manual');
    await (db.update(db.anime)..where((a) => a.uuid.equals(uuid))).write(
      _values(draft)
          .copyWith(updatedAt: Value(now), startDateSource: Value(source)),
    );
    await _overallNote(uuid, draft.notes, now);
    if (trimHistory != null) {
      await (db.delete(db.watchHistory)..where(
            (h) =>
                h.animeUuid.equals(uuid) &
                h.episode.isBiggerThanValue(draft.progress),
          ))
          .go();
      if (source == 'history') await _historyDate(uuid);
    }
    _undo.remove(uuid);
  });

  @override
  Future<HistoryTrimPreview> previewHistoryTrim(
    String uuid,
    int targetProgress,
  ) => db.transaction(() async {
    final record = await _require(uuid);
    if (targetProgress < 0 || targetProgress >= record.progress) {
      throw const QuickRecordValidationException('批量清理只用于降低观看进度');
    }
    return HistoryTrimPreview(
      uuid,
      targetProgress,
      record.updatedAt,
      (await history(uuid)).where((e) => e.episode > targetProgress).toList(),
    );
  });

  static String _historySignature(List<WatchHistoryRecord> events) {
    final sorted = events.toList()..sort((a, b) => a.uuid.compareTo(b.uuid));
    return jsonEncode(
      sorted
          .map(
            (e) => [e.uuid, e.episode, e.watchedOn, e.watchedAt, e.createdAt],
          )
          .toList(),
    );
  }

  @override
  Future<List<AnimeNote>> episodeNotes(String animeUuid) async =>
      (await (db.select(db.animeNotes)
                ..where(
                  (n) => n.animeUuid.equals(animeUuid) & n.episode.isNotNull(),
                )
                ..orderBy([
                  (n) => OrderingTerm.asc(n.episode),
                  (n) => OrderingTerm.desc(n.notedOn),
                  (n) => OrderingTerm.asc(n.uuid),
                ]))
              .get())
          .map(
            (n) => AnimeNote(
              uuid: n.uuid,
              animeUuid: n.animeUuid,
              episode: n.episode,
              content: n.content,
              notedOn: n.notedOn,
              createdAt: n.createdAt,
              updatedAt: n.updatedAt,
            ),
          )
          .toList();

  @override
  Future<String> saveEpisodeNote(
    String animeUuid, {
    String? noteUuid,
    required int episode,
    required String content,
    required String notedOn,
  }) => db.transaction(() async {
    validateEpisodeNote(episode, content, notedOn);
    await _require(animeUuid);
    final now = _now();
    final uuid = noteUuid ?? _uuid.v4();
    if (noteUuid == null) {
      await db
          .into(db.animeNotes)
          .insert(
            AnimeNotesCompanion.insert(
              uuid: uuid,
              animeUuid: animeUuid,
              episode: Value(episode),
              content: content.trim(),
              notedOn: notedOn,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await _requireEpisodeNote(animeUuid, noteUuid);
      await (db.update(
        db.animeNotes,
      )..where((n) => n.uuid.equals(noteUuid))).write(
        AnimeNotesCompanion(
          episode: Value(episode),
          content: Value(content.trim()),
          notedOn: Value(notedOn),
          updatedAt: Value(now),
        ),
      );
    }
    await _touch(animeUuid);
    _undo.remove(animeUuid);
    return uuid;
  });

  Future<void> _requireEpisodeNote(String animeUuid, String noteUuid) async {
    final note =
        await (db.select(db.animeNotes)..where(
              (n) =>
                  n.uuid.equals(noteUuid) &
                  n.animeUuid.equals(animeUuid) &
                  n.episode.isNotNull(),
            ))
            .getSingleOrNull();
    if (note == null) {
      throw const QuickRecordValidationException('分集备注不存在或不属于当前记录');
    }
  }

  @override
  Future<void> deleteEpisodeNote(String animeUuid, String noteUuid) =>
      db.transaction(() async {
        await _requireEpisodeNote(animeUuid, noteUuid);
        await (db.delete(
          db.animeNotes,
        )..where((n) => n.uuid.equals(noteUuid))).go();
        await _touch(animeUuid);
        _undo.remove(animeUuid);
      });

  Future<void> _touch(String uuid) =>
      (db.update(db.anime)..where((a) => a.uuid.equals(uuid))).write(
        AnimeCompanion(updatedAt: Value(_now())),
      );

  @override
  Future<MetadataCompletionPreview> previewMetadataCompletion(
    String uuid,
    AnimeMetadata source,
  ) => db.transaction(() async {
    final record = await _require(uuid);
    final episodes = await history(uuid);
    final maxEpisode = episodes.fold(
      0,
      (int largest, e) => e.episode > largest ? e.episode : largest,
    );
    return MetadataCompletionPreview(
      animeUuid: uuid,
      recordUpdatedAt: record.updatedAt,
      source: source,
      result: fillMissingAnimeMetadata(
        record,
        source,
        largestHistoryEpisode: maxEpisode,
      ),
    );
  });

  @override
  Future<int> applyMetadataCompletion(MetadataCompletionPreview confirmed) =>
      db.transaction(() async {
        final current = await previewMetadataCompletion(
          confirmed.animeUuid,
          confirmed.source,
        );
        if (current.recordUpdatedAt != confirmed.recordUpdatedAt ||
            _fillSignature(current.result) !=
                _fillSignature(confirmed.result)) {
          throw const QuickRecordValidationException('记录已变化，请重新预览资料补全');
        }
        if (current.result.changes.isEmpty) return 0;
        final m = current.result.metadata;
        await (db.update(
          db.anime,
        )..where((a) => a.uuid.equals(confirmed.animeUuid))).write(
          AnimeCompanion(
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
            updatedAt: Value(_now()),
          ),
        );
        _undo.remove(confirmed.animeUuid);
        return current.result.changes.length;
      });

  static String _fillSignature(MetadataFill fill) => jsonEncode({
    'changes': fill.changes.map(
      (k, v) => MapEntry(k, v is AnimeEntryType ? v.wireValue : v),
    ),
    'warnings': fill.warnings,
  });

  @override
  Future<List<WatchHistoryRecord>> history(String animeUuid) async =>
      (await (db.select(db.watchHistory)
                ..where((h) => h.animeUuid.equals(animeUuid))
                ..orderBy([
                  (h) => OrderingTerm.desc(h.watchedOn),
                  (h) => OrderingTerm.desc(h.watchedAt),
                  (h) => OrderingTerm.desc(h.id),
                ]))
              .get())
          .map(
            (h) => WatchHistoryRecord(
              id: h.id,
              uuid: h.uuid,
              animeUuid: h.animeUuid,
              episode: h.episode,
              watchedOn: h.watchedOn,
              watchedAt: h.watchedAt,
              createdAt: h.createdAt,
            ),
          )
          .toList();

  @override
  Future<ProgressReceipt> increment(String uuid, String watchedOn) =>
      db.transaction(() async {
        final old = await _require(uuid);
        if (old.metadata.totalEpisodes != null &&
            old.progress >= old.metadata.totalEpisodes!) {
          throw const QuickRecordValidationException('已到总集数，不能继续加一');
        }
        final eventUuid = await _appendHistory(
          old,
          old.progress + 1,
          watchedOn,
          watchedAt: _incrementMoment(watchedOn),
        );
        final current = await _require(uuid);
        final receipt = ProgressReceipt(_uuid.v4(), uuid, eventUuid);
        _undo[uuid] = _UndoState(
          receipt,
          old,
          current.updatedAt,
          DateTime.now().add(const Duration(seconds: 8)),
        );
        return receipt;
      });

  @override
  Future<void> decrement(String uuid) => db.transaction(() async {
    final old = await _require(uuid);
    if (old.progress <= 0) {
      throw const QuickRecordValidationException('进度已经为 0，不能继续减一');
    }
    final progress = old.progress - 1;
    await (db.update(db.anime)..where((a) => a.uuid.equals(uuid))).write(
      AnimeCompanion(
        progress: Value(progress),
        status: Value(
          old.status == AnimeStatus.completed
              ? AnimeStatus.watching.wireValue
              : old.status.wireValue,
        ),
        endDate: old.status == AnimeStatus.completed
            ? const Value(null)
            : const Value.absent(),
        updatedAt: Value(_now()),
      ),
    );
    final deletedHistory =
        await (db.delete(db.watchHistory)..where(
              (h) =>
                  h.animeUuid.equals(uuid) &
                  h.episode.isBiggerThanValue(progress),
            ))
            .go();
    if (deletedHistory > 0) await _historyDate(uuid);
    _undo.remove(uuid);
  });

  @override
  Future<void> undoIncrement(ProgressReceipt receipt) =>
      db.transaction(() async {
        final state = _undo[receipt.animeUuid];
        final current = await _require(receipt.animeUuid);
        final event = await (db.select(
          db.watchHistory,
        )..where((h) => h.uuid.equals(receipt.historyUuid))).getSingleOrNull();
        if (state == null ||
            state.receipt.token != receipt.token ||
            DateTime.now().isAfter(state.expiresAt) ||
            current.updatedAt != state.updatedAt ||
            current.progress != state.old.progress + 1 ||
            event == null ||
            event.animeUuid != receipt.animeUuid ||
            event.episode != current.progress) {
          throw const QuickRecordValidationException('已有后续操作或撤销已过期，请在详情中纠正');
        }
        await (db.delete(
          db.watchHistory,
        )..where((h) => h.uuid.equals(event.uuid))).go();
        await (db.update(
          db.anime,
        )..where((a) => a.uuid.equals(receipt.animeUuid))).write(
          AnimeCompanion(
            progress: Value(state.old.progress),
            status: Value(state.old.status.wireValue),
            endDate: Value(state.old.endDate),
            startDate: Value(state.old.startDate),
            startDateSource: Value(state.old.startDateSource),
            updatedAt: Value(_now()),
          ),
        );
        _undo.remove(receipt.animeUuid);
      });

  @override
  Future<void> addHistory(
    String uuid,
    int episode,
    String watchedOn, {
    String? watchedAt,
  }) => db.transaction(() async {
    await _appendHistory(
      await _require(uuid),
      episode,
      watchedOn,
      watchedAt: watchedAt,
    );
    _undo.remove(uuid);
  });

  Future<String> _appendHistory(
    AnimeRecord old,
    int episode,
    String on, {
    String? watchedAt,
  }) async {
    _validateEvent(old, episode, on);
    final moment = _historyMoment(on, watchedAt);
    final eventUuid = _uuid.v4();
    final now = _now();
    await db
        .into(db.watchHistory)
        .insert(
          WatchHistoryCompanion.insert(
            uuid: eventUuid,
            animeUuid: old.uuid,
            episode: episode,
            watchedOn: on,
            watchedAt: Value(moment),
            createdAt: now,
          ),
        );
    final progress = episode > old.progress ? episode : old.progress;
    final completed = old.metadata.totalEpisodes == progress;
    final status = completed
        ? AnimeStatus.completed
        : (old.status == AnimeStatus.planToWatch
              ? AnimeStatus.watching
              : old.status);
    await (db.update(db.anime)..where((a) => a.uuid.equals(old.uuid))).write(
      AnimeCompanion(
        progress: Value(progress),
        status: Value(status.wireValue),
        updatedAt: Value(now),
      ),
    );
    await _historyDate(old.uuid);
    return eventUuid;
  }

  void _validateEvent(AnimeRecord record, int episode, String on) {
    if (episode < 1 ||
        (record.metadata.totalEpisodes != null &&
            episode > record.metadata.totalEpisodes!)) {
      throw const QuickRecordValidationException('历史集数必须为正整数且不超过总集数');
    }
    if (normalizeDateString(on) != on) {
      throw const QuickRecordValidationException('观看日期必须是有效的 YYYY-MM-DD');
    }
  }

  @override
  Future<void> correctHistory(
    String historyUuid,
    int episode,
    String on, {
    String? watchedAt,
    bool clearTime = false,
  }) => db.transaction(() async {
    final event = await (db.select(
      db.watchHistory,
    )..where((h) => h.uuid.equals(historyUuid))).getSingle();
    _validateEvent(await _require(event.animeUuid), episode, on);
    final moment = watchedAt != null
        ? watchedAt == event.watchedAt && on == event.watchedOn
              ? event.watchedAt
              : _historyMoment(on, watchedAt)
        : !clearTime && on == event.watchedOn
        ? event.watchedAt
        : null;
    await (db.update(
      db.watchHistory,
    )..where((h) => h.uuid.equals(historyUuid))).write(
      WatchHistoryCompanion(
        episode: Value(episode),
        watchedOn: Value(on),
        watchedAt: Value(moment),
      ),
    );
    await _historyDate(event.animeUuid);
    _undo.remove(event.animeUuid);
  });

  static String? _incrementMoment(String on) {
    final now = DateTime.now();
    return now.toIso8601String().substring(0, 10) == on
        ? now.toUtc().toIso8601String()
        : null;
  }

  static String? _historyMoment(String on, String? raw) {
    if (raw == null) return null;
    final moment = DateTime.tryParse(raw);
    if (moment == null ||
        !RegExp(
          r'^\d{4}-\d{2}-\d{2}T([01]\d|2[0-3]):[0-5]\d(?::[0-5]\d(?:\.\d+)?)?(Z|[+-]([01]\d|2[0-3]):?[0-5]\d)$',
        ).hasMatch(raw) ||
        normalizeDateString(raw.substring(0, 10)) != raw.substring(0, 10) ||
        moment.toLocal().toIso8601String().substring(0, 10) != on) {
      throw const QuickRecordValidationException('观看时刻必须有效，且与观看日期一致');
    }
    return moment.toUtc().toIso8601String();
  }

  @override
  Future<HistoryUndoPreview> previewHistoryUndo(String historyUuid) =>
      db.transaction(() => _previewHistoryUndo(historyUuid));

  Future<HistoryUndoPreview> _previewHistoryUndo(String historyUuid) async {
    final event = await (db.select(
      db.watchHistory,
    )..where((h) => h.uuid.equals(historyUuid))).getSingleOrNull();
    if (event == null) {
      throw const QuickRecordValidationException('观看历史已不存在');
    }
    final record = await _require(event.animeUuid);
    final previousEpisode = event.episode - 1;
    final targetProgress = previousEpisode < record.progress
        ? previousEpisode
        : record.progress;
    return HistoryUndoPreview(
      animeUuid: event.animeUuid,
      historyUuid: event.uuid,
      selectedEpisode: event.episode,
      currentProgress: record.progress,
      targetProgress: targetProgress,
      recordUpdatedAt: record.updatedAt,
      events: (await history(event.animeUuid))
          .where((item) => item.episode > targetProgress)
          .toList(),
    );
  }

  @override
  Future<void> deleteHistory(
    String historyUuid, {
    HistoryUndoPreview? confirmed,
  }) => db.transaction(() async {
    final current = await _previewHistoryUndo(historyUuid);
    if (confirmed != null &&
        (confirmed.animeUuid != current.animeUuid ||
            confirmed.historyUuid != current.historyUuid ||
            confirmed.selectedEpisode != current.selectedEpisode ||
            confirmed.currentProgress != current.currentProgress ||
            confirmed.targetProgress != current.targetProgress ||
            confirmed.recordUpdatedAt != current.recordUpdatedAt ||
            _historySignature(confirmed.events) !=
                _historySignature(current.events))) {
      throw const QuickRecordValidationException('进度或历史已变化，请重新确认撤销范围');
    }
    final record = await _require(current.animeUuid);
    final downgrade =
        record.status == AnimeStatus.completed &&
        current.targetProgress < record.progress;
    await (db.update(db.anime)..where((a) => a.uuid.equals(record.uuid))).write(
      AnimeCompanion(
        progress: Value(current.targetProgress),
        status: Value(
          downgrade ? AnimeStatus.watching.wireValue : record.status.wireValue,
        ),
        endDate: downgrade ? const Value(null) : const Value.absent(),
        updatedAt: Value(_now()),
      ),
    );
    final deletedHistory =
        await (db.delete(db.watchHistory)..where(
              (h) =>
                  h.animeUuid.equals(current.animeUuid) &
                  h.episode.isBiggerThanValue(current.targetProgress),
            ))
            .go();
    if (deletedHistory > 0) await _historyDate(current.animeUuid);
    _undo.remove(current.animeUuid);
  });

  Future<void> _historyDate(String uuid) async {
    final current = await _require(uuid);
    String? start = current.startDate;
    String? source = current.startDateSource;
    if (source == 'history' || current.startDate == null) {
      final dates =
          await (db.select(db.watchHistory)
                ..where((h) => h.animeUuid.equals(uuid))
                ..orderBy([(h) => OrderingTerm.asc(h.watchedOn)])
                ..limit(1))
              .get();
      start = dates.isEmpty ? null : dates.first.watchedOn;
      source = start == null ? null : 'history';
    }
    if (start != null &&
        current.endDate != null &&
        start.compareTo(current.endDate!) > 0) {
      throw const QuickRecordValidationException('观看历史的开始日期晚于完成日期，请先纠正完成日期');
    }
    await (db.update(db.anime)..where((a) => a.uuid.equals(uuid))).write(
      AnimeCompanion(
        startDate: Value(start),
        startDateSource: Value(source),
        updatedAt: Value(_now()),
      ),
    );
  }

  @override
  Future<DeleteSummary> deletionSummary(String uuid) async => DeleteSummary(
    (await (db.select(
      db.watchHistory,
    )..where((h) => h.animeUuid.equals(uuid))).get()).length,
    (await (db.select(
      db.animeNotes,
    )..where((n) => n.animeUuid.equals(uuid))).get()).length,
  );

  @override
  Future<void> delete(String uuid, DeleteSummary confirmedSummary) =>
      db.transaction(() async {
        await _require(uuid);
        final counts = await deletionSummary(uuid);
        if (counts.historyCount != confirmedSummary.historyCount ||
            counts.noteCount != confirmedSummary.noteCount) {
          throw const QuickRecordValidationException('关联数据已变化，请重新确认删除范围');
        }
        await (db.delete(db.anime)..where((a) => a.uuid.equals(uuid))).go();
        _undo.remove(uuid);
      });

  Future<void> _overallNote(String uuid, String? notes, String now) async {
    final content = notes?.trim();
    final query = db.select(db.animeNotes)
      ..where((n) => n.animeUuid.equals(uuid) & n.episode.isNull());
    final old = await query.getSingleOrNull();
    if (content == null || content.isEmpty) {
      await (db.delete(
        db.animeNotes,
      )..where((n) => n.animeUuid.equals(uuid) & n.episode.isNull())).go();
    } else if (old == null) {
      await db
          .into(db.animeNotes)
          .insert(
            AnimeNotesCompanion.insert(
              uuid: _uuid.v4(),
              animeUuid: uuid,
              content: content,
              notedOn: _today(),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (db.update(
        db.animeNotes,
      )..where((n) => n.uuid.equals(old.uuid))).write(
        AnimeNotesCompanion(content: Value(content), updatedAt: Value(now)),
      );
    }
  }

  AnimeCompanion _values(AnimeCreationDraft d) => AnimeCompanion(
    title: Value(d.metadata.title.trim()),
    originalTitle: Value(d.metadata.originalTitle),
    season: Value(d.metadata.season),
    entryType: Value(d.metadata.entryType?.wireValue),
    sourceProvider: Value(d.metadata.sourceProvider),
    sourceId: Value(d.metadata.sourceId),
    totalEpisodes: Value(d.metadata.totalEpisodes),
    durationMinutes: Value(d.metadata.durationMinutes),
    summary: Value(d.metadata.summary),
    coverUrl: Value(d.metadata.coverUrl),
    premiereDate: Value(d.metadata.premiereDate),
    isFinished: Value(d.metadata.isFinished),
    cast: Value(jsonEncode(d.metadata.cast)),
    castAliases: Value(jsonEncode(d.metadata.castAliases)),
    status: Value(d.status.wireValue),
    progress: Value(d.progress),
    score: Value(d.score),
    rewatchCount: Value(d.rewatchCount),
    tags: Value(jsonEncode(d.tags)),
    notes: Value(d.notes?.trim().isEmpty == true ? null : d.notes?.trim()),
    startDate: Value(d.startDate),
    endDate: Value(d.endDate),
  );

  AnimeRecord _record(AnimeData a) => AnimeRecord(
    id: a.id,
    uuid: a.uuid,
    metadata: AnimeMetadata(
      title: a.title,
      originalTitle: a.originalTitle,
      season: a.season,
      entryType: animeEntryTypeFromWire(a.entryType),
      sourceProvider: a.sourceProvider,
      sourceId: a.sourceId,
      totalEpisodes: a.totalEpisodes,
      durationMinutes: a.durationMinutes,
      summary: a.summary,
      coverUrl: a.coverUrl,
      premiereDate: a.premiereDate,
      isFinished: a.isFinished,
      cast: (jsonDecode(a.cast) as List).cast<String>(),
      castAliases: (jsonDecode(a.castAliases) as List).cast<String>(),
    ),
    status: animeStatusFromWire(a.status)!,
    progress: a.progress,
    score: a.score,
    rewatchCount: a.rewatchCount,
    tags: (jsonDecode(a.tags) as List).cast<String>(),
    notes: a.notes,
    localCoverPath: a.localCoverPath,
    startDate: a.startDate,
    startDateSource: a.startDateSource,
    endDate: a.endDate,
    createdAt: a.createdAt,
    updatedAt: a.updatedAt,
  );

  static String _now() => DateTime.now().toUtc().toIso8601String();
  static String _today() => DateTime.now().toIso8601String().substring(0, 10);
}

class _UndoState {
  final ProgressReceipt receipt;
  final AnimeRecord old;
  final String updatedAt;
  final DateTime expiresAt;
  const _UndoState(this.receipt, this.old, this.updatedAt, this.expiresAt);
}

AnimeCreationDraft _draftWith(
  AnimeCreationDraft d, {
  required AnimeStatus status,
  bool clearEnd = false,
}) => AnimeCreationDraft(
  draftId: d.draftId,
  metadata: d.metadata,
  status: status,
  progress: d.progress,
  score: d.score,
  notes: d.notes,
  tags: d.tags,
  rewatchCount: d.rewatchCount,
  startDate: d.startDate,
  endDate: clearEnd ? null : d.endDate,
);
