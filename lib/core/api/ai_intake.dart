import 'dart:async';
import 'dart:typed_data';

import '../ai/quick_record_prompt.dart';
import '../domain/quick_record_models.dart';
import '../domain/title_matching.dart';

enum NetworkFailureKind {
  unconfigured,
  timeout,
  offline,
  authentication,
  rateLimited,
  invalidResponse,
  source,
  cancelled,
  storage,
  storagePluginMissing,
}

class NetworkFailure implements Exception {
  final NetworkFailureKind kind;
  const NetworkFailure(this.kind);
  @override
  String toString() => switch (kind) {
    NetworkFailureKind.unconfigured => '请先配置接口地址和模型',
    NetworkFailureKind.timeout => '请求超时，请重试或手动添加',
    NetworkFailureKind.offline => '无法连接网络，请检查连接或手动添加',
    NetworkFailureKind.authentication => '接口认证失败，请检查 API Key',
    NetworkFailureKind.rateLimited => '接口限流，请稍后重试',
    NetworkFailureKind.invalidResponse => '接口响应无效，请重试或手动添加',
    NetworkFailureKind.source => 'Bangumi 资料查询失败，可重试或仅保存标题',
    NetworkFailureKind.cancelled => '已取消',
    NetworkFailureKind.storage => '系统安全存储不可用，请重试',
    NetworkFailureKind.storagePluginMissing => '当前安装包缺少安全存储组件，请安装修复版应用',
  };
}

/// One operation owns its deadline and cancellation. Cancelling also closes
/// active HTTP clients; a future that ignores cancellation cannot win the race.
class RequestScope {
  final Duration budget;
  final Stopwatch _clock = Stopwatch()..start();
  final Completer<NetworkFailure> _cancelled = Completer();
  final Set<void Function()> _closers = {};
  NetworkFailure? _failure;
  RequestScope({this.budget = const Duration(seconds: 45)});
  bool get isCancelled => _cancelled.isCompleted;
  Future<NetworkFailure> get cancellation => _cancelled.future;
  void check() {
    if (isCancelled) throw _failure!;
    if (_clock.elapsed >= budget) {
      cancel(const NetworkFailure(NetworkFailureKind.timeout));
      throw const NetworkFailure(NetworkFailureKind.timeout);
    }
  }

  void attach(void Function() close) {
    check();
    _closers.add(close);
  }

  void detach(void Function() close) => _closers.remove(close);
  void cancel([
    NetworkFailure reason = const NetworkFailure(NetworkFailureKind.cancelled),
  ]) {
    if (isCancelled) return;
    _failure = reason;
    _cancelled.complete(reason);
    for (final close in _closers.toList()) {
      close();
    }
    _closers.clear();
  }

  Future<T> guard<T>(Future<T> future, {Duration? limit}) async {
    check();
    final remaining = budget - _clock.elapsed;
    final duration = limit == null || remaining < limit ? remaining : limit;
    return Future.any<T>([
      future,
      cancellation.then<T>((failure) => throw failure),
    ]).timeout(
      duration,
      onTimeout: () {
        const failure = NetworkFailure(NetworkFailureKind.timeout);
        cancel(failure);
        throw failure;
      },
    );
  }
}

class AiConfiguration {
  final String baseUrl;
  final String model;
  const AiConfiguration({required this.baseUrl, required this.model});
  Uri get endpoint {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !['https', 'http'].contains(uri.scheme)) {
      throw const FormatException('接口地址必须是有效的 HTTPS base URL');
    }
    if (uri.scheme == 'http' && !_localHost(uri.host)) {
      throw const FormatException('HTTP 仅用于明确配置的本地或局域网接口');
    }
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.endsWith('/chat/completions')) {
      throw const FormatException('请填写 base URL，不包含 chat/completions');
    }
    return uri.replace(path: '$path/chat/completions');
  }

  void validate() {
    endpoint;
    if (model.trim().isEmpty || model.length > 200) {
      throw const FormatException('请填写模型名称（最多 200 字符）');
    }
  }
}

bool _localHost(String host) {
  if (['localhost', '::1'].contains(host.toLowerCase())) return true;
  final parts = host.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) {
    return false;
  }
  return parts[0] == 127 ||
      parts[0] == 10 ||
      (parts[0] == 192 && parts[1] == 168) ||
      (parts[0] == 172 && parts[1]! >= 16 && parts[1]! <= 31);
}

abstract interface class AiConfigurationStore {
  Future<AiConfiguration?> load();
  Future<void> save(AiConfiguration configuration);
}

abstract interface class ApiKeyStore {
  Future<String?> read({String? endpoint});
  Future<void> write(String? key, {String? endpoint});
}

abstract interface class AiClient {
  Future<Object?> complete(
    AiConfiguration configuration,
    String? key,
    List<AiMessage> messages,
    RequestScope scope,
  );
}

abstract interface class SourceProvider {
  Future<List<AnimeTitleCandidate>> search(String title, RequestScope scope);
  Future<AnimeMetadata> details(int id, RequestScope scope);
}

abstract interface class CoverStore {
  Future<Uint8List?> load(String url);
}
