import 'package:animelog/core/api/ai_intake.dart';
import 'package:animelog/core/api/library_repository.dart';
import 'package:animelog/core/anime_log_core.dart';

const configuration = AiConfiguration(
  baseUrl: 'https://ai.example/v1/',
  model: 'configured-model',
);
const subject = <String, dynamic>{
  'id': 253,
  'type': 2,
  'name_cn': '星际牛仔',
  'name': 'カウボーイビバップ',
  'platform': 'TV',
  'date': '1998-10-23',
  'eps': 26,
  'total_episodes': 31,
  'summary': '真实来源简介',
  'images': <String, dynamic>{},
  'infobox': [
    {'key': '播放结束', 'value': '1999年4月23日'},
    {'key': '单集片长', 'value': '24 分'},
  ],
};
const titlePayload = <String, dynamic>{
  'record': <String, dynamic>{
    'animeTitle': '星际牛仔',
    'originalTitle': null,
    'season': null,
    'entryType': null,
    'titleKind': null,
    'progress': 26,
    'score': 10,
    'status': 'completed',
    'tags': ['九刷'],
    'sourceId': 999,
  },
};

class MemoryConfigurations implements AiConfigurationStore {
  AiConfiguration? value;
  MemoryConfigurations([this.value = configuration]);
  @override
  Future<AiConfiguration?> load() async => value;
  @override
  Future<void> save(AiConfiguration configuration) async {
    value = configuration;
  }
}

class MemoryKeys implements ApiKeyStore {
  String? value;
  String? binding = configuration.endpoint.toString();
  MemoryKeys([this.value = 'fixture-secret']);
  @override
  Future<String?> read({String? endpoint}) async =>
      endpoint == null || endpoint == binding ? value : null;
  @override
  Future<void> write(String? key, {String? endpoint}) async {
    value = key;
    binding = endpoint;
  }
}

class MemoryDrafts implements IntakeDraftStore {
  Map<String, dynamic>? value;
  @override
  Future<Map<String, dynamic>?> load() async => value;
  @override
  Future<void> save(Map<String, dynamic> data) async {
    value = data;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class FixtureAi implements AiClient {
  final List<Object?> responses;
  final List<List<AiMessage>> calls = [];
  FixtureAi(this.responses);
  @override
  Future<Object?> complete(
    AiConfiguration configuration,
    String? key,
    List<AiMessage> messages,
    RequestScope scope,
  ) async {
    scope.check();
    calls.add(messages);
    final result = responses.removeAt(0);
    if (result is Exception) throw result;
    if (result is Future) return result;
    return result;
  }
}

class FixtureSource implements SourceProvider {
  final List<AnimeTitleCandidate> candidates;
  final List<String> searches = [];
  int detailCalls = 0;
  NetworkFailure? failure;
  FixtureSource([
    this.candidates = const [
      AnimeTitleCandidate(id: 253, title: '星际牛仔', entryType: AnimeEntryType.tv),
    ],
  ]);
  @override
  Future<List<AnimeTitleCandidate>> search(
    String title,
    RequestScope scope,
  ) async {
    scope.check();
    searches.add(title);
    if (failure != null) throw failure!;
    return candidates;
  }

  @override
  Future<AnimeMetadata> details(int id, RequestScope scope) async {
    scope.check();
    detailCalls++;
    return AnimeMetadata(
      title: '星际牛仔',
      originalTitle: 'カウボーイビバップ',
      sourceProvider: 'bangumi',
      sourceId: '$id',
      totalEpisodes: 26,
      entryType: AnimeEntryType.tv,
      summary: '真实来源简介',
    );
  }
}
