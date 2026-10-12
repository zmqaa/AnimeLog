import 'package:flutter/material.dart';

import '../../application/ai_settings.dart';
import '../../application/backup_service.dart';
import '../../core/api/ai_intake.dart';
import '../../core/ai/ai_provider_presets.dart';
import '../shared/app_theme.dart';
import '../shared/appearance_controls.dart';
import 'ai_settings_page.dart';
import 'backup_page.dart';
import 'settings_panel.dart';

class SettingsPage extends StatefulWidget {
  final int animeCount;
  final AiSettings? ai;
  final BackupService? backups;
  const SettingsPage({
    super.key,
    required this.animeCount,
    this.ai,
    this.backups,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AiConfiguration? configuration;
  bool loading = true;
  bool loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final value = await widget.ai?.configurations.load();
      if (mounted) {
        setState(() {
          configuration = value;
          loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadFailed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openAi() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AiSettingsPage(service: widget.ai!)),
    );
    if (mounted) await _loadConfiguration();
  }

  void _openBackups() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        allowSnapshotting: false,
        builder: (_) => BackupPage(service: widget.backups!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: ListView(
          primary: false,
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
          ),
          children: [
            const PageHeading(
              title: '设置',
              subtitle: '按你的习惯，调整外观与录入方式。',
              compact: true,
            ),
            const SettingsPanel(
              icon: Icons.palette_outlined,
              title: '外观',
              child: AppearanceControls(expanded: true),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, size) {
                final panels = [
                  if (widget.ai != null) _aiPanel(context),
                  if (widget.backups != null) _backupPanel(),
                ];
                if (panels.length == 2 && size.maxWidth >= 680) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: panels[0]),
                      const SizedBox(width: 18),
                      Expanded(child: panels[1]),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final panel in panels) ...[
                      panel,
                      const SizedBox(height: 18),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.devices_outlined,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '收藏保存在本机 · ${widget.animeCount} 部动漫',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiPanel(BuildContext context) {
    final configured = configuration != null;
    final status = loading
        ? '读取中'
        : loadFailed
        ? '读取失败'
        : configured
        ? '已保存配置'
        : '未配置';
    return SettingsPanel(
      icon: Icons.auto_awesome_outlined,
      title: 'AI 录入',
      subtitle: 'DeepSeek / Qwen / 自定义',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            configured
                ? '${AiProvider.fromConfiguration(configuration).label} · ${configuration!.model}'
                : '选服务和模型，填 Key 即可。',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(status, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            key: const Key('open-ai-settings'),
            onPressed: _openAi,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('AI 设置'),
          ),
        ],
      ),
    );
  }

  Widget _backupPanel() => SettingsPanel(
    icon: Icons.cloud_download_outlined,
    title: '备份与迁移',
    subtitle: 'JSON 导入与导出',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('备份收藏，或迁移到另一台设备。'),
        const SizedBox(height: 8),
        Text('动漫、漫画与历史记录', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          key: const Key('open-backups'),
          onPressed: _openBackups,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: const Text('备份与迁移'),
        ),
      ],
    ),
  );
}
