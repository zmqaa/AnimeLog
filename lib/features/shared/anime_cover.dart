import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api/ai_intake.dart';

class AnimeCover extends StatefulWidget {
  final String? url;
  final CoverStore? store;
  final double width;
  final double height;
  final String? title;
  final BorderRadius borderRadius;
  const AnimeCover({
    super.key,
    this.url,
    this.store,
    this.width = 60,
    this.height = 84,
    this.title,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });
  @override
  State<AnimeCover> createState() => _AnimeCoverState();
}

class _AnimeCoverState extends State<AnimeCover> {
  Future<Uint8List?>? future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AnimeCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.store != widget.store) _load();
  }

  void _load() {
    future = widget.url == null ? null : widget.store?.load(widget.url!);
  }

  Widget placeholder() {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHigh,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.width < 80 ? '暂无\n封面' : '暂无封面',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget remote() => widget.url == null
      ? placeholder()
      : Image.network(
          widget.url!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder(),
        );
  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    height: widget.height,
    child: ClipRRect(
      borderRadius: widget.borderRadius,
      child: future == null
          ? remote()
          : FutureBuilder<Uint8List?>(
              future: future,
              builder: (context, snapshot) =>
                  snapshot.connectionState != ConnectionState.done
                  ? placeholder()
                  : snapshot.data == null
                  ? remote()
                  : Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => remote(),
                    ),
            ),
    ),
  );
}
