import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Gives actionable controls a hand pointer when their native cursor is basic.
/// Placed above the Navigator so menus and built-in pickers follow the same rule.
class AppClickCursor extends SingleChildRenderObjectWidget {
  const AppClickCursor({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderClickCursor();
}

class _RenderClickCursor extends RenderProxyBox
    implements MouseTrackerAnnotation {
  MouseCursor _cursor = MouseCursor.defer;

  @override
  MouseCursor get cursor => _cursor;

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit => null;

  @override
  bool get validForMouseTracker => attached;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;

    // Only the cursor annotation is prioritised. Child hit tests, transforms,
    // pointer handlers and gesture arbitration keep their original order.
    final start = result.path.length;
    result.add(BoxHitTestEntry(this, position));
    hitTestChildren(result, position: position);

    MouseCursor existing = MouseCursor.defer;
    bool? actionable;
    for (final entry in result.path.skip(start + 1)) {
      final target = entry.target;
      if (existing == MouseCursor.defer && target is MouseTrackerAnnotation) {
        existing = (target as MouseTrackerAnnotation).cursor;
      }
      if (actionable != null) continue;
      if (target is RenderSemanticsAnnotations) {
        final properties = target.properties;
        if (properties.enabled == false || properties.textField == true) {
          actionable = false;
        } else if (properties.onTap != null || properties.onLongPress != null) {
          actionable = true;
        }
      } else if (target is RenderSemanticsGestureHandler &&
          (target.onTap != null || target.onLongPress != null)) {
        actionable = true;
      }
    }
    // Explicit text, resize, precision and other specialised cursors win.
    _cursor =
        actionable == true &&
            (existing == MouseCursor.defer ||
                existing == SystemMouseCursors.basic)
        ? SystemMouseCursors.click
        : MouseCursor.defer;
    return true;
  }
}
