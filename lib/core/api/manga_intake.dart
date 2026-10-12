import '../domain/manga_models.dart';
import 'ai_intake.dart';

abstract interface class MangaMetadataSource {
  Future<List<MangaMetadataCandidate>> search(String title, RequestScope scope);
}
