import 'package:flutter/material.dart';

import '../shared/app_theme.dart';
import '../shared/date_input.dart';
import '../shared/form_controls.dart';

import 'package:flutter/services.dart';

import '../../core/anime_log_core.dart';
import '../library/library_controller.dart';
import 'editor_controller.dart';
import '../../core/api/ai_intake.dart';
import '../shared/anime_cover.dart';
import '../../core/api/library_repository.dart';

class EditorPage extends StatefulWidget {
  final EditorController controller;
  final CoverStore? covers;
  const EditorPage({super.key, required this.controller, this.covers});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  EditorController get c => widget.controller;
  String? error;
  bool _leaveAllowed = false;
  bool _leaving = false;
  bool _submitting = false;
  final form = GlobalKey<FormState>();
  int? get _total {
    final total = int.tryParse(c.text['total']!.text.trim());
    return total != null && total > 0 ? total : null;
  }

  bool get _locked => c.saving || _submitting;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (c.saving || _submitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (form.currentState?.validate() == false) return;
    setState(() {
      error = null;
      _submitting = true;
    });
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      c.draft();
      if (c.original == null && !await _reviewExisting()) return;
      HistoryTrimPreview? trim;
      if (c.loweringProgress && c.trimHigherHistory) {
        trim = await c.useCases.records.previewHistoryTrim(
          c.original!.uuid,
          c.draft().progress,
        );
        if (!mounted) return;
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认批量清理观看历史？'),
            content: Text(
              '进度将调整为 ${trim!.targetProgress} 集，同时删除高于该进度的 ${trim.events.length} 条观看历史。\n总体备注和分集备注保留。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('返回编辑'),
              ),
              FilledButton(
                key: const Key('confirm-trim-history'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认保存并清理'),
              ),
            ],
          ),
        );
        if (accepted != true || !mounted) return;
      }
      final uuid = await c.save(trimHistory: trim);
      if (mounted) {
        setState(() => _leaveAllowed = true);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context, uuid);
      }
    } catch (failure) {
      if (mounted) {
        setState(() => error = '保存未完成：$failure');
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(context, error: true, content: Text(error!)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _reviewExisting() async {
    final metadata = c.metadata();
    final records = await c.useCases.records.all();
    var suggestion = resolveRewatchSuggestion(
      metadata: metadata,
      existingRecords: records,
    );
    if (!mounted) return false;
    if (suggestion.reason ==
        RewatchSuggestionReason.identityNeedsConfirmation) {
      final confirmed = <String>{};
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            title: const Text('确认是否为同一部作品'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('标题相同不能证明是同一季度或条目。只勾选你确认属于本次作品的记录。'),
                    for (final record in records.where(
                      (r) => suggestion.relatedRecordUuids.contains(r.uuid),
                    ))
                      CheckboxListTile(
                        value: confirmed.contains(record.uuid),
                        onChanged: (checked) => refresh(() {
                          if (checked == true) {
                            confirmed.add(record.uuid);
                          } else {
                            confirmed.remove(record.uuid);
                          }
                        }),
                        title: Text(record.metadata.title),
                        subtitle: Text(
                          '${statusLabel(record.status)} · ${record.progress} 集'
                          '${record.rewatchCount == null ? '' : ' · 第 ${record.rewatchCount} 刷'}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('返回编辑'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('继续'),
              ),
            ],
          ),
        ),
      );
      if (accepted != true || !mounted) return false;
      suggestion = resolveRewatchSuggestion(
        metadata: metadata,
        existingRecords: records,
        confirmedRecordUuids: confirmed,
      );
    }
    if (suggestion.relatedRecordUuids.isEmpty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('已有记录与刷次'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.reason == RewatchSuggestionReason.completedRecords
                      ? '已确认的记录全部看完，建议第 ${suggestion.suggestedCount} 刷。新记录的进度、评分和备注由本次表单决定。'
                      : '存在未完成或身份未确认的记录，保留普通新建。你仍可在表单中手动指定刷次。',
                ),
                const SizedBox(height: 12),
                for (final record in records.where(
                  (r) => suggestion.relatedRecordUuids.contains(r.uuid),
                ))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(record.metadata.title),
                    subtitle: Text(
                      '${statusLabel(record.status)} · ${record.progress} 集 · '
                      '${record.rewatchCount == null ? '普通记录' : '第 ${record.rewatchCount} 刷'}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'ordinary'),
            child: const Text('普通新建'),
          ),
          if (c.optional('rewatch') != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'keep'),
              child: const Text('使用表单刷次'),
            ),
          if (suggestion.suggestedCount != null)
            FilledButton(
              onPressed: () => Navigator.pop(context, 'suggested'),
              child: Text('采用第 ${suggestion.suggestedCount} 刷'),
            ),
        ],
      ),
    );
    if (choice == null || !mounted) return false;
    if (choice == 'ordinary') c.text['rewatch']!.clear();
    if (choice == 'suggested') {
      c.text['rewatch']!.text = '${suggestion.suggestedCount}';
    }
    return true;
  }

  Future<bool> _canLeave() async {
    if (c.saving || _submitting) return false;
    if (!c.dirty) return true;
    if (c.original == null) {
      try {
        await c.flush();
        return true;
      } catch (failure) {
        if (mounted) setState(() => error = '草稿未保留：$failure');
        return false;
      }
    }
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('放弃未保存的修改？'),
            content: const Text('记录还没有保存此次编辑。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('继续编辑'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('放弃修改'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => PopScope(
      canPop: _leaveAllowed || (!c.dirty && !c.saving && !_submitting),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _leaving) return;
        _leaving = true;
        if (await _canLeave() && context.mounted) {
          setState(() => _leaveAllowed = true);
          await WidgetsBinding.instance.endOfFrame;
          if (context.mounted) Navigator.pop(context);
        }
        _leaving = false;
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        },
        child: Scaffold(
          appBar: AppBar(title: Text(c.original == null ? '填写新记录' : '编辑记录')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: form,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(20),
                          children: [
                            PageHeading(
                              title: c.original == null
                                  ? '留下你的观看记录'
                                  : '更新这段观看记录',
                              subtitle: c.original == null
                                  ? '填写观看进度与感想，其他资料可以以后补充。返回会保留草稿。'
                                  : '作品资料与个人记录分别填写，保存后生效。',
                            ),
                            SectionCard(
                              title: '作品身份',

                              children: [
                                _field('title', '作品标题 *', maxLength: 200),
                                if (c.optional('coverUrl') != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AnimeCover(
                                        url: c.optional('coverUrl'),
                                        store: widget.covers,
                                        width: 120,
                                        height: 168,
                                      ),
                                    ),
                                  ),
                                ChoiceField<AnimeEntryType?>(
                                  label: '作品形式',
                                  value: c.entryType,
                                  choices: [
                                    const FormChoice(null, '未知'),
                                    for (final type in AnimeEntryType.values)
                                      FormChoice(type, type.name.toUpperCase()),
                                  ],
                                  onChanged: _locked ? null : c.setEntryType,
                                ),
                              ],
                            ),
                            SectionCard(
                              title: '观看记录',

                              children: [
                                ChoiceField<AnimeStatus>(
                                  label: '观看状态',
                                  value: c.status,
                                  choices: [
                                    for (final status in AnimeStatus.values)
                                      FormChoice(status, statusLabel(status)),
                                  ],
                                  onChanged: _locked ? null : c.setStatus,
                                ),
                                const SizedBox(height: 16),
                                _pair(
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: IntegerInput(
                                      key: const Key('field-progress'),
                                      controller: c.text['progress']!,
                                      label: '已看集数',
                                      maximum: _total,
                                      enabled: !_locked,
                                      validator: (_) => _validate('progress'),
                                    ),
                                  ),
                                  _field(
                                    'total',
                                    '总集数',
                                    number: true,
                                    hint: '未知可留空',
                                  ),
                                ),
                                if (c.loweringProgress)
                                  CheckboxListTile(
                                    key: const Key('trim-higher-history'),
                                    contentPadding: EdgeInsets.zero,
                                    value: c.trimHigherHistory,
                                    onChanged: _locked
                                        ? null
                                        : (value) => c.setTrimHistory(value!),
                                    title: const Text('同时删除高于新进度的观看历史'),
                                    subtitle: const Text(
                                      '默认保留全部历史。勾选后，保存前会显示删除数量并再次确认。',
                                    ),
                                  ),
                                _pair(
                                  _dateField('startDate', '开始日期'),
                                  _dateField('endDate', '完成日期'),
                                ),
                                if (c.original?.startDateSource == 'history')
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('将开始日期固定为手动日期'),
                                    subtitle: const Text('固定后，纠正历史不会再改变开始日期。'),
                                    value: c.manualStartDate,
                                    onChanged: _locked
                                        ? null
                                        : (value) => setState(() {
                                            c.manualStartDate = value!;
                                            c.dirty = true;
                                          }),
                                  ),
                                const Text(
                                  '表单修改进度保留历史；新建不会生成历史。看完时已知总集数会填入进度。',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            SectionCard(
                              title: '评价与感想',

                              children: [
                                _pair(
                                  _field(
                                    'score',
                                    '评分',
                                    number: true,
                                    hint: '0–10，可留空',
                                  ),
                                  _field(
                                    'rewatch',
                                    '第几刷',
                                    number: true,
                                    hint: '重刷填 2 或更高，普通留空',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: TokenInput(
                                    key: const Key('field-tags'),
                                    controller: c.text['tags']!,
                                    label: '标签',
                                    enabled: !_locked,
                                  ),
                                ),
                                _field(
                                  'notes',
                                  '总体备注',
                                  lines: 4,
                                  hint: '记下这部作品带给你的感受…',
                                ),
                              ],
                            ),
                            Card(
                              child: ExpansionTile(
                                title: const Text('更多作品资料'),
                                childrenPadding: const EdgeInsets.all(20),
                                children: [
                                  _pair(
                                    _field('originalTitle', '原名'),
                                    _field('season', '季度', number: true),
                                  ),
                                  _field('summary', '作品简介', lines: 4),
                                  _field('cast', '声优（用逗号分隔）'),
                                  _field('castAliases', '声优别名（用逗号分隔）'),
                                  _field('coverUrl', '封面 URL'),
                                  _pair(
                                    _field(
                                      'duration',
                                      '单集时长（分钟）',
                                      number: true,
                                    ),
                                    _dateField('premiereDate', '首播日期'),
                                  ),
                                  ChoiceField<bool?>(
                                    label: '作品是否完结',
                                    value: c.isFinished,
                                    choices: const [
                                      FormChoice(null, '未知'),
                                      FormChoice(true, '已完结'),
                                      FormChoice(false, '未完结'),
                                    ],
                                    onChanged: _locked ? null : c.setFinished,
                                  ),
                                  const SizedBox(height: 16),
                                  _pair(
                                    _field('sourceProvider', '资料来源（成对填写）'),
                                    _field('sourceId', '来源条目 ID'),
                                  ),
                                ],
                              ),
                            ),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: FeedbackPanel(
                                  message: error!,
                                  error: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('save-record'),
                            onPressed: _locked ? null : _save,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_locked) ...[
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  c.saving
                                      ? '正在保存…'
                                      : _submitting
                                      ? '正在确认…'
                                      : '保存记录',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _dateField(String name, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DateInput(
      key: Key('field-$name'),
      controller: c.text[name]!,
      label: label,
      enabled: !_locked,
      validator: (value) =>
          value == null ||
              value.trim().isEmpty ||
              normalizeDateString(value.trim()) != null
          ? null
          : '请选择有效日期',
    ),
  );

  Widget _field(
    String name,
    String label, {
    bool number = false,
    int lines = 1,
    int? maxLength,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: Key('field-$name'),
      controller: c.text[name],
      enabled: !_locked,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (_) => _validate(name),
      maxLines: lines,
      maxLength: maxLength,
      keyboardType: number
          ? TextInputType.numberWithOptions(decimal: name == 'score')
          : (lines > 1 ? TextInputType.multiline : TextInputType.text),
      textInputAction: lines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
    ),
  );

  String? _validate(String name) {
    final value = c.text[name]!.text.trim();
    if (name == 'title') {
      return value.isEmpty
          ? '请填写作品标题'
          : value.length > 200
          ? '标题最多 200 个字符'
          : null;
    }
    if (value.isEmpty) return name == 'progress' ? '请填写已看集数' : null;
    if (name == 'score') {
      final score = double.tryParse(value);
      return score == null || !score.isFinite || score < 0 || score > 10
          ? '评分范围为 0–10'
          : null;
    }
    if (['progress', 'total', 'season', 'duration', 'rewatch'].contains(name)) {
      final number = int.tryParse(value);
      final minimum = name == 'progress'
          ? 0
          : name == 'rewatch'
          ? 2
          : 1;
      if (number == null || number < minimum) return '请填写不小于 $minimum 的整数';
      if (name == 'progress') {
        if (_total != null && number > _total!) return '已看集数不能超过总集数';
        if (c.status == AnimeStatus.planToWatch && number > 0) {
          return '想看记录的进度应为 0';
        }
      }
      return null;
    }
    return null;
  }

  Widget _pair(Widget first, Widget second) =>
      FormRow(runSpacing: 0, children: [first, second]);
}
