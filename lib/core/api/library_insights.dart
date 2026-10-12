import '../domain/quick_record_models.dart';

/// Optional read-only aggregate feed; CRUD repositories keep their contract.
abstract interface class LibraryInsightsRepository {
  Stream<List<WatchHistoryRecord>> watchAllHistory();
}
