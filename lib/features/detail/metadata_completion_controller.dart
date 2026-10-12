import 'package:flutter/foundation.dart';

import '../../application/metadata_completion.dart';
import '../../core/api/ai_intake.dart';
import '../../core/domain/metadata_completion.dart';

class MetadataCompletionController extends ChangeNotifier {
  final String uuid;
  final MetadataCompletionService service;
  CompletionLookup? lookup;
  MetadataCompletionPreview? preview;
  Object? error;
  bool busy = false;
  bool applying = false;
  bool _disposed = false;
  int _generation = 0;
  RequestScope? _scope;
  MetadataCompletionController(this.uuid, this.service);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void cancel() {
    _generation++;
    _scope?.cancel();
    _scope = null;
    busy = false;
    _notify();
  }

  Future<void> load() async {
    if (applying) return;
    lookup = null;
    preview = null;
    await _query<CompletionLookup>((scope) => service.lookup(uuid, scope), (
      value,
    ) {
      lookup = value;
      preview = value.preview;
    });
  }

  Future<void> choose(int id) async {
    if (busy ||
        applying ||
        lookup == null ||
        !lookup!.candidates.any((c) => c.id == id)) {
      return;
    }
    preview = null;
    await _query<MetadataCompletionPreview>(
      (scope) => service.choose(uuid, id, scope),
      (value) => preview = value,
    );
  }

  Future<void> _query<T>(
    Future<T> Function(RequestScope) action,
    void Function(T) accept,
  ) async {
    cancel();
    error = null;
    busy = true;
    final generation = _generation;
    final scope = _scope = RequestScope();
    _notify();
    try {
      final result = await action(scope);
      if (_disposed || generation != _generation) return;
      accept(result);
    } catch (failure) {
      if (!_disposed && generation == _generation) error = failure;
    } finally {
      scope.cancel();
      if (generation == _generation) {
        busy = false;
        _scope = null;
        _notify();
      }
    }
  }

  Future<int> apply() async {
    if (busy || applying || preview == null) throw StateError('请先预览资料');
    applying = true;
    error = null;
    _notify();
    try {
      return await service.apply(preview!);
    } catch (failure) {
      error = failure;
      rethrow;
    } finally {
      applying = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    super.dispose();
  }
}
