import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

import '../../core/api/ai_intake.dart';

class SecureApiKeyStore implements ApiKeyStore {
  final FlutterSecureStorage storage;
  // This namespace must survive upgrades. Do not share keys with test fixtures.
  final String namespace;
  SecureApiKeyStore({
    this.storage = const FlutterSecureStorage(),
    this.namespace = 'animelog.ai.api_key.v1',
  });
  @override
  Future<String?> read({String? endpoint}) async {
    try {
      final saved = await storage.read(key: namespace);
      if (saved == null) return null;
      // An unbound legacy value is never sent to a configured endpoint.
      if (!saved.startsWith('{')) return endpoint == null ? saved : null;
      final credentials = jsonDecode(saved) as Map<String, dynamic>;
      if (endpoint != null && credentials['endpoint'] != endpoint) return null;
      return credentials['key'] as String?;
    } on MissingPluginException {
      throw const NetworkFailure(NetworkFailureKind.storagePluginMissing);
    } catch (_) {
      throw const NetworkFailure(NetworkFailureKind.storage);
    }
  }

  @override
  Future<void> write(String? key, {String? endpoint}) async {
    try {
      if (key == null || key.isEmpty) {
        await storage.delete(key: namespace);
      } else {
        await storage.write(
          key: namespace,
          value: jsonEncode({'key': key, 'endpoint': endpoint}),
        );
      }
    } on MissingPluginException {
      throw const NetworkFailure(NetworkFailureKind.storagePluginMissing);
    } catch (_) {
      throw const NetworkFailure(NetworkFailureKind.storage);
    }
  }
}
