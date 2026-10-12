import 'dart:io';

import 'package:animelog/core/backup/backup_document.dart';
import 'package:animelog/core/backup/backup_codec.dart';
import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_backup_repository.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated/schema.dart';
import '../generated/schema_v1.dart' as v1;
import 'backup_test_helpers.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  late SqliteLibraryRepository library;
  late SqliteBackupRepository backup;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('animelog-backup-');
    db = AppDatabase.file(File('${dir.path}/db.sqlite'));
    library = SqliteLibraryRepository(db);
    backup = SqliteBackupRepository(
      db,
      onImported: library.invalidateUndoReceipts,
    );
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  Future<void> apply(BackupDocument d, ImportMode m) async =>
      backup.importAtomically(d, await backup.preview(d, m));

  test('JSON restore/export preserves relationships with changed integer IDs and no intake/history inference', () async {
    final sample = sampleBackup();
    await apply(sample, ImportMode.replace);
    expect(
      (await backup.snapshot()).toJson()..remove('exportedAt'),
      sample.toJson()..remove('exportedAt'),
    );
    final firstId = (await library.find(animeUuid))!.id;
    await apply(sample, ImportMode.replace);
    expect((await library.find(animeUuid))!.id, isNot(firstId));
    expect(await library.history(animeUuid), hasLength(1));
    expect(await db.select(db.intakeCommits).get(), isEmpty);
    expect(
      (await db.select(db.animeNotes).get()).every(
        (n) => n.animeUuid == animeUuid,
      ),
      true,
    );
  });

  test('append twice skips whole existing group, keeps local edited progress/notes and allows same title UUIDs', () async {
    await apply(sampleBackup(), ImportMode.append);
    await library.edit(
      animeUuid,
      const AnimeCreationDraft(
        draftId: 'edit',
        metadata: AnimeMetadata(title: '中文动画'),
        progress: 9,
        notes: '本机备注',
      ),
    );
    final preview = await backup.preview(sampleBackup(), ImportMode.append);
    expect(preview.newAnime, 0);
    expect(preview.skippedAnime, 1);
    await backup.importAtomically(sampleBackup(), preview);
    expect((await library.find(animeUuid))!.progress, 9);
    expect((await library.find(animeUuid))!.notes, '本机备注');
    expect(await library.history(animeUuid), hasLength(1));
    final root = newBackup();
    root['anime'][0]['uuid'] = otherUuid;
    root['watchHistory'] = [];
    root['notes'] = [];
    root['anime'][0]['notes'] = null;
    await apply(decodeBackup(encodeJson(root)), ImportMode.append);
    expect(await library.all(), hasLength(2));
  });

  test('failed replacement rolls back deletion, anime, history and overall notes together', () async {
    final old = (await library.createAtomically(
      const AnimeCreationDraft(
        draftId: 'old',
        metadata: AnimeMetadata(title: '原记录'),
        notes: '保留',
      ),
    )).entry;
    await db.customStatement(
      "CREATE TRIGGER reject_backup_history BEFORE INSERT ON watch_history BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
    );
    await expectLater(
      apply(sampleBackup(), ImportMode.replace),
      throwsA(anything),
    );
    expect((await library.all()).single.uuid, old.uuid);
    expect((await db.select(db.animeNotes).get()).single.content, '保留');
    expect((await db.select(db.intakeCommits).get()).single.draftId, 'old');
  });

  test('stale confirmed preview cannot replace a later manual write', () async {
    final preview = await backup.preview(sampleBackup(), ImportMode.replace);
    await library.createAtomically(
      const AnimeCreationDraft(
        draftId: 'later',
        metadata: AnimeMetadata(title: '后来添加'),
      ),
    );
    await expectLater(
      backup.importAtomically(sampleBackup(), preview),
      throwsA(isA<BackupValidationException>()),
    );
    expect((await library.all()).single.metadata.title, '后来添加');
  });

  test('restore does not export settings, local cover paths or commits and clears old receipt', () async {
    final old = (await library.createAtomically(
      const AnimeCreationDraft(
        draftId: 'old',
        metadata: AnimeMetadata(title: '原记录'),
      ),
    )).entry;
    final receipt = await library.increment(old.uuid, '2026-10-10');
    await db
        .into(db.appSettings)
        .insert(
          const AppSettingsCompanion(
            settingKey: Value('model'),
            value: Value('private-config'),
          ),
        );
    await (db.update(db.anime)..where((a) => a.uuid.equals(old.uuid))).write(
      const AnimeCompanion(localCoverPath: Value('C:/private/cover.png')),
    );
    final snap = await backup.snapshot();
    expect(snap.toJson().toString(), isNot(contains('private-config')));
    expect(snap.toJson().toString(), isNot(contains('C:/private')));
    await apply(snap, ImportMode.replace);
    await expectLater(
      library.undoIncrement(receipt),
      throwsA(isA<QuickRecordValidationException>()),
    );
    expect(
      (await db.select(db.appSettings).get()).single.value,
      'private-config',
    );
  });

  test('v5 old integer ID collision cannot attach history to a local anime; exact file retry is idempotent', () async {
    final local = (await library.createAtomically(
      const AnimeCreationDraft(
        draftId: 'local',
        metadata: AnimeMetadata(title: '本机独立'),
      ),
    )).entry;
    expect(local.id, 1);
    final d = decodeBackup(
      File('test/fixtures/animetrack_v5.json').readAsBytesSync(),
    );
    await apply(d, ImportMode.append);
    await apply(d, ImportMode.append);
    expect(await library.all(), hasLength(3));
    expect(await library.history(local.uuid), isEmpty);
    expect(await library.history(d.anime.first.uuid), hasLength(2));
    expect((await db.select(db.animeNotes).get()), hasLength(3));
    expect((await library.find(d.anime.first.uuid))!.rewatchCount, 3);
    expect((await library.find(d.anime.first.uuid))!.startDateSource, isNull);
    await library.correctHistory(d.history.first.uuid, 1, '2026-08-01');
    expect((await library.find(d.anime.first.uuid))!.startDate, '2026-09-01');
  });

  test('v1 -> v2 changes only date-source constraint and preserves all relations/settings/indexes', () async {
    await db.close();
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    final old = v1.DatabaseAtV1(schema.newConnection());
    await old.customStatement(
      "INSERT INTO anime(id,uuid,title,status,progress,notes,start_date,start_date_source,created_at,updated_at) VALUES (41,?,'旧记录','watching',1,'原备注','2026-10-01','manual',?,?)",
      [animeUuid, time, time],
    );
    await old.customStatement(
      "INSERT INTO watch_history(uuid,anime_uuid,episode,watched_on,created_at) VALUES (?,?,1,'2026-10-01',?)",
      [historyUuid, animeUuid, time],
    );
    await old.customStatement(
      "INSERT INTO anime_notes(uuid,anime_uuid,content,noted_on,created_at,updated_at) VALUES (?,?,'原备注','2026-10-01',?,?)",
      [noteUuid, animeUuid, time, time],
    );
    await old.customStatement(
      "INSERT INTO intake_commits(draft_id,anime_uuid) VALUES ('old-draft',?)",
      [animeUuid],
    );
    await old.customStatement(
      "INSERT INTO app_settings(setting_key,value) VALUES ('model','kept')",
    );
    await old.close();
    db = AppDatabase(schema.newConnection());
    final migrated = db;
    await verifier.migrateAndValidate(migrated, 2);
    expect((await migrated.select(migrated.anime).get()).single.id, 41);
    expect(
      (await migrated.select(migrated.watchHistory).get()).single.animeUuid,
      animeUuid,
    );
    expect(
      (await migrated.select(migrated.animeNotes).get()).single.content,
      '原备注',
    );
    expect(
      (await migrated.select(migrated.intakeCommits).get()).single.draftId,
      'old-draft',
    );
    expect(
      (await migrated.select(migrated.appSettings).get()).single.value,
      'kept',
    );
    await (migrated.update(migrated.anime)
          ..where((a) => a.uuid.equals(animeUuid)))
        .write(const AnimeCompanion(startDateSource: Value(null)));
    expect(
      await migrated.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );
    await migrated.close();
    schema.rawDatabase.close();
  });
}
