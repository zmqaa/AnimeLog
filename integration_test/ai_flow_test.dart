import 'dart:convert';
import 'dart:io';

import 'package:animelog/application/ai_intake.dart';
import 'package:animelog/application/ai_settings.dart';
import 'package:animelog/application/manual_library.dart';
import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_ai_configuration.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/data/platform/local_files.dart';
import 'package:animelog/data/platform/secure_api_key.dart';
import 'package:animelog/data/remote/bangumi_source.dart';
import 'package:animelog/data/remote/compatible_ai_client.dart';
import 'package:animelog/data/remote/json_http.dart';
import 'package:animelog/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';

import '../test/ai/ai_fixtures.dart' show subject, titlePayload;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native secure storage and real HTTP candidate confirmation only create a new SQLite record',
    (tester) async {
      final namespace = 'animelog.test.ai.${const Uuid().v4()}';
      final keys = SecureApiKeyStore(namespace: namespace);
      final support = await applicationDirectory();
      final directory = await support.createTemp('ai-integration-');
      final db = AppDatabase.file(File('${directory.path}/database.sqlite'));
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var aiCalls = 0;
      var sourceCalls = 0;
      var credentialSentOnlyToAi = true;
      var protocolValid = true;
      bool? wasConnectionTest;
      String? serverFailure;
      final base = 'http://127.0.0.1:${server.port}';
      server.listen((request) async {
        try {
          final body = await utf8.decoder.bind(request).join();
          request.response.headers.contentType = ContentType.json;
          if (request.uri.path == '/v1/chat/completions') {
            aiCalls++;
            final json = jsonDecode(body);
            protocolValid =
                protocolValid &&
                request.headers.value('authorization') ==
                    'Bearer native-test-secret' &&
                json['model'] == 'fixture-model' &&
                json['stream'] == false;
            final test = json['messages'][1]['content'] == '连接测试';
            wasConnectionTest = test;
            request.response.write(
              jsonEncode({
                'choices': [
                  {
                    'message': {
                      'content': jsonEncode(test ? {'ok': true} : titlePayload),
                    },
                  },
                ],
              }),
            );
          } else {
            sourceCalls++;
            credentialSentOnlyToAi =
                credentialSentOnlyToAi &&
                request.headers.value('authorization') == null;
            request.response.write(
              jsonEncode(
                request.method == 'POST'
                    ? {
                        'data': [subject],
                      }
                    : subject,
              ),
            );
          }
          await request.response.close();
        } catch (failure) {
          serverFailure = failure.runtimeType.toString();
          request.response.statusCode = 500;
          await request.response.close();
        }
      });
      try {
        await keys.write('native-roundtrip-secret');
        expect(
          await SecureApiKeyStore(namespace: namespace).read(),
          'native-roundtrip-secret',
        );
        await keys.write(null);
        expect(await keys.read(), isNull);
        final repo = SqliteLibraryRepository(db);
        final old = await repo.createAtomically(
          const AnimeCreationDraft(
            draftId: 'previous',
            metadata: AnimeMetadata(
              title: '星际牛仔',
              sourceProvider: 'bangumi',
              sourceId: '253',
              totalEpisodes: 26,
            ),
            status: AnimeStatus.completed,
            progress: 26,
            score: 0,
            notes: '此前记录保持原样',
          ),
        );
        final transport = JsonHttp();
        final settings = AiSettings(
          SqliteAiConfigurationStore(db),
          keys,
          CompatibleAiClient(transport),
        );
        final intake = AiIntake(
          settings,
          BangumiSourceProvider(transport, baseUrl: Uri.parse(base)),
        );
        await tester.pumpWidget(
          AnimeLogApp(
            useCases: ManualLibrary(repo, repo),
            drafts: FileIntakeDraftStore(File('${directory.path}/draft.json')),
            aiIntake: intake,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('本机').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('open-ai-settings')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('ai-base-url')),
          '$base/v1',
        );
        await tester.enterText(
          find.byKey(const Key('ai-model')),
          'fixture-model',
        );
        await tester.enterText(
          find.byKey(const Key('ai-key')),
          'native-test-secret',
        );
        await tester.ensureVisible(find.byKey(const Key('test-ai-settings')));
        await tester.tap(find.byKey(const Key('test-ai-settings')));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (w) => w is SelectableText && w.data == '连接测试通过，设置尚未保存',
          ),
          findsOneWidget,
          reason:
              'AI calls: $aiCalls; connection test: $wasConnectionTest; server error: $serverFailure; visible messages: ${tester.widgetList<SelectableText>(find.byType(SelectableText)).map((t) => t.data).join(' | ')}',
        );
        expect(await settings.configurations.load(), isNull);
        await tester.ensureVisible(find.byKey(const Key('save-ai-settings')));
        await tester.tap(find.byKey(const Key('save-ai-settings')));
        await tester.pumpAndSettle();
        expect(await keys.read(), 'native-test-secret');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('动漫库').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add-anime')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('intake-query')), '星际牛仔');
        await tester.pump();
        await tester.tap(find.byKey(const Key('recognize-title')));
        await tester.pumpAndSettle();
        expect(await repo.all(), hasLength(1));
        await tester.ensureVisible(find.byKey(const Key('candidate-253')));
        await tester.tap(find.byKey(const Key('candidate-253')));
        await tester.pumpAndSettle();
        expect(
          sourceCalls,
          2,
          reason:
              'server error: $serverFailure; visible text: ${tester.widgetList<Text>(find.byType(Text)).map((w) => w.data).join(' | ')}',
        );
        expect(await repo.all(), hasLength(1));
        await tester.scrollUntilVisible(
          find.byKey(const Key('confirm-metadata')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('confirm-metadata')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('confirm-metadata')).hitTestable(),
          findsOneWidget,
        );
        debugPrint('AI integration: confirmation visible');
        await tester.tap(find.byKey(const Key('confirm-metadata')));
        debugPrint('AI integration: confirmation tapped');
        await tester.pumpAndSettle();
        debugPrint('AI integration: editor opened');
        expect(await repo.all(), hasLength(1));
        await tester.tap(find.byKey(const Key('save-record')));
        debugPrint('AI integration: save tapped');
        await tester.pumpAndSettle();
        expect(find.text('已有记录与刷次'), findsOneWidget);
        await tester.tap(find.text('采用第 2 刷'));
        debugPrint('AI integration: rewatch confirmed');
        await tester.pumpAndSettle();
        debugPrint('AI integration: saved and returned');
        final records = await repo.all();
        expect(records, hasLength(2));
        final created = records.singleWhere((r) => r.uuid != old.entry.uuid);
        expect(created.progress, 0);
        expect(created.score, isNull);
        expect(created.notes, isNull);
        expect(created.rewatchCount, 2);
        expect(created.metadata.totalEpisodes, 26);
        expect(await repo.history(created.uuid), isEmpty);
        final unchanged = (await repo.find(old.entry.uuid))!;
        expect(unchanged.progress, 26);
        expect(unchanged.score, 0);
        expect(unchanged.notes, '此前记录保持原样');
        expect(aiCalls, 2);
        expect(sourceCalls, 2);
        expect(credentialSentOnlyToAi, true);
        expect(protocolValid, true);
        expect(tester.takeException(), isNull);
        final rows = await db.select(db.appSettings).get();
        expect(
          rows.map((r) => r.value).join(),
          isNot(contains('native-test-secret')),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await keys.write(null);
        await server.close(force: true);
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
