import 'package:flutter/material.dart';

import '../../core/anime_log_core.dart';
import 'date_input.dart';
import 'app_theme.dart';
import 'form_controls.dart';
import 'time_input.dart';
import 'history_time.dart';

class WatchHistoryValues {
  final int episode;
  final String watchedOn;
  final String? watchedAt;
  const WatchHistoryValues(this.episode, this.watchedOn, {this.watchedAt});
}

class WatchHistoryDialog extends StatefulWidget {
  final AnimeRecord record;
  final WatchHistoryRecord? event;
  const WatchHistoryDialog({super.key, required this.record, this.event});

  @override
  State<WatchHistoryDialog> createState() => _WatchHistoryDialogState();
}

class _WatchHistoryDialogState extends State<WatchHistoryDialog> {
  late final openedAt = DateTime.now();
  bool timeEdited = false;
  late final episode = TextEditingController(
    text:
        '${widget.event?.episode ?? (widget.record.metadata.totalEpisodes == null ? widget.record.progress + 1 : (widget.record.progress + 1).clamp(1, widget.record.metadata.totalEpisodes!))}',
  );
  late final date = TextEditingController(
    text:
        widget.event?.watchedOn ?? openedAt.toIso8601String().substring(0, 10),
  );
  String? error;
  late final time = TextEditingController(
    text: widget.event == null
        ? TimeInput.label(TimeOfDay.fromDateTime(openedAt))
        : widget.event!.watchedAt == null
        ? ''
        : DateTime.tryParse(widget.event!.watchedAt!) == null
        ? ''
        : clockLabel(DateTime.parse(widget.event!.watchedAt!).toLocal()),
  );
  final form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    date.addListener(_dateChanged);
  }

  void _dateChanged() {
    if (widget.event != null || timeEdited) return;
    time.text = date.text.trim() == openedAt.toIso8601String().substring(0, 10)
        ? TimeInput.label(TimeOfDay.fromDateTime(openedAt))
        : '';
  }

  @override
  void dispose() {
    episode.dispose();
    date.removeListener(_dateChanged);
    date.dispose();
    time.dispose();
    super.dispose();
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (form.currentState?.validate() == false) return;
    final number = int.tryParse(episode.text.trim());
    final on = date.text.trim();
    final total = widget.record.metadata.totalEpisodes;
    if (number == null ||
        number <= 0 ||
        (total != null && number > total) ||
        normalizeDateString(on) != on) {
      setState(() => error = '请填写${total == null ? '正整数' : '1–$total'}集数和有效日期');
      return;
    }
    final selectedTime = TimeInput.parse(time.text.trim());
    String? moment;
    if (selectedTime != null) {
      final original = widget.event?.watchedAt;
      final previous = original == null
          ? null
          : DateTime.tryParse(original)?.toLocal();
      final unchangedClock =
          previous != null &&
          clockLabel(previous) == TimeInput.label(selectedTime);
      if (unchangedClock && widget.event!.watchedOn == on) {
        moment = original;
      } else {
        final day = DateTime.parse(on);
        moment = DateTime(
          day.year,
          day.month,
          day.day,
          selectedTime.hour,
          selectedTime.minute,
          unchangedClock ? previous.second : 0,
          unchangedClock ? previous.millisecond : 0,
          unchangedClock ? previous.microsecond : 0,
        ).toUtc().toIso8601String();
      }
    }
    Navigator.pop(context, WatchHistoryValues(number, on, watchedAt: moment));
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: FormPanel(
      title: widget.event == null ? '记录一集观看历史' : '纠正观看历史',
      subtitle: widget.record.metadata.title,
      width: 440,
      onSave: _save,
      saveLabel: '保存历史',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          IntegerInput(
            controller: episode,
            label: '第几集',
            minimum: 1,
            maximum: widget.record.metadata.totalEpisodes,
            validator: (value) {
              final number = int.tryParse(value?.trim() ?? '');
              final total = widget.record.metadata.totalEpisodes;
              return number == null ||
                      number <= 0 ||
                      (total != null && number > total)
                  ? '请填写${total == null ? '正整数' : '1–$total'}集数'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          DateInput(
            controller: date,
            label: '观看日期',
            quickDates: true,
            validator: (value) =>
                value == null ||
                    value.trim().isEmpty ||
                    normalizeDateString(value.trim()) != value.trim()
                ? '请选择有效日期'
                : null,
          ),
          const SizedBox(height: 16),
          TimeInput(controller: time, onUserEdit: () => timeEdited = true),
          const SizedBox(height: 8),
          Text(
            '使用本机时区；不知道具体时间时可以留空。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            widget.event == null ? '记录这一集，并在需要时增加进度。' : '修改集数或日期，保留当前进度。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            FeedbackPanel(message: error!, error: true),
          ],
        ],
      ),
    ),
  );
}
