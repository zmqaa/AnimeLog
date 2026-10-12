import 'dart:io';

import 'package:animelog/application/backup_service.dart';
import 'package:animelog/core/api/backup_repository.dart';
import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/core/backup/backup_codec.dart';
import 'package:animelog/core/backup/backup_document.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_backup_repository.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/data/platform/backup_files.dart';
import 'package:animelog/data/platform/local_files.dart';
import 'package:animelog/features/settings/backup_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_test_helpers.dart';

/// Only the OS dialog selection is substituted; bytes, snapshots and SQLite
/// remain real. Native picker interaction is a separate platform acceptance.
class DialogFixtureFiles extends PlatformBackupFiles {
  SelectedBackup? selection;
  bool cancelSave = false;
  bool rejectSnapshot = false;
  bool rejectExport = false;
  DialogFixtureFiles(super.directory);
  @override
  Future<SelectedBackup?> pick() async => selection;
  @override
  Future<String?> save(List<int> bytes, String suggestedName) async {
    if (cancelSave) return null;
    if (rejectExport) throw const FileSystemException('injected write failure');
    final file = File('${privateDirectory.path}/$suggestedName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<String> saveSafetySnapshot(List<int> bytes) async {
    if (rejectSnapshot) {
      throw const FileSystemException('injected snapshot failure');
    }
    return super.saveSafetySnapshot(bytes);
  }
}

void main() {
  late Directory directory;
  late AppDatabase db;
  late SqliteLibraryRepository library;
  late DialogFixtureFiles files;
  late FileIntakeDraftStore drafts;
  late BackupService service;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'animelog-backup-service-',
    );
    db = AppDatabase.file(File('${directory.path}/test.sqlite'));
    library = SqliteLibraryRepository(db);
    files = DialogFixtureFiles(directory);
    drafts = FileIntakeDraftStore(File('${directory.path}/draft.json'));
    service = BackupService(SqliteBackupRepository(db), files, drafts);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });
  Future<void> oldRecord() async => library.createAtomically(
    const AnimeCreationDraft(
      draftId: 'old',
      metadata: AnimeMetadata(title: '本机原记录'),
      score: 0,
      notes: '本机备注',
    ),
  );

  test('full restore saves exact local snapshot before confirmation, then can restore it from private list', () async {
    await oldRecord();
    await drafts.save({
      'draftId': 'pending',
      'fields': {'title': '未提交'},
    });
    final before = await service.repository.snapshot();
    final prepared = await service.prepare(
      SelectedBackup('incoming.json', sampleBackup().encode()),
      ImportMode.replace,
    );
    expect((await library.all()).single.metadata.title, '本机原记录');
    final snapshot = decodeBackup(
      File(prepared.safetySnapshot!).readAsBytesSync(),
    );
    expect(backupStateDigest(snapshot), backupStateDigest(before));
    expect(await drafts.load(), isNotNull);
    await service.commit(prepared);
    expect((await library.all()).single.uuid, animeUuid);
    expect(await drafts.load(), isNull);
    final names = await files.safetySnapshots();
    expect(names, hasLength(1));
    final saved = await files.readSafetySnapshot(names.single);
    final restore = await service.prepare(saved, ImportMode.replace);
    await service.commit(restore);
    expect((await library.all()).single.metadata.title, '本机原记录');
    expect((await library.all()).single.score, 0);
  });

  test('snapshot write failure aborts full restore and leaves drafts and records intact', () async {
    await oldRecord();
    await drafts.save({
      'draftId': 'pending',
      'fields': {'title': '未提交'},
    });
    files.rejectSnapshot = true;
    await expectLater(
      service.prepare(
        SelectedBackup('sample.json', sampleBackup().encode()),
        ImportMode.replace,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect((await library.all()).single.metadata.title, '本机原记录');
    expect(await drafts.load(), isNotNull);
  });

  test('export saves UTF-8 snapshot of all records; dialog cancellation and disk failure never report success', () async {
    await oldRecord();
    expect(await service.exportAll(), true);
    final saved = directory.listSync().whereType<File>().firstWhere(
      (f) => f.path.endsWith('.json'),
    );
    expect(decodeBackup(saved.readAsBytesSync()).anime.single.notes, '本机备注');
    files.cancelSave = true;
    expect(await service.exportAll(), false);
    files.cancelSave = false;
    files.rejectExport = true;
    await expectLater(service.exportAll(), throwsA(isA<FileSystemException>()));
  });

  test('canceling selection/preview or rejecting malformed bytes does not mutate official tables', () async {
    await oldRecord();
    final c = BackupController(service);
    await c.pick(ImportMode.replace);
    expect(c.prepared, isNull);
    expect(c.message, contains('取消'));
    files.selection = SelectedBackup('bad.json', [0xff]);
    await c.pick(ImportMode.replace);
    expect(c.error, contains('UTF-8'));
    expect(c.prepared, isNull);
    files.selection = SelectedBackup('valid.json', sampleBackup().encode());
    await c.pick(ImportMode.append);
    expect(c.prepared, isNotNull);
    c.cancelPreview();
    expect((await library.all()).single.metadata.title, '本机原记录');
    c.dispose();
  });

  test('append retains unsubmitted draft and private snapshot selection refuses traversal', () async {
    await drafts.save({
      'draftId': 'pending',
      'fields': {'title': '保留草稿'},
    });
    final p = await service.prepare(
      SelectedBackup('sample.json', sampleBackup().encode()),
      ImportMode.append,
    );
    expect(p.safetySnapshot, isNull);
    await service.commit(p);
    expect((await drafts.load())!['draftId'], 'pending');
    await expectLater(
      files.readSafetySnapshot('../test.sqlite'),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('controller prevents duplicate writes while busy and exposes success only after completed commit', () async {
    files.selection = SelectedBackup('sample.json', sampleBackup().encode());
    final c = BackupController(service);
    await c.pick(ImportMode.append);
    await Future.wait([c.commit(), c.commit()]);
    expect(await library.all(), hasLength(1));
    expect(c.error, isNull);
    expect(c.message, contains('导入完成'));
    expect(c.prepared, isNull);
    c.dispose();
  });
}
