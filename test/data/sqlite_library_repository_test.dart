import 'dart:io';

import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/data/platform/local_files.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

AnimeCreationDraft draft({
  String draftId = 'draft',
  String title = '某动画 第二季',
  int progress = 0,
  int? total,
  double? score,
  String? notes,
  AnimeStatus status = AnimeStatus.watching,
  int? rewatch,
  String? start,
  String? end,
}) => AnimeCreationDraft(
  draftId: draftId,
  metadata: AnimeMetadata(
    title: title,
    totalEpisodes: total,
    sourceProvider: 'bangumi',
    sourceId: '123',
  ),
  progress: progress,
  score: score,
  notes: notes,
  status: status,
  rewatchCount: rewatch,
  tags: buildCreationTags([], rewatch),
  startDate: start,
  endDate: end,
);

void main() {
  late Directory directory;
  late File file;
  late AppDatabase db;
  late SqliteLibraryRepository repo;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('animelog-test-');
    file = File('${directory.path}/library.sqlite');
    db = AppDatabase.file(file);
    repo = SqliteLibraryRepository(db);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test('file database reopens with Unicode, zero score, notes and no invented history', () async {
    final entry = (await repo.createAtomically(
      draft(score: 0, notes: '中文备注\n第二行'),
    )).entry;
    expect(entry.progress, 0);
    expect(entry.status, AnimeStatus.watching);
    expect(entry.startDate, isNull);
    expect(await repo.history(entry.uuid), isEmpty);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 2);
    await db.close();
    db = AppDatabase.file(file);
    repo = SqliteLibraryRepository(db);
    final restored = (await repo.find(entry.uuid))!;
    expect(restored.score, 0);
    expect(restored.notes, '中文备注\n第二行');
    expect(restored.createdAt, entry.createdAt);
    expect(
      (await db.select(db.animeNotes).get()).single.content,
      restored.notes,
    );
    expect(await repo.history(entry.uuid), isEmpty);
    expect((await repo.createAtomically(draft())).alreadySaved, true);
  });

  test('concurrent duplicate submission inserts exactly once; another draft remains independent', () async {
    final results = await Future.wait(
      List.generate(8, (_) => repo.createAtomically(draft())),
    );
    expect(results.map((r) => r.entry.uuid).toSet(), hasLength(1));
    expect(results.where((r) => !r.alreadySaved), hasLength(1));
    final other = (await repo.createAtomically(
      draft(draftId: 'another', rewatch: 2),
    )).entry;
    expect(other.uuid, isNot(results.first.entry.uuid));
    expect(other.tags, ['二刷']);
    expect(await repo.all(), hasLength(2));
  });

  test('failure writing overall note rolls back anime and commit', () async {
    await repo.all();
    await db.customStatement(
      "CREATE TRIGGER reject_note BEFORE INSERT ON anime_notes BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      repo.createAtomically(draft(notes: '备注')),
      throwsA(anything),
    );
    expect(await repo.all(), isEmpty);
    expect(await db.select(db.intakeCommits).get(), isEmpty);
    await db.customStatement('DROP TRIGGER reject_note');
    expect(
      (await repo.createAtomically(draft(notes: '备注'))).alreadySaved,
      false,
    );
  });

  test(
    'failure inserting history leaves progress, dates and status unchanged',
    () async {
      final entry = (await repo.createAtomically(draft(total: 1))).entry;
      await db.customStatement(
        "CREATE TRIGGER reject_history BEFORE INSERT ON watch_history BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await expectLater(
        repo.increment(entry.uuid, '2026-10-10'),
        throwsA(anything),
      );
      final current = (await repo.find(entry.uuid))!;
      expect(current.progress, 0);
      expect(current.status, AnimeStatus.watching);
      expect(current.updatedAt, entry.updatedAt);
      expect(current.startDate, isNull);
      expect(await repo.history(entry.uuid), isEmpty);
    },
  );

  test('concurrent +1 reads latest progress, completes at total and prohibits overflow', () async {
    final entry = (await repo.createAtomically(draft(total: 2))).entry;
    await Future.wait([
      repo.increment(entry.uuid, '2026-10-10'),
      repo.increment(entry.uuid, '2026-10-10'),
    ]);
    expect((await repo.find(entry.uuid))!.progress, 2);
    expect((await repo.find(entry.uuid))!.status, AnimeStatus.completed);
    expect((await repo.find(entry.uuid))!.endDate, isNull);
    expect((await repo.history(entry.uuid)).map((h) => h.episode).toSet(), {
      1,
      2,
    });
    await expectLater(
      repo.increment(entry.uuid, '2026-10-10'),
      throwsA(isA<QuickRecordValidationException>()),
    );
    expect(await repo.history(entry.uuid), hasLength(2));
  });

  test(
    'undo restores progress/status/dates and deletes only its history event',
    () async {
      final entry = (await repo.createAtomically(draft(total: 1))).entry;
      final receipt = await repo.increment(entry.uuid, '2026-10-10');
      expect((await repo.find(entry.uuid))!.startDateSource, 'history');
      await repo.undoIncrement(receipt);
      final current = (await repo.find(entry.uuid))!;
      expect(current.progress, 0);
      expect(current.status, AnimeStatus.watching);
      expect(current.startDate, isNull);
      expect(current.startDateSource, isNull);
      expect(await repo.history(entry.uuid), isEmpty);
      await expectLater(
        repo.undoIncrement(receipt),
        throwsA(isA<QuickRecordValidationException>()),
      );
    },
  );

  test(
    'old receipt cannot undo after subsequent progress or history edits',
    () async {
      final entry = (await repo.createAtomically(draft())).entry;
      final first = await repo.increment(entry.uuid, '2026-10-09');
      final second = await repo.increment(entry.uuid, '2026-10-10');
      await expectLater(
        repo.undoIncrement(first),
        throwsA(isA<QuickRecordValidationException>()),
      );
      final event = (await repo.history(entry.uuid)).first;
      await repo.correctHistory(event.uuid, event.episode, '2026-10-08');
      await expectLater(
        repo.undoIncrement(second),
        throwsA(isA<QuickRecordValidationException>()),
      );
      expect((await repo.find(entry.uuid))!.progress, 2);
      expect(await repo.history(entry.uuid), hasLength(2));
    },
  );

  test('full edit clears nullable fields, keeps history and downgrades completed progress', () async {
    final entry = (await repo.createAtomically(
      draft(total: 2, score: 0, notes: '备注', start: '2026-10-01'),
    )).entry;
    await repo.increment(entry.uuid, '2026-10-09');
    await repo.increment(entry.uuid, '2026-10-10');
    await repo.edit(
      entry.uuid,
      draft(
        title: '改名',
        progress: 0,
        total: 2,
        status: AnimeStatus.completed,
        end: '2026-10-10',
      ),
    );
    final current = (await repo.find(entry.uuid))!;
    expect(current.metadata.title, '改名');
    expect(current.progress, 0);
    expect(current.score, isNull);
    expect(current.notes, isNull);
    expect(current.startDate, isNull);
    expect(current.endDate, isNull);
    expect(current.status, AnimeStatus.watching);
    expect(await repo.history(entry.uuid), hasLength(2));
    expect(await db.select(db.animeNotes).get(), isEmpty);
  });

  test(
    'undoing a history rolls back progress and recalculates history dates',
    () async {
      final entry = (await repo.createAtomically(draft())).entry;
      await repo.addHistory(entry.uuid, 7, '2026-10-08');
      await repo.addHistory(entry.uuid, 7, '2026-10-09');
      final events = await repo.history(entry.uuid);
      await repo.correctHistory(events.last.uuid, 3, '2026-10-10');
      expect((await repo.find(entry.uuid))!.startDate, '2026-10-09');
      await repo.deleteHistory(events.first.uuid);
      expect((await repo.find(entry.uuid))!.progress, 6);
      expect((await repo.find(entry.uuid))!.startDate, '2026-10-10');
      await repo.deleteHistory(events.last.uuid);
      expect((await repo.find(entry.uuid))!.progress, 2);
      expect((await repo.find(entry.uuid))!.startDate, isNull);
    },
  );

  test('manual start date survives history correction and removal', () async {
    final entry = (await repo.createAtomically(draft(start: '2026-10-01')))
        .entry;
    await repo.addHistory(entry.uuid, 1, '2026-10-09');
    final event = (await repo.history(entry.uuid)).single;
    await repo.correctHistory(event.uuid, 1, '2026-09-01');
    await repo.deleteHistory(event.uuid);
    expect((await repo.find(entry.uuid))!.startDate, '2026-10-01');
    expect((await repo.find(entry.uuid))!.startDateSource, 'manual');
  });

  test(
    'history-derived start can be explicitly fixed to the same manual date',
    () async {
      final entry = (await repo.createAtomically(draft())).entry;
      await repo.addHistory(entry.uuid, 1, '2026-10-09');
      await repo.edit(
        entry.uuid,
        draft(progress: 1, start: '2026-10-09'),
        manualStartDate: true,
      );
      final event = (await repo.history(entry.uuid)).single;
      await repo.correctHistory(event.uuid, 1, '2026-09-01');
      expect((await repo.find(entry.uuid))!.startDate, '2026-10-09');
      expect((await repo.find(entry.uuid))!.startDateSource, 'manual');
    },
  );

  test('history/date conflict rolls back whole event transaction', () async {
    final entry = (await repo.createAtomically(
      draft(
        total: 1,
        progress: 1,
        status: AnimeStatus.completed,
        end: '2026-10-01',
      ),
    )).entry;
    await expectLater(
      repo.addHistory(entry.uuid, 1, '2026-10-10'),
      throwsA(isA<QuickRecordValidationException>()),
    );
    expect(await repo.history(entry.uuid), isEmpty);
    expect((await repo.find(entry.uuid))!.updatedAt, entry.updatedAt);
  });

  test('deletion preview and cascade affect exactly one UUID', () async {
    final first = (await repo.createAtomically(draft(notes: '备注'))).entry;
    final second = (await repo.createAtomically(
      draft(draftId: 'second', notes: '保留'),
    )).entry;
    await repo.addHistory(first.uuid, 1, '2026-10-10');
    final counts = await repo.deletionSummary(first.uuid);
    expect(counts.historyCount, 1);
    expect(counts.noteCount, 1);
    await repo.delete(first.uuid, counts);
    expect(await repo.find(first.uuid), isNull);
    expect(await repo.history(first.uuid), isEmpty);
    expect((await repo.find(second.uuid))!.notes, '保留');
    expect(
      (await db.select(db.animeNotes).get()).single.animeUuid,
      second.uuid,
    );
    expect(
      (await db.select(db.intakeCommits).get()).single.animeUuid,
      second.uuid,
    );
    await expectLater(
      db
          .into(db.watchHistory)
          .insert(
            WatchHistoryCompanion.insert(
              uuid: 'orphan',
              animeUuid: first.uuid,
              episode: 1,
              watchedOn: '2026-10-10',
              createdAt: DateTime.now().toUtc().toIso8601String(),
            ),
          ),
      throwsA(anything),
    );
  });

  test('changed deletion counts require fresh confirmation', () async {
    final entry = (await repo.createAtomically(draft())).entry;
    final counts = await repo.deletionSummary(entry.uuid);
    await repo.addHistory(entry.uuid, 1, '2026-10-10');
    await expectLater(
      repo.delete(entry.uuid, counts),
      throwsA(isA<QuickRecordValidationException>()),
    );
    expect(await repo.find(entry.uuid), isNotNull);
  });

  test('database CHECK prevents invalid data even outside use cases', () async {
    final entry = (await repo.createAtomically(draft())).entry;
    await expectLater(
      (db.update(db.anime)..where((a) => a.uuid.equals(entry.uuid))).write(
        const AnimeCompanion(progress: Value(-1)),
      ),
      throwsA(anything),
    );
    await expectLater(
      (db.update(db.anime)..where((a) => a.uuid.equals(entry.uuid))).write(
        const AnimeCompanion(sourceId: Value(null)),
      ),
      throwsA(anything),
    );
    expect((await repo.find(entry.uuid))!.progress, 0);
  });

  test(
    'increment today stores a real viewing moment and undo removes that event',
    () async {
      final entry = (await repo.createAtomically(draft())).entry;
      final before = DateTime.now();
      final on = before.toIso8601String().substring(0, 10);
      final receipt = await repo.increment(entry.uuid, on);
      final event = (await repo.history(entry.uuid)).single;
      final moment = DateTime.parse(event.watchedAt!);
      expect(event.watchedOn, on);
      expect(moment.isBefore(before), isFalse);
      expect(moment.isAfter(DateTime.now()), isFalse);
      await repo.undoIncrement(receipt);
      expect(await repo.history(entry.uuid), isEmpty);
    },
  );

  test('explicit viewing time sorts same-day history and corrections preserve precision', () async {
    final entry = (await repo.createAtomically(draft(total: 12))).entry;
    const on = '2026-10-08';
    final later = DateTime(
      2026,
      10,
      8,
      12,
      57,
      34,
      123,
    ).toUtc().toIso8601String();
    final earlier = DateTime(2026, 10, 8, 12, 30).toUtc().toIso8601String();
    await repo.addHistory(entry.uuid, 2, on, watchedAt: later);
    await repo.addHistory(entry.uuid, 1, on, watchedAt: earlier);
    final events = await repo.history(entry.uuid);
    expect(events.map((event) => event.watchedAt), [later, earlier]);
    expect(
      (await repo.watchAllHistory().first).map((event) => event.watchedAt),
      [later, earlier],
    );
    await repo.correctHistory(events.first.uuid, 3, on);
    expect((await repo.history(entry.uuid)).first.watchedAt, later);
    expect((await repo.find(entry.uuid))!.progress, 2);
    await repo.correctHistory(events.first.uuid, 3, on, clearTime: true);
    expect(
      (await repo.history(entry.uuid))
          .where((event) => event.uuid == events.first.uuid)
          .single
          .watchedAt,
      isNull,
    );
  });

  test(
    'time can be corrected and moving a date without a supplied time clears it',
    () async {
      final entry = (await repo.createAtomically(draft())).entry;
      final original = DateTime(2026, 10, 8, 20, 30).toUtc().toIso8601String();
      await repo.addHistory(entry.uuid, 1, '2026-10-08', watchedAt: original);
      final event = (await repo.history(entry.uuid)).single;
      final corrected = DateTime(2026, 10, 8, 21, 45).toUtc().toIso8601String();
      await repo.correctHistory(
        event.uuid,
        1,
        event.watchedOn,
        watchedAt: corrected,
      );
      expect((await repo.history(entry.uuid)).single.watchedAt, corrected);
      await repo.correctHistory(event.uuid, 1, '2026-10-09');
      expect((await repo.history(entry.uuid)).single.watchedAt, isNull);
      expect((await repo.find(entry.uuid))!.progress, 1);
    },
  );

  test(
    'invalid or mismatched viewing moments roll back without changing progress',
    () async {
      final entry = (await repo.createAtomically(draft())).entry;
      final otherDay = DateTime(2026, 10, 9, 12).toUtc().toIso8601String();
      await expectLater(
        repo.addHistory(entry.uuid, 1, '2026-10-08', watchedAt: otherDay),
        throwsA(isA<QuickRecordValidationException>()),
      );
      expect(await repo.history(entry.uuid), isEmpty);
      expect((await repo.find(entry.uuid))!.progress, 0);
      await repo.addHistory(entry.uuid, 1, '2026-10-08');
      final event = (await repo.history(entry.uuid)).single;
      await expectLater(
        repo.correctHistory(
          event.uuid,
          2,
          event.watchedOn,
          watchedAt: otherDay,
        ),
        throwsA(isA<QuickRecordValidationException>()),
      );
      await expectLater(
        repo.correctHistory(
          event.uuid,
          2,
          event.watchedOn,
          watchedAt: '2026-10-08T25:00:00Z',
        ),
        throwsA(isA<QuickRecordValidationException>()),
      );
      final unchanged = (await repo.history(entry.uuid)).single;
      expect(unchanged.episode, 1);
      expect(unchanged.watchedAt, isNull);
      expect((await repo.find(entry.uuid))!.progress, 1);
    },
  );

  test(
    'date-only history never infers viewing time from its creation time',
    () async {
      final entry = (await repo.createAtomically(draft())).entry;
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      await repo.increment(entry.uuid, yesterday);
      final event = (await repo.history(entry.uuid)).single;
      expect(event.createdAt, isNotEmpty);
      expect(event.watchedAt, isNull);
      await repo.correctHistory(event.uuid, 2, yesterday);
      expect((await repo.history(entry.uuid)).single.watchedAt, isNull);
    },
  );

  test('private draft preserves ID and invalid/unfinished Unicode input across file reopen', () async {
    final draftFile = File('${directory.path}/draft.json');
    final store = FileIntakeDraftStore(draftFile);
    final snapshot = {
      'draftId': 'stable-id',
      'fields': {'title': '未保存 中文', 'score': '输入中'},
      'status': 'watching',
    };
    await store.save(snapshot);
    expect(await FileIntakeDraftStore(draftFile).load(), snapshot);
    await store.save({...snapshot, 'status': 'completed'});
    expect((await store.load())!['status'], 'completed');
    await store.clear();
    expect(await store.load(), isNull);
  });
}
