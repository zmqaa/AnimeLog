import '../backup/backup_document.dart';

abstract interface class BackupRepository {
  Future<BackupDocument> snapshot();
  Future<ImportPreview> preview(BackupDocument document, ImportMode mode);
  Future<void> importAtomically(
    BackupDocument document,
    ImportPreview confirmed,
  );
}

abstract interface class BackupFileService {
  Future<SelectedBackup?> pick();
  Future<String?> save(List<int> bytes, String suggestedName);
  Future<String> saveSafetySnapshot(List<int> bytes);
  Future<List<String>> safetySnapshots();
  Future<SelectedBackup> readSafetySnapshot(String name);
}

class SelectedBackup {
  final String name;
  final List<int> bytes;
  const SelectedBackup(this.name, this.bytes);
}
