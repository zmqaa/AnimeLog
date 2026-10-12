import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animelog/core/anime_log_core.dart';
import 'package:animelog/core/api/ai_intake.dart';
import 'package:animelog/data/platform/cover_cache.dart';
import 'package:animelog/data/remote/bangumi_source.dart';
import 'package:animelog/data/remote/compatible_ai_client.dart';
import 'package:animelog/data/remote/json_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'ai_fixtures.dart';
import 'ai_intake_test.dart' show failure;

void main() {
  test('compatible request sends configured model, nonstream JSON and parses fenced UTF-8', () async {
    var calls = 0;
    final client = CompatibleAiClient(
      JsonHttp(
        createClient: () => MockClient((request) async {
          calls++;
          expect(
            request.url.toString(),
            'https://ai.example/v1/chat/completions',
          );
          expect(request.headers['Authorization'], 'Bearer fixture-secret');
          final body = jsonDecode(request.body);
          expect(body['model'], 'configured-model');
          expect(body['stream'], false);
          expect(body['messages'][1]['content'], '星际牛仔');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'choices': [
                  {
                    'message': {
                      'content': '```json\n${jsonEncode(titlePayload)}\n```',
                    },
                  },
                ],
              }),
            ),
            200,
          );
        }),
      ),
    );
    final result = await client.complete(
      configuration,
      'fixture-secret',
      buildQuickRecordAiMessages('星际牛仔'),
      RequestScope(),
    );
    expect(parseSingleAnimeTitlePayload(result)?.animeTitle, '星际牛仔');
    expect(calls, 1);
  });
  for (final entry in {
    401: NetworkFailureKind.authentication,
    403: NetworkFailureKind.authentication,
    429: NetworkFailureKind.rateLimited,
    500: NetworkFailureKind.invalidResponse,
    302: NetworkFailureKind.invalidResponse,
  }.entries) {
    test(
      'HTTP ${entry.key} is translated and raw server error never exposed or retried',
      () async {
        var calls = 0;
        final transport = JsonHttp(
          createClient: () => MockClient((_) async {
            calls++;
            return http.Response('fixture-secret raw response', entry.key);
          }),
        );
        try {
          await transport.json('POST', configuration.endpoint, RequestScope());
          fail('Expected network failure');
        } on NetworkFailure catch (e) {
          expect(e.kind, entry.value);
          expect('$e', isNot(contains('fixture-secret')));
        }
        expect(calls, 1);
      },
    );
  }
  test(
    'malformed content and missing choices are recoverable failures',
    () async {
      for (final body in [
        'not JSON',
        '{}',
        '{"choices":[{"message":{"content":"not JSON"}}]}',
      ]) {
        final client = CompatibleAiClient(
          JsonHttp(
            createClient: () =>
                MockClient((_) async => http.Response(body, 200)),
          ),
        );
        await expectLater(
          client.complete(
            configuration,
            null,
            buildQuickRecordAiMessages('标题'),
            RequestScope(),
          ),
          throwsA(failure(NetworkFailureKind.invalidResponse)),
        );
      }
    },
  );
  test(
    'socket disconnect translated without leaking transport details',
    () async {
      final transport = JsonHttp(
        createClient: () =>
            MockClient((_) async => throw const SocketException('secret-host')),
      );
      await expectLater(
        transport.json('GET', configuration.endpoint, RequestScope()),
        throwsA(failure(NetworkFailureKind.offline)),
      );
    },
  );
  test('response size is bounded and client is closed', () async {
    final tracking = TrackingClient(
      MockClient((_) async => http.Response('123456789', 200)),
    );
    final transport = JsonHttp(createClient: () => tracking);
    await expectLater(
      transport.bytes(
        'GET',
        configuration.endpoint,
        RequestScope(),
        maxBytes: 8,
      ),
      throwsA(failure(NetworkFailureKind.invalidResponse)),
    );
    expect(tracking.closed, true);
  });
  test('cancelling active request closes client promptly and rejects late completion', () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final tracking = TrackingClient(
      MockClient((_) {
        started.complete();
        return pending.future;
      }),
    );
    final scope = RequestScope();
    final transport = JsonHttp(createClient: () => tracking);
    final request = transport.json('GET', configuration.endpoint, scope);
    final expectation = expectLater(
      request,
      throwsA(failure(NetworkFailureKind.cancelled)),
    );
    await started.future;
    scope.cancel();
    await expectation;
    expect(tracking.closed, true);
    pending.complete(http.Response('{}', 200));
    await Future<void>.delayed(Duration.zero);
  });
  test(
    'per-request timeout closes HTTP client and preserves timeout reason',
    () async {
      final pending = Completer<http.Response>();
      final tracking = TrackingClient(MockClient((_) => pending.future));
      final scope = RequestScope();
      final transport = JsonHttp(createClient: () => tracking);
      await expectLater(
        transport.json(
          'GET',
          configuration.endpoint,
          scope,
          limit: const Duration(milliseconds: 30),
        ),
        throwsA(failure(NetworkFailureKind.timeout)),
      );
      expect(tracking.closed, true);
      expect(() => scope.check(), throwsA(failure(NetworkFailureKind.timeout)));
      pending.complete(http.Response('{}', 200));
    },
  );
  test('chain shares remaining deadline across requests', () async {
    final scope = RequestScope(budget: const Duration(milliseconds: 120));
    await scope.guard(Future<void>.delayed(const Duration(milliseconds: 80)));
    final watch = Stopwatch()..start();
    await expectLater(
      scope.guard(Future<void>.delayed(const Duration(milliseconds: 150))),
      throwsA(failure(NetworkFailureKind.timeout)),
    );
    expect(watch.elapsedMilliseconds, lessThan(100));
  });
  test(
    'actual loopback HTTP can be cancelled while receiving a streamed body',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final started = Completer<void>();
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write('{');
        await request.response.flush();
        started.complete();
        // The incomplete response remains open until scope cancellation.
      });
      final scope = RequestScope();
      final response = JsonHttp().json(
        'GET',
        Uri.parse('http://127.0.0.1:${server.port}'),
        scope,
      );
      final expectation = expectLater(
        response,
        throwsA(failure(NetworkFailureKind.cancelled)),
      );
      await started.future;
      scope.cancel();
      await expectation;
      await server.close(force: true);
    },
  );
  test('Bangumi maps real platform and declared eps; unknowns remain null', () {
    final source = BangumiSourceProvider(
      JsonHttp(),
      now: () => DateTime(2026, 10, 10),
    );
    final metadata = source.mapSubject(subject);
    expect(metadata.totalEpisodes, 26);
    expect(metadata.entryType, AnimeEntryType.tv);
    expect(metadata.sourceId, '253');
    expect(metadata.durationMinutes, 24);
    expect(metadata.isFinished, true);
    final unknown = source.mapSubject({
      ...subject,
      'eps': 0,
      'platform': 'unknown',
      'date': '0000-00-00',
      'infobox': [],
    });
    expect(unknown.totalEpisodes, isNull);
    expect(unknown.entryType, isNull);
    expect(unknown.premiereDate, isNull);
    expect(unknown.isFinished, isNull);
  });
  test('Bangumi search limits to anime, maps actual IDs and detail validates identity', () async {
    final source = BangumiSourceProvider(
      JsonHttp(
        createClient: () => MockClient((request) async {
          expect(request.headers['User-Agent'], contains('AnimeLog'));
          if (request.method == 'POST') {
            expect(jsonDecode(request.body)['filter']['type'], [2]);
            expect(request.url.queryParameters['limit'], '20');
            return http.Response(
              jsonEncode({
                'data': [
                  subject,
                  {...subject, 'type': 1},
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response.bytes(
            utf8.encode(jsonEncode({...subject, 'id': 999})),
            200,
          );
        }),
      ),
    );
    final candidates = await source.search('星际牛仔', RequestScope());
    expect(candidates.single.id, 253);
    expect(candidates.single.totalEpisodes, 26);
    await expectLater(
      source.details(253, RequestScope()),
      throwsA(failure(NetworkFailureKind.source)),
    );
  });
  test('cover downloaded once, cached for offline access and private cache errors do not fail display', () async {
    final root = await Directory.systemTemp.createTemp('animelog-cover-');
    addTearDown(() => root.delete(recursive: true));
    final image = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lXcAAAAASUVORK5CYII=',
    );
    var calls = 0;
    final transport = JsonHttp(
      createClient: () => MockClient((_) async {
        calls++;
        return http.Response.bytes(image, 200);
      }),
    );
    final cache = FileCoverCache(Directory('${root.path}/cache'), transport);
    final pair = await Future.wait([
      cache.load('https://cover.example/1'),
      cache.load('https://cover.example/1'),
    ]);
    expect(pair[0], image);
    expect(calls, 1);
    final offline = FileCoverCache(
      Directory('${root.path}/cache'),
      JsonHttp(
        createClient: () =>
            MockClient((_) async => throw const SocketException('offline')),
      ),
    );
    expect(await offline.load('https://cover.example/1'), image);
    final blocker = File('${root.path}/blocker');
    await blocker.writeAsString('not a directory');
    expect(
      await FileCoverCache(
        Directory(blocker.path),
        transport,
      ).load('https://cover.example/2'),
      image,
    );
  });
}

class TrackingClient extends http.BaseClient {
  final http.Client delegate;
  bool closed = false;
  TrackingClient(this.delegate);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      delegate.send(request);
  @override
  void close() {
    closed = true;
    delegate.close();
  }
}
