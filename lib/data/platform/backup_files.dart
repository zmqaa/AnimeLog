import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/backup_repository.dart';
import '../../core/backup/backup_codec.dart';

class PlatformBackupFiles implements BackupFileService {
  final Directory privateDirectory;
  PlatformBackupFiles(this.privateDirectory);

  Directory get _snapshots =>
      Directory('${privateDirectory.path}/restore-snapshots');

  @override
  Future<List<String>> safetySnapshots() async {
    if (!await _snapshots.exists()) return [];
    final result = <String>[];
    await for (final entity in _snapshots.list(followLinks: false)) {
      if (entity is File &&
          entity.path.endsWith('.json') &&
          entity.uri.pathSegments.last.startsWith('AnimeLog-before-restore-')) {
        result.add(entity.uri.pathSegments.last);
      }
    }
    result.sort((a, b) => b.compareTo(a));
    return result;
  }

  @override
  Future<SelectedBackup> readSafetySnapshot(String name) async {
    if (!name.startsWith('AnimeLog-before-restore-') ||
        !name.endsWith('.json') ||
        name.contains('/') ||
        name.contains('\\')) {
      fail('恢复快照', '无效的快照名称');
    }
    final file = File('${_snapshots.path}/$name');
    if (await FileSystemEntity.isLink(file.path)) fail('恢复快照', '不接受符号链接');
    if (await file.length() > maxBackupBytes) fail('恢复快照', '超过 50 MiB 上限');
    return SelectedBackup(name, await file.readAsBytes());
  }

  @override
  Future<SelectedBackup?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '选择动漫备份 JSON',
    );
    if (file == null) return null;
    final size = file.lengthSync() ?? await file.length();
    if (size != null && size > maxBackupBytes) fail('文件', '超过 50 MiB 上限');
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (builder.length + chunk.length > maxBackupBytes) {
        fail('文件', '超过 50 MiB 上限');
      }
      builder.add(chunk);
    }
    return SelectedBackup(file.name, builder.takeBytes());
  }

  @override
  Future<String?> save(List<int> bytes, String suggestedName) async {
    final uri = await FilePicker.saveFile(
      fileName: suggestedName,
      bytes: Uint8List.fromList(bytes),
      mimeType: 'application/json',
      dialogTitle: '导出全部动漫数据',
    );
    return uri?.toString(); // Android content URI is never treated as a path.
  }

  @override
  Future<String> saveSafetySnapshot(List<int> bytes) async {
    final directory = Directory('${privateDirectory.path}/restore-snapshots');
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}/AnimeLog-before-restore-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}-${const Uuid().v4()}.json',
    );
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
    return file.path;
  }
}
