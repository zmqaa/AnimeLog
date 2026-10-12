import '../../core/anime_log_core.dart';
import '../../core/api/ai_intake.dart';
import 'json_http.dart';

class BangumiSourceProvider implements SourceProvider {
  final JsonHttp transport;
  final Uri baseUrl;
  final DateTime Function() now;
  BangumiSourceProvider(
    this.transport, {
    Uri? baseUrl,
    DateTime Function()? now,
  }) : baseUrl = baseUrl ?? Uri.parse('https://api.bgm.tv'),
       now = now ?? DateTime.now;
  static const headers = {
    'User-Agent':
        'AnimeLog/AnimeLog/1.0.3 (Android; Windows; local personal client)',
  };

  @override
  Future<List<AnimeTitleCandidate>> search(
    String title,
    RequestScope scope,
  ) async {
    final response = await transport.json(
      'POST',
      baseUrl.resolve('/v0/search/subjects?limit=20&offset=0'),
      scope,
      headers: headers,
      source: true,
      body: {
        'keyword': title,
        'sort': 'match',
        'filter': {
          'type': [2],
        },
      },
    );
    if (response is! Map<String, dynamic> || response['data'] is! List) {
      throw const NetworkFailure(NetworkFailureKind.source);
    }
    final result = <AnimeTitleCandidate>[];
    for (final item in (response['data'] as List).take(20)) {
      if (item is! Map<String, dynamic> ||
          item['type'] != 2 ||
          item['id'] is! int ||
          item['id'] <= 0) {
        continue;
      }
      final metadata = mapSubject(item);
      result.add(
        AnimeTitleCandidate(
          id: item['id'],
          title: metadata.title,
          originalTitle: metadata.originalTitle,
          season: metadata.season,
          entryType: metadata.entryType,
          premiereDate: metadata.premiereDate,
          totalEpisodes: metadata.totalEpisodes,
        ),
      );
    }
    return result;
  }

  @override
  Future<AnimeMetadata> details(int id, RequestScope scope) async {
    final response = await transport.json(
      'GET',
      baseUrl.resolve('/v0/subjects/$id'),
      scope,
      headers: headers,
      source: true,
    );
    if (response is! Map<String, dynamic> ||
        response['id'] != id ||
        response['type'] != 2) {
      throw const NetworkFailure(NetworkFailureKind.source);
    }
    return mapSubject(response);
  }

  AnimeMetadata mapSubject(Map<String, dynamic> subject) {
    final original = _text(subject['name']);
    final title = _text(subject['name_cn']) ?? original;
    if (title == null || title.length > 200) {
      throw const NetworkFailure(NetworkFailureKind.source);
    }
    final info = <String, String>{};
    if (subject['infobox'] is List) {
      for (final item in subject['infobox'] as List) {
        if (item is Map && item['key'] is String && item['value'] is String) {
          info[item['key']] = item['value'];
        }
      }
    }
    final end = _date(info['播放结束'] ?? info['放送終了']);
    final today = now().toIso8601String().substring(0, 10);
    final images = subject['images'];
    final cover = images is Map
        ? _text(images['common']) ?? _text(images['medium'])
        : null;
    final duration = RegExp(
      r'^\s*(\d+)\s*(?:分钟|分鐘|分|minutes?|mins?)\s*$',
      caseSensitive: false,
    ).firstMatch(info['片长'] ?? info['单集片长'] ?? info['毎話時間'] ?? '');
    return AnimeMetadata(
      title: title,
      originalTitle: original,
      sourceProvider: 'bangumi',
      sourceId: subject['id'].toString(),
      season: extractSeasonNumber(title) ?? extractSeasonNumber(original),
      entryType: switch (_text(subject['platform'])?.toLowerCase()) {
        'tv' => AnimeEntryType.tv,
        '剧场版' || '劇場版' || 'movie' => AnimeEntryType.movie,
        'ova' || 'oad' => AnimeEntryType.ova,
        'ona' || 'web' => AnimeEntryType.ona,
        'special' || 'sp' || '特别篇' || '特別篇' => AnimeEntryType.special,
        _ => null,
      },
      // total_episodes counts database chapters, including specials. eps is
      // the source's declared main episode count. Never use candidate order.
      totalEpisodes: _positive(subject['eps']),
      durationMinutes: duration == null
          ? null
          : _positive(int.tryParse(duration.group(1)!)),
      summary: _text(subject['summary']),
      coverUrl: _httpUrl(cover),
      premiereDate: _date(subject['date']),
      isFinished: end == null ? null : end.compareTo(today) <= 0,
    );
  }
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
int? _positive(Object? value) => value is int && value > 0 ? value : null;
String? _httpUrl(String? value) {
  final uri = Uri.tryParse(value ?? '');
  return uri != null &&
          uri.host.isNotEmpty &&
          ['https', 'http'].contains(uri.scheme)
      ? value
      : null;
}

String? _date(Object? value) {
  final text = _text(value);
  if (text == null) return null;
  final direct = normalizeDateString(text);
  if (direct != null) return direct;
  final match = RegExp(r'^(\d{4})年(\d{1,2})月(\d{1,2})日$').firstMatch(text);
  if (match == null) return null;
  return normalizeDateString(
    '${match.group(1)}-${match.group(2)!.padLeft(2, '0')}-${match.group(3)!.padLeft(2, '0')}',
  );
}
