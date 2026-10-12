import 'package:animelog/application/manual_library.dart';
import 'package:animelog/application/metadata_completion.dart';
import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/core/api/ai_intake.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ai/ai_fixtures.dart';

Future<void> reveal(WidgetTester tester, Key key) async =>
    tester.scrollUntilVisible(
      find.byKey(key),
      180,
      scrollable: find.byType(Scrollable).first,
    );

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  testWidgets(
    'small window and large text can validate and save long episode note without changing progress',
    (tester) async {
      tester.view.physicalSize = const Size(390, 600);
      await tester.binding.setSurfaceSize(const Size(390, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SqliteLibraryRepository(db);
      final record = (await repo.createAtomically(
        const AnimeCreationDraft(
          draftId: 'new',
          metadata: AnimeMetadata(title: '备注测试'),
        ),
      )).entry;
      await tester.pumpWidget(
        AnimeLogApp(
          useCases: ManualLibrary(repo, repo),
          drafts: MemoryDrafts(),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, Key('anime-${record.uuid}'));
      await tester.tap(find.text('备注测试'));
      await tester.pumpAndSettle();
      await reveal(tester, const Key('add-episode-note'));
      await tester.tap(find.byKey(const Key('add-episode-note')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-episode-note')));
      await tester.pumpAndSettle();
      expect(find.text('备注内容不能为空'), findsOneWidget);
      expect(await repo.episodeNotes(record.uuid), isEmpty);
      await tester.enterText(find.byKey(const Key('note-episode')), '7');
      await tester.ensureVisible(find.byKey(const Key('note-content')));
      await tester.enterText(
        find.byKey(const Key('note-content')),
        '很长的中文感想\n' * 25,
      );
      await tester.ensureVisible(find.byKey(const Key('note-date')));
      await tester.enterText(find.byKey(const Key('note-date')), '2026-10-10');
      await tester.tap(find.byKey(const Key('save-episode-note')));
      await tester.pumpAndSettle();
      final note = (await repo.episodeNotes(record.uuid)).single;
      expect(note.episode, 7);
      expect(note.content, ('很长的中文感想\n' * 25).trim());
      expect((await repo.find(record.uuid))!.progress, 0);
      expect(await repo.history(record.uuid), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    },
  );
  testWidgets(
    'source-less record rejects conflicting identity then previews and confirms compatible metadata',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SqliteLibraryRepository(db);
      final record = (await repo.createAtomically(
        const AnimeCreationDraft(
          draftId: 'new',
          metadata: AnimeMetadata(
            title: '用户标题 第二季',
            originalTitle: '用户原名',
            season: 2,
            entryType: AnimeEntryType.tv,
          ),
          score: 0,
          notes: '个人备注',
        ),
      )).entry;
      final source = SelectionSource();
      await tester.pumpWidget(
        AnimeLogApp(
          useCases: ManualLibrary(repo, repo),
          drafts: MemoryDrafts(),
          metadataCompletion: MetadataCompletionService(repo, source),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('用户标题 第二季'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('complete-metadata')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('completion-candidate-1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('季度或作品形式'), findsOneWidget);
      expect((await repo.find(record.uuid))!.metadata.sourceId, isNull);
      await reveal(tester, const Key('completion-candidate-2'));
      await tester.tap(find.byKey(const Key('completion-candidate-2')));
      await tester.pumpAndSettle();
      expect((await repo.find(record.uuid))!.metadata.summary, isNull);
      await reveal(tester, const Key('confirm-metadata-completion'));
      await tester.tap(find.byKey(const Key('confirm-metadata-completion')));
      await tester.pumpAndSettle();
      final current = (await repo.find(record.uuid))!;
      expect(current.metadata.title, '用户标题 第二季');
      expect(current.metadata.originalTitle, '用户原名');
      expect(current.metadata.sourceId, '2');
      expect(current.metadata.summary, '来源简介');
      expect(current.score, 0);
      expect(current.progress, 0);
      expect(current.notes, '个人备注');
      expect(await repo.history(record.uuid), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    },
  );
}

class SelectionSource extends FixtureSource {
  SelectionSource()
    : super(const [
        AnimeTitleCandidate(
          id: 1,
          title: '第一季剧场版',
          season: 1,
          entryType: AnimeEntryType.movie,
        ),
        AnimeTitleCandidate(
          id: 2,
          title: '第二季电视动画',
          season: 2,
          entryType: AnimeEntryType.tv,
        ),
      ]);
  @override
  Future<AnimeMetadata> details(int id, RequestScope scope) async =>
      AnimeMetadata(
        title: '来源作品',
        originalTitle: '原名',
        sourceProvider: 'bangumi',
        sourceId: '$id',
        season: id,
        entryType: id == 1 ? AnimeEntryType.movie : AnimeEntryType.tv,
        totalEpisodes: 12,
        summary: '来源简介',
      );
}
