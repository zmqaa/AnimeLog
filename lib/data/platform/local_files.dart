import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/api/library_repository.dart';

Future<Directory> applicationDirectory() async {
  final root = await getApplicationSupportDirectory();
  final directory = Directory(p.join(root.path, 'AnimeLog'));
  await directory.create(recursive: true);
  return directory;
}

class FileIntakeDraftStore implements IntakeDraftStore {
  final File file;
  FileIntakeDraftStore(this.file);

  @override
  Future<Map<String, dynamic>?> load() async {
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString(encoding: utf8));
    if (decoded is! Map<String, dynamic> ||
        decoded['draftId'] is! String ||
        decoded['fields'] is! Map<String, dynamic>) {
      throw const FormatException('未提交草稿格式无效');
    }
    return decoded;
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(data),
      encoding: utf8,
      flush: true,
    );
    await temporary.rename(file.path);
  }

  @override
  Future<void> clear() async {
    if (await file.exists()) await file.delete();
  }
}
