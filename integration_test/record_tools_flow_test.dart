import 'dart:convert';
import 'dart:io';

import 'package:animelog/application/manual_library.dart';
import 'package:animelog/application/metadata_completion.dart';
import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/data/platform/local_files.dart';
import 'package:animelog/data/remote/bangumi_source.dart';
import 'package:animelog/data/remote/json_http.dart';
import 'package:animelog/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/ai/ai_fixtures.dart' show subject;

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    220,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native note CRUD, confirmed history cleanup and source-only metadata completion preserve personal data',
    (tester) async {
      final support = await applicationDirectory();
      final directory = await support.createTemp('record-tools-integration-');
      final db = AppDatabase.file(File('${directory.path}/db.sqlite'));
      final repo = SqliteLibraryRepository(db);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var sourceCalls = 0;
      var validRequests = true;
      server.listen((request) async {
        sourceCalls++;
        validRequests =
            validRequests &&
            request.method == 'GET' &&
            request.uri.path == '/v0/subjects/253' &&
            request.headers.value('authorization') == null;
        await request.drain<void>();
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(subject));
        await request.response.close();
      });
      try {
        final record = (await repo.createAtomically(
          const AnimeCreationDraft(
            draftId: 'target',
            metadata: AnimeMetadata(
              title: '原有记录',
              summary: '用户简介保留',
              totalEpisodes: 4,
              sourceProvider: 'bangumi',
              sourceId: '253',
            ),
            progress: 4,
            notes: '总体备注保留',
            score: 0,
            rewatchCount: 2,
            tags: ['二刷'],
          ),
        )).entry;
        await repo.addHistory(record.uuid, 1, '2026-10-01');
        await repo.addHistory(record.uuid, 3, '2026-09-01');
        await repo.addHistory(record.uuid, 4, '2026-10-02');
        final existingNote = await repo.saveEpisodeNote(
          record.uuid,
          episode: 4,
          content: '既有分集备注',
          notedOn: '2026-10-02',
        );
        final source = BangumiSourceProvider(
          JsonHttp(),
          baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        );
        await tester.pumpWidget(
          AnimeLogApp(
            useCases: ManualLibrary(repo, repo),
            drafts: FileIntakeDraftStore(File('${directory.path}/draft.json')),
            metadataCompletion: MetadataCompletionService(repo, source),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('原有记录'));
        await tester.pumpAndSettle();

        await reveal(tester, find.byKey(const Key('add-episode-note')));
        await tester.tap(find.byKey(const Key('add-episode-note')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('note-episode')), '2');
        await tester.enterText(
          find.byKey(const Key('note-date')),
          '2026-10-10',
        );
        await tester.enterText(find.byKey(const Key('note-content')), '中文新增备注');
        await tester.tap(find.byKey(const Key('save-episode-note')));
        await tester.pumpAndSettle();
        debugPrint('Record tools: note saved');
        final newNote = (await repo.episodeNotes(record.uuid))
            .singleWhere((n) => n.uuid != existingNote);
        expect((await repo.find(record.uuid))!.progress, 4);
        expect(await repo.history(record.uuid), hasLength(3));
        await reveal(tester, find.byKey(Key('note-actions-${newNote.uuid}')));
        await tester.tap(find.byKey(Key('note-actions-${newNote.uuid}')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('编辑备注'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('note-content')), '编辑后备注');
        await tester.tap(find.byKey(const Key('save-episode-note')));
        await tester.pumpAndSettle();
        expect(
          (await repo.episodeNotes(record.uuid))
              .singleWhere((n) => n.uuid == newNote.uuid)
              .content,
          '编辑后备注',
        );
        await tester.tap(find.byKey(Key('note-actions-${newNote.uuid}')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('删除备注'));
        await tester.pumpAndSettle();
        expect(await repo.episodeNotes(record.uuid), hasLength(2));
        await tester.tap(find.byKey(const Key('confirm-delete-note')));
        await tester.pumpAndSettle();
        debugPrint('Record tools: note CRUD complete');
        expect(
          (await repo.episodeNotes(record.uuid)).single.uuid,
          existingNote,
        );

        await tester.tap(find.byKey(const Key('edit-record')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('field-progress')));
        await tester.enterText(find.byKey(const Key('field-progress')), '2');
        await tester.pump();
        await reveal(tester, find.byKey(const Key('trim-higher-history')));
        expect(
          tester
              .widget<CheckboxListTile>(
                find.byKey(const Key('trim-higher-history')),
              )
              .value,
          false,
        );
        await tester.tap(find.byKey(const Key('trim-higher-history')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('save-record')));
        await tester.pumpAndSettle();
        expect(find.textContaining('2 条观看历史'), findsOneWidget);
        expect((await repo.find(record.uuid))!.progress, 4);
        await tester.tap(find.text('返回编辑'));
        await tester.pumpAndSettle();
        expect(await repo.history(record.uuid), hasLength(3));
        await tester.tap(find.byKey(const Key('save-record')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm-trim-history')));
        await tester.pumpAndSettle();
        debugPrint('Record tools: history cleanup complete');
        expect((await repo.history(record.uuid)).single.episode, 1);
        expect((await repo.find(record.uuid))!.progress, 2);
        expect(
          (await repo.episodeNotes(record.uuid)).single.uuid,
          existingNote,
        );

        await tester.drag(find.byType(ListView).first, const Offset(0, 1800));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('complete-metadata')));
        await tester.tap(find.byKey(const Key('complete-metadata')));
        await tester.pumpAndSettle();
        expect(sourceCalls, 1);
        expect((await repo.find(record.uuid))!.metadata.originalTitle, isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect((await repo.find(record.uuid))!.metadata.originalTitle, isNull);
        await tester.tap(find.byKey(const Key('complete-metadata')));
        await tester.pumpAndSettle();
        await reveal(
          tester,
          find.byKey(const Key('confirm-metadata-completion')),
        );
        await tester.tap(find.byKey(const Key('confirm-metadata-completion')));
        await tester.pumpAndSettle();
        debugPrint('Record tools: metadata completion complete');
        final after = (await repo.find(record.uuid))!;
        expect(after.metadata.originalTitle, 'カウボーイビバップ');
        expect(after.metadata.entryType, AnimeEntryType.tv);
        expect(after.metadata.title, '原有记录');
        expect(after.metadata.totalEpisodes, 4);
        expect(after.metadata.summary, '用户简介保留');
        expect(after.progress, 2);
        expect(after.status, AnimeStatus.watching);
        expect(after.score, 0);
        expect(after.notes, '总体备注保留');
        expect(after.tags, ['二刷']);
        expect(
          (await repo.episodeNotes(record.uuid)).single.uuid,
          existingNote,
        );
        expect((await repo.history(record.uuid)).single.episode, 1);
        expect(sourceCalls, 2);
        expect(validRequests, true);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await server.close(force: true);
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
