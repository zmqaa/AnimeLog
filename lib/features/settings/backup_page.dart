import 'package:flutter/material.dart';

import '../../application/backup_service.dart';
import '../../core/backup/backup_document.dart';
import 'backup_controller.dart';
import '../shared/app_theme.dart';

class BackupPage extends StatefulWidget {
  final BackupService service;
  const BackupPage({super.key, required this.service});
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  late final c = BackupController(widget.service);
  final previewAnchor = GlobalKey();
  final noticeAnchor = GlobalKey();

  @override
  void initState() {
    super.initState();
    c.addListener(_focusResult);
  }

  void _focusResult() {
    if (c.busy) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || c.busy) return;
      final target = c.prepared != null
          ? previewAnchor.currentContext
          : noticeAnchor.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  @override
  void dispose() {
    c.removeListener(_focusResult);
    c.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final preview = c.prepared;
    if (preview == null) return;
    final replace = preview.preview.mode == ImportMode.replace;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(replace ? '确认完整恢复？' : '确认追加导入？'),
        content: Text(
          replace
              ? '将替换本机 ${preview.preview.replacedAnime} 条动漫、${preview.preview.replacedManga} 条漫画、${preview.preview.replacedHistory} 条历史和 ${preview.preview.replacedNotes} 条备注。恢复前的本机快照已保存。'
              : '将新增 ${preview.preview.newAnime} 条动漫、${preview.preview.newManga} 条漫画及其历史和备注，跳过 ${preview.preview.skippedAnime} 条已有动漫和 ${preview.preview.skippedManga} 条已有漫画。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回预览'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(replace ? '确认替换并恢复' : '确认追加'),
          ),
        ],
      ),
    );
    if (accepted == true) await c.commit();
  }

  Future<void> _snapshots() async {
    try {
      final names = await widget.service.files.safetySnapshots();
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('恢复前的本机快照'),
          content: SizedBox(
            width: 500,
            child: names.isEmpty
                ? const Text('还没有恢复前快照。')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final name in names)
                        ListTile(
                          title: Text(
                            name
                                .replaceFirst('AnimeLog-before-restore-', '')
                                .split('Z-')
                                .first
                                .replaceFirst('T', ' '),
                          ),
                          subtitle: const Text('选择后预览完整恢复范围'),
                          onTap: () => Navigator.pop(context, name),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      );
      if (selected != null) await c.loadSafetySnapshot(selected);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(context, error: true, content: Text('快照读取失败：$error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => PopScope(
      canPop: !c.busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('备份与迁移')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const PageHeading(
                    title: '给收藏留一份备份',
                    subtitle: '用 JSON 保存完整动漫、漫画、观看历史和备注，也可以搬移到另一台设备。',
                  ),
                  SectionCard(
                    title: '导出收藏',

                    subtitle: '导出全部记录，不受动漫库当前筛选影响。',
                    children: [
                      FilledButton(
                        key: const Key('export-backup'),
                        onPressed: c.busy ? null : c.exportAll,
                        child: const Text('导出全部数据'),
                      ),
                    ],
                  ),
                  SectionCard(
                    title: '追加到本机',

                    subtitle: '合并两个收藏时使用，已有记录保留。',
                    children: [
                      OutlinedButton(
                        key: const Key('append-backup'),
                        onPressed: c.busy
                            ? null
                            : () => c.pick(ImportMode.append),
                        child: const Text('追加导入 JSON'),
                      ),
                      const SizedBox(height: 12),
                      const Text('跳过已存在的记录及其历史与备注，同名的独立记录仍分别导入。'),
                    ],
                  ),
                  SectionCard(
                    title: '完整恢复',

                    subtitle: '使用备份替换本机全部记录，适合恢复或搬家。',
                    children: [
                      OutlinedButton(
                        key: const Key('restore-backup'),
                        onPressed: c.busy
                            ? null
                            : () => c.pick(ImportMode.replace),
                        child: const Text('从 JSON 完整恢复'),
                      ),
                      const SizedBox(height: 12),
                      const Text('确认前会显示替换范围并自动保存本机快照，取消预览不会更改记录。'),
                      const SizedBox(height: 12),
                      TextButton(
                        key: const Key('safety-snapshots'),
                        onPressed: c.busy ? null : _snapshots,
                        child: const Text('恢复前的本机快照'),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '支持 AnimeLog v1 和 AnimeTrack v5；单个文件最大 50 MiB。API Key、接口设置、外观和本机缓存不进入备份。',
                    ),
                  ),
                  if (c.busy)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (c.error != null)
                    Padding(
                      key: noticeAnchor,
                      padding: const EdgeInsets.only(top: 16),
                      child: FeedbackPanel(message: c.error!, error: true),
                    ),
                  if (c.message != null)
                    Padding(
                      key: c.error == null ? noticeAnchor : null,
                      padding: const EdgeInsets.only(top: 16),
                      child: FeedbackPanel(message: c.message!),
                    ),
                  if (c.prepared != null) _preview(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _preview() {
    final prepared = c.prepared!;
    final p = prepared.preview;
    return Card(
      key: previewAnchor,
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('导入预览', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(prepared.fileName),
            Text(
              '文件：${prepared.document.anime.length} 条动漫，${prepared.document.manga.length} 条漫画，${prepared.document.history.length} 条历史，${prepared.document.notes.length} 条备注',
            ),
            Text(
              '将新增：${p.newAnime} 条动漫，${p.newManga} 条漫画，${p.newHistory} 条历史，${p.newNotes} 条备注',
            ),
            Text('将跳过：${p.skippedAnime} 条已有动漫、${p.skippedManga} 条已有漫画及其整组数据'),
            if (p.filledCast > 0)
              Text('将补充：${p.filledCast} 条已有动漫的声优资料（只填入空字段）'),
            if (p.mode == ImportMode.replace)
              Text(
                '将替换本机：${p.replacedAnime} 条动漫，${p.replacedManga} 条漫画，${p.replacedHistory} 条历史，${p.replacedNotes} 条备注',
              ),
            if (prepared.document.repairedTags > 0)
              Text('已按明确刷次修正 ${prepared.document.repairedTags} 条记录的刷次标签。'),
            for (final warning in prepared.document.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(warning),
              ),
            if (prepared.safetySnapshot != null) ...[
              const SizedBox(height: 12),
              const Text('恢复前快照已保存，可通过“恢复前的本机快照”再次恢复。'),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: c.busy ? null : c.cancelPreview,
                  child: const Text('取消导入'),
                ),
                FilledButton(
                  key: const Key('confirm-backup'),
                  onPressed: c.busy ? null : _confirm,
                  child: const Text('确认导入'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
