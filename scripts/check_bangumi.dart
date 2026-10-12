import 'dart:io';

import 'package:animelog/core/api/ai_intake.dart';
import 'package:animelog/data/remote/bangumi_source.dart';
import 'package:animelog/data/remote/json_http.dart';

/// Explicit public-source smoke check. No Key or personal library is loaded.
Future<void> main() async {
  final scope = RequestScope(budget: const Duration(seconds: 30));
  try {
    final source = BangumiSourceProvider(JsonHttp());
    final candidates = await source.search('星际牛仔', scope);
    if (!candidates.any((c) => c.id == 253)) throw StateError('已知公开条目未返回');
    final details = await source.details(253, scope);
    if (details.totalEpisodes != 26 || details.entryType?.name != 'tv') {
      throw StateError('公开资料字段与已核对条目不符');
    }
    stdout.writeln(
      'Bangumi 公开查询通过：${candidates.length} 个候选；'
      '${details.title} / ${details.originalTitle} / ${details.totalEpisodes} 集 / ${details.entryType?.name}',
    );
  } finally {
    scope.cancel();
  }
}
