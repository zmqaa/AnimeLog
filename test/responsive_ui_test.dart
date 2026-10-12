import 'dart:io';
import 'dart:ui' as ui;

import 'package:animelog/application/manual_library.dart';
import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ai/ai_fixtures.dart' show MemoryDrafts;

const previewKey = Key('ui-preview');

Future<void> viewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  await tester.binding.setSurfaceSize(size);
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('UI_PREVIEW')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(previewKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = await Directory('build/ui_preview')
        .create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  setUpAll(() async {
    if (!const bool.fromEnvironment('UI_PREVIEW')) return;
    // Optional Windows preview uses installed fonts rather than test Ahem.
    for (final entry in {
      'Microsoft YaHei': 'C:/Windows/Fonts/msyh.ttc',
      'MaterialIcons': 'D:/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    }.entries) {
      final bytes = await File(entry.value).readAsBytes();
      await (FontLoader(
        entry.key,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });

  testWidgets(
    'library adapts, filters and opens records at desktop and phone sizes',
    (tester) async {
      await viewport(tester, const Size(1280, 800));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SqliteLibraryRepository(db);
      final library = ManualLibrary(repo, repo);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await db.close();
      });
      const titles = ['星海漫游', '夏日回声', '风起之时', '星海漫游 第二季', '远山来信', '雨后的庭院'];
      final uuids = List<String>.filled(titles.length, '');
      for (var i = titles.length - 1; i >= 0; i--) {
        final result = await library.create(
          AnimeCreationDraft(
            draftId: 'ui-fixture-$i',
            metadata: AnimeMetadata(
              title: titles[i],
              entryType: AnimeEntryType.tv,
              totalEpisodes: i == 4 ? null : 12,
            ),
            status: [
              AnimeStatus.watching,
              AnimeStatus.completed,
              AnimeStatus.planToWatch,
            ][i % 3],
            progress: i % 3 == 1
                ? 12
                : i % 3 == 2
                ? 0
                : i,
            score: i == 0
                ? 0
                : i == 1
                ? 9
                : null,
            notes: i == 0 ? '慢慢看，也慢慢记录。' : null,
            tags: const ['日常', '冒险'],
          ),
        );
        uuids[i] = result.entry.uuid;
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: previewKey,
          child: AnimeLogApp(useCases: library, drafts: MemoryDrafts()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('page-navigation-menu')), findsNothing);
      expect(find.byKey(Key('anime-${uuids.first}')), findsOneWidget);
      expect(find.text('评分 0.0'), findsOneWidget);
      await capture(tester, 'library-desktop');
      await tester.enterText(find.byKey(const Key('library-search')), '星海');
      await tester.pumpAndSettle();
      expect(find.text('找到 2 部作品'), findsOneWidget);
      expect(find.text('夏日回声'), findsNothing);
      await tester.enterText(find.byKey(const Key('library-search')), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('看完 2'));
      await tester.pumpAndSettle();
      expect(find.text('夏日回声'), findsOneWidget);
      expect(find.text('星海漫游'), findsNothing);
      await tester.tap(find.text('全部 6'));
      await tester.pumpAndSettle();
      await viewport(tester, const Size(390, 844));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('page-navigation-menu')), findsOneWidget);
      await capture(tester, 'library-phone');
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      await viewport(tester, const Size(390, 600));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(Key('anime-${uuids.first}')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      // Desktop navigation also remains usable in a short, large-text window.
      await viewport(tester, const Size(844, 390));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await viewport(tester, const Size(1280, 800));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('anime-${uuids.first}')));
      await tester.pumpAndSettle();
      await capture(tester, 'detail-desktop');
      await tester.tap(find.byKey(const Key('detail-increment')));
      await tester.pumpAndSettle();
      expect((await repo.find(uuids.first))!.progress, 1);
      expect(await repo.history(uuids.first), hasLength(1));
      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect((await repo.find(uuids.first))!.progress, 0);
      expect(await repo.history(uuids.first), isEmpty);
      await viewport(tester, const Size(390, 600));
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('grouped editor keeps save visible above phone keyboard', (
    tester,
  ) async {
    await viewport(tester, const Size(1280, 800));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    final repo = SqliteLibraryRepository(db);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: AnimeLogApp(
          useCases: ManualLibrary(repo, repo),
          drafts: MemoryDrafts(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-anime')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-title')), '新的观看记录');
    await tester.pumpAndSettle();
    await capture(tester, 'editor-desktop');
    await viewport(tester, const Size(390, 844));
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('save-record'));
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(544));
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect((await repo.all()).single.metadata.title, '新的观看记录');
    expect(await repo.history((await repo.all()).single.uuid), isEmpty);
  });
}
