import 'package:flutter/foundation.dart';

import '../../core/anime_log_core.dart';
import '../../core/api/library_repository.dart';

class DetailController extends ChangeNotifier {
  final String uuid;
  final LibraryRepository repository;
  AnimeRecord? record;
  List<WatchHistoryRecord> events = [];
  List<AnimeNote> notes = [];
  bool loading = true;
  bool busy = false;
  Object? error;
  bool _disposed = false;
  DetailController(this.uuid, this.repository);

  Future<void> retry() async {
    if (_disposed || loading || busy) return;
    loading = true;
    error = null;
    notifyListeners();
    await reload();
  }

  Future<void> reload() async {
    try {
      record = await repository.find(uuid);
      events = await repository.history(uuid);
      notes = await repository.episodeNotes(uuid);
      error = null;
    } catch (failure) {
      error = failure;
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await action();
      await reload();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
