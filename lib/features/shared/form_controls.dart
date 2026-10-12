import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Short choices stay visible and wrap when space or text size changes.
class FormChoice<T> {
  final T value;
  final String label;
  const FormChoice(this.value, this.label);
}

class ChoiceField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<FormChoice<T>> choices;
  final ValueChanged<T>? onChanged;
  const ChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.choices,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final choice in choices)
            ChoiceChip(
              label: Text(choice.label),
              selected: value == choice.value,
              mouseCursor: WidgetStateMouseCursor.clickable,
              onSelected: onChanged == null
                  ? null
                  : (_) {
                      if (value == choice.value) return;
                      HapticFeedback.selectionClick();
                      onChanged!(choice.value);
                    },
            ),
        ],
      ),
    ],
  );
}

class FormRow extends StatelessWidget {
  final List<Widget> children;
  final double runSpacing;
  const FormRow({super.key, required this.children, this.runSpacing = 16});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final minimum = 180 * MediaQuery.textScalerOf(context).scale(1);
      if (size.maxWidth <
          minimum * children.length + 16 * (children.length - 1)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in children.indexed) ...[
              if (item.$1 > 0) SizedBox(height: runSpacing),
              item.$2,
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in children.indexed) ...[
            if (item.$1 > 0) const SizedBox(width: 16),
            Expanded(child: item.$2),
          ],
        ],
      );
    },
  );
}

class IntegerInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int minimum;
  final int? maximum;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  const IntegerInput({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.minimum = 0,
    this.maximum,
    this.errorText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final number = int.tryParse(controller.text.trim());
      void step(int delta) {
        final next = (number ?? minimum) + delta;
        controller.text =
            '${next.clamp(minimum, maximum ?? math.max(minimum, next))}';
        HapticFeedback.selectionClick();
      }

      return TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '$label减一',
                onPressed: enabled && number != null && number > minimum
                    ? () => step(-1)
                    : null,
                icon: const Icon(Icons.remove_rounded, size: 18),
              ),
              IconButton(
                tooltip: '$label加一',
                onPressed:
                    enabled &&
                        (maximum == null || (number ?? minimum) < maximum!)
                    ? () => step(1)
                    : null,
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Pending input is mirrored into the draft, including before the user presses Enter.
class TokenInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  const TokenInput({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
  });

  @override
  State<TokenInput> createState() => _TokenInputState();
}

class _TokenInputState extends State<TokenInput> {
  final input = TextEditingController();
  final focus = FocusNode();
  late List<String> tokens = _split(widget.controller.text);
  bool writing = false;

  List<String> _split(String value) => value
      .split(RegExp('[,，\\n]'))
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty)
      .toSet()
      .toList();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_externalChanged);
    focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(TokenInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_externalChanged);
      widget.controller.addListener(_externalChanged);
      tokens = _split(widget.controller.text);
      input.clear();
    }
  }

  void _externalChanged() {
    if (writing) return;
    setState(() {
      tokens = _split(widget.controller.text);
      input.clear();
    });
  }

  void _focusChanged() {
    if (!focus.hasFocus && input.text.trim().isNotEmpty) {
      _commit();
    } else {
      setState(() {});
    }
  }

  void _write() {
    writing = true;
    final value = {...tokens, ..._split(input.text)}.join('，');
    if (widget.controller.text != value) widget.controller.text = value;
    writing = false;
  }

  void _commit() {
    setState(() {
      tokens = {...tokens, ..._split(input.text)}.toList();
      input.clear();
    });
    _write();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_externalChanged);
    focus.removeListener(_focusChanged);
    focus.dispose();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InputDecorator(
    isFocused: focus.hasFocus,
    isEmpty: tokens.isEmpty && input.text.isEmpty,
    decoration: InputDecoration(
      labelText: widget.label,
      enabled: widget.enabled,
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),
    child: LayoutBuilder(
      builder: (context, size) => Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final token in tokens)
            InputChip(
              label: Text(token),
              isEnabled: widget.enabled,
              mouseCursor: WidgetStateMouseCursor.clickable,
              onDeleted: !widget.enabled
                  ? null
                  : () {
                      setState(() => tokens.remove(token));
                      _write();
                    },
            ),
          SizedBox(
            width: math.min(size.maxWidth, 220),
            child: TextField(
              controller: input,
              focusNode: focus,
              enabled: widget.enabled,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: tokens.isEmpty ? '输入后按回车或逗号添加' : '继续添加…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                if (value.contains(RegExp('[,，\\n]'))) {
                  _commit();
                } else {
                  _write();
                }
              },
              onSubmitted: (_) => _commit(),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<T?> showFormPanel<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: builder,
    );
  }
  return showDialog<T>(context: context, builder: builder);
}

/// Keeps the title and actions visible while the form scrolls above the keyboard.
class FormPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback onSave;
  final String saveLabel;
  final Key? saveKey;
  final double width;
  const FormPanel({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.subtitle,
    this.saveLabel = '保存',
    this.saveKey,
    this.width = 640,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final colors = Theme.of(context).colorScheme;
    final insets = MediaQuery.viewInsetsOf(context);
    final available = math.max(
      0.0,
      MediaQuery.sizeOf(context).height -
          insets.bottom -
          MediaQuery.viewPaddingOf(context).vertical -
          (compact ? 16 : 64),
    );
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: available, maxWidth: width),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          key: saveKey,
                          onPressed: onSave,
                          child: Text(saveLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final shortcuts = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): onSave,
      },
      child: content,
    );
    if (!compact) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: shortcuts,
      );
    }
    return AnimatedPadding(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: shortcuts,
    );
  }
}
