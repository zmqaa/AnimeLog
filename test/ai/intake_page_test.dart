import 'package:animelog/application/ai_intake.dart';
import 'package:animelog/application/ai_settings.dart';
import 'package:animelog/application/manual_library.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ai_fixtures.dart';

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  testWidgets(
    'narrow large-text intake retains input on back and manual fallback saves only on confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SqliteLibraryRepository(db);
      final drafts = MemoryDrafts();
      final intake = AiIntake(
        AiSettings(MemoryConfigurations(null), MemoryKeys(), FixtureAi([])),
        FixtureSource(),
      );
      await tester.pumpWidget(
        AnimeLogApp(
          useCases: ManualLibrary(repo, repo),
          drafts: drafts,
          aiIntake: intake,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-anime')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('intake-query')), '离线中文作品');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('recognize-title')));
      await tester.tap(find.byKey(const Key('recognize-title')));
      await tester.pumpAndSettle();
      expect(find.text('请先配置接口地址和模型'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(drafts.value?['fields']['title'], '离线中文作品');
      await tester.tap(find.byKey(const Key('add-anime')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续填写'));
      await tester.pumpAndSettle();
      expect(find.text('离线中文作品'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('manual-intake')));
      await tester.tap(find.byKey(const Key('manual-intake')));
      await tester.pumpAndSettle();
      expect(await repo.all(), isEmpty);
      await tester.tap(find.byKey(const Key('save-record')));
      await tester.pumpAndSettle();
      final records = await repo.all();
      expect(records.single.metadata.title, '离线中文作品');
      expect(records.single.progress, 0);
      expect(await repo.history(records.single.uuid), isEmpty);
      expect(drafts.value, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    },
  );
}
