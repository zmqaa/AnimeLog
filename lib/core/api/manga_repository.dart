import '../domain/manga_models.dart';

abstract interface class MangaRepository {
  Stream<List<MangaRecord>> watchAll();
  Future<MangaRecord?> find(String uuid);
  Future<MangaRecord> create(MangaDraft draft);
  Future<void> edit(String uuid, MangaDraft draft);
  Future<void> delete(String uuid);
}
