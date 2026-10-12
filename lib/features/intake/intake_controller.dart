import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../application/ai_intake.dart';
import '../../core/api/ai_intake.dart';
import '../../core/api/library_repository.dart';
import '../../core/anime_log_core.dart';

class IntakeController extends ChangeNotifier {
  final AiIntake service;
  final IntakeDraftStore store;
  String query;
  String draftId;
  AnimeIntakeStage? stage;
  IntakeRecognition? result;
  AnimeMetadata? metadata;
  Object? error;
  Object? draftError;
  RequestScope? _scope;
  int _generation = 0;
  bool _disposed = false;
  Future<void> _pending = Future.value();
  IntakeController(this.service, this.store, {Map<String, dynamic>? restored})
    : query = (restored?['fields']?['title'] as String?) ?? '',
      draftId = restored?['draftId'] as String? ?? const Uuid().v4();
  bool get busy => stage != null && stage != AnimeIntakeStage.ready;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void changeQuery(String value) {
    if (query == value) return;
    cancel(notify: false);
    query = value;
    draftId = const Uuid().v4();
    result = null;
    metadata = null;
    error = null;
    _persist();
    _notify();
  }

  Map<String, dynamic> snapshot([AnimeMetadata? details]) => {
    'draftId': draftId,
    'intakeMode': details == null ? 'recognition' : 'editor',
    'status': 'watching',
    'entryType': details?.entryType?.wireValue,
    'isFinished': details?.isFinished,
    'fields': {
      'title': details?.title ?? query,
      'originalTitle': details?.originalTitle ?? '',
      'season': details?.season?.toString() ?? '',
      'total': details?.totalEpisodes?.toString() ?? '',
      'duration': details?.durationMinutes?.toString() ?? '',
      'summary': details?.summary ?? '',
      'coverUrl': details?.coverUrl ?? '',
      'sourceProvider': details?.sourceProvider ?? '',
      'sourceId': details?.sourceId ?? '',
      'premiereDate': details?.premiereDate ?? '',
      'cast': details?.cast.join('，') ?? '',
      'castAliases': details?.castAliases.join('，') ?? '',
      'progress': '0',
    },
  };
  void _persist() {
    final data = snapshot(metadata);
    _pending = _pending
        .then((_) => store.save(data))
        .then((_) {
          draftError = null;
          _notify();
        })
        .catchError((Object failure) {
          draftError = failure;
          _notify();
        });
  }

  Future<void> flush() async {
    await _pending;
    if (draftError != null) {
      try {
        await store.save(snapshot(metadata));
        draftError = null;
      } catch (failure) {
        draftError = failure;
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> prepareEditor({bool titleOnly = false}) async {
    cancel(notify: false);
    await flush();
    final data = snapshot(
      titleOnly ? AnimeMetadata(title: query.trim()) : metadata,
    );
    data['intakeMode'] = 'editor';
    await store.save(data);
    return data;
  }

  void cancel({bool notify = true}) {
    _generation++;
    _scope?.cancel();
    _scope = null;
    stage = metadata == null ? null : AnimeIntakeStage.ready;
    if (notify) _notify();
  }

  Future<void> recognize() async {
    if (query.trim().isEmpty || busy) return;
    cancel(notify: false);
    result = null;
    metadata = null;
    error = null;
    _persist();
    stage = AnimeIntakeStage.recognizing;
    final generation = _generation;
    final scope = _scope = RequestScope();
    _notify();
    try {
      final recognized = await service.recognize(
        query,
        scope,
        onStage: (value) {
          if (_generation == generation && !_disposed) {
            stage = value;
            _notify();
          }
        },
      );
      if (_generation != generation || _disposed) return;
      result = recognized;
      stage = null;
    } catch (failure) {
      if (_generation != generation || _disposed) return;
      error = failure;
      stage = null;
    } finally {
      scope.cancel();
      if (_generation == generation) {
        _scope = null;
        _notify();
      }
    }
  }

  Future<void> choose(AnimeTitleCandidate candidate) async {
    if (busy ||
        result == null ||
        !result!.candidates.any((c) => c.id == candidate.id)) {
      return;
    }
    cancel(notify: false);
    metadata = null;
    error = null;
    stage = AnimeIntakeStage.searching;
    _persist();
    final generation = _generation;
    final scope = _scope = RequestScope(budget: const Duration(seconds: 10));
    _notify();
    try {
      final details = await service.details(candidate, scope);
      if (_generation != generation || _disposed) return;
      metadata = details;
      stage = AnimeIntakeStage.ready;
      _persist();
    } catch (failure) {
      if (_generation != generation || _disposed) return;
      error = failure;
      stage = null;
    } finally {
      scope.cancel();
      if (_generation == generation) {
        _scope = null;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    cancel(notify: false);
    super.dispose();
  }
}
