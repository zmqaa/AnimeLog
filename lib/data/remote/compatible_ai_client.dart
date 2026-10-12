import '../../core/api/ai_intake.dart';
import '../../core/ai/ai_json.dart';
import '../../core/ai/ai_provider_presets.dart';
import '../../core/ai/quick_record_prompt.dart';
import 'json_http.dart';

class CompatibleAiClient implements AiClient {
  final JsonHttp transport;
  CompatibleAiClient(this.transport);
  @override
  Future<Object?> complete(
    AiConfiguration configuration,
    String? key,
    List<AiMessage> messages,
    RequestScope scope,
  ) async {
    configuration.validate();
    final response = await transport.json(
      'POST',
      configuration.endpoint,
      scope,
      headers: {
        if (key != null && key.isNotEmpty) 'Authorization': 'Bearer $key',
      },
      body: {
        'model': configuration.model,
        'stream': false,
        'messages': messages.map((m) => m.toJson()).toList(),
        ...aiPresetRequestOptions(configuration),
      },
      limit: const Duration(seconds: 20),
    );
    try {
      final content =
          (response
              as Map<String, dynamic>)['choices'][0]['message']['content'];
      if (content is! String) throw const FormatException();
      final json = parseJsonFromAiContent(content);
      if (json is! Map<String, dynamic>) throw const FormatException();
      return json;
    } catch (_) {
      throw const NetworkFailure(NetworkFailureKind.invalidResponse);
    }
  }
}
