import 'package:flutter/material.dart';

class PageStatePanel extends StatelessWidget {
  final String title;
  final String? message;
  final String? details;
  final Widget? action;
  final bool loading;
  final bool error;
  final bool compact;
  const PageStatePanel({
    super.key,
    required this.title,
    this.message,
    this.details,
    this.action,
    this.loading = false,
    this.error = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = error ? theme.colorScheme.error : theme.colorScheme.primary;
    final content = Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: compact
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (!compact && loading) ...[
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
            ),
            const SizedBox(height: 20),
          ],
          if (compact)
            Text(title, style: theme.textTheme.titleSmall)
          else
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: compact ? TextAlign.start : TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ],
          if (loading && compact) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
          if (details != null) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              title: Text('查看错误详情', style: theme.textTheme.bodySmall),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                SelectableText(details!, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ],
      ),
    );
    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    }
    return Center(
      child: SingleChildScrollView(
        primary: false,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: content,
          ),
        ),
      ),
    );
  }
}
