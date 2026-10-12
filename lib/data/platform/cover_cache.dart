import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/api/ai_intake.dart';
import '../remote/json_http.dart';

class FileCoverCache implements CoverStore {
  final Directory directory;
  final JsonHttp transport;
  final Map<String, Future<Uint8List?>> _pending = {};
  FileCoverCache(this.directory, this.transport);
  @override
  Future<Uint8List?> load(String url) => _pending.putIfAbsent(
    url,
    () => _load(url).whenComplete(() {
      _pending.remove(url);
    }),
  );
  Future<Uint8List?> _load(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      return null;
    }
    final file = File(
      p.join(directory.path, '${sha256.convert(utf8.encode(url))}.image'),
    );
    try {
      if (await file.exists()) {
        if (await file.length() <= 5 * 1024 * 1024) {
          final data = await file.readAsBytes();
          if (_image(data)) return data;
        }
        await file.delete();
      }
    } catch (_) {
      /* Cache read failure still permits a remote download. */
    }
    try {
      final data = await transport.bytes(
        'GET',
        uri,
        RequestScope(budget: const Duration(seconds: 10)),
        headers: {'Accept': 'image/*'},
        maxBytes: 5 * 1024 * 1024,
      );
      if (!_image(data)) return null;
      try {
        await directory.create(recursive: true);
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsBytes(data, flush: true);
        await tmp.rename(file.path);
      } catch (_) {
        /* Display downloaded bytes even when caching fails. */
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  bool _image(Uint8List bytes) =>
      bytes.length >= 12 &&
      ((bytes[0] == 0xff && bytes[1] == 0xd8) ||
          (bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4e &&
              bytes[3] == 0x47) ||
          (ascii.decode(bytes.sublist(0, 3), allowInvalid: true) == 'GIF') ||
          (ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
              ascii.decode(bytes.sublist(8, 12), allowInvalid: true) ==
                  'WEBP'));
}
