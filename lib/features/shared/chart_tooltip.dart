import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/domain/library_statistics.dart';

String statisticTooltip(StatisticBucket bucket, {String unit = '集'}) =>
    '${bucket.periodLabel ?? bucket.label}\n'
    '${bucket.workCount == null ? '' : '${bucket.workCount} 部作品 · '}${bucket.count} $unit';

class _ChartTooltipCoordinator {
  static _ChartHoverRegionState? active;
  static bool routeInstalled = false;

  static void ensurePointerRoute() {
    if (routeInstalled) return;
    routeInstalled = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  static void activate(_ChartHoverRegionState state) {
    final previous = active;
    if (previous != null && !identical(previous, state)) {
      previous._hideInternal();
    }
    active = state;
  }

  static void deactivate(_ChartHoverRegionState state) {
    if (identical(active, state)) active = null;
  }

  static void _handlePointerEvent(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    final state = active;
    if (state == null || state._containsGlobalPoint(event.position)) return;
    deactivate(state);
    state._hideInternal();
  }
}

/// A pointer-following tooltip also available by tapping or holding on touch screens.
class ChartHoverRegion extends StatefulWidget {
  final String message;
  final Widget child;
  final bool highlight;
  final MouseCursor cursor;
  final ValueChanged<Offset?>? onPositionChanged;
  const ChartHoverRegion({
    super.key,
    required this.message,
    required this.child,
    this.highlight = true,
    this.cursor = SystemMouseCursors.basic,
    this.onPositionChanged,
  });

  @override
  State<ChartHoverRegion> createState() => _ChartHoverRegionState();
}

class _ChartHoverRegionState extends State<ChartHoverRegion> {
  final portal = OverlayPortalController();
  Offset position = Offset.zero;
  Timer? dismissTimer;
  bool active = false;

  @override
  void initState() {
    super.initState();
    _ChartTooltipCoordinator.ensurePointerRoute();
  }

  void _show(Offset point) {
    _ChartTooltipCoordinator.activate(this);
    _showInternal(point);
  }

  void _showInternal(Offset point) {
    dismissTimer?.cancel();
    widget.onPositionChanged?.call(point);
    if (!mounted) return;
    setState(() {
      position = point;
      active = true;
    });
    if (!portal.isShowing) portal.show();
  }

  void _hide() {
    _ChartTooltipCoordinator.deactivate(this);
    _hideInternal();
  }

  void _hideInternal() {
    dismissTimer?.cancel();
    if (!mounted) return;
    widget.onPositionChanged?.call(null);
    if (portal.isShowing) portal.hide();
    if (active) setState(() => active = false);
  }

  bool _containsGlobalPoint(Offset globalPoint) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final localPoint = renderObject.globalToLocal(globalPoint);
    return renderObject.size.contains(localPoint);
  }

  void _dismissLater() {
    dismissTimer?.cancel();
    dismissTimer = Timer(const Duration(seconds: 4), _hide);
  }

  @override
  void dispose() {
    _ChartTooltipCoordinator.deactivate(this);
    dismissTimer?.cancel();
    super.dispose();
  }

  Widget _popup(BuildContext overlayContext) {
    if (widget.message.isEmpty) return const SizedBox.shrink();
    final anchor = context.findRenderObject();
    final overlay = Overlay.of(context).context.findRenderObject();
    if (anchor is! RenderBox ||
        !anchor.hasSize ||
        overlay is! RenderBox ||
        !overlay.hasSize) {
      return const SizedBox.shrink();
    }
    final point = anchor.localToGlobal(position, ancestor: overlay);
    final bounds = overlay.size;
    final colors = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final width = math.min(
      260.0 * scaler.scale(1),
      math.max(0.0, bounds.width - 24),
    );
    final style = Theme.of(context).textTheme.bodySmall!.copyWith(
      color: colors.onSurface,
      fontSize: 13,
      height: 1.5,
      fontWeight: FontWeight.w500,
    );
    final measure = TextPainter(
      text: TextSpan(text: widget.message, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout(maxWidth: math.max(0, width - 24));
    final height = math.min(
      measure.height + 24,
      math.max(0.0, bounds.height - 24),
    );
    measure.dispose();
    final left = (point.dx + 14).clamp(
      12.0,
      math.max(12.0, bounds.width - width - 12),
    );
    final below = point.dy + 18;
    final top =
        (below + height <= bounds.height - 12 ? below : point.dy - height - 14)
            .clamp(12.0, math.max(12.0, bounds.height - height - 12));
    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      width: width,
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          child: Material(
            elevation: 6,
            shadowColor: colors.shadow.withValues(alpha: .2),
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: height),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(widget.message, style: style),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: portal,
    overlayChildBuilder: _popup,
    child: MouseRegion(
      cursor: widget.cursor,
      onEnter: (event) => _show(event.localPosition),
      onHover: (event) => _show(event.localPosition),
      onExit: (_) => _hide(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _show(details.localPosition),
        onTapUp: (_) => _dismissLater(),
        onTapCancel: _hide,
        onLongPressStart: (details) => _show(details.localPosition),
        onLongPressEnd: (_) => _dismissLater(),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 120),
          foregroundDecoration: widget.highlight
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                )
              : null,
          child: widget.child,
        ),
      ),
    ),
  );
}
