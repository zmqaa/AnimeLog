import 'dart:async';
import 'dart:io';

import 'package:animelog/application/metadata_completion.dart';
import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/core/api/ai_intake.dart';
import 'package:animelog/core/backup/backup_document.dart';
import 'package:animelog/data/local/app_database.dart' hide AnimeNote;
import 'package:animelog/data/local/sqlite_backup_repository.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/features/detail/metadata_completion_controller.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ai/ai_fixtures.dart' show FixtureSource;

const sourceMetadata = AnimeMetadata(
  title: '来源标题',
  originalTitle: 'Source title',
  sourceProvider: 'bangumi',
  sourceId: '253',
  season: 2,
  entryType: AnimeEntryType.tv,
  totalEpisodes: 12,
  durationMinutes: 24,
  summary: '来源简介',
  premiereDate: '2026-01-01',
  isFinished: true,
);

AnimeCreationDraft editValues(
  AnimeRecord record,
  int progress, {
  AnimeMetadata? metadata,
  String? notes,
}) {
  final completed =
      record.status == AnimeStatus.completed &&
      record.metadata.totalEpisodes == progress;
  return AnimeCreationDraft(
    draftId: 'edit',
    metadata: metadata ?? record.metadata,
    status:
        record.status == AnimeStatus.completed &&
            !completed &&
            record.metadata.totalEpisodes != null
        ? AnimeStatus.watching
        : record.status,
    progress: progress,
    score: record.score,
    notes: notes ?? record.notes,
    tags: record.tags,
    rewatchCount: record.rewatchCount,
    startDate: record.startDate,
    endDate: completed || record.metadata.totalEpisodes == null
        ? record.endDate
        : null,
  );
}

void main() {
  late Directory directory;
  late AppDatabase db;
  late SqliteLibraryRepository repo;
  Future<AnimeRecord> create({
    String draftId = 'one',
    AnimeMetadata? metadata,
    int progress = 0,
    AnimeStatus status = AnimeStatus.watching,
    String? start,
    String? end,
  }) async => (await repo.createAtomically(
    AnimeCreationDraft(
      draftId: draftId,
      metadata: metadata ?? const AnimeMetadata(title: '用户标题'),
      status: status,
      progress: progress,
      notes: '总体备注',
      score: 0,
      rewatchCount: 2,
      tags: const ['私人标签', '二刷'],
      startDate: start,
      endDate: end,
    ),
  )).entry;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('animelog-record-tools-');
    db = AppDatabase.file(File('${directory.path}/db.sqlite'));
    repo = SqliteLibraryRepository(db);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test('multiple episode notes retain identity and creation date; never change overall note, progress or history', () async {
    final record = await create(progress: 4);
    final first = await repo.saveEpisodeNote(
      record.uuid,
      episode: 6,
      content: ' 中文分集备注 ',
      notedOn: '2026-10-01',
    );
    final second = await repo.saveEpisodeNote(
      record.uuid,
      episode: 6,
      content: '同集第二条',
      notedOn: '2026-10-02',
    );
    final initial = (await repo.episodeNotes(record.uuid))
        .singleWhere((n) => n.uuid == first);
    await repo.saveEpisodeNote(
      record.uuid,
      noteUuid: first,
      episode: 5,
      content: '纠正内容',
      notedOn: '2026-09-30',
    );
    final edited = (await repo.episodeNotes(record.uuid))
        .singleWhere((n) => n.uuid == first);
    expect(edited.createdAt, initial.createdAt);
    expect(edited.notedOn, '2026-09-30');
    expect(edited.episode, 5);
    await repo.deleteEpisodeNote(record.uuid, second);
    expect((await repo.episodeNotes(record.uuid)).single.uuid, first);
    final current = (await repo.find(record.uuid))!;
    expect(current.progress, 4);
    expect(current.score, 0);
    expect(current.notes, '总体备注');
    expect(current.tags, ['私人标签', '二刷']);
    expect(await repo.history(record.uuid), isEmpty);
    expect(
      (await db.select(db.animeNotes).get())
          .where((n) => n.episode == null)
          .single
          .content,
      '总体备注',
    );
  });
  test('episode note validation and UUID ownership refuse invalid input and overall-note edits', () async {
    final first = await create();
    final other = await create(draftId: 'other');
    final uuid = await repo.saveEpisodeNote(
      first.uuid,
      episode: 1,
      content: '内容',
      notedOn: '2026-10-01',
    );
    for (final values in [
      (0, '内容', '2026-10-01'),
      (1, ' ', '2026-10-01'),
      (1, '内容', '2026-02-30'),
    ]) {
      await expectLater(
        repo.saveEpisodeNote(
          first.uuid,
          episode: values.$1,
          content: values.$2,
          notedOn: values.$3,
        ),
        throwsA(isA<QuickRecordValidationException>()),
      );
    }
    await expectLater(
      repo.deleteEpisodeNote(other.uuid, uuid),
      throwsA(isA<QuickRecordValidationException>()),
    );
    await expectLater(
      repo.saveEpisodeNote(
        other.uuid,
        noteUuid: uuid,
        episode: 1,
        content: '串记录',
        notedOn: '2026-10-01',
      ),
      throwsA(isA<QuickRecordValidationException>()),
    );
    final overall =
        (await (db.select(db.animeNotes)..where(
                  (n) => n.animeUuid.equals(first.uuid) & n.episode.isNull(),
                ))
                .get())
            .single;
    await expectLater(
      repo.deleteEpisodeNote(first.uuid, overall.uuid),
      throwsA(isA<QuickRecordValidationException>()),
    );
    expect((await repo.episodeNotes(first.uuid)).single.content, '内容');
  });
  test(
    'episode-note insert, edit and delete roll back if parent update fails',
    () async {
      final record = await create();
      final uuid = await repo.saveEpisodeNote(
        record.uuid,
        episode: 1,
        content: '原内容',
        notedOn: '2026-10-01',
      );
      await db.customStatement(
        "CREATE TRIGGER fail_note_parent BEFORE UPDATE ON anime BEGIN SELECT RAISE(ABORT, 'fixture failure'); END",
      );
      await expectLater(
        repo.saveEpisodeNote(
          record.uuid,
          episode: 2,
          content: '新内容',
          notedOn: '2026-10-02',
        ),
        throwsA(anything),
      );
      await expectLater(
        repo.saveEpisodeNote(
          record.uuid,
          noteUuid: uuid,
          episode: 3,
          content: '修改',
          notedOn: '2026-10-03',
        ),
        throwsA(anything),
      );
      await expectLater(
        repo.deleteEpisodeNote(record.uuid, uuid),
        throwsA(anything),
      );
      final note = (await repo.episodeNotes(record.uuid)).single;
      expect(note.uuid, uuid);
      expect(note.content, '原内容');
      expect(note.episode, 1);
    },
  );
  test('edited episode notes survive close/reopen and JSON full restore with same UUID and dates', () async {
    final record = await create();
    final uuid = await repo.saveEpisodeNote(
      record.uuid,
      episode: 2,
      content: '迁移后备注',
      notedOn: '2026-10-01',
    );
    await repo.saveEpisodeNote(
      record.uuid,
      noteUuid: uuid,
      episode: 3,
      content: '重开保留中文',
      notedOn: '2026-10-02',
    );
    final before = (await repo.episodeNotes(record.uuid)).single;
    await db.close();
    db = AppDatabase.file(File('${directory.path}/db.sqlite'));
    repo = SqliteLibraryRepository(db);
    expect((await repo.episodeNotes(record.uuid)).single.content, '重开保留中文');
    final backup = await SqliteBackupRepository(db).snapshot();
    await db.close();
    db = AppDatabase(NativeDatabase.memory());
    final targetDb = db;
    final backupRepo = SqliteBackupRepository(targetDb);
    await backupRepo.importAtomically(
      backup,
      await backupRepo.preview(backup, ImportMode.replace),
    );
    final restored = (await SqliteLibraryRepository(
      targetDb,
    ).episodeNotes(record.uuid)).single;
    expect(restored.uuid, before.uuid);
    expect(restored.createdAt, before.createdAt);
    expect(restored.updatedAt, before.updatedAt);
    expect(restored.notedOn, before.notedOn);
  });
  test('lowering progress preserves history by default; confirmed trim removes only higher episodes and retains notes', () async {
    final record = await create(
      metadata: const AnimeMetadata(title: '历史记录', totalEpisodes: 12),
    );
    await repo.addHistory(record.uuid, 1, '2026-10-04');
    await repo.addHistory(record.uuid, 4, '2026-09-01');
    await repo.addHistory(record.uuid, 6, '2026-10-05');
    await repo.addHistory(record.uuid, 6, '2026-10-06');
    await repo.saveEpisodeNote(
      record.uuid,
      episode: 6,
      content: '高于新进度的备注也保留',
      notedOn: '2026-10-06',
    );
    await repo.edit(
      record.uuid,
      editValues((await repo.find(record.uuid))!, 2),
    );
    expect(await repo.history(record.uuid), hasLength(4));
    await repo.edit(
      record.uuid,
      editValues((await repo.find(record.uuid))!, 6),
    );
    final preview = await repo.previewHistoryTrim(record.uuid, 2);
    expect(preview.events, hasLength(3));
    await repo.edit(
      record.uuid,
      editValues((await repo.find(record.uuid))!, 2),
      trimHistory: preview,
    );
    expect((await repo.history(record.uuid)).single.episode, 1);
    final after = (await repo.find(record.uuid))!;
    expect(after.progress, 2);
    expect(after.startDate, '2026-10-04');
    expect(after.startDateSource, 'history');
    expect(after.notes, '总体备注');
    expect((await repo.episodeNotes(record.uuid)).single.episode, 6);
  });
  test('trim to zero clears history-derived start and completed end but preserves manual start', () async {
    final record = await create(
      metadata: const AnimeMetadata(title: '记录', totalEpisodes: 2),
    );
    await repo.addHistory(record.uuid, 1, '2026-10-01');
    await repo.addHistory(record.uuid, 2, '2026-10-02');
    var latest = (await repo.find(record.uuid))!;
    final preview = await repo.previewHistoryTrim(record.uuid, 0);
    await repo.edit(record.uuid, editValues(latest, 0), trimHistory: preview);
    latest = (await repo.find(record.uuid))!;
    expect(latest.status, AnimeStatus.watching);
    expect(latest.startDate, isNull);
    expect(latest.endDate, isNull);
    final manual = await create(draftId: 'manual', start: '2025-01-01');
    await repo.addHistory(manual.uuid, 3, '2026-10-03');
    final manualPreview = await repo.previewHistoryTrim(manual.uuid, 0);
    await repo.edit(
      manual.uuid,
      editValues((await repo.find(manual.uuid))!, 0),
      trimHistory: manualPreview,
    );
    expect((await repo.find(manual.uuid))!.startDate, '2025-01-01');
  });
  test('trim preserves an explicitly cleared start date even with remaining history', () async {
    final record = await create();
    await repo.addHistory(record.uuid, 1, '2026-10-01');
    await repo.addHistory(record.uuid, 4, '2026-10-02');
    final preview = await repo.previewHistoryTrim(record.uuid, 2);
    final current = (await repo.find(record.uuid))!;
    await repo.edit(
      record.uuid,
      AnimeCreationDraft(
        draftId: 'clear-date',
        metadata: current.metadata,
        progress: 2,
        notes: current.notes,
        score: current.score,
        tags: current.tags,
        rewatchCount: current.rewatchCount,
      ),
      trimHistory: preview,
    );
    final after = (await repo.find(record.uuid))!;
    expect(after.startDate, isNull);
    expect(after.startDateSource, isNull);
    expect((await repo.history(record.uuid)).single.episode, 1);
  });
  test('trim retains an imported unknown-source start date without relabelling it manual', () async {
    final record = await create();
    await repo.addHistory(record.uuid, 3, '2026-10-01');
    await (db.update(db.anime)..where((a) => a.uuid.equals(record.uuid))).write(
      const AnimeCompanion(
        startDate: Value('2025-01-01'),
        startDateSource: Value(null),
      ),
    );
    final preview = await repo.previewHistoryTrim(record.uuid, 0);
    await repo.edit(
      record.uuid,
      editValues((await repo.find(record.uuid))!, 0),
      trimHistory: preview,
    );
    final after = (await repo.find(record.uuid))!;
    expect(after.startDate, '2025-01-01');
    expect(after.startDateSource, isNull);
    expect(await repo.history(record.uuid), isEmpty);
  });
  test('trim rejects a same-count changed history even if parent timestamp is unchanged', () async {
    final record = await create();
    await repo.addHistory(record.uuid, 4, '2026-10-01');
    final preview = await repo.previewHistoryTrim(record.uuid, 2);
    await (db.update(db.watchHistory)
          ..where((h) => h.animeUuid.equals(record.uuid)))
        .write(const WatchHistoryCompanion(watchedOn: Value('2026-10-02')));
    await expectLater(
      repo.edit(
        record.uuid,
        editValues((await repo.find(record.uuid))!, 2),
        trimHistory: preview,
      ),
      throwsA(isA<QuickRecordValidationException>()),
    );
    expect((await repo.find(record.uuid))!.progress, 4);
    expect((await repo.history(record.uuid)).single.watchedOn, '2026-10-02');
  });
  test('new history invalidates preview and preview cannot trim another record or another target', () async {
    final record = await create();
    await repo.addHistory(record.uuid, 5, '2026-10-01');
    final preview = await repo.previewHistoryTrim(record.uuid, 2);
    await repo.addHistory(record.uuid, 4, '2026-10-02');
    await expectLater(
      repo.edit(
        record.uuid,
        editValues((await repo.find(record.uuid))!, 2),
        trimHistory: preview,
      ),
      throwsA(anything),
    );
    final fresh = await repo.previewHistoryTrim(record.uuid, 2);
    await expectLater(
      repo.edit(
        record.uuid,
        editValues((await repo.find(record.uuid))!, 1),
        trimHistory: fresh,
      ),
      throwsA(anything),
    );
    final other = await create(draftId: 'other', progress: 5);
    await expectLater(
      repo.edit(other.uuid, editValues(other, 2), trimHistory: fresh),
      throwsA(anything),
    );
    expect((await repo.find(other.uuid))!.progress, 5);
  });
  test('history delete failure rolls back progress, overall note and every deletion', () async {
    final record = await create();
    await repo.addHistory(record.uuid, 2, '2026-10-01');
    await repo.addHistory(record.uuid, 4, '2026-10-02');
    final preview = await repo.previewHistoryTrim(record.uuid, 0);
    await db.customStatement(
      "CREATE TRIGGER fail_trim BEFORE DELETE ON watch_history BEGIN SELECT RAISE(ABORT, 'fixture failure'); END",
    );
    await expectLater(
      repo.edit(
        record.uuid,
        editValues((await repo.find(record.uuid))!, 0, notes: '不能部分保存'),
        trimHistory: preview,
      ),
      throwsA(anything),
    );
    final after = (await repo.find(record.uuid))!;
    expect(after.progress, 4);
    expect(after.notes, '总体备注');
    expect(await repo.history(record.uuid), hasLength(2));
  });
  test('completion previews only missing fields, preserves false and all personal data and does not create history', () async {
    final record = await create(
      metadata: const AnimeMetadata(
        title: '用户自定标题',
        originalTitle: '用户原名',
        entryType: AnimeEntryType.tv,
        summary: '用户简介',
        isFinished: false,
        sourceProvider: 'bangumi',
        sourceId: '253',
      ),
      progress: 3,
      start: '2025-01-01',
    );
    await repo.addHistory(record.uuid, 2, '2026-10-01');
    final before = (await repo.find(record.uuid))!;
    final history = await repo.history(record.uuid);
    final preview = await repo.previewMetadataCompletion(
      record.uuid,
      sourceMetadata,
    );
    expect((await repo.find(record.uuid))!.metadata.totalEpisodes, isNull);
    expect(preview.result.changes.keys, isNot(contains('summary')));
    expect(preview.result.changes.keys, isNot(contains('isFinished')));
    await repo.applyMetadataCompletion(preview);
    final after = (await repo.find(record.uuid))!;
    expect(after.metadata.title, '用户自定标题');
    expect(after.metadata.originalTitle, '用户原名');
    expect(after.metadata.summary, '用户简介');
    expect(after.metadata.isFinished, false);
    expect(after.metadata.totalEpisodes, 12);
    expect(after.status, before.status);
    expect(after.progress, before.progress);
    expect(after.score, 0);
    expect(after.tags, before.tags);
    expect(after.notes, before.notes);
    expect(after.startDate, before.startDate);
    expect(after.createdAt, before.createdAt);
    expect((await repo.history(record.uuid)).single.uuid, history.single.uuid);
    expect(
      (await repo.previewMetadataCompletion(
        record.uuid,
        sourceMetadata,
      )).result.changes,
      isEmpty,
    );
  });
  test('conflicting source total does not alter completed progress or guess a different status', () async {
    final record = await create(
      progress: 8,
      status: AnimeStatus.completed,
      end: '2026-10-02',
    );
    final preview = await repo.previewMetadataCompletion(
      record.uuid,
      sourceMetadata,
    );
    expect(preview.result.warnings, hasLength(1));
    expect(preview.result.changes, isNot(contains('totalEpisodes')));
    await repo.applyMetadataCompletion(preview);
    final after = (await repo.find(record.uuid))!;
    expect(after.metadata.totalEpisodes, isNull);
    expect(after.progress, 8);
    expect(after.status, AnimeStatus.completed);
    expect(after.endDate, '2026-10-02');
  });
  test('source total lower than retained history is skipped even when current progress is low', () async {
    final record = await create();
    await repo.addHistory(record.uuid, 20, '2026-10-01');
    await repo.edit(
      record.uuid,
      editValues((await repo.find(record.uuid))!, 2),
    );
    final preview = await repo.previewMetadataCompletion(
      record.uuid,
      sourceMetadata,
    );
    expect(preview.result.metadata.totalEpisodes, isNull);
    expect(preview.result.warnings, isNotEmpty);
    await repo.applyMetadataCompletion(preview);
    expect((await repo.history(record.uuid)).single.episode, 20);
  });
  test(
    'completion refuses source identity, known season and known form conflicts',
    () async {
      for (final m in [
        const AnimeMetadata(
          title: '记录',
          sourceProvider: 'bangumi',
          sourceId: '999',
        ),
        const AnimeMetadata(title: '记录', season: 1),
        const AnimeMetadata(title: '记录', entryType: AnimeEntryType.movie),
      ]) {
        final record = await create(
          draftId: '${m.sourceId}${m.season}${m.entryType}',
          metadata: m,
        );
        await expectLater(
          repo.previewMetadataCompletion(record.uuid, sourceMetadata),
          throwsA(isA<QuickRecordValidationException>()),
        );
      }
    },
  );
  test('completion stale preview refuses concurrent manual data without overwriting it', () async {
    final record = await create();
    final preview = await repo.previewMetadataCompletion(
      record.uuid,
      sourceMetadata,
    );
    await repo.edit(
      record.uuid,
      editValues(
        record,
        0,
        metadata: const AnimeMetadata(title: '用户标题', summary: '新写的简介'),
      ),
    );
    await expectLater(
      repo.applyMetadataCompletion(preview),
      throwsA(isA<QuickRecordValidationException>()),
    );
    final after = (await repo.find(record.uuid))!;
    expect(after.metadata.summary, '新写的简介');
    expect(after.metadata.sourceId, isNull);
    final refreshed = await repo.previewMetadataCompletion(
      record.uuid,
      sourceMetadata,
    );
    expect(refreshed.result.changes, isNot(contains('summary')));
    await repo.applyMetadataCompletion(refreshed);
    expect((await repo.find(record.uuid))!.metadata.summary, '新写的简介');
  });
  test('completion SQL failure rolls back every field and preserves unrelated records', () async {
    final record = await create();
    final other = await create(draftId: 'other');
    final preview = await repo.previewMetadataCompletion(
      record.uuid,
      sourceMetadata,
    );
    await db.customStatement(
      "CREATE TRIGGER fail_fill BEFORE UPDATE ON anime BEGIN SELECT RAISE(ABORT, 'fixture failure'); END",
    );
    await expectLater(repo.applyMetadataCompletion(preview), throwsA(anything));
    expect((await repo.find(record.uuid))!.metadata.sourceId, isNull);
    expect((await repo.find(other.uuid))!.metadata.sourceId, isNull);
  });
  test('known Bangumi identity fetches details directly, title-only records require a candidate and confirmation', () async {
    final known = await create(
      metadata: const AnimeMetadata(
        title: '自己的标题',
        sourceProvider: 'bangumi',
        sourceId: '253',
      ),
    );
    final source = FixtureSource();
    final service = MetadataCompletionService(repo, source);
    final knownLookup = await service.lookup(known.uuid, RequestScope());
    expect(source.searches, isEmpty);
    expect(source.detailCalls, 1);
    expect(knownLookup.preview, isNotNull);
    expect((await repo.find(known.uuid))!.metadata.originalTitle, isNull);
    final unknown = await create(draftId: 'unknown');
    final controller = MetadataCompletionController(unknown.uuid, service);
    await controller.load();
    expect(controller.preview, isNull);
    expect(controller.lookup!.candidates.single.id, 253);
    await controller.choose(999);
    expect(source.detailCalls, 1);
    await controller.choose(253);
    expect(controller.preview, isNotNull);
    expect((await repo.find(unknown.uuid))!.metadata.sourceId, isNull);
    await controller.apply();
    expect((await repo.find(unknown.uuid))!.metadata.sourceId, '253');
    controller.dispose();
  });
  test('cancelled completion cannot accept a late source result or mutate the record', () async {
    final record = await create(
      metadata: const AnimeMetadata(
        title: '记录',
        sourceProvider: 'bangumi',
        sourceId: '253',
      ),
    );
    final delayed = DelayedSource();
    final controller = MetadataCompletionController(
      record.uuid,
      MetadataCompletionService(repo, delayed),
    );
    final loading = controller.load();
    await delayed.started.future;
    controller.cancel();
    delayed.response.complete(sourceMetadata);
    await loading;
    expect(controller.preview, isNull);
    expect(controller.busy, false);
    expect((await repo.find(record.uuid))!.metadata.summary, isNull);
    controller.dispose();
  });
}

class DelayedSource extends FixtureSource {
  final started = Completer<void>();
  final response = Completer<AnimeMetadata>();
  @override
  Future<AnimeMetadata> details(int id, RequestScope scope) async {
    started.complete();
    return response.future;
  }
}
