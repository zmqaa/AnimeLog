import 'package:flutter/material.dart';

import 'app_appearance.dart';
import 'app_theme.dart';

class AppearanceControls extends StatelessWidget {
  final bool expanded;
  const AppearanceControls({super.key, this.expanded = false});

  Future<void> _save(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(context, error: true, content: Text('外观未保存：$error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance == null) return const SizedBox.shrink();
    if (expanded) return _expanded(context, appearance);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('主题色', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final accent in AppAccent.values)
              Semantics(
                button: true,
                selected: appearance.accent == accent,
                label: accent.label,
                child: Tooltip(
                  message: accent.label,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      mouseCursor: WidgetStateMouseCursor.clickable,
                      key: Key('accent-${accent.name}'),
                      customBorder: const CircleBorder(),
                      onTap: appearance.saving
                          ? null
                          : () => _save(
                              context,
                              () => appearance.selectAccent(accent),
                            ),
                      child: Container(
                        width: 34,
                        height: 34,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: appearance.accent == accent
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent.seed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mode in [ThemeMode.light, ThemeMode.dark])
              ChoiceChip(
                mouseCursor: WidgetStateMouseCursor.clickable,
                key: Key('appearance-${mode.name}'),
                label: Text(mode == ThemeMode.light ? '浅色' : '深色'),
                selected: appearance.mode == mode,
                showCheckmark: false,
                onSelected: appearance.saving
                    ? null
                    : (_) => _save(context, () => appearance.select(mode)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _expanded(BuildContext context, AppAppearance appearance) {
    final modes = Row(
      children: [
        for (final mode in [ThemeMode.light, ThemeMode.dark]) ...[
          if (mode == ThemeMode.dark) const SizedBox(width: 12),
          Expanded(
            child: _AppearanceModeTile(
              key: Key('appearance-${mode.name}'),
              mode: mode,
              accent: appearance.accent.seed,
              selected: appearance.mode == mode,
              onTap: appearance.saving
                  ? null
                  : () => _save(context, () => appearance.select(mode)),
            ),
          ),
        ],
      ],
    );
    final accents = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('主题色', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final accent in AppAccent.values)
              ChoiceChip(
                key: Key('accent-${accent.name}'),
                mouseCursor: WidgetStateMouseCursor.clickable,
                avatar: CircleAvatar(backgroundColor: accent.seed, radius: 8),
                label: Text(accent.label),
                selected: appearance.accent == accent,
                showCheckmark: false,
                onSelected: appearance.saving
                    ? null
                    : (_) =>
                          _save(context, () => appearance.selectAccent(accent)),
              ),
          ],
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, size) => size.maxWidth >= 670
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: modes),
                const SizedBox(width: 28),
                Expanded(flex: 3, child: accents),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [modes, const SizedBox(height: 20), accents],
            ),
    );
  }
}

class _AppearanceModeTile extends StatelessWidget {
  final ThemeMode mode;
  final Color accent;
  final bool selected;
  final VoidCallback? onTap;
  const _AppearanceModeTile({
    super.key,
    required this.mode,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = mode == ThemeMode.dark;
    final background = dark ? const Color(0xff15211f) : const Color(0xfff5f8f7);
    final panel = dark ? const Color(0xff293632) : Colors.white;
    final label = dark ? '深色' : '浅色';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: .35)
            : colors.surface,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  height: 62,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 7),
                      for (var index = 0; index < 2; index++) ...[
                        if (index == 1) const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: panel,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: accent.withValues(
                                    alpha: index == 0 ? .8 : .4,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
