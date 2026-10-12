import 'package:flutter/material.dart';

class DateInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool quickDates;
  final FormFieldValidator<String>? validator;
  const DateInput({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.quickDates = false,
    this.validator,
  });

  @override
  State<DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<DateInput> {
  bool typing = false;
  late final focus = FocusNode();

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  Future<void> _pick(BuildContext context) async {
    final first = DateTime(1900);
    final last = DateTime(2200, 12, 31);
    focus.unfocus();
    final controller = widget.controller;
    var initial = DateTime.tryParse(controller.text.trim()) ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: widget.label,
      cancelText: '取消',
      confirmText: '确定',
      fieldLabelText: '日期',
      fieldHintText: '年/月/日',
      errorInvalidText: '日期超出可选范围',
      errorFormatText: '请输入有效日期',
    );
    if (picked != null && mounted && widget.enabled) {
      controller.text = picked.toIso8601String().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final readOnly = compact && !typing;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: focus,
            enabled: widget.enabled,
            readOnly: readOnly,
            showCursor: !readOnly,
            mouseCursor: readOnly
                ? WidgetStateMouseCursor.clickable
                : SystemMouseCursors.text,
            onTap: readOnly && widget.enabled ? () => _pick(context) : null,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.next,
            validator: widget.validator,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: readOnly ? '选择日期' : 'YYYY-MM-DD',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.text.isNotEmpty)
                    IconButton(
                      tooltip: '清空日期',
                      onPressed: widget.enabled
                          ? widget.controller.clear
                          : null,
                      icon: const Icon(Icons.clear, size: 18),
                    ),
                  IconButton(
                    tooltip: '选择日期',
                    onPressed: widget.enabled ? () => _pick(context) : null,
                    icon: const Icon(Icons.calendar_month_outlined, size: 20),
                  ),
                ],
              ),
            ),
          ),
          if (widget.quickDates || compact)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                children: [
                  if (widget.quickDates) ...[
                    _quickDate('今天', 0),
                    _quickDate('昨天', 1),
                  ],
                  if (compact)
                    TextButton(
                      onPressed: !widget.enabled
                          ? null
                          : () {
                              setState(() => typing = !typing);
                              if (typing) {
                                focus.requestFocus();
                              } else {
                                focus.unfocus();
                              }
                            },
                      child: Text(typing ? '使用日历' : '手动输入'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickDate(String label, int daysAgo) => TextButton(
    onPressed: !widget.enabled
        ? null
        : () {
            focus.unfocus();
            final now = DateTime.now();
            widget.controller.text = DateTime(
              now.year,
              now.month,
              now.day - daysAgo,
            ).toIso8601String().substring(0, 10);
          },
    child: Text(label),
  );
}
