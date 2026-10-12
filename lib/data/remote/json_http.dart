import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/api/ai_intake.dart';

class JsonHttp {
  final http.Client Function() createClient;
  JsonHttp({http.Client Function()? createClient})
    : createClient = createClient ?? http.Client.new;

  Future<Uint8List> bytes(
    String method,
    Uri uri,
    RequestScope scope, {
    Map<String, String> headers = const {},
    Object? body,
    Duration limit = const Duration(seconds: 10),
    int maxBytes = 2 * 1024 * 1024,
    bool source = false,
  }) async {
    scope.check();
    final client = createClient();
    void close() => client.close();
    scope.attach(close);
    try {
      return await scope.guard(() async {
        final request = http.AbortableRequest(
          method,
          uri,
          abortTrigger: scope.cancellation.then((_) {}),
        );
        request.followRedirects = false;
        request.headers.addAll({'Accept': 'application/json', ...headers});
        if (body != null) {
          request.headers['Content-Type'] = 'application/json; charset=utf-8';
          request.body = jsonEncode(body);
        }
        final response = await client.send(request);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw NetworkFailure(switch (response.statusCode) {
            401 || 403 =>
              source
                  ? NetworkFailureKind.source
                  : NetworkFailureKind.authentication,
            429 => NetworkFailureKind.rateLimited,
            _ =>
              source
                  ? NetworkFailureKind.source
                  : NetworkFailureKind.invalidResponse,
          });
        }
        final buffer = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          if (buffer.length + chunk.length > maxBytes) {
            throw NetworkFailure(
              source
                  ? NetworkFailureKind.source
                  : NetworkFailureKind.invalidResponse,
            );
          }
          buffer.add(chunk);
        }
        return buffer.takeBytes();
      }(), limit: limit);
    } on NetworkFailure {
      rethrow;
    } on SocketException {
      throw const NetworkFailure(NetworkFailureKind.offline);
    } on http.ClientException {
      throw const NetworkFailure(NetworkFailureKind.offline);
    } on HandshakeException {
      throw const NetworkFailure(NetworkFailureKind.offline);
    } catch (_) {
      throw NetworkFailure(
        source ? NetworkFailureKind.source : NetworkFailureKind.invalidResponse,
      );
    } finally {
      scope.detach(close);
      close();
    }
  }

  Future<Object?> json(
    String method,
    Uri uri,
    RequestScope scope, {
    Map<String, String> headers = const {},
    Object? body,
    Duration limit = const Duration(seconds: 10),
    bool source = false,
  }) async {
    final data = await bytes(
      method,
      uri,
      scope,
      headers: headers,
      body: body,
      limit: limit,
      source: source,
    );
    try {
      return jsonDecode(utf8.decode(data));
    } catch (_) {
      throw NetworkFailure(
        source ? NetworkFailureKind.source : NetworkFailureKind.invalidResponse,
      );
    }
  }
}
