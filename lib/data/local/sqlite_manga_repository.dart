import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/manga_repository.dart';
import '../../core/anime_log_core.dart';
import 'app_database.dart';

class SqliteMangaRepository implements MangaRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  SqliteMangaRepository(this.db);

  @override
  Stream<List<MangaRecord>> watchAll() =>
      (db.select(db.manga)..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
          .watch()
          .map((rows) => rows.map(_record).toList());

  @override
  Future<MangaRecord?> find(String uuid) async {
    final row = await (db.select(
      db.manga,
    )..where((m) => m.uuid.equals(uuid))).getSingleOrNull();
    return row == null ? null : _record(row);
  }

  @override
  Future<MangaRecord> create(MangaDraft draft) async {
    _validate(draft);
    final uuid = draft.uuid ?? _uuid.v4();
    final now = _now();
    await db
        .into(db.manga)
        .insert(
          _values(draft).copyWith(
            uuid: Value(uuid),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return (await find(uuid))!;
  }

  @override
  Future<void> edit(String uuid, MangaDraft draft) async {
    _validate(draft);
    final result =
        await (db.update(db.manga)..where((m) => m.uuid.equals(uuid))).write(
          _values(draft).copyWith(updatedAt: Value(_now())),
        );
    if (result == 0) {
      throw const QuickRecordValidationException('漫画记录不存在');
    }
  }

  @override
  Future<void> delete(String uuid) async {
    final result = await (db.delete(
      db.manga,
    )..where((m) => m.uuid.equals(uuid))).go();
    if (result == 0) {
      throw const QuickRecordValidationException('漫画记录不存在');
    }
  }

  MangaCompanion _values(MangaDraft d) => MangaCompanion(
    bangumiId: Value(d.bangumiId),
    title: Value(d.title.trim()),
    originalTitle: Value(_text(d.originalTitle)),
    aliases: Value(jsonEncode(d.aliases)),
    coverUrl: Value(_text(d.coverUrl)),
    status: Value(d.status.wireValue),
    publicationStatus: Value(d.publicationStatus.wireValue),
    score: Value(d.score),
    currentVolume: Value(d.currentVolume),
    currentChapter: Value(d.currentChapter),
    totalVolumes: Value(d.totalVolumes),
    totalChapters: Value(d.totalChapters),
    notes: Value(_text(d.notes)),
    tags: Value(jsonEncode(d.tags)),
    summary: Value(_text(d.summary)),
    authors: Value(jsonEncode(d.authors)),
    illustrators: Value(jsonEncode(d.illustrators)),
    publishers: Value(jsonEncode(d.publishers)),
    serializations: Value(jsonEncode(d.serializations)),
    startDate: Value(_text(d.startDate)),
    endDate: Value(_text(d.endDate)),
    releaseDate: Value(_text(d.releaseDate)),
  );

  MangaRecord _record(MangaData m) => MangaRecord(
    id: m.id,
    uuid: m.uuid,
    bangumiId: m.bangumiId,
    title: m.title,
    originalTitle: m.originalTitle,
    aliases: _strings(m.aliases),
    coverUrl: m.coverUrl,
    localCoverPath: m.localCoverPath,
    status: mangaReadingStatusFromWire(m.status)!,
    publicationStatus: mangaPublicationStatusFromWire(m.publicationStatus)!,
    score: m.score,
    currentVolume: m.currentVolume,
    currentChapter: m.currentChapter,
    totalVolumes: m.totalVolumes,
    totalChapters: m.totalChapters,
    notes: m.notes,
    tags: _strings(m.tags),
    summary: m.summary,
    authors: _strings(m.authors),
    illustrators: _strings(m.illustrators),
    publishers: _strings(m.publishers),
    serializations: _strings(m.serializations),
    startDate: m.startDate,
    endDate: m.endDate,
    releaseDate: m.releaseDate,
    createdAt: m.createdAt,
    updatedAt: m.updatedAt,
  );

  static List<String> _strings(String value) =>
      (jsonDecode(value) as List).cast<String>();

  static String? _text(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }

  static void _validate(MangaDraft d) {
    if (d.title.trim().isEmpty || d.title.trim().length > 500) {
      throw const QuickRecordValidationException('漫画标题不能为空且不能超过 500 个字符');
    }
    if (d.score != null &&
        (!d.score!.isFinite || d.score! < 0 || d.score! > 10)) {
      throw const QuickRecordValidationException('评分必须在 0 到 10 之间');
    }
    if (d.currentVolume != null && d.currentVolume! < 0 ||
        d.currentChapter != null && d.currentChapter! < 0) {
      throw const QuickRecordValidationException('当前卷数和话数不能为负数');
    }
    if (d.totalVolumes != null && d.totalVolumes! <= 0 ||
        d.totalChapters != null && d.totalChapters! <= 0) {
      throw const QuickRecordValidationException('总卷数和总话数必须为正数');
    }
    if (d.startDate != null &&
            normalizeDateString(d.startDate!) != d.startDate ||
        d.endDate != null && normalizeDateString(d.endDate!) != d.endDate ||
        d.releaseDate != null &&
            normalizeDateString(d.releaseDate!) != d.releaseDate) {
      throw const QuickRecordValidationException('漫画日期必须是有效的 YYYY-MM-DD');
    }
    if (d.startDate != null &&
        d.endDate != null &&
        d.startDate!.compareTo(d.endDate!) > 0) {
      throw const QuickRecordValidationException('开始日期不能晚于结束日期');
    }
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();
}
