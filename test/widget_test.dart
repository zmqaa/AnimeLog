import 'dart:io';

import 'package:animelog/application/manual_library.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/data/platform/local_files.dart';
import 'package:animelog/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settleIo(WidgetTester tester) async {
  // Native SQLite and private-file writes run outside the test's fake clock.
  for (var index = 0; index < 20; index++) {
    await tester.pump(const Duration(milliseconds: 30));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String name, String value) async {
  final field = find.byKey(Key('field-$name'));
  if (field.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      field,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

void main() {
  // Real time permits actual file IO. Pump frames explicitly so pointer-fade
  // debug frames cannot race the narrow-window rotation during this test.
  LiveTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  testWidgets('manual create/detail/edit survives real SQLite close/reopen', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('animelog-ui-'),
    ))!;
    final file = File('${directory.path}/app.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var repo = SqliteLibraryRepository(db);
    final drafts = FileIntakeDraftStore(File('${directory.path}/draft.json'));
    await repo.all();
    await tester.pumpWidget(
      AnimeLogApp(useCases: ManualLibrary(repo, repo), drafts: drafts),
    );
    await settleIo(tester);
    await tester.tap(find.byKey(const Key('add-anime')));
    await settleIo(tester);
    await enter(tester, 'title', '离线记录 第二季');
    await enter(tester, 'score', '0');
    await enter(tester, 'notes', '中文备注');
    await tester.tap(find.byKey(const Key('save-record')));
    await settleIo(tester);
    expect(find.text('离线记录 第二季'), findsOneWidget);
    await tester.tap(find.byTooltip('进度加一'));
    await settleIo(tester);
    expect((await repo.all()).single.progress, 1);
    await tester.tap(find.text('撤销'));
    await settleIo(tester);
    expect((await repo.all()).single.progress, 0);
    await tester.tap(find.text('离线记录 第二季'));
    await settleIo(tester);
    expect(find.text('中文备注'), findsOneWidget);
    expect(find.text('评分 0.0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-record')));
    await settleIo(tester);
    await enter(tester, 'title', '编辑后的中文标题');
    await enter(tester, 'score', '');
    await enter(tester, 'notes', '');
    await tester.tap(find.byKey(const Key('save-record')));
    await settleIo(tester);
    expect(find.text('编辑后的中文标题'), findsOneWidget);
    expect(find.text('中文备注'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    repo = SqliteLibraryRepository(db);
    await repo.all();
    await tester.pumpWidget(
      AnimeLogApp(useCases: ManualLibrary(repo, repo), drafts: drafts),
    );
    await settleIo(tester);
    expect(find.text('编辑后的中文标题'), findsOneWidget);
    final records = await repo.all();
    expect(records, hasLength(1));
    expect(records.single.score, isNull);
    expect(await repo.history(records.single.uuid), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
    await tester.runAsync(() async {
      await directory.delete(recursive: true);
    });
  });

  testWidgets('narrow phone and large text retain saved draft on back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('animelog-draft-ui-'),
    ))!;
    final db = AppDatabase(
      NativeDatabase(File('${directory.path}/app.sqlite')),
    );
    final repo = SqliteLibraryRepository(db);
    final drafts = FileIntakeDraftStore(File('${directory.path}/draft.json'));
    await repo.all();
    await tester.pumpWidget(
      AnimeLogApp(useCases: ManualLibrary(repo, repo), drafts: drafts),
    );
    await settleIo(tester);
    expect(find.byKey(const Key('page-navigation-menu')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-anime')));
    await settleIo(tester);
    await enter(tester, 'title', '保留草稿');
    tester.view.physicalSize = const Size(844, 390);
    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pumpAndSettle();
    expect(find.text('保留草稿'), findsOneWidget);
    await tester.pageBack();
    await settleIo(tester);
    await tester.tap(find.byKey(const Key('add-anime')));
    await settleIo(tester);
    expect(find.text('发现未提交草稿'), findsOneWidget);
    await tester.tap(find.text('继续填写'));
    await settleIo(tester);
    expect(find.text('保留草稿'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
    await tester.runAsync(() async {
      await directory.delete(recursive: true);
    });
  });
}
