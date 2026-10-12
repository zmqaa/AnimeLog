import 'dart:io';

import 'package:animelog/application/manual_library.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/data/platform/local_files.dart';
import 'package:animelog/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Run twice in separate native processes. The read pass removes its fixture.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const readPass = bool.fromEnvironment('VERIFY_REOPEN');
  testWidgets(
    readPass
        ? 'read after previous native process exited'
        : 'write for native process restart',
    (tester) async {
      final support = await applicationDirectory();
      final fixture = Directory('${support.path}/native-process-fixture');
      await fixture.create();
      final file = File('${fixture.path}/fixture.sqlite');
      final db = AppDatabase.file(file);
      final repo = SqliteLibraryRepository(db);
      final drafts = FileIntakeDraftStore(File('${fixture.path}/draft.json'));
      await repo.all();
      await tester.pumpWidget(
        AnimeLogApp(useCases: ManualLibrary(repo, repo), drafts: drafts),
      );
      await tester.pumpAndSettle();
      if (!readPass) {
        expect(
          await repo.all(),
          isEmpty,
          reason: 'Inspect a prior interrupted fixture before rerunning the write pass',
        );
        await tester.tap(find.byKey(const Key('add-anime')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('field-title')),
          '跨进程持久化记录',
        );
        await tester.tap(find.byKey(const Key('save-record')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('跨进程持久化记录'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('edit-record')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('field-title')),
          '跨进程编辑后标题',
        );
        await tester.tap(find.byKey(const Key('save-record')));
        await tester.pumpAndSettle();
        expect(find.text('跨进程编辑后标题'), findsOneWidget);
      } else {
        expect(find.text('跨进程编辑后标题'), findsOneWidget);
        expect((await repo.all()).single.metadata.title, '跨进程编辑后标题');
        expect(await repo.history((await repo.all()).single.uuid), isEmpty);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
      if (readPass) {
        expect(fixture.absolute.parent.path, support.absolute.path);
        await fixture.delete(recursive: true);
      }
    },
  );
}
