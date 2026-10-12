import 'package:flutter/material.dart';

class TimeInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onUserEdit;
  const TimeInput({super.key, required this.controller, this.onUserEdit});

  static TimeOfDay? parse(String value) {
    if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)) return null;
    final parts = value.split(':');
    final hour = int.parse(parts.first);
    final minute = int.parse(parts.last);
    return hour < 24 && minute < 60
        ? TimeOfDay(hour: hour, minute: minute)
        : null;
  }

  static String label(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: parse(controller.text.trim()) ?? TimeOfDay.now(),
      helpText: '选择观看时间',
      cancelText: '取消',
      confirmText: '确定',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      onUserEdit?.call();
      controller.text = label(picked);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('history-time'),
          controller: controller,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onUserEdit?.call(),
          readOnly: MediaQuery.sizeOf(context).width < 600,
          showCursor: MediaQuery.sizeOf(context).width >= 600,
          mouseCursor: MediaQuery.sizeOf(context).width < 600
              ? WidgetStateMouseCursor.clickable
              : SystemMouseCursors.text,
          onTap: MediaQuery.sizeOf(context).width < 600
              ? () => _pick(context)
              : null,
          validator: (value) =>
              value == null ||
                  value.trim().isEmpty ||
                  parse(value.trim()) != null
              ? null
              : '请输入有效时分，如 20:30',
          decoration: InputDecoration(
            labelText: '观看时间',
            hintText: 'HH:mm，未知可留空',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    tooltip: '清空时间',
                    onPressed: () {
                      onUserEdit?.call();
                      controller.clear();
                    },
                    icon: const Icon(Icons.clear, size: 18),
                  ),
                IconButton(
                  tooltip: '选择时间',
                  onPressed: () => _pick(context),
                  icon: const Icon(Icons.schedule_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            onUserEdit?.call();
            controller.text = label(TimeOfDay.now());
          },
          child: const Text('当前时分'),
        ),
      ],
    ),
  );
}
