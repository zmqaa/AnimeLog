import 'dart:io';

import 'package:animelog/application/manual_library.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/data/platform/local_files.dart';
import 'package:animelog/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native private directory and manual flow with database reopen', (
    tester,
  ) async {
    final support = await applicationDirectory();
    final directory = await support.createTemp('integration-');
    final file = File('${directory.path}/test.sqlite');
    var db = AppDatabase.file(file);
    var repository = SqliteLibraryRepository(db);
    final drafts = FileIntakeDraftStore(File('${directory.path}/draft.json'));
    await repository.all();
    await tester.pumpWidget(
      AnimeLogApp(
        useCases: ManualLibrary(repository, repository),
        drafts: drafts,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-anime')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('field-title')),
      'Windows 离线验收记录',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('field-score')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('field-score')), '0');
    await tester.ensureVisible(find.byKey(const Key('field-notes')));
    await tester.enterText(find.byKey(const Key('field-notes')), '原生中文备注');
    await tester.tap(find.byKey(const Key('save-record')));
    await tester.pumpAndSettle();
    expect(find.text('Windows 离线验收记录'), findsOneWidget);
    expect((await repository.all()).single.score, 0);
    expect((await repository.all()).single.notes, '原生中文备注');
    await tester.tap(find.text('Windows 离线验收记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-record')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-title')), '原生运行编辑后保留');
    await tester.tap(find.byKey(const Key('save-record')));
    await tester.pumpAndSettle();
    expect(find.text('原生运行编辑后保留'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
    db = AppDatabase.file(file);
    repository = SqliteLibraryRepository(db);
    await repository.all();
    await tester.pumpWidget(
      AnimeLogApp(
        useCases: ManualLibrary(repository, repository),
        drafts: drafts,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('原生运行编辑后保留'), findsOneWidget);
    expect(await repository.all(), hasLength(1));
    expect(
      await repository.history((await repository.all()).single.uuid),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
    // A fixture created under the application directory; never touch its real DB.
    expect(directory.absolute.parent.path, support.absolute.path);
    await directory.delete(recursive: true);
  });
}
