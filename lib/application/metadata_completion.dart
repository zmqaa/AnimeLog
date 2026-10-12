import '../core/anime_log_core.dart';
import '../core/api/ai_intake.dart';
import '../core/api/library_repository.dart';
import '../core/domain/metadata_completion.dart';

class CompletionLookup {
  final String title;
  final List<AnimeTitleCandidate> candidates;
  final MetadataCompletionPreview? preview;
  const CompletionLookup(this.title, this.candidates, {this.preview});
}

/// No AI client or creation repository: completion reads real source metadata
/// and uses a distinct transaction that never writes personal fields.
class MetadataCompletionService {
  final LibraryRepository records;
  final SourceProvider source;
  MetadataCompletionService(this.records, this.source);
  Future<CompletionLookup> lookup(String uuid, RequestScope scope) async {
    final record = await scope.guard(records.find(uuid));
    if (record == null) throw const QuickRecordValidationException('记录不存在');
    final metadata = record.metadata;
    if (metadata.sourceProvider != null) {
      final id = int.tryParse(metadata.sourceId ?? '');
      if (metadata.sourceProvider != 'bangumi' || id == null || id <= 0) {
        throw const QuickRecordValidationException('当前来源不支持自动补全，请手动核对并编辑资料');
      }
      final preview = await choose(uuid, id, scope);
      return CompletionLookup(metadata.title, const [], preview: preview);
    }
    final byId = <int, AnimeTitleCandidate>{};
    for (final query in {
      metadata.title,
      if (metadata.originalTitle != null) metadata.originalTitle!,
    }) {
      for (final candidate in await source.search(query.trim(), scope)) {
        byId.putIfAbsent(candidate.id, () => candidate);
      }
    }
    scope.check();
    return CompletionLookup(metadata.title, byId.values.take(40).toList());
  }

  Future<MetadataCompletionPreview> choose(
    String uuid,
    int id,
    RequestScope scope,
  ) async {
    final metadata = await source.details(id, scope);
    scope.check();
    if (metadata.sourceProvider != 'bangumi' ||
        metadata.sourceId != id.toString()) {
      throw const NetworkFailure(NetworkFailureKind.source);
    }
    return scope.guard(records.previewMetadataCompletion(uuid, metadata));
  }

  Future<int> apply(MetadataCompletionPreview confirmed) =>
      records.applyMetadataCompletion(confirmed);
}
