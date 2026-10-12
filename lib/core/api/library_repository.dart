import '../anime_log_core.dart';
import '../domain/metadata_completion.dart';

class HistoryTrimPreview {
  final String animeUuid;
  final int targetProgress;
  final String recordUpdatedAt;
  final List<WatchHistoryRecord> events;
  HistoryTrimPreview(
    this.animeUuid,
    this.targetProgress,
    this.recordUpdatedAt,
    List<WatchHistoryRecord> events,
  ) : events = List.unmodifiable(events);
}

class HistoryUndoPreview {
  final String animeUuid;
  final String historyUuid;
  final int selectedEpisode;
  final int currentProgress;
  final int targetProgress;
  final String recordUpdatedAt;
  final List<WatchHistoryRecord> events;

  HistoryUndoPreview({
    required this.animeUuid,
    required this.historyUuid,
    required this.selectedEpisode,
    required this.currentProgress,
    required this.targetProgress,
    required this.recordUpdatedAt,
    required List<WatchHistoryRecord> events,
  }) : events = List.unmodifiable(events);
}

class DeleteSummary {
  final int historyCount;
  final int noteCount;
  const DeleteSummary(this.historyCount, this.noteCount);
}

/// A short-lived receipt for exactly one successful +1 operation.
class ProgressReceipt {
  final String token;
  final String animeUuid;
  final String historyUuid;
  const ProgressReceipt(this.token, this.animeUuid, this.historyUuid);
}

abstract interface class LibraryRepository {
  Stream<List<AnimeRecord>> watchLibrary();
  Future<AnimeRecord?> find(String uuid);
  Future<List<AnimeRecord>> all();
  Future<void> edit(
    String uuid,
    AnimeCreationDraft values, {
    bool manualStartDate = false,
    HistoryTrimPreview? trimHistory,
  });
  Future<HistoryTrimPreview> previewHistoryTrim(
    String uuid,
    int targetProgress,
  );
  Future<List<AnimeNote>> episodeNotes(String animeUuid);
  Future<String> saveEpisodeNote(
    String animeUuid, {
    String? noteUuid,
    required int episode,
    required String content,
    required String notedOn,
  });
  Future<void> deleteEpisodeNote(String animeUuid, String noteUuid);
  Future<MetadataCompletionPreview> previewMetadataCompletion(
    String uuid,
    AnimeMetadata source,
  );
  Future<int> applyMetadataCompletion(MetadataCompletionPreview confirmed);
  Future<List<WatchHistoryRecord>> history(String animeUuid);
  Future<ProgressReceipt> increment(String uuid, String watchedOn);

  /// Lower progress by one and remove viewing history above the new progress.
  Future<void> decrement(String uuid);
  Future<void> undoIncrement(ProgressReceipt receipt);
  Future<void> addHistory(
    String uuid,
    int episode,
    String watchedOn, {
    String? watchedAt,
  });

  /// Retains the known moment on an unchanged date unless explicitly cleared.
  Future<void> correctHistory(
    String historyUuid,
    int episode,
    String watchedOn, {
    String? watchedAt,
    bool clearTime = false,
  });
  Future<HistoryUndoPreview> previewHistoryUndo(String historyUuid);

  /// Undo the selected episode and remove later history in one transaction.
  /// When [confirmed] is provided, the operation rejects a stale preview.
  Future<void> deleteHistory(
    String historyUuid, {
    HistoryUndoPreview? confirmed,
  });
  Future<DeleteSummary> deletionSummary(String uuid);
  Future<void> delete(String uuid, DeleteSummary confirmedSummary);
}

abstract interface class IntakeDraftStore {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> data);
  Future<void> clear();
}
