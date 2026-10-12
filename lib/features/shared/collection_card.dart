import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;

import '../../core/api/ai_intake.dart';
import 'anime_cover.dart';

const collectionCardSpacing = 16.0;

/// Poster columns retain readable widths when system text is enlarged.
int collectionColumns(BuildContext context, double width) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  final minimum = MediaQuery.sizeOf(context).width < 600
      ? 280.0 * scale
      : scale > 1.3
      ? 250.0 * scale
      : 164.0 * scale;
  return math.max(
    1,
    math.min(
      5,
      ((width + collectionCardSpacing) / (minimum + collectionCardSpacing))
          .floor(),
    ),
  );
}

/// Size two desktop rows after the header, reserving room for pagination.
double? collectionCardHeight(
  BuildContext context,
  SliverConstraints constraints,
  int columns,
) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  if (columns != 5 || scale > 1.3) return null;
  final available =
      constraints.viewportMainAxisExtent - constraints.precedingScrollExtent;
  final height = (available - 120) / 2 - collectionCardSpacing;
  final minimum = 224.0 * scale;
  if (height < minimum) return null;
  return height.clamp(minimum, 420.0 * scale);
}

class CollectionFilters extends StatelessWidget {
  final Widget search;
  final Widget filters;

  const CollectionFilters({
    super.key,
    required this.search,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      if (size.maxWidth >= 900 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
        return Row(
          children: [
            SizedBox(width: math.min(300, size.maxWidth * .28), child: search),
            const SizedBox(width: 16),
            Expanded(child: filters),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [search, const SizedBox(height: 12), filters],
      );
    },
  );
}

double collectionActionHeight(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600 ? 44 : 36;

enum CollectionView { posters, list }

class CollectionViewPicker extends StatelessWidget {
  final CollectionView selected;
  final ValueChanged<CollectionView> onChanged;
  const CollectionViewPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SegmentedButton<CollectionView>(
    selected: {selected},
    showSelectedIcon: false,
    style: SegmentedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      textStyle: Theme.of(context).textTheme.labelMedium,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    segments: const [
      ButtonSegment(
        value: CollectionView.posters,
        label: Text('封面'),
        tooltip: '封面卡片',
      ),
      ButtonSegment(
        value: CollectionView.list,
        label: Text('列表'),
        tooltip: '紧凑列表',
      ),
    ],
    onSelectionChanged: (value) => onChanged(value.single),
  );
}

class CollectionListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final CoverStore? covers;
  final VoidCallback onTap;
  final Key? tapKey;
  final List<Widget> badges;
  final Widget footer;
  const CollectionListCard({
    super.key,
    required this.title,
    required this.onTap,
    required this.badges,
    required this.footer,
    this.subtitle,
    this.coverUrl,
    this.covers,
    this.tapKey,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      mouseCursor: WidgetStateMouseCursor.clickable,
      key: tapKey,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimeCover(
              title: title,
              url: coverUrl,
              store: covers,
              width: 54,
              height: 76,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: badges),
                  const SizedBox(height: 8),
                  footer,
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CollectionCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? summary;
  final String? coverUrl;
  final CoverStore? covers;
  final String status;
  final String? publicationLabel;
  final VoidCallback onTap;
  final Widget progress;
  final Widget actions;
  final Key? tapKey;
  final double? height;
  const CollectionCard({
    super.key,
    required this.title,
    required this.status,
    required this.onTap,
    required this.progress,
    required this.actions,
    this.subtitle,
    this.summary,
    this.coverUrl,
    this.covers,
    this.publicationLabel,
    this.tapKey,
    this.height,
  });
  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 160);
    return Padding(
      padding: const EdgeInsets.only(bottom: collectionCardSpacing),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: AnimatedScale(
          scale: hovered ? 1.012 : 1,
          duration: duration,
          child: AnimatedContainer(
            duration: duration,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: hovered ? .1 : .025),
                  blurRadius: hovered ? 22 : 8,
                  offset: Offset(0, hovered ? 8 : 3),
                ),
              ],
            ),
            child: Material(
              color: hovered ? colors.surfaceContainerHigh : colors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: hovered
                      ? colors.primary.withValues(alpha: .5)
                      : colors.outlineVariant,
                ),
              ),
              child: InkWell(
                key: widget.tapKey,
                mouseCursor: WidgetStateMouseCursor.clickable,
                onTap: widget.onTap,
                hoverColor: colors.primary.withValues(alpha: .04),
                splashColor: colors.primary.withValues(alpha: .12),
                highlightColor: colors.primary.withValues(alpha: .06),
                child: _posterContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _posterContent(BuildContext context) {
    final body = _information(context);
    if (widget.height != null) {
      return SizedBox(
        height: widget.height,
        child: Column(
          children: [
            Expanded(child: _posterHeader(context)),
            body,
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, size) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        return Column(
          children: [
            SizedBox(
              height: (size.maxWidth * 1.25).clamp(180 * scale, 300 * scale),
              child: _posterHeader(context),
            ),
            body,
          ],
        );
      },
    );
  }

  Widget _information(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = widget.summary?.trim().replaceAll(RegExp(r'\s+'), ' ');
    final style = (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
        .copyWith(
          color: colors.onSurfaceVariant,
          fontSize: MediaQuery.sizeOf(context).width < 600 ? 12 : 11,
          height: 1.5,
        );
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.progress,
          const SizedBox(height: 8),
          SizedBox(
            height:
                MediaQuery.textScalerOf(context).scale(style.fontSize!) *
                style.height! *
                2,
            child: Text(
              summary == null || summary.isEmpty ? '暂无简介' : summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const SizedBox(height: 8),
          widget.actions,
        ],
      ),
    );
  }

  Widget _posterHeader(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final subtitle = widget.subtitle?.trim();
      final showSubtitle =
          size.maxHeight >= 140 * scale &&
          subtitle != null &&
          subtitle.isNotEmpty;
      return Stack(
        fit: StackFit.expand,
        children: [
          AnimeCover(
            title: widget.title,
            url: widget.coverUrl,
            store: widget.covers,
            width: size.maxWidth,
            height: size.maxHeight,
            borderRadius: BorderRadius.zero,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .08),
                  Colors.black.withValues(alpha: .04),
                  Colors.black.withValues(alpha: .88),
                ],
                stops: const [0, .35, 1],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _badge(context, widget.status, primary: true),
                if (size.maxHeight >= 130 * scale &&
                    widget.publicationLabel != null)
                  _badge(context, widget.publicationLabel!),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: size.maxHeight >= 170 * scale ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                if (showSubtitle) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: .75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _badge(BuildContext context, String label, {bool primary = false}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary
              ? colors.primary.withValues(alpha: .3)
              : colors.outlineVariant,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: primary ? colors.primary : colors.onSurface,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CollectionProgress extends StatelessWidget {
  final String label;
  final String value;
  final double? fraction;
  const CollectionProgress({
    super.key,
    required this.label,
    required this.value,
    this.fraction,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: value,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 11, height: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: fraction?.clamp(0.0, 1.0) ?? 0,
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    ),
  );
}
