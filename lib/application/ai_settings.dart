import '../core/api/ai_intake.dart';
import '../core/ai/quick_record_prompt.dart';

class AiSettings {
  final AiConfigurationStore configurations;
  final ApiKeyStore keys;
  final AiClient client;
  AiSettings(this.configurations, this.keys, this.client);

  Future<void> save(
    AiConfiguration configuration, {
    String? replacementKey,
    bool clearKey = false,
  }) async {
    configuration.validate();
    final previous = await configurations.load();
    // Never reuse a saved secret at a newly configured endpoint.
    final changed = previous?.endpoint != configuration.endpoint;
    if (clearKey || changed || replacementKey != null) {
      await keys.write(
        clearKey ? null : replacementKey?.trim(),
        endpoint: configuration.endpoint.toString(),
      );
    }
    await configurations.save(
      AiConfiguration(
        baseUrl: configuration.baseUrl.trim().replaceFirst(RegExp(r'/+$'), ''),
        model: configuration.model.trim(),
      ),
    );
  }

  Future<void> test(
    AiConfiguration configuration,
    RequestScope scope, {
    String? replacementKey,
    bool clearKey = false,
  }) async {
    configuration.validate();
    final previous = await scope.guard(configurations.load());
    final sameEndpoint = previous?.endpoint == configuration.endpoint;
    final key = clearKey
        ? null
        : replacementKey ??
              (sameEndpoint
                  ? await scope.guard(
                      keys.read(endpoint: configuration.endpoint.toString()),
                    )
                  : null);
    final result = await client.complete(configuration, key, const [
      AiMessage(role: 'system', content: '仅输出 JSON：{"ok":true}。'),
      AiMessage(role: 'user', content: '连接测试'),
    ], scope);
    if (result is! Map<String, dynamic> || result['ok'] != true) {
      throw const NetworkFailure(NetworkFailureKind.invalidResponse);
    }
  }
}
