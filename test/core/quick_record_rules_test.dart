import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:animelog/core/anime_log_core.dart';

int _passed = 0;

Future<void> _check(String name, FutureOr<void> Function() body) async {
  try {
    await body();
    _passed++;
  } catch (error) {
    throw StateError('$name: $error');
  }
}

void _expect(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('expected $expected, got $actual');
  }
}

void _expectList(List<Object?> actual, List<Object?> expected) {
  _expect(jsonEncode(actual), jsonEncode(expected));
}

void _rejects(void Function() body) {
  try {
    body();
  } on QuickRecordValidationException {
    return;
  }
  throw StateError('expected a validation rejection');
}

AnimeCreationDraft _draft({
  AnimeMetadata metadata = const AnimeMetadata(title: '某动画'),
  int progress = 0,
  double? score,
  AnimeStatus status = AnimeStatus.watching,
  int? rewatchCount,
  List<String> tags = const <String>[],
  String? startDate,
  String? endDate,
}) => AnimeCreationDraft(
  draftId: 'test-draft',
  metadata: metadata,
  progress: progress,
  score: score,
  status: status,
  rewatchCount: rewatchCount,
  tags: tags,
  startDate: startDate,
  endDate: endDate,
);

/// 仅测试创建用例的边界；真实 SQLite 的事务与幂等性另做集成测试。
class _CreationRepository implements AnimeCreationRepository {
  final Map<String, AnimeRecord> entriesByDraft = <String, AnimeRecord>{};
  int calls = 0;

  @override
  Future<AnimeCreationResult> createAtomically(AnimeCreationDraft draft) async {
    calls++;
    final existing = entriesByDraft[draft.draftId];
    if (existing != null) {
      return AnimeCreationResult(entry: existing, alreadySaved: true);
    }
    final entry = AnimeRecord(
      id: entriesByDraft.length + 1,
      uuid: 'test-record-${entriesByDraft.length + 1}',
      metadata: draft.metadata,
      status: draft.status,
      progress: draft.progress,
      score: draft.score,
      notes: draft.notes,
      tags: draft.tags,
      rewatchCount: draft.rewatchCount,
      startDate: draft.startDate,
      endDate: draft.endDate,
      createdAt: '2026-10-10T04:00:00.000Z',
      updatedAt: '2026-10-10T04:00:00.000Z',
    );
    entriesByDraft[draft.draftId] = entry;
    return AnimeCreationResult(entry: entry);
  }
}

const _knownWork = AnimeMetadata(
  title: '某动画',
  sourceProvider: 'bangumi',
  sourceId: '42',
  totalEpisodes: 12,
);

AnimeRecord _previousRecord({
  String uuid = 'previous-record',
  AnimeMetadata metadata = _knownWork,
  AnimeStatus status = AnimeStatus.completed,
  int? rewatchCount,
  List<String> tags = const <String>[],
}) => AnimeRecord(
  id: 1,
  uuid: uuid,
  metadata: metadata,
  status: status,
  progress: status == AnimeStatus.completed ? 12 : 4,
  score: 9,
  notes: '旧备注',
  tags: tags,
  rewatchCount: rewatchCount,
  createdAt: '2025-10-10T04:00:00.000Z',
  updatedAt: '2025-10-10T04:00:00.000Z',
);

Future<void> _runCoreChecks() async {
  await _check('没有旧记录时仍是普通新建', () {
    final suggestion = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: const <AnimeRecord>[],
    );
    _expect(suggestion.suggestedCount, null);
    _expect(suggestion.reason, RewatchSuggestionReason.noPreviousRecord);
  });

  await _check('同一来源作品已看完时建议二刷且不继承个人数据', () {
    final previous = _previousRecord();
    final draft = buildAnimeCreationDraft(
      draftId: 'automatic-second',
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[previous],
    );
    _expect(draft.rewatchCount, 2);
    _expectList(draft.tags, <String>['二刷']);
    _expect(draft.progress, 0);
    _expect(draft.score, null);
    _expect(draft.notes, null);
    _expect(previous.progress, 12);
    _expect(previous.score, 9);
  });

  await _check('最高明确刷次加一而不是数记录条数', () {
    final suggestion = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[_previousRecord(rewatchCount: 3)],
    );
    _expect(suggestion.suggestedCount, 4);
  });

  await _check('兼容旧标签但结构次数优先', () {
    final legacy = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[
        _previousRecord(tags: <String>['三刷', '5刷']),
      ],
    );
    _expect(legacy.suggestedCount, 6);
    final structured = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[
        _previousRecord(rewatchCount: 2, tags: <String>['五刷']),
      ],
    );
    _expect(structured.suggestedCount, 3);
  });

  await _check('重复 UUID 与重复无标签记录不抬高刷次', () {
    final duplicate = _previousRecord(rewatchCount: 2);
    final suggestion = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[duplicate, duplicate, duplicate],
    );
    _expect(suggestion.suggestedCount, 3);
    _expectList(suggestion.relatedRecordUuids, <String>['previous-record']);
    final unlabelled = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[
        _previousRecord(uuid: 'one'),
        _previousRecord(uuid: 'two'),
        _previousRecord(uuid: 'three'),
      ],
    );
    _expect(unlabelled.suggestedCount, 2);
  });

  await _check('同名不同来源 ID 或 provider 不串刷次', () {
    for (final other in const <AnimeMetadata>[
      AnimeMetadata(title: '某动画', sourceProvider: 'bangumi', sourceId: '43'),
      AnimeMetadata(title: '某动画', sourceProvider: 'other', sourceId: '42'),
    ]) {
      final suggestion = resolveRewatchSuggestion(
        metadata: _knownWork,
        existingRecords: <AnimeRecord>[
          _previousRecord(metadata: other, rewatchCount: 8),
        ],
      );
      _expect(suggestion.suggestedCount, null);
      _expect(suggestion.reason, RewatchSuggestionReason.noPreviousRecord);
    }
  });

  await _check('缺少来源时不同季度或形式也不串刷次', () {
    for (final other in const <AnimeMetadata>[
      AnimeMetadata(title: '某动画', season: 2, entryType: AnimeEntryType.tv),
      AnimeMetadata(title: '某动画', season: 1, entryType: AnimeEntryType.ova),
    ]) {
      final suggestion = resolveRewatchSuggestion(
        metadata: const AnimeMetadata(
          title: '某动画',
          season: 1,
          entryType: AnimeEntryType.tv,
        ),
        existingRecords: <AnimeRecord>[_previousRecord(metadata: other)],
      );
      _expect(suggestion.suggestedCount, null);
      _expect(suggestion.reason, RewatchSuggestionReason.noPreviousRecord);
    }
  });

  await _check('来源不明的同名记录需要确认身份', () {
    final previous = _previousRecord(
      metadata: const AnimeMetadata(title: '某动画'),
      tags: <String>['三刷'],
    );
    final uncertain = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[previous],
    );
    _expect(uncertain.suggestedCount, null);
    _expect(
      uncertain.reason,
      RewatchSuggestionReason.identityNeedsConfirmation,
    );
    final confirmed = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[previous],
      confirmedRecordUuids: <String>[previous.uuid],
    );
    _expect(confirmed.suggestedCount, 4);
  });

  await _check('已有未完成记录时不自动建议更高刷次', () {
    for (final status in <AnimeStatus>[
      AnimeStatus.watching,
      AnimeStatus.dropped,
      AnimeStatus.planToWatch,
    ]) {
      final suggestion = resolveRewatchSuggestion(
        metadata: _knownWork,
        existingRecords: <AnimeRecord>[
          _previousRecord(uuid: 'first'),
          _previousRecord(uuid: 'unfinished', status: status, rewatchCount: 2),
        ],
      );
      _expect(suggestion.suggestedCount, null);
      _expect(suggestion.reason, RewatchSuggestionReason.unfinishedRecord);
    }
  });

  await _check('用户可覆盖次数或关闭建议改成普通记录', () {
    final records = <AnimeRecord>[_previousRecord()];
    final manual = buildAnimeCreationDraft(
      draftId: 'manual-count',
      metadata: _knownWork,
      existingRecords: records,
      rewatchCount: 7,
    );
    _expectList(manual.tags, <String>['七刷']);
    final ordinary = buildAnimeCreationDraft(
      draftId: 'ordinary-override',
      metadata: _knownWork,
      existingRecords: records,
      useRewatchSuggestion: false,
    );
    _expect(ordinary.rewatchCount, null);
    _expectList(ordinary.tags, <String>[]);
  });

  await _check('同一稳定来源 ID 不因展示标题改名丢失关联', () {
    final suggestion = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[
        _previousRecord(
          metadata: const AnimeMetadata(
            title: '另一个译名',
            sourceProvider: 'bangumi',
            sourceId: '42',
          ),
        ),
      ],
    );
    _expect(suggestion.suggestedCount, 2);
  });

  await _check('保存只采用确认的草稿刷次，重试不重新计算', () async {
    final first = _previousRecord();
    final draft = buildAnimeCreationDraft(
      draftId: 'confirmed-second',
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[first],
    );
    final later = resolveRewatchSuggestion(
      metadata: _knownWork,
      existingRecords: <AnimeRecord>[
        first,
        _previousRecord(uuid: 'later-second', rewatchCount: 2),
      ],
    );
    _expect(later.suggestedCount, 3);
    final repository = _CreationRepository();
    final saved = await saveConfirmedAnimeDraft(
      draft: draft,
      repository: repository,
    );
    final retry = await saveConfirmedAnimeDraft(
      draft: draft,
      repository: repository,
    );
    _expect(saved.entry.rewatchCount, 2);
    _expect(retry.entry.rewatchCount, 2);
    _expect(retry.alreadySaved, true);
    _expect(repository.entriesByDraft.length, 1);
  });

  await _check('单部季度输入', () {
    final intent = parseSingleAnimeTitlePayload(
      jsonDecode(
        '{"record":{"animeTitle":"某动画","titleKind":"generic-season","season":2}}',
      ),
    );
    _expect(intent?.animeTitle, '某动画 第二季');
    _expect(intent?.season, 2);
  });

  await _check('官方副标题不机械追加季数', () {
    final intent = parseSingleAnimeTitlePayload(<String, dynamic>{
      'record': <String, dynamic>{
        'animeTitle': '某动画 某副标题',
        'titleKind': 'official',
        'season': 2,
      },
    });
    _expect(intent?.animeTitle, '某动画 某副标题');
  });

  await _check('作品形式识别', () {
    for (final type in <String>['movie', 'ova', 'ona', 'special', 'tv']) {
      final intent = parseSingleAnimeTitlePayload(<String, dynamic>{
        'record': <String, dynamic>{'animeTitle': '某动画', 'entryType': type},
      });
      _expect(intent?.entryType?.wireValue, type);
    }
  });

  await _check('不确定时可以返回空', () {
    _expect(
      parseSingleAnimeTitlePayload(<String, dynamic>{'record': null}),
      null,
    );
    _expect(parseSingleAnimeTitlePayload(null), null);
  });

  await _check('批量对象与数组均不取第一条', () {
    final record = <String, dynamic>{'animeTitle': '某动画'};
    _expect(
      parseSingleAnimeTitlePayload(<String, dynamic>{
        'records': <Object>[record],
      }),
      null,
    );
    _expect(
      parseSingleAnimeTitlePayload(<String, dynamic>{
        'record': <Object>[record],
      }),
      null,
    );
    _expect(
      parseSingleAnimeTitlePayload(<String, dynamic>{
        'record': record,
        'records': <Object>[],
      }),
      null,
    );
  });

  await _check('拒绝缺少标题和旧平铺协议', () {
    _expect(
      parseSingleAnimeTitlePayload(<String, dynamic>{
        'record': <String, dynamic>{'animeTitle': '  '},
      }),
      null,
    );
    _expect(
      parseSingleAnimeTitlePayload(<String, dynamic>{'animeTitle': '某动画'}),
      null,
    );
  });

  await _check('不接受非法季数和形式', () {
    for (final season in <Object>[0, -1, 1.5, 1000, '2', double.nan]) {
      _expect(
        ParsedAnimeTitleIntent.tryParse(<String, dynamic>{
          'animeTitle': '某动画',
          'season': season,
        }),
        null,
      );
    }
    _expect(
      ParsedAnimeTitleIntent.tryParse(<String, dynamic>{
        'animeTitle': '某动画',
        'entryType': 'unknown-type',
      }),
      null,
    );
  });

  await _check('AI 的个人字段和虚构资料被隔离', () {
    final intent = parseSingleAnimeTitlePayload(
      jsonDecode(
        '{"record":{"animeTitle":"某动画","progress":12,"status":"completed","score":10,"watchedAt":"2020-01-01","rewatchTag":"三刷","tags":["三刷"],"summary":"虚构简介","sourceId":"999","totalEpisodes":12}}',
      ),
    );
    _expect(intent != null, true);
    _expectList(intent!.toJson().keys.toList(), <String>[
      'animeTitle',
      'originalTitle',
      'titleKind',
      'season',
      'entryType',
    ]);
    final draft = buildAnimeCreationDraft(
      draftId: 'single-input',
      metadata: AnimeMetadata(title: intent.animeTitle),
    );
    _expect(draft.progress, 0);
    _expect(draft.status, AnimeStatus.watching);
    _expect(draft.score, null);
    _expect(draft.startDate, null);
    _expect(draft.metadata.totalEpisodes, null);
    _expectList(draft.tags, <String>[]);
  });

  await _check('普通与重刷草稿均从零开始', () {
    final normal = buildAnimeCreationDraft(
      draftId: 'normal',
      metadata: const AnimeMetadata(title: '某动画', totalEpisodes: 12),
    );
    final rewatch = buildAnimeCreationDraft(
      draftId: 'rewatch',
      metadata: const AnimeMetadata(title: '某动画', totalEpisodes: 12),
      rewatchCount: 3,
    );
    _expect(normal.progress, 0);
    _expect(rewatch.progress, 0);
    _expect(normal.rewatchCount, null);
    _expect(rewatch.rewatchCount, 3);
    _expectList(normal.tags, <String>[]);
    _expectList(rewatch.tags, <String>['三刷']);
  });

  await _check('重刷次数由用户指定，可超过两次', () {
    _expect(rewatchLabel(null), null);
    _expect(rewatchLabel(2), '二刷');
    _expect(rewatchLabel(10), '十刷');
    _expect(rewatchLabel(11), '十一刷');
    _expect(rewatchLabel(101), '101刷');
    _rejects(() => rewatchLabel(1));
  });

  await _check('重刷标签由次数统一派生', () {
    _expectList(
      buildCreationTags(<String>['日常', '二刷', '3刷', '日常', ' '], 4),
      <String>['日常', '四刷'],
    );
    _expectList(buildCreationTags(<String>['二刷', '日常'], null), <String>['日常']);
    _rejects(
      () => validateAnimeCreationDraft(
        _draft(tags: <String>['三刷'], rewatchCount: 2),
      ),
    );
  });

  await _check('评分零和满分合法', () {
    validateAnimeCreationDraft(_draft(score: 0));
    validateAnimeCreationDraft(_draft(score: 10));
    validateAnimeCreationDraft(_draft(score: null));
  });

  await _check('非法评分在写入前拒绝', () {
    for (final score in <double>[-1, 10.1, double.nan, double.infinity]) {
      _rejects(() => validateAnimeCreationDraft(_draft(score: score)));
    }
  });

  await _check('进度归零有效，超出已知总集数拒绝', () {
    validateAnimeCreationDraft(_draft(progress: 0));
    _rejects(() => validateAnimeCreationDraft(_draft(progress: -1)));
    _rejects(
      () => validateAnimeCreationDraft(
        _draft(
          metadata: const AnimeMetadata(title: '某动画', totalEpisodes: 12),
          progress: 13,
        ),
      ),
    );
  });

  await _check('已完成状态与已知总集数一致', () {
    _rejects(
      () => validateAnimeCreationDraft(
        _draft(
          metadata: const AnimeMetadata(title: '某动画', totalEpisodes: 12),
          status: AnimeStatus.completed,
        ),
      ),
    );
    validateAnimeCreationDraft(
      _draft(
        metadata: const AnimeMetadata(title: '某动画', totalEpisodes: 12),
        status: AnimeStatus.completed,
        progress: 12,
      ),
    );
    validateAnimeCreationDraft(
      _draft(status: AnimeStatus.completed, progress: 0),
    );
    _rejects(
      () => validateAnimeCreationDraft(
        _draft(status: AnimeStatus.planToWatch, progress: 1),
      ),
    );
  });

  await _check('来源 ID 与 provider 成对', () {
    _rejects(
      () => validateAnimeCreationDraft(
        _draft(
          metadata: const AnimeMetadata(title: '某动画', sourceId: '42'),
        ),
      ),
    );
    validateAnimeCreationDraft(
      _draft(
        metadata: const AnimeMetadata(
          title: '某动画',
          sourceProvider: 'bangumi',
          sourceId: '42',
        ),
      ),
    );
  });

  await _check('日期校验及清空日期', () {
    _expect(normalizeDateString('2024-02-29'), '2024-02-29');
    _expect(normalizeDateString('2026-02-29'), null);
    _expect(normalizeDateString('0000-01-01'), null);
    _rejects(() => validateAnimeCreationDraft(_draft(startDate: '2026-02-29')));
    _rejects(
      () => validateAnimeCreationDraft(
        _draft(
          startDate: '2026-10-10',
          endDate: '2026-10-09',
          status: AnimeStatus.completed,
        ),
      ),
    );
    validateAnimeCreationDraft(_draft(startDate: null, endDate: null));
  });

  await _check('JSON 代码块清洗仍可用', () {
    _expect(
      parseSingleAnimeTitlePayload(parseJsonFromAiContent('~~~invalid')),
      null,
    );
    _expect(
      parseSingleAnimeTitlePayload(
        parseJsonFromAiContent('说明 {"record":{"animeTitle":"某动画"}}'),
      )?.animeTitle,
      '某动画',
    );
    _expect(
      parseSingleAnimeTitlePayload(parseJsonFromAiContent('invalid JSON')),
      null,
    );
  });

  await _check('严格匹配保留续作标点', () {
    _expect(
      normalizeTitleToken('NEW GAME!') == normalizeTitleToken('NEW GAME!!'),
      false,
    );
    _expect(
      pickHighConfidenceAnimeCandidate(const <AnimeTitleCandidate>[
        AnimeTitleCandidate(id: 1, title: 'NEW GAME!!'),
      ], const AnimeCandidateIntent(userTitle: 'NEW GAME!')),
      null,
    );
  });

  await _check('匹配候选必须符合明确形式', () {
    _expect(
      pickHighConfidenceAnimeCandidate(
        const <AnimeTitleCandidate>[
          AnimeTitleCandidate(
            id: 1,
            title: '某动画',
            entryType: AnimeEntryType.tv,
          ),
        ],
        const AnimeCandidateIntent(
          userTitle: '某动画',
          expectedEntryType: AnimeEntryType.ova,
        ),
      ),
      null,
    );
  });

  await _check('AI 不能选错季度的有效 ID', () async {
    final result = await selectAnimeCandidate(
      candidates: const <AnimeTitleCandidate>[
        AnimeTitleCandidate(id: 1, title: '某动画 第一季', season: 1),
      ],
      intent: const AnimeCandidateIntent(
        userTitle: '某动画 第二季',
        expectedSeason: 2,
      ),
      requestSelectedId: () async => 1,
    );
    _expect(result, null);
  });

  await _check('AI 不能选错作品形式的有效 ID', () async {
    final result = await selectAnimeCandidate(
      candidates: const <AnimeTitleCandidate>[
        AnimeTitleCandidate(
          id: 1,
          title: '某动画',
          entryType: AnimeEntryType.movie,
        ),
      ],
      intent: const AnimeCandidateIntent(
        userTitle: '某动画',
        expectedEntryType: AnimeEntryType.ova,
      ),
      requestSelectedId: () async => 1,
    );
    _expect(result, null);
  });

  await _check('不存在的候选 ID 不静默变成第一条', () async {
    var requests = 0;
    final result = await selectAnimeCandidate(
      candidates: const <AnimeTitleCandidate>[
        AnimeTitleCandidate(id: 1, title: '另一个作品'),
      ],
      intent: const AnimeCandidateIntent(userTitle: '某动画'),
      requestSelectedId: () async {
        requests++;
        return 999;
      },
    );
    _expect(result, null);
    _expect(requests, 1);
  });

  await _check('未给模型展示的第 21 个候选不接受', () async {
    final candidates = List<AnimeTitleCandidate>.generate(
      21,
      (index) => AnimeTitleCandidate(id: index + 1, title: '候选$index'),
    );
    final result = await selectAnimeCandidate(
      candidates: candidates,
      intent: const AnimeCandidateIntent(userTitle: '某动画'),
      requestSelectedId: () async => 21,
    );
    _expect(result, null);
  });

  await _check('网络失败保留唯一精确匹配路径', () async {
    final result = await selectAnimeCandidate(
      candidates: const <AnimeTitleCandidate>[
        AnimeTitleCandidate(id: 1, title: '某动画'),
      ],
      intent: const AnimeCandidateIntent(userTitle: '某动画'),
      requestSelectedId: () async => throw StateError('network unavailable'),
    );
    _expect(result?.id, 1);
  });

  await _check('同分歧义交给用户，不任意选取', () {
    _expect(
      pickHighConfidenceAnimeCandidate(const <AnimeTitleCandidate>[
        AnimeTitleCandidate(id: 1, title: '某动画'),
        AnimeTitleCandidate(id: 2, title: '某动画'),
      ], const AnimeCandidateIntent(userTitle: '某动画')),
      null,
    );
  });

  await _check('非法草稿不进入 Repository', () async {
    final repository = _CreationRepository();
    var rejected = false;
    try {
      await saveConfirmedAnimeDraft(
        draft: _draft(score: 99),
        repository: repository,
      );
    } on QuickRecordValidationException {
      rejected = true;
    }
    _expect(rejected, true);
    _expect(repository.calls, 0);
  });

  await _check('同名普通与重刷使用独立新建请求', () async {
    final repository = _CreationRepository();
    final normal = buildAnimeCreationDraft(
      draftId: 'normal',
      metadata: const AnimeMetadata(title: '某动画'),
    );
    final rewatch = buildAnimeCreationDraft(
      draftId: 'rewatch',
      metadata: const AnimeMetadata(title: '某动画'),
      rewatchCount: 2,
    );
    final first = await saveConfirmedAnimeDraft(
      draft: normal,
      repository: repository,
    );
    final second = await saveConfirmedAnimeDraft(
      draft: rewatch,
      repository: repository,
    );
    _expect(repository.entriesByDraft.length, 2);
    _expect(first.entry.uuid == second.entry.uuid, false);
    _expectList(first.entry.tags, <String>[]);
    _expectList(second.entry.tags, <String>['二刷']);
    _expect(first.entry.progress, 0);
    _expect(second.entry.progress, 0);
  });

  await _check('保存重试保留草稿身份及 Repository 结果', () async {
    final repository = _CreationRepository();
    final draft = buildAnimeCreationDraft(
      draftId: 'same-draft',
      metadata: const AnimeMetadata(title: '某动画'),
    );
    final first = await saveConfirmedAnimeDraft(
      draft: draft,
      repository: repository,
    );
    final retry = await saveConfirmedAnimeDraft(
      draft: draft,
      repository: repository,
    );
    _expect(retry.alreadySaved, true);
    _expect(first.entry.uuid, retry.entry.uuid);
    _expect(repository.entriesByDraft.length, 1);
  });

  // ignore: avoid_print
  print('$_passed core behavior checks passed.');
}

void main() {
  test('core behavior checks', () async {
    await _runCoreChecks();
  });
}
