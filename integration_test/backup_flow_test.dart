import 'dart:io';

import 'package:animelog/application/backup_service.dart';
import 'package:animelog/application/manual_library.dart';
import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/core/api/backup_repository.dart';
import 'package:animelog/core/backup/backup_codec.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_backup_repository.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/data/platform/local_files.dart';
import 'package:animelog/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/backup/backup_service_test.dart' show DialogFixtureFiles;
import '../test/backup/backup_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'backup preview/confirm/repeat append/export and full restore in native app',
    (tester) async {
      final support = await applicationDirectory();
      final directory = await support.createTemp('backup-integration-');
      final db = AppDatabase.file(File('${directory.path}/database.sqlite'));
      final library = SqliteLibraryRepository(db);
      final repo = SqliteBackupRepository(
        db,
        onImported: library.invalidateUndoReceipts,
      );
      final files = DialogFixtureFiles(directory);
      final drafts = FileIntakeDraftStore(File('${directory.path}/draft.json'));
      final service = BackupService(repo, files, drafts);
      await library.createAtomically(
        const AnimeCreationDraft(
          draftId: 'old',
          metadata: AnimeMetadata(title: '本机原记录'),
        ),
      );
      final fixture = File('${directory.path}/input.json');
      await fixture.writeAsBytes(sampleBackup().encode(), flush: true);
      files.selection = SelectedBackup(
        'input.json',
        await fixture.readAsBytes(),
      );
      await tester.pumpWidget(
        AnimeLogApp(
          useCases: ManualLibrary(library, library),
          drafts: drafts,
          backups: service,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('本机').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-backups')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('append-backup')));
      await tester.pumpAndSettle();
      expect(find.text('导入预览'), findsOneWidget);
      expect(await library.all(), hasLength(1));
      await tester.ensureVisible(find.byKey(const Key('confirm-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-backup')));
      await tester.pumpAndSettle();
      expect(find.text('确认追加导入？'), findsOneWidget);
      await tester.tap(find.text('确认追加'));
      await tester.pumpAndSettle();
      expect(await library.all(), hasLength(2));
      await tester.ensureVisible(find.byKey(const Key('append-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('append-backup')));
      await tester.pumpAndSettle();
      expect(find.text('将跳过：1 条已有动漫及其整组数据'), findsOneWidget);
      await tester.ensureVisible(find.text('取消导入'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消导入'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('export-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('export-backup')));
      await tester.pumpAndSettle();
      expect(find.text('全部数据已导出'), findsOneWidget);
      final exported = directory.listSync().whereType<File>().firstWhere(
        (f) => f.uri.pathSegments.last.startsWith('AnimeLog-'),
      );
      expect(decodeBackup(await exported.readAsBytes()).anime, hasLength(2));
      await tester.ensureVisible(find.byKey(const Key('restore-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-backup')));
      await tester.pumpAndSettle();
      expect(find.text('将替换本机：2 条动漫，1 条历史，2 条备注'), findsOneWidget);
      expect(await files.safetySnapshots(), hasLength(1));
      await tester.ensureVisible(find.byKey(const Key('confirm-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认替换并恢复'));
      await tester.pumpAndSettle();
      expect((await library.all()).single.uuid, animeUuid);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('动漫库').last);
      await tester.pumpAndSettle();
      expect(find.text('中文动画'), findsOneWidget);
      expect(find.text('本机原记录'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
      expect(directory.absolute.parent.path, support.absolute.path);
      await directory.delete(recursive: true);
    },
  );
}
