import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/anime_log_core.dart';
import '../../core/api/library_repository.dart';
import '../shared/pagination.dart';

enum LibrarySort { updated, title, score, progress }

String sortLabel(LibrarySort sort) => switch (sort) {
  LibrarySort.updated => '最近更新',
  LibrarySort.title => '标题顺序',
  LibrarySort.score => '评分优先',
  LibrarySort.progress => '进度优先',
};

class LibraryController extends ChangeNotifier {
  final LibraryRepository repository;
  final int pageSize;
  StreamSubscription<List<AnimeRecord>>? _subscription;
  List<AnimeRecord> records = [];
  String query = '';
  AnimeStatus? filter;
  String? tagFilter;
  String? castFilter;
  LibrarySort sort = LibrarySort.updated;
  int page = 0;
  bool loading = true;
  Object? error;
  final Set<String> busy = {};
  bool _disposed = false;
  bool _retrying = false;

  LibraryController(this.repository, {this.pageSize = collectionPageSize}) {
    _listen();
  }

  void _listen() {
    _subscription = repository.watchLibrary().listen(
      (value) {
        if (_disposed) return;
        records = value;
        page = boundedPage(page, visible.length, pageSize);
        loading = false;
        error = null;
        if (!_disposed) notifyListeners();
      },
      onError: (Object failure) {
        if (_disposed) return;
        error = failure;
        loading = false;
        if (!_disposed) notifyListeners();
      },
    );
  }

  Future<void> retry() async {
    if (_disposed || _retrying) return;
    _retrying = true;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _subscription?.cancel();
      if (!_disposed) _listen();
    } catch (failure) {
      if (!_disposed) {
        error = failure;
        loading = false;
        notifyListeners();
      }
    } finally {
      _retrying = false;
    }
  }

  List<AnimeRecord> get visible {
    final result = records
        .where(
          (a) =>
              (filter == null || a.status == filter) &&
              (tagFilter == null ||
                  a.tags.any((tag) => tag.trim() == tagFilter)) &&
              (castFilter == null ||
                  [
                    ...a.metadata.cast,
                    ...a.metadata.castAliases,
                  ].any((cast) => cast.trim() == castFilter)) &&
              ('${a.metadata.title} ${a.metadata.originalTitle ?? ''} '
                      '${a.tags.join(' ')} ${a.metadata.cast.join(' ')} '
                      '${a.metadata.castAliases.join(' ')}')
                  .toLowerCase()
                  .contains(query.trim().toLowerCase()),
        )
        .toList();
    result.sort((a, b) {
      final order = switch (sort) {
        LibrarySort.updated => b.updatedAt.compareTo(a.updatedAt),
        LibrarySort.title => a.metadata.title.compareTo(b.metadata.title),
        LibrarySort.score => (b.score ?? -1).compareTo(a.score ?? -1),
        LibrarySort.progress => b.progress.compareTo(a.progress),
      };
      return order == 0 ? a.uuid.compareTo(b.uuid) : order;
    });
    return result;
  }

  void selectSort(LibrarySort value) {
    sort = value;
    page = 0;
    notifyListeners();
  }

  void resetFilters() {
    query = '';
    filter = null;
    tagFilter = null;
    castFilter = null;
    page = 0;
    notifyListeners();
  }

  void search(String value) {
    query = value;
    page = 0;
    notifyListeners();
  }

  void selectStatus(AnimeStatus? value) {
    filter = value;
    page = 0;
    notifyListeners();
  }

  void selectTag(String? value) {
    tagFilter = value;
    page = 0;
    notifyListeners();
  }

  void selectCast(String? value) {
    castFilter = value;
    page = 0;
    notifyListeners();
  }

  Future<ProgressReceipt> increment(String uuid) async {
    if (busy.contains(uuid)) throw StateError('进度正在保存');
    busy.add(uuid);
    notifyListeners();
    try {
      return await repository.increment(
        uuid,
        DateTime.now().toIso8601String().substring(0, 10),
      );
    } finally {
      busy.remove(uuid);
      if (!_disposed) notifyListeners();
    }
  }

  void selectPage(int value) {
    page = boundedPage(value, visible.length, pageSize);
    notifyListeners();
  }

  Future<void> decrement(String uuid) async {
    if (busy.contains(uuid)) return;
    busy.add(uuid);
    notifyListeners();
    try {
      await repository.decrement(uuid);
    } finally {
      busy.remove(uuid);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

String statusLabel(AnimeStatus status) => switch (status) {
  AnimeStatus.watching => '在看',
  AnimeStatus.completed => '看完',
  AnimeStatus.dropped => '弃番',
  AnimeStatus.planToWatch => '想看',
};
