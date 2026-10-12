import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SqliteLibraryRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = SqliteLibraryRepository(db);
  });
  tearDown(() => db.close());

  Future<AnimeRecord> create({
    int progress = 0,
    AnimeStatus status = AnimeStatus.watching,
  }) async => (await repository.createAtomically(
    AnimeCreationDraft(
      draftId: 'quick-progress',
      metadata: const AnimeMetadata(title: '进度纠正', totalEpisodes: 3),
      progress: progress,
      status: status,
      score: 0,
      notes: '保留总体备注',
      startDate: '2026-10-01',
      endDate: status == AnimeStatus.completed ? '2026-10-10' : null,
    ),
  )).entry;

  test(
    'decrement reopens completed records and keeps history and personal data',
    () async {
      final record = await create(progress: 3, status: AnimeStatus.completed);
      await repository.addHistory(record.uuid, 3, '2026-10-10');
      await repository.saveEpisodeNote(
        record.uuid,
        episode: 3,
        content: '保留分集备注',
        notedOn: '2026-10-10',
      );
      final history = await repository.history(record.uuid);

      await repository.decrement(record.uuid);

      final current = (await repository.find(record.uuid))!;
      expect(current.progress, 2);
      expect(current.status, AnimeStatus.watching);
      expect(current.endDate, isNull);
      expect(current.startDate, '2026-10-01');
      expect(current.startDateSource, 'manual');
      expect(current.score, 0);
      expect(current.notes, '保留总体备注');
      expect(
        (await repository.history(record.uuid)).single.uuid,
        history.single.uuid,
      );
      expect(
        (await repository.episodeNotes(record.uuid)).single.content,
        '保留分集备注',
      );
    },
  );

  test(
    'concurrent decrements read the latest value and never lower below zero',
    () async {
      final record = await create(progress: 2);
      await Future.wait([
        repository.decrement(record.uuid),
        repository.decrement(record.uuid),
      ]);
      expect((await repository.find(record.uuid))!.progress, 0);
      await expectLater(
        repository.decrement(record.uuid),
        throwsA(isA<QuickRecordValidationException>()),
      );
      expect((await repository.find(record.uuid))!.progress, 0);
      expect(await repository.history(record.uuid), isEmpty);
    },
  );

  test('decrement invalidates an older increment receipt without removing its event', () async {
    final record = await create();
    final receipt = await repository.increment(record.uuid, '2026-10-11');
    await repository.decrement(record.uuid);
    await expectLater(
      repository.undoIncrement(receipt),
      throwsA(isA<QuickRecordValidationException>()),
    );
    expect((await repository.find(record.uuid))!.progress, 0);
    expect(await repository.history(record.uuid), hasLength(1));
  });
}
