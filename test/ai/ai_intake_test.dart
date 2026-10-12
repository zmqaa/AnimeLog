import 'dart:async';
import 'dart:convert';

import 'package:animelog/application/ai_intake.dart';
import 'package:animelog/application/ai_settings.dart';
import 'package:animelog/application/manual_library.dart';
import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/core/api/ai_intake.dart';
import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_ai_configuration.dart';
import 'package:animelog/data/local/sqlite_backup_repository.dart';
import 'package:animelog/data/local/sqlite_library_repository.dart';
import 'package:animelog/features/intake/editor_controller.dart';
import 'package:animelog/features/intake/intake_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ai_fixtures.dart';

Matcher failure(NetworkFailureKind kind) =>
    isA<NetworkFailure>().having((f) => f.kind, 'kind', kind);
AiIntake intake(FixtureAi ai, FixtureSource source) =>
    AiIntake(AiSettings(MemoryConfigurations(), MemoryKeys(), ai), source);

void main() {
  test(
    'base URL preserves supplied path and accepts only explicit local HTTP',
    () {
      for (final base in [
        'https://example.test/v1',
        'https://example.test/v1///',
      ]) {
        expect(
          AiConfiguration(baseUrl: base, model: 'm').endpoint.toString(),
          'https://example.test/v1/chat/completions',
        );
      }
      expect(
        AiConfiguration(
          baseUrl: 'http://127.0.0.1:8080',
          model: 'm',
        ).endpoint.path,
        '/chat/completions',
      );
      expect(
        AiConfiguration(
          baseUrl: 'http://[::1]:8080/v1',
          model: 'm',
        ).endpoint.path,
        '/v1/chat/completions',
      );
      for (final base in [
        'http://remote.example/v1',
        'ftp://localhost',
        'https://user:secret@example.test',
        'https://example.test?key=secret',
        'https://example.test/v1/chat/completions',
      ]) {
        expect(
          () => AiConfiguration(baseUrl: base, model: 'm').validate(),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'empty input and missing config never request model or source',
    () async {
      final ai = FixtureAi([]);
      final source = FixtureSource();
      final service = AiIntake(
        AiSettings(MemoryConfigurations(null), MemoryKeys(), ai),
        source,
      );
      await expectLater(
        service.recognize(' ', RequestScope()),
        throwsFormatException,
      );
      await expectLater(
        service.recognize('作品', RequestScope()),
        throwsA(failure(NetworkFailureKind.unconfigured)),
      );
      expect(ai.calls, isEmpty);
      expect(source.searches, isEmpty);
    },
  );
  test('unique strict source match skips candidate AI; no details read until choice', () async {
    final ai = FixtureAi([titlePayload]);
    final source = FixtureSource([
      ...List.generate(
        6,
        (i) => AnimeTitleCandidate(id: i + 1, title: '其他作品 $i'),
      ),
      const AnimeTitleCandidate(
        id: 253,
        title: '星际牛仔',
        entryType: AnimeEntryType.tv,
      ),
    ]);
    final result = await intake(ai, source).recognize('星际牛仔', RequestScope());
    expect(ai.calls, hasLength(1));
    expect(source.searches, ['星际牛仔']);
    expect(result.recommendation?.id, 253);
    expect(result.candidates, hasLength(5));
    expect(result.candidates.map((candidate) => candidate.id), [
      253,
      1,
      2,
      3,
      4,
    ]);
    expect(source.detailCalls, 0);
    expect(result.title.toJson().keys, isNot(contains('progress')));
  });
  test('old batch responses refused without searching', () async {
    final ai = FixtureAi([
      {
        'records': [titlePayload['record']],
      },
    ]);
    final source = FixtureSource();
    await expectLater(
      intake(ai, source).recognize('星际牛仔', RequestScope()),
      throwsA(failure(NetworkFailureKind.invalidResponse)),
    );
    expect(source.searches, isEmpty);
    expect(ai.calls, hasLength(1));
  });
  test('two queries deduplicate IDs and candidate AI sees at most twenty actual entries', () async {
    final candidates = List.generate(
      30,
      (i) => AnimeTitleCandidate(id: i + 1, title: '候选 $i'),
    );
    final source = FixtureSource(candidates);
    final ai = FixtureAi([
      titlePayload,
      {'selectedId': 30},
    ]);
    final result = await intake(ai, source).recognize('用户别名', RequestScope());
    expect(source.searches, ['用户别名', '星际牛仔']);
    expect(ai.calls, hasLength(2));
    final prompt = jsonDecode(ai.calls.last.last.content) as Map;
    expect(prompt['candidates'], hasLength(20));
    expect(result.candidates, hasLength(5));
    expect(result.recommendation, isNull);
  });
  test(
    'explicit season and format conflicts are not automatically recommended',
    () async {
      final source = FixtureSource(const [
        AnimeTitleCandidate(
          id: 1,
          title: '候选第一季',
          season: 1,
          entryType: AnimeEntryType.movie,
        ),
      ]);
      final ai = FixtureAi([
        {
          'record': {'animeTitle': '作品 第二季', 'season': 2, 'entryType': 'tv'},
        },
        {'selectedId': 1},
      ]);
      final result = await intake(
        ai,
        source,
      ).recognize('作品 第二季', RequestScope());
      expect(result.recommendation, isNull);
      expect(result.candidates.single.id, 1);
    },
  );
  test('candidate API authentication error leaves actual choices and warns without retry', () async {
    final ai = FixtureAi([
      titlePayload,
      const NetworkFailure(NetworkFailureKind.authentication),
    ]);
    final source = FixtureSource(const [
      AnimeTitleCandidate(id: 1, title: '另一个名字'),
    ]);
    final result = await intake(ai, source).recognize('作品', RequestScope());
    expect(result.candidates, hasLength(1));
    expect(result.warning?.kind, NetworkFailureKind.authentication);
    expect(ai.calls, hasLength(2));
    expect(result.recommendation, isNull);
  });
  test(
    'source failure retains recognized title with manual fallback',
    () async {
      final source = FixtureSource()
        ..failure = const NetworkFailure(NetworkFailureKind.source);
      final result = await intake(
        FixtureAi([titlePayload]),
        source,
      ).recognize('星际牛仔', RequestScope());
      expect(result.candidates, isEmpty);
      expect(result.title.animeTitle, '星际牛仔');
      expect(result.warning?.kind, NetworkFailureKind.source);
    },
  );
  test('changing query invalidates late responses and cancellation cannot start source search', () async {
    final pending = Completer<Object?>();
    final ai = FixtureAi([pending.future, titlePayload]);
    final source = FixtureSource();
    final drafts = MemoryDrafts();
    final controller = IntakeController(intake(ai, source), drafts);
    controller.changeQuery('旧标题');
    final oldId = controller.draftId;
    final oldRequest = controller.recognize();
    await Future<void>.delayed(Duration.zero);
    controller.changeQuery('星际牛仔');
    await controller.recognize();
    pending.complete({
      'record': {'animeTitle': '旧响应标题'},
    });
    await oldRequest;
    expect(controller.query, '星际牛仔');
    expect(controller.result?.title.animeTitle, '星际牛仔');
    expect(controller.draftId, isNot(oldId));
    expect(source.searches, ['星际牛仔']);
    await controller.flush();
    expect(drafts.value?['fields']['title'], '星际牛仔');
    controller.dispose();
  });
  test('recognized chosen metadata persists and explicit save only creates without personal AI fields', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SqliteLibraryRepository(db);
    final useCases = ManualLibrary(repo, repo);
    final old = await useCases.create(
      const AnimeCreationDraft(
        draftId: 'old',
        metadata: AnimeMetadata(
          title: '星际牛仔',
          sourceProvider: 'bangumi',
          sourceId: '253',
          totalEpisodes: 26,
        ),
        status: AnimeStatus.completed,
        progress: 26,
        score: 9,
        notes: '旧备注',
      ),
    );
    final drafts = MemoryDrafts();
    final controller = IntakeController(
      intake(FixtureAi([titlePayload]), FixtureSource()),
      drafts,
    );
    controller.changeQuery('星际牛仔');
    final id = controller.draftId;
    await controller.recognize();
    await controller.choose(controller.result!.candidates.single);
    await controller.flush();
    expect(drafts.value?['intakeMode'], 'editor');
    expect(drafts.value?['fields']['sourceId'], '253');
    expect(await repo.all(), hasLength(1));
    final editor = EditorController(
      useCases: useCases,
      store: drafts,
      restored: await controller.prepareEditor(),
    );
    final draft = editor.draft();
    expect(draft.draftId, id);
    expect(draft.progress, 0);
    expect(draft.status, AnimeStatus.watching);
    expect(draft.score, isNull);
    expect(draft.notes, isNull);
    expect(draft.tags, isEmpty);
    editor.text['rewatch']!.text = '2';
    final uuid = await editor.save();
    expect(await repo.all(), hasLength(2));
    expect(await repo.history(uuid), isEmpty);
    final previous = (await repo.find(old.entry.uuid))!;
    expect(previous.progress, 26);
    expect(previous.notes, '旧备注');
    expect(previous.score, 9);
    expect((await repo.find(uuid))!.tags, ['二刷']);
    editor.dispose();
    controller.dispose();
  });
  test('SQLite settings exclude secret and backup; endpoint changes remove old key', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final keys = MemoryKeys();
    final configs = SqliteAiConfigurationStore(db);
    final settings = AiSettings(configs, keys, FixtureAi([]));
    await settings.save(configuration, replacementKey: 'private-fixture-key');
    final rows = await db.select(db.appSettings).get();
    expect(
      rows.map((r) => r.value).join(),
      isNot(contains('private-fixture-key')),
    );
    expect((await configs.load())?.baseUrl, 'https://ai.example/v1');
    final backup = await SqliteBackupRepository(db).snapshot();
    expect(utf8.decode(backup.encode()), isNot(contains('ai.example')));
    await settings.save(
      const AiConfiguration(baseUrl: 'https://new.example/v1', model: 'm'),
    );
    expect(keys.value, isNull);
  });
  test(
    'testing different endpoint never sends old key or persists test values',
    () async {
      final configs = MemoryConfigurations();
      final keys = MemoryKeys();
      final ai = KeyCapturingAi();
      final settings = AiSettings(configs, keys, ai);
      await settings.test(
        const AiConfiguration(baseUrl: 'https://new.example', model: 'm'),
        RequestScope(),
      );
      expect(ai.sentKey, isNull);
      expect(keys.value, 'fixture-secret');
      expect(configs.value, configuration);
    },
  );
  test(
    'failed configuration commit cannot send replacement key to old endpoint',
    () async {
      final configurations = FailingConfigurations();
      final keys = MemoryKeys();
      final ai = KeyCapturingAi();
      final settings = AiSettings(configurations, keys, ai);
      const target = AiConfiguration(
        baseUrl: 'https://new.example/v1',
        model: 'm',
      );
      await expectLater(
        settings.save(target, replacementKey: 'new-endpoint-secret'),
        throwsStateError,
      );
      expect(configurations.value, configuration);
      expect(
        await keys.read(endpoint: configuration.endpoint.toString()),
        isNull,
      );
      await settings.test(configuration, RequestScope());
      expect(ai.sentKey, isNull);
    },
  );
}

class FailingConfigurations extends MemoryConfigurations {
  @override
  Future<void> save(AiConfiguration configuration) async =>
      throw StateError('fixture write failure');
}

class KeyCapturingAi implements AiClient {
  String? sentKey;
  @override
  Future<Object?> complete(
    AiConfiguration configuration,
    String? key,
    List<AiMessage> messages,
    RequestScope scope,
  ) async {
    sentKey = key;
    return {'ok': true};
  }
}
