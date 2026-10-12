import '../api/ai_intake.dart';

class AiModelPreset {
  final String id;
  final String label;
  const AiModelPreset(this.id, this.label);
}

enum AiProvider {
  deepSeek('DeepSeek', 'DS', [
    AiModelPreset('deepseek-flash', 'DeepSeek Flash'),
    AiModelPreset('deepseek-v4-pro', 'DeepSeek Pro'),
  ]),
  qwen('Qwen', '千问', [
    AiModelPreset('qwen-plus', 'Qwen Plus'),
    AiModelPreset('qwen-flash', 'Qwen Flash'),
    AiModelPreset('qwen3.5-plus', 'Qwen 3.5 Plus'),
  ]),
  custom('自定义', 'API', []);

  final String label;
  final String mark;
  final List<AiModelPreset> models;
  const AiProvider(this.label, this.mark, this.models);

  String get baseUrl => switch (this) {
    deepSeek => 'https://api.deepseek.com',
    qwen => QwenRegion.beijing.baseUrl,
    custom => '',
  };

  static AiProvider fromConfiguration(AiConfiguration? configuration) {
    if (configuration == null) return custom;
    try {
      final endpoint = configuration.endpoint;
      if (endpoint.scheme != 'https' || endpoint.port != 443) return custom;
      if (endpoint.host == 'api.deepseek.com' &&
          const [
            '/chat/completions',
            '/v1/chat/completions',
          ].contains(endpoint.path)) {
        return deepSeek;
      }
      if (QwenRegion.values.any(
            (region) => Uri.parse(region.baseUrl).host == endpoint.host,
          ) &&
          endpoint.path == '/compatible-mode/v1/chat/completions') {
        return qwen;
      }
    } on FormatException {
      // Invalid or custom saved addresses stay editable without migration.
    }
    return custom;
  }
}

enum QwenRegion {
  beijing('北京', 'https://dashscope.aliyuncs.com/compatible-mode/v1'),
  singapore('新加坡', 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1'),
  virginia('美国弗吉尼亚', 'https://dashscope-us.aliyuncs.com/compatible-mode/v1');

  final String label;
  final String baseUrl;
  const QwenRegion(this.label, this.baseUrl);

  static QwenRegion fromConfiguration(AiConfiguration configuration) {
    final host = Uri.tryParse(configuration.baseUrl.trim())?.host;
    return values.firstWhere(
      (region) => Uri.parse(region.baseUrl).host == host,
      orElse: () => beijing,
    );
  }
}

/// Provider extensions belong only to known official endpoints and models.
/// Custom compatible APIs keep the standard request body.
Map<String, Object> aiPresetRequestOptions(AiConfiguration configuration) {
  final provider = AiProvider.fromConfiguration(configuration);
  if (!provider.models.any((model) => model.id == configuration.model.trim())) {
    return const {};
  }
  return switch (provider) {
    AiProvider.deepSeek => const {
      'thinking': {'type': 'disabled'},
    },
    AiProvider.qwen => const {'enable_thinking': false},
    AiProvider.custom => const {},
  };
}
