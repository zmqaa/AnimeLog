import 'package:flutter/material.dart';

import '../../core/anime_log_core.dart';
import '../../core/domain/metadata_completion.dart';
import '../shared/date_input.dart';
import '../shared/app_theme.dart';
import '../shared/form_controls.dart';

class EpisodeNoteValues {
  final int episode;
  final String content;
  final String notedOn;
  const EpisodeNoteValues(this.episode, this.content, this.notedOn);
}

class EpisodeNoteDialog extends StatefulWidget {
  final AnimeNote? note;
  const EpisodeNoteDialog({super.key, this.note});
  @override
  State<EpisodeNoteDialog> createState() => _EpisodeNoteDialogState();
}

class _EpisodeNoteDialogState extends State<EpisodeNoteDialog> {
  late final episode = TextEditingController(
    text: widget.note?.episode?.toString() ?? '1',
  );
  late final content = TextEditingController(text: widget.note?.content ?? '');
  late final date = TextEditingController(
    text:
        widget.note?.notedOn ??
        DateTime.now().toIso8601String().substring(0, 10),
  );
  String? error;
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    episode.dispose();
    content.dispose();
    date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: FormPanel(
      title: widget.note == null ? '添加分集备注' : '编辑分集备注',
      onSave: _save,
      saveKey: const Key('save-episode-note'),
      saveLabel: '保存备注',
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntegerInput(
            key: const Key('note-episode'),
            controller: episode,
            label: '第几集',
            minimum: 1,
            validator: (value) => (int.tryParse(value?.trim() ?? '') ?? 0) <= 0
                ? '请填写正整数集数'
                : null,
          ),
          const SizedBox(height: 16),
          DateInput(
            key: const Key('note-date'),
            controller: date,
            label: '备注日期',
            quickDates: true,
            validator: (value) =>
                value == null ||
                    value.trim().isEmpty ||
                    normalizeDateString(value.trim()) != value.trim()
                ? '请选择有效日期'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('note-content'),
            controller: content,
            minLines: 4,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: '备注内容',
              hintText: '这一集有哪些想记下的片段？',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? '请填写备注内容' : null,
          ),
          const SizedBox(height: 12),
          Text(
            '分集备注独立保存，不改变进度和观看历史。同一集可以有多条备注。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FeedbackPanel(message: error!, error: true),
            ),
        ],
      ),
    ),
  );

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (form.currentState?.validate() == false) return;
    try {
      final number = int.tryParse(episode.text.trim()) ?? 0;
      validateEpisodeNote(number, content.text, date.text.trim());
      Navigator.pop(
        context,
        EpisodeNoteValues(number, content.text.trim(), date.text.trim()),
      );
    } catch (failure) {
      setState(() => error = '$failure');
    }
  }
}
