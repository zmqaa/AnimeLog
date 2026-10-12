import 'dart:typed_data';
import 'dart:isolate';

import '../core/api/backup_repository.dart';
import '../core/api/library_repository.dart';
import '../core/backup/backup_codec.dart';
import '../core/backup/backup_document.dart';

class PreparedImport {
  final BackupDocument document;
  final ImportPreview preview;
  final String? safetySnapshot;
  final String fileName;
  const PreparedImport(
    this.document,
    this.preview,
    this.safetySnapshot,
    this.fileName,
  );
}

class BackupService {
  final BackupRepository repository;
  final BackupFileService files;
  final IntakeDraftStore drafts;
  const BackupService(this.repository, this.files, this.drafts);

  Future<bool> exportAll() async {
    final snapshot = await repository.snapshot();
    final now = DateTime.now();
    final name =
        'AnimeLog-${now.toIso8601String().replaceAll(RegExp('[-:]'), '').substring(0, 15).replaceFirst('T', '-')}.json';
    return await files.save(await Isolate.run(snapshot.encode), name) != null;
  }

  Future<PreparedImport> prepare(
    SelectedBackup selected,
    ImportMode mode,
  ) async {
    final document = await _decodeInBackground(selected.bytes);
    final current = await repository.snapshot();
    // Snapshot must be the same state the counts/digest describe.
    final preview = await repository.preview(document, mode);
    String? safety;
    if (mode == ImportMode.replace) {
      if (backupStateDigest(current) != preview.currentDigest) {
        throw const BackupValidationException('完整恢复', '本机数据已变化，请重新预览');
      }
      safety = await files.saveSafetySnapshot(
        await Isolate.run(current.encode),
      );
      final recheck = await repository.preview(document, mode);
      if (recheck.currentDigest != preview.currentDigest) {
        throw const BackupValidationException('完整恢复', '保存快照时本机数据已变化，请重新预览');
      }
    }
    return PreparedImport(document, preview, safety, selected.name);
  }

  Future<void> commit(PreparedImport confirmed) async {
    if (confirmed.preview.mode == ImportMode.replace &&
        confirmed.safetySnapshot == null) {
      throw const BackupValidationException('完整恢复', '缺少恢复前的安全快照');
    }
    await repository.importAtomically(confirmed.document, confirmed.preview);
    if (confirmed.preview.mode == ImportMode.replace) {
      try {
        await drafts.clear();
      } catch (_) {
        throw const BackupValidationException(
          '完整恢复',
          '数据已经恢复，但旧草稿清理失败；请丢弃旧草稿后再添加',
        );
      }
    }
  }
}

Future<BackupDocument> _decodeInBackground(List<int> bytes) =>
    Isolate.run(() => decodeBackup(Uint8List.fromList(bytes)));
