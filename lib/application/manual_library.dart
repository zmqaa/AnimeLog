import '../core/anime_log_core.dart';
import '../core/api/library_repository.dart';

/// Both manual and AI intake use the existing create-only contract.
class ManualLibrary {
  final AnimeCreationRepository creation;
  final LibraryRepository records;
  const ManualLibrary(this.creation, this.records);

  Future<AnimeCreationResult> create(AnimeCreationDraft draft) =>
      saveConfirmedAnimeDraft(draft: draft, repository: creation);

  Future<void> edit(
    String uuid,
    AnimeCreationDraft draft, {
    bool manualStartDate = false,
    HistoryTrimPreview? trimHistory,
  }) {
    validateAnimeCreationDraft(draft);
    return records.edit(
      uuid,
      draft,
      manualStartDate: manualStartDate,
      trimHistory: trimHistory,
    );
  }

  Future<RewatchSuggestion> suggest(
    AnimeMetadata metadata, {
    Iterable<String> confirmed = const [],
  }) async => resolveRewatchSuggestion(
    metadata: metadata,
    existingRecords: await records.all(),
    confirmedRecordUuids: confirmed,
  );
}
