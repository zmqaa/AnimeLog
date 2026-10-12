import '../domain/quick_record_models.dart';
import '../domain/quick_record_rules.dart';

/// AI 请求只含一个作品查询；刷次由本地规则建议并在表单确认。
class AnimeTitleRecognitionRequest {
  final String query;

  const AnimeTitleRecognitionRequest({required this.query});
}

enum AnimeIntakeStage { recognizing, searching, choosing, ready, saving }

class AnimeCreationResult {
  final AnimeRecord entry;
  final bool alreadySaved;

  const AnimeCreationResult({required this.entry, this.alreadySaved = false});
}

/// 创建入口没有更新方法。实现须在同一事务中插入记录和 draftId 提交凭据。
/// 重复提交同一个 draftId 返回首次保存的记录；不能再次 INSERT。
/// 创建不会自动生成观看历史，也不会修改任何已有动漫记录。
abstract interface class AnimeCreationRepository {
  Future<AnimeCreationResult> createAtomically(AnimeCreationDraft draft);
}

/// 页面只在用户确认保存后调用。SQLite 事务和幂等性由 Repository 实现。
Future<AnimeCreationResult> saveConfirmedAnimeDraft({
  required AnimeCreationDraft draft,
  required AnimeCreationRepository repository,
}) {
  validateAnimeCreationDraft(draft);
  return repository.createAtomically(draft);
}
