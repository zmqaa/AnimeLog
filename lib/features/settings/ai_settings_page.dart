import 'package:flutter/material.dart';

import '../../application/ai_settings.dart';
import '../../core/api/ai_intake.dart';
import '../../core/ai/ai_provider_presets.dart';
import '../shared/app_theme.dart';
import 'settings_panel.dart';

class AiSettingsPage extends StatefulWidget {
  final AiSettings service;
  const AiSettingsPage({super.key, required this.service});
  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  final baseUrl = TextEditingController();
  final model = TextEditingController();
  final key = TextEditingController();
  AiProvider provider = AiProvider.deepSeek;
  QwenRegion region = QwenRegion.beijing;
  bool customModel = false;
  bool advanced = false;
  bool loading = true;
  bool busy = false;
  bool savedHasKey = false;
  String? savedEndpoint;
  String? credentialEndpoint;
  bool clearKey = false;
  bool revealKey = false;
  bool messageIsError = false;
  bool testing = false;
  String? message;
  RequestScope? scope;

  AiConfiguration get configuration =>
      AiConfiguration(baseUrl: baseUrl.text, model: model.text);

  String? get currentEndpoint {
    try {
      return configuration.endpoint.toString();
    } on FormatException {
      return null;
    }
  }

  bool get hasKey =>
      savedHasKey && savedEndpoint != null && savedEndpoint == currentEndpoint;

  @override
  void initState() {
    super.initState();
    baseUrl.text = provider.baseUrl;
    model.text = provider.models.first.id;
    credentialEndpoint = currentEndpoint;
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await widget.service.configurations.load();
      if (!mounted) return;
      if (value != null) {
        // Preserve the user's exact endpoint and model; presets are optional.
        baseUrl.text = value.baseUrl;
        model.text = value.model;
        provider = AiProvider.fromConfiguration(value);
        region = QwenRegion.fromConfiguration(value);
        customModel = !provider.models.any(
          (preset) => preset.id == value.model,
        );
        savedEndpoint = value.endpoint.toString();
        final savedKey = await widget.service.keys.read(
          endpoint: savedEndpoint,
        );
        if (!mounted) return;
        savedHasKey = savedKey?.isNotEmpty ?? false;
      }
      credentialEndpoint = currentEndpoint;
    } catch (failure) {
      if (mounted) {
        message = '$failure';
        messageIsError = true;
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _resetEnteredKey() {
    // An entered secret must not travel to another provider or region either.
    key.clear();
    clearKey = false;
    revealKey = false;
    credentialEndpoint = currentEndpoint;
    message = null;
    messageIsError = false;
  }

  void _selectProvider(AiProvider value) {
    if (provider == value) return;
    setState(() {
      provider = value;
      if (value != AiProvider.custom) {
        baseUrl.text = value == AiProvider.qwen
            ? region.baseUrl
            : value.baseUrl;
        model.text = value.models.first.id;
      }
      customModel = value == AiProvider.custom;
      _resetEnteredKey();
    });
  }

  void _selectRegion(QwenRegion value) {
    if (region == value) return;
    setState(() {
      region = value;
      baseUrl.text = value.baseUrl;
      _resetEnteredKey();
    });
  }

  void _editAddress(String _) {
    setState(() {
      if (credentialEndpoint != currentEndpoint) _resetEnteredKey();
    });
  }

  Future<void> _perform(bool test) async {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      testing = test;
      message = null;
      messageIsError = false;
    });
    final operation = scope = RequestScope(budget: const Duration(seconds: 20));
    try {
      final value = configuration;
      value.validate();
      final replacement = key.text.trim().isEmpty ? null : key.text.trim();
      final endpointProvider = AiProvider.fromConfiguration(value);
      if (endpointProvider != AiProvider.custom &&
          (!hasKey || clearKey) &&
          replacement == null &&
          (test || !clearKey)) {
        throw FormatException('请填写 ${endpointProvider.label} 的 API Key');
      }
      if (test) {
        await widget.service.test(
          value,
          operation,
          replacementKey: replacement,
          clearKey: clearKey,
        );
        if (mounted) setState(() => message = '连接成功，记得保存设置。');
      } else {
        await widget.service.save(
          value,
          replacementKey: replacement,
          clearKey: clearKey,
        );
        final savedKey = await widget.service.keys.read(
          endpoint: value.endpoint.toString(),
        );
        if (mounted) {
          key.clear();
          setState(() {
            message = 'AI 设置已保存';
            savedEndpoint = value.endpoint.toString();
            savedHasKey = savedKey?.isNotEmpty ?? false;
            clearKey = false;
            revealKey = false;
            provider = endpointProvider;
            region = QwenRegion.fromConfiguration(value);
            customModel = !provider.models.any(
              (preset) => preset.id == value.model,
            );
          });
        }
      }
    } catch (failure) {
      if (mounted) {
        setState(() {
          message = '$failure';
          messageIsError = true;
        });
      }
    } finally {
      operation.cancel();
      if (mounted) {
        setState(() {
          busy = false;
          scope = null;
        });
      }
    }
  }

  @override
  void dispose() {
    scope?.cancel();
    baseUrl.dispose();
    model.dispose();
    key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) scope?.cancel();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('AI 设置')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.all(
                            MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
                          ),
                          children: [
                            if (message != null) ...[
                              FeedbackPanel(
                                message: message!,
                                error: messageIsError,
                              ),
                              const SizedBox(height: 16),
                            ],
                            SettingsPanel(
                              icon: Icons.auto_awesome_outlined,
                              title: '连接 AI 助手',
                              subtitle: '选服务、选模型，填入 Key。',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _providers(),
                                  const SizedBox(height: 20),
                                  if (provider == AiProvider.custom) ...[
                                    _addressField(),
                                    const SizedBox(height: 16),
                                  ],
                                  _modelField(),
                                  if (provider == AiProvider.qwen)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: busy
                                            ? null
                                            : () => setState(
                                                () => advanced = true,
                                              ),
                                        icon: const Icon(
                                          Icons.public,
                                          size: 16,
                                        ),
                                        label: Text('${region.label}地域'),
                                      ),
                                    ),
                                  const SizedBox(height: 18),
                                  _keyField(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _advanced(),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (busy) ...[
                              const LinearProgressIndicator(),
                              const SizedBox(height: 12),
                            ],
                            _actions(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    ),
  );

  Widget _providers() => LayoutBuilder(
    builder: (context, size) {
      if (size.maxWidth < 460) {
        return DropdownButtonFormField<AiProvider>(
          key: ValueKey('ai-provider-${provider.name}'),
          initialValue: provider,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'AI 服务'),
          items: [
            for (final value in AiProvider.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: busy
              ? null
              : (value) {
                  if (value != null) _selectProvider(value);
                },
        );
      }
      return Row(
        children: [
          for (final value in AiProvider.values) ...[
            if (value != AiProvider.deepSeek) const SizedBox(width: 12),
            Expanded(
              child: _ProviderTile(
                key: Key('ai-provider-${value.name}'),
                provider: value,
                selected: provider == value,
                onTap: busy ? null : () => _selectProvider(value),
              ),
            ),
          ],
        ],
      );
    },
  );

  Widget _modelField() {
    if (provider == AiProvider.custom) return _customModelField();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(
            'ai-model-choice-${provider.name}-${customModel ? 'custom' : model.text}',
          ),
          initialValue: customModel ? '__custom__' : model.text,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '模型'),
          items: [
            for (final preset in provider.models)
              DropdownMenuItem(value: preset.id, child: Text(preset.label)),
            const DropdownMenuItem(value: '__custom__', child: Text('自定义模型')),
          ],
          onChanged: busy
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    customModel = value == '__custom__';
                    if (!customModel) model.text = value;
                  });
                },
        ),
        if (customModel) ...[const SizedBox(height: 16), _customModelField()],
      ],
    );
  }

  Widget _customModelField() => TextField(
    key: const Key('ai-model'),
    controller: model,
    enabled: !busy,
    autocorrect: false,
    textInputAction: TextInputAction.next,
    decoration: const InputDecoration(
      labelText: '模型 ID',
      hintText: '服务商提供的模型名称',
    ),
  );

  Widget _addressField() => TextField(
    key: const Key('ai-base-url'),
    controller: baseUrl,
    enabled: !busy,
    keyboardType: TextInputType.url,
    textInputAction: TextInputAction.next,
    autocorrect: false,
    onChanged: _editAddress,
    decoration: const InputDecoration(
      labelText: '接口地址（base URL）',
      hintText: 'https://api.example.com/v1',
    ),
  );

  Widget _keyField() => TextField(
    key: const Key('ai-key'),
    controller: key,
    enabled: !busy && !clearKey,
    obscureText: !revealKey,
    autocorrect: false,
    enableSuggestions: false,
    textInputAction: TextInputAction.done,
    decoration: InputDecoration(
      labelText: hasKey ? 'API Key（留空保留）' : 'API Key',
      helperText: clearKey
          ? '保存后删除当前 Key'
          : hasKey
          ? '已保存在本机，可填写新 Key 替换。'
          : provider == AiProvider.custom
          ? '系统安全存储 · 本地服务可留空'
          : '由系统安全存储保存',
      helperMaxLines: 2,
      suffixIcon: IconButton(
        tooltip: revealKey ? '隐藏 Key' : '显示 Key',
        onPressed: busy || clearKey
            ? null
            : () => setState(() => revealKey = !revealKey),
        icon: Icon(
          revealKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    ),
  );

  Widget _advanced() {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('ai-advanced'),
            mouseCursor: WidgetStateMouseCursor.clickable,
            onTap: busy ? null : () => setState(() => advanced = !advanced),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 19, color: colors.onSurfaceVariant),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('高级设置')),
                  Icon(advanced ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (advanced)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider == AiProvider.qwen) ...[
                    DropdownButtonFormField<QwenRegion>(
                      key: ValueKey('ai-qwen-region-${region.name}'),
                      initialValue: region,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Key 所属地域'),
                      items: [
                        for (final value in QwenRegion.values)
                          DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                      ],
                      onChanged: busy
                          ? null
                          : (value) {
                              if (value != null) _selectRegion(value);
                            },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '地域需与 Key 一致，模型以账号可用范围为准。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (provider != AiProvider.custom) ...[
                    _addressField(),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    '兼容 Chat Completions · 本地服务支持 HTTP',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (hasKey)
                    SwitchListTile.adaptive(
                      key: const Key('ai-clear-key'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('删除已保存的 Key'),
                      value: clearKey,
                      onChanged: busy
                          ? null
                          : (value) => setState(() => clearKey = value),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actions() => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      FilledButton.icon(
        key: const Key('save-ai-settings'),
        onPressed: busy ? null : () => _perform(false),
        icon: const Icon(Icons.check, size: 18),
        label: Text(busy && !testing ? '正在保存…' : '保存设置'),
      ),
      OutlinedButton.icon(
        key: const Key('test-ai-settings'),
        onPressed: busy ? null : () => _perform(true),
        icon: const Icon(Icons.link, size: 18),
        label: Text(busy && testing ? '正在连接…' : '测试连接'),
      ),
      if (scope != null && busy && testing)
        TextButton(onPressed: () => scope?.cancel(), child: const Text('取消')),
    ],
  );
}

class _ProviderTile extends StatelessWidget {
  final AiProvider provider;
  final bool selected;
  final VoidCallback? onTap;
  const _ProviderTile({
    super.key,
    required this.provider,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: provider.label,
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: .45)
            : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          mouseCursor: WidgetStateMouseCursor.clickable,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      provider.mark,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: colors.primary),
                    ),
                    const Spacer(),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  provider.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
