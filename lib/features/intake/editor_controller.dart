import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../application/manual_library.dart';
import '../../core/anime_log_core.dart';
import '../../core/api/library_repository.dart';

class EditorController extends ChangeNotifier {
  final ManualLibrary useCases;
  final IntakeDraftStore? store;
  final String draftId;
  final AnimeRecord? original;
  final Map<String, TextEditingController> text = {};
  AnimeStatus status;
  AnimeEntryType? entryType;
  bool? isFinished;
  bool saving = false;
  bool dirty = false;
  bool manualStartDate = false;
  bool trimHigherHistory = false;
  Object? draftError;
  Future<void> _pending = Future.value();
  bool _disposed = false;

  EditorController({
    required this.useCases,
    this.store,
    this.original,
    Map<String, dynamic>? restored,
  }) : draftId = restored?['draftId'] as String? ?? const Uuid().v4(),
       status =
           original?.status ??
           animeStatusFromWire(restored?['status']) ??
           AnimeStatus.watching,
       entryType =
           original?.metadata.entryType ??
           animeEntryTypeFromWire(restored?['entryType']),
       isFinished =
           original?.metadata.isFinished ?? restored?['isFinished'] as bool? {
    final record = original;
    final fields = restored?['fields'] as Map<String, dynamic>? ?? {};
    final initial = <String, Object?>{
      'title': record?.metadata.title,
      'originalTitle': record?.metadata.originalTitle,
      'season': record?.metadata.season,
      'total': record?.metadata.totalEpisodes,
      'duration': record?.metadata.durationMinutes,
      'sourceProvider': record?.metadata.sourceProvider,
      'sourceId': record?.metadata.sourceId,
      'summary': record?.metadata.summary,
      'coverUrl': record?.metadata.coverUrl,
      'premiereDate': record?.metadata.premiereDate,
      'progress': record?.progress ?? '0',
      'cast': record?.metadata.cast.join('，'),
      'castAliases': record?.metadata.castAliases.join('，'),
      'score': record?.score,
      'notes': record?.notes,
      'tags': record?.tags.join('，'),
      'rewatch': record?.rewatchCount,
      'startDate': record?.startDate,
      'endDate': record?.endDate,
    };
    for (final entry in initial.entries) {
      text[entry.key] = TextEditingController(
        text: fields[entry.key]?.toString() ?? entry.value?.toString() ?? '',
      )..addListener(_changed);
    }
    dirty = restored != null;
  }

  String? optional(String key) {
    final value = text[key]!.text.trim();
    return value.isEmpty ? null : value;
  }

  int? integer(String key, String label, {bool required = false}) {
    final value = optional(key);
    if (value == null && !required) return null;
    final number = int.tryParse(value ?? '');
    if (number == null) throw QuickRecordValidationException('$label必须是整数');
    return number;
  }

  AnimeMetadata metadata() => AnimeMetadata(
    title: text['title']!.text.trim(),
    originalTitle: optional('originalTitle'),
    season: integer('season', '季度'),
    entryType: entryType,
    sourceProvider: optional('sourceProvider'),
    sourceId: optional('sourceId'),
    totalEpisodes: integer('total', '总集数'),
    durationMinutes: integer('duration', '时长'),
    summary: optional('summary'),
    coverUrl: optional('coverUrl'),
    premiereDate: optional('premiereDate'),
    isFinished: isFinished,
    cast: _list('cast'),
    castAliases: _list('castAliases'),
  );

  List<String> _list(String key) => text[key]!.text
      .split(RegExp('[,，\n]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();

  AnimeCreationDraft draft() {
    final scoreText = optional('score');
    final score = scoreText == null ? null : double.tryParse(scoreText);
    if (scoreText != null && score == null) {
      throw const QuickRecordValidationException('评分必须是 0–10 的数字');
    }
    final meta = metadata();
    var progress = integer('progress', '进度', required: true)!;
    var selectedStatus = status;
    var end = optional('endDate');
    if (selectedStatus == AnimeStatus.completed &&
        meta.totalEpisodes != null &&
        progress < meta.totalEpisodes! &&
        original?.status == AnimeStatus.completed) {
      selectedStatus = AnimeStatus.watching;
      end = null;
    }
    final count = integer('rewatch', '刷次');
    final result = AnimeCreationDraft(
      draftId: draftId,
      metadata: meta,
      status: selectedStatus,
      progress: progress,
      score: score,
      notes: optional('notes'),
      rewatchCount: count,
      tags: buildCreationTags(
        text['tags']!.text.split(RegExp('[,，\n]')),
        count,
      ),
      startDate: optional('startDate'),
      endDate: end,
    );
    validateAnimeCreationDraft(result);
    return result;
  }

  void setStatus(AnimeStatus value) {
    status = value;
    if (value == AnimeStatus.completed && optional('total') != null) {
      text['progress']!.text = text['total']!.text;
    }
    if (value != AnimeStatus.completed) text['endDate']!.clear();
    _changed();
  }

  void setEntryType(AnimeEntryType? value) {
    entryType = value;
    _changed();
  }

  void setFinished(bool? value) {
    isFinished = value;
    _changed();
  }

  bool get loweringProgress {
    final progress = int.tryParse(text['progress']!.text.trim());
    return original != null &&
        progress != null &&
        progress >= 0 &&
        progress < original!.progress;
  }

  void setTrimHistory(bool value) {
    trimHigherHistory = value;
    _changed();
  }

  Map<String, dynamic> snapshot() => {
    'draftId': draftId,
    'status': status.wireValue,
    'entryType': entryType?.wireValue,
    'isFinished': isFinished,
    'fields': {for (final entry in text.entries) entry.key: entry.value.text},
  };

  void _changed() {
    dirty = true;
    if (store != null) {
      final data = snapshot();
      _pending = _pending
          .then((_) => store!.save(data))
          .then((_) {
            draftError = null;
          })
          .catchError((Object error) {
            draftError = error;
          });
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> flush() async {
    await _pending;
    if (draftError != null) throw draftError!;
  }

  Future<String> save({HistoryTrimPreview? trimHistory}) async {
    if (saving) throw const QuickRecordValidationException('正在保存');
    final values = draft();
    saving = true;
    notifyListeners();
    try {
      await flush();
      final String uuid;
      if (original == null) {
        uuid = (await useCases.create(values)).entry.uuid;
      } else {
        await useCases.edit(
          original!.uuid,
          values,
          manualStartDate: manualStartDate,
          trimHistory: trimHistory,
        );
        uuid = original!.uuid;
      }
      // Keep draftId when a result/cleanup fails, so retry remains idempotent.
      if (store != null) await store!.clear();
      dirty = false;
      return uuid;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final controller in text.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
