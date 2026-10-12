/// 与平台无关的中文标题和数字处理工具。
///
/// 这些函数不依赖 Flutter、网络或数据库，可以在 Android、Windows 和测试中复用。
library;

const Map<String, int> _cjkDigitMap = <String, int>{
  '零': 0,
  '〇': 0,
  '一': 1,
  '二': 2,
  '两': 2,
  '三': 3,
  '四': 4,
  '五': 5,
  '六': 6,
  '七': 7,
  '八': 8,
  '九': 9,
};

/// 解析阿拉伯数字或中文数字 token，例如 `3`、`三`、`十二`、`二十三`。
int? parseChineseNumberToken(String? token) {
  final normalized = token?.trim() ?? '';
  if (normalized.isEmpty) return null;

  if (RegExp(r'^\d+$').hasMatch(normalized)) {
    final parsed = int.tryParse(normalized);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  var value = 0;
  var current = 0;
  for (final char in normalized.split('')) {
    final digit = _cjkDigitMap[char];
    if (digit != null) {
      current = digit;
    } else if (char == '十') {
      value += (current == 0 ? 1 : current) * 10;
      current = 0;
    } else if (char == '百') {
      value += (current == 0 ? 1 : current) * 100;
      current = 0;
    } else {
      return null;
    }
  }

  final result = value + current;
  return result > 0 ? result : null;
}

String toChineseNumberToken(int value) {
  if (value <= 0) return value.toString();
  const digits = <String>['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  if (value < 10) return digits[value];
  if (value < 20) return '十${value % 10 == 0 ? '' : digits[value % 10]}';
  if (value < 100) {
    final tens = value ~/ 10;
    final ones = value % 10;
    return '${digits[tens]}十${ones == 0 ? '' : digits[ones]}';
  }
  return value.toString();
}

final RegExp _seasonZh = RegExp(
  r'第\s*([0-9一二三四五六七八九十百零两〇]+)\s*[季期]',
  caseSensitive: false,
);
final RegExp _seasonEn = RegExp(
  r'\bseason\s*([0-9]{1,3})\b',
  caseSensitive: false,
);
final RegExp _seasonS = RegExp(r'\bS\s*([0-9]{1,3})\b', caseSensitive: false);

int? extractSeasonNumber(String? text) {
  final normalized = text?.trim() ?? '';
  if (normalized.isEmpty) return null;

  final zhToken = _seasonZh.firstMatch(normalized)?.group(1);
  if (zhToken != null) return parseChineseNumberToken(zhToken);

  final seasonToken = _seasonEn.firstMatch(normalized)?.group(1);
  if (seasonToken != null) return int.tryParse(seasonToken);

  final sToken = _seasonS.firstMatch(normalized)?.group(1);
  if (sToken != null) return int.tryParse(sToken);

  return null;
}

bool hasSeasonMarker(String text) {
  return _seasonZh.hasMatch(text) ||
      _seasonEn.hasMatch(text) ||
      _seasonS.hasMatch(text);
}

String stripSeasonToken(String? text) {
  var result = text ?? '';
  result = result.replaceAll(_seasonZh, ' ');
  result = result.replaceAll(_seasonEn, ' ');
  result = result.replaceAll(_seasonS, ' ');
  return result.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String appendSeasonToTitle(String title, int? season) {
  final normalized = title.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty ||
      season == null ||
      season <= 0 ||
      hasSeasonMarker(normalized)) {
    return normalized;
  }
  return '$normalized 第${toChineseNumberToken(season)}季';
}

String normalizeTitleToken(String? text) {
  if (text == null) return '';
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'''[\s\-_:：·・'"“”‘’`~，,.。()/\\\[\]【】]'''), '')
      .trim();
}

String? normalizeDateString(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(normalized);
  if (match == null) return null;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (year < 1) return null;
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return normalized;
}

List<String> uniqueStrings(Iterable<String> values) {
  final result = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || !seen.add(normalized)) continue;
    result.add(normalized);
  }
  return result;
}
