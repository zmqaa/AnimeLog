import 'package:flutter/material.dart';

import 'app_appearance.dart';

ThemeData animeLogTheme({
  Brightness brightness = Brightness.light,
  AppAccent accent = AppAccent.teal,
}) {
  final dark = brightness == Brightness.dark;
  final seeded = ColorScheme.fromSeed(
    seedColor: accent.seed,
    brightness: brightness,
  );
  final teal = accent == AppAccent.teal;
  final colors =
      ColorScheme.fromSeed(
        seedColor: accent.seed,
        brightness: brightness,
      ).copyWith(
        primary: teal
            ? (dark ? const Color(0xff7bd8bc) : accent.seed)
            : seeded.primary,
        onPrimary: teal
            ? (dark ? const Color(0xff07382d) : Colors.white)
            : seeded.onPrimary,
        primaryContainer: !teal
            ? seeded.primaryContainer
            : dark
            ? const Color(0xff183c34)
            : const Color(0xffe2f3ed),
        onPrimaryContainer: !teal
            ? seeded.onPrimaryContainer
            : dark
            ? const Color(0xffa2e6cf)
            : const Color(0xff145345),
        surface: dark ? const Color(0xff192220) : Colors.white,
        onSurface: dark ? const Color(0xffe5eeea) : const Color(0xff202d29),
        onSurfaceVariant: dark
            ? const Color(0xffa2b4ac)
            : const Color(0xff65766e),
        surfaceContainerLowest: dark ? const Color(0xff111916) : Colors.white,
        surfaceContainerLow: dark
            ? const Color(0xff16201c)
            : const Color(0xfff8faf9),
        surfaceContainer: dark
            ? const Color(0xff202c26)
            : const Color(0xfff0f4f2),
        surfaceContainerHigh: dark
            ? const Color(0xff28362f)
            : const Color(0xffeaf0ec),
        surfaceContainerHighest: dark
            ? const Color(0xff324239)
            : const Color(0xffe3eae6),
        outline: dark ? const Color(0xff789087) : const Color(0xff889c93),
        outlineVariant: dark
            ? const Color(0xff304239)
            : const Color(0xffe1e8e4),
      );
  final background = dark ? const Color(0xff101815) : const Color(0xfff4f7f5);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  );
  final cursor = WidgetStateProperty.resolveWith<MouseCursor>(
    (states) => states.contains(WidgetState.disabled)
        ? SystemMouseCursors.basic
        : SystemMouseCursors.click,
  );
  ButtonStyle feedback(Color foreground) => ButtonStyle(
    mouseCursor: cursor,
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    animationDuration: const Duration(milliseconds: 160),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return foreground.withValues(alpha: .14);
      }
      if (states.contains(WidgetState.focused)) {
        return foreground.withValues(alpha: .14);
      }
      if (states.contains(WidgetState.hovered)) {
        return foreground.withValues(alpha: .08);
      }
      return null;
    }),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    scaffoldBackgroundColor: background,
    hoverColor: colors.primary.withValues(alpha: .07),
    focusColor: colors.primary.withValues(alpha: .14),
    highlightColor: colors.primary.withValues(alpha: .06),
    splashColor: colors.primary.withValues(alpha: .12),
    fontFamily: 'Microsoft YaHei',
    fontFamilyFallback: const ['Noto Sans CJK SC', 'sans-serif'],
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.6, color: colors.onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: colors.onSurface),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.5,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.onSurfaceVariant,
      ),
      labelSmall: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
    ),
    iconTheme: IconThemeData(color: colors.onSurfaceVariant, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: colors.onSurface,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: colors.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .8)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: border.copyWith(borderSide: BorderSide(color: colors.error)),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      disabledBorder: border,
      hoverColor: colors.primary.withValues(alpha: .035),
      alignLabelWithHint: true,
      labelStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
      floatingLabelStyle: TextStyle(
        color: colors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
      helperMaxLines: 3,
      errorMaxLines: 3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).merge(feedback(colors.onPrimary)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).merge(feedback(colors.primary)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).merge(feedback(colors.primary)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).merge(feedback(colors.primary)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        mouseCursor: cursor,
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surface,
      selectedColor: colors.primaryContainer,
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? colors.primary.withValues(alpha: .35)
              : colors.outlineVariant,
        ),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: colors.onSurface,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: colors.surface,
      indicatorColor: colors.primaryContainer,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colors.onSurfaceVariant,
      mouseCursor: cursor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    checkboxTheme: CheckboxThemeData(
      mouseCursor: cursor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    switchTheme: SwitchThemeData(mouseCursor: cursor),
    expansionTileTheme: ExpansionTileThemeData(
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: colors.primary,
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    popupMenuTheme: PopupMenuThemeData(
      mouseCursor: cursor,
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 400),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.surfaceContainerHigh,
      contentTextStyle: TextStyle(
        color: colors.onSurface,
        fontSize: 13,
        height: 1.5,
      ),
      actionTextColor: colors.primary,
      disabledActionTextColor: colors.onSurfaceVariant,
      elevation: 3,
      insetPadding: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: colors.outlineVariant),
  );
}

/// Compact, responsive feedback shared by every page. Keep the native snackbar
/// lifecycle, accessibility announcements and action handling.
SnackBar appSnackBar(
  BuildContext context, {
  required Widget content,
  SnackBarAction? action,
  Duration? duration,
  bool error = false,
}) {
  final media = MediaQuery.of(context);
  final colors = Theme.of(context).colorScheme;
  final availableWidth = media.size.width - media.padding.horizontal - 32;
  final preferredWidth = media.textScaler.scale(440).clamp(440.0, 560.0);
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    width: availableWidth.clamp(1.0, preferredWidth),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    duration: duration ?? Duration(seconds: error || action != null ? 6 : 3),
    action: action,
    actionOverflowThreshold: .35,
    content: Row(
      children: [
        Icon(
          error
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          size: 20,
          color: error ? colors.error : colors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(child: content),
      ],
    ),
  );
}

class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? action;
  final bool collapsible;
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.action,
    this.collapsible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (collapsible) {
      return Card(
        child: ExpansionTile(
          key: PageStorageKey('section-$title'),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (action != null) ...[const SizedBox(width: 8), action!],
            ],
          ),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          childrenPadding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 18 : 22,
            4,
            MediaQuery.sizeOf(context).width < 600 ? 18 : 22,
            22,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 18 : 22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (action != null) ...[const SizedBox(width: 8), action!],
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final bool compact;
  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: compact
          ? 16
          : MediaQuery.sizeOf(context).width < 600
          ? 20
          : 28,
    ),
    child: LayoutBuilder(
      builder: (context, size) {
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: compact || MediaQuery.sizeOf(context).width < 600
                  ? Theme.of(context).textTheme.headlineSmall
                  : Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: compact ? 6 : 10),
            Text(
              subtitle,
              style:
                  (compact
                          ? Theme.of(context).textTheme.bodySmall
                          : Theme.of(context).textTheme.bodyMedium)
                      ?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
            ),
          ],
        );
        if (size.maxWidth < 460 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            if (action != null) ...[const SizedBox(width: 24), action!],
          ],
        );
      },
    ),
  );
}

class SectionHeading extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionHeading({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final text = Text(title, style: Theme.of(context).textTheme.titleLarge);
      if (size.maxWidth < 440 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.4) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            text,
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: text),
          if (action != null) ...[const SizedBox(width: 24), action!],
        ],
      );
    },
  );
}

class RecordBadge extends StatelessWidget {
  final String label;
  final Color? color;
  const RecordBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackPanel extends StatelessWidget {
  final String message;
  final bool error;
  const FeedbackPanel({super.key, required this.message, this.error = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: error ? colors.errorContainer : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: SelectableText(
                message,
                style: TextStyle(
                  color: error
                      ? colors.onErrorContainer
                      : colors.onSecondaryContainer,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
