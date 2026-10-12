import 'package:flutter/foundation.dart';

import '../../application/backup_service.dart';
import '../../core/backup/backup_document.dart';

class BackupController extends ChangeNotifier {
  final BackupService service;
  bool busy = false;
  String? error;
  String? message;
  PreparedImport? prepared;
  bool _disposed = false;
  BackupController(this.service);

  Future<void> _run(Future<void> Function() body) async {
    if (busy) return;
    busy = true;
    error = null;
    message = null;
    notifyListeners();
    try {
      await body();
    } catch (failure) {
      error = failure.toString();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> exportAll() => _run(() async {
    final saved = await service.exportAll();
    message = saved ? '全部数据已导出' : '已取消导出';
  });
  Future<void> pick(ImportMode mode) => _run(() async {
    prepared = null;
    final file = await service.files.pick();
    if (file == null) {
      message = '已取消选择';
      return;
    }
    prepared = await service.prepare(file, mode);
  });
  Future<void> loadSafetySnapshot(String name) => _run(() async {
    prepared = null;
    final selected = await service.files.readSafetySnapshot(name);
    prepared = await service.prepare(selected, ImportMode.replace);
  });
  Future<void> commit() => _run(() async {
    final confirmed = prepared;
    if (confirmed == null) return;
    await service.commit(confirmed);
    message =
        '导入完成：新增 ${confirmed.preview.newAnime} 条动漫、'
        '${confirmed.preview.newHistory} 条历史、${confirmed.preview.newNotes} 条备注；'
        '${confirmed.preview.newManga} 条漫画；跳过 '
        '${confirmed.preview.skippedAnime} 条已有动漫、'
        '${confirmed.preview.skippedManga} 条已有漫画；'
        '补充 ${confirmed.preview.filledCast} 条动漫的声优资料。';
    prepared = null;
  });
  void cancelPreview() {
    prepared = null;
    error = null;
    message = '已取消导入，本机记录未改变';
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
