import 'dart:convert';

/// 兼容严格 JSON、```json 代码块和带少量解释文字的模型响应。
///
/// 解析失败返回 null；调用方必须把 null 当作可恢复错误处理，不能把原文直接写入数据库。
Object? parseJsonFromAiContent(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) return null;

  Object? tryDecode(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  final direct = tryDecode(normalized);
  if (direct != null) return direct;

  final fenced = RegExp(
    r'```(?:json)?\s*([\s\S]*?)\s*```',
    caseSensitive: false,
  ).firstMatch(normalized)?.group(1)?.trim();
  if (fenced != null) {
    final decoded = tryDecode(fenced);
    if (decoded != null) return decoded;
  }

  final start = normalized.indexOf('{');
  final end = normalized.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  return tryDecode(normalized.substring(start, end + 1));
}
