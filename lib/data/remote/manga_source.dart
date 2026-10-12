import '../../core/anime_log_core.dart';
import '../../core/api/ai_intake.dart';
import '../../core/api/manga_intake.dart';
import 'json_http.dart';

class BangumiMangaSource implements MangaMetadataSource {
  final JsonHttp transport;
  final Uri baseUrl;

  BangumiMangaSource(this.transport, {Uri? baseUrl})
    : baseUrl = baseUrl ?? Uri.parse('https://api.bgm.tv');

  static const headers = {
    'User-Agent':
        'AnimeLog/AnimeLog/1.0.3 (Android; Windows; local personal client)',
  };

  @override
  Future<List<MangaMetadataCandidate>> search(
    String title,
    RequestScope scope,
  ) async {
    final response = await transport.json(
      'POST',
      baseUrl.resolve('/v0/search/subjects?limit=10&offset=0'),
      scope,
      headers: headers,
      source: true,
      body: {
        'keyword': title,
        'sort': 'match',
        'filter': {
          'type': [1],
        },
      },
    );
    if (response is! Map<String, dynamic> || response['data'] is! List) {
      throw const NetworkFailure(NetworkFailureKind.source);
    }

    final subjects = (response['data'] as List)
        .whereType<Map<String, dynamic>>()
        .where((item) => item['type'] == 1 && item['id'] is int)
        .where((item) => (item['id'] as int) > 0)
        .take(10)
        .toList(growable: false);
    if (subjects.isEmpty) return const [];

    final details = await Future.wait(
      subjects.take(5).map((subject) async {
        try {
          return await _details(subject['id'] as int, scope);
        } on NetworkFailure catch (failure) {
          if (failure.kind == NetworkFailureKind.cancelled) rethrow;
          return null;
        }
      }),
    );
    return [
      for (var index = 0; index < subjects.length; index++)
        details.length > index && details[index] != null
            ? mapSubject(details[index]!, detailLoaded: true)
            : mapSubject(subjects[index], detailLoaded: false),
    ];
  }

  Future<Map<String, dynamic>?> _details(int id, RequestScope scope) async {
    final response = await transport.json(
      'GET',
      baseUrl.resolve('/v0/subjects/$id'),
      scope,
      headers: headers,
      source: true,
    );
    if (response is! Map<String, dynamic> ||
        response['id'] != id ||
        response['type'] != 1) {
      throw const NetworkFailure(NetworkFailureKind.source);
    }
    return response;
  }

  MangaMetadataCandidate mapSubject(
    Map<String, dynamic> subject, {
    required bool detailLoaded,
  }) {
    final original = _text(subject['name']);
    final title = _text(subject['name_cn']) ?? original;
    final id = subject['id'];
    if (title == null || title.length > 500 || id is! int || id <= 0) {
      throw const NetworkFailure(NetworkFailureKind.source);
    }

    final startValue = _firstInfoboxValue(subject, RegExp(r'^(?:开始|连载开始)$'));
    final endValue = _firstInfoboxValue(subject, RegExp(r'^(?:结束|连载结束)$'));
    final publicationValue = _firstInfoboxValue(
      subject,
      RegExp(r'^(?:状态|连载状态)$'),
    );
    final volumeValue = _firstInfoboxValue(subject, RegExp(r'^(?:册数|卷数)$'));
    final chapterValue = _firstInfoboxValue(subject, RegExp(r'^(?:话数|章节数)$'));
    final finished =
        endValue != null ||
        (publicationValue != null &&
            RegExp(r'完结|終了', caseSensitive: false).hasMatch(publicationValue));
    final ongoing =
        publicationValue != null &&
        RegExp(
          r'连载中|連載中|ongoing',
          caseSensitive: false,
        ).hasMatch(publicationValue);
    final images = subject['images'];
    final cover = images is Map
        ? _text(images['large']) ??
              _text(images['common']) ??
              _text(images['medium'])
        : null;

    return MangaMetadataCandidate(
      id: id,
      title: title,
      originalTitle: original == title ? null : original,
      aliases: _infoboxValues(subject, RegExp(r'^(?:别名|又名)$')),
      authors: _infoboxValues(subject, RegExp(r'^(?:作者|原作)$')),
      illustrators: _infoboxValues(subject, RegExp(r'^(?:作画|插画)$')),
      publishers: _infoboxValues(subject, RegExp(r'^(?:出版社)$')),
      serializations: _infoboxValues(subject, RegExp(r'^(?:连载杂志|连载平台)$')),
      releaseDate: _date(subject['date']),
      startDate: _date(startValue),
      endDate: _date(endValue),
      volumeCount: _positive(subject['volumes']) ?? _positive(volumeValue),
      chapterCount: _positive(subject['eps']) ?? _positive(chapterValue),
      isFinished: finished
          ? true
          : ongoing
          ? false
          : null,
      coverUrl: _httpUrl(cover),
      summary: _text(subject['summary']),
      tags: _tags(subject['tags']),
      detailLoaded: detailLoaded,
    );
  }
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

int? _positive(Object? value) {
  if (value is int && value > 0) return value;
  if (value is num &&
      value.isFinite &&
      value > 0 &&
      value == value.roundToDouble()) {
    return value.toInt();
  }
  final match = RegExp(r'\d+').firstMatch('$value');
  final parsed = match == null ? null : int.tryParse(match.group(0)!);
  return parsed != null && parsed > 0 ? parsed : null;
}

List<String> _infoboxValues(Map<String, dynamic> subject, RegExp keys) {
  final infobox = subject['infobox'];
  if (infobox is! List) return const [];
  return uniqueStrings(
    infobox
        .whereType<Map>()
        .where((item) {
          final key = item['key'];
          return key is String && keys.hasMatch(key.trim());
        })
        .expand((item) => _flatten(item['value'])),
  );
}

String? _firstInfoboxValue(Map<String, dynamic> subject, RegExp keys) {
  final values = _infoboxValues(subject, keys);
  return values.isEmpty ? null : values.first;
}

Iterable<String> _flatten(Object? value) sync* {
  if (value is String || value is num) {
    final text = '$value'.trim();
    if (text.isNotEmpty) yield text;
    return;
  }
  if (value is List) {
    for (final item in value) {
      yield* _flatten(item);
    }
    return;
  }
  if (value is Map) {
    if (value['v'] is String || value['v'] is num) {
      yield* _flatten(value['v']);
      return;
    }
    for (final item in value.values) {
      yield* _flatten(item);
    }
  }
}

List<String> _tags(Object? value) {
  if (value is! List) return const [];
  final tags = <({String name, int count})>[];
  for (final item in value.whereType<Map>()) {
    final name = _text(item['name']);
    if (name == null) continue;
    tags.add((name: name, count: _positive(item['count']) ?? 0));
  }
  tags.sort((a, b) => b.count.compareTo(a.count));
  return uniqueStrings(tags.take(12).map((tag) => tag.name));
}

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
  final embedded = RegExp(r'(\d{4})[-年/.](\d{1,2})[-月/.](\d{1,2})')
      .firstMatch(text);
  final found = match ?? embedded;
  if (found == null) return null;
  return normalizeDateString(
    '${found.group(1)}-${found.group(2)!.padLeft(2, '0')}-${found.group(3)!.padLeft(2, '0')}',
  );
}
