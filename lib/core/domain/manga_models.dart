enum MangaReadingStatus {
  planToRead,
  reading,
  caughtUp,
  completed,
  paused,
  dropped,
}

extension MangaReadingStatusWire on MangaReadingStatus {
  String get wireValue => switch (this) {
    MangaReadingStatus.planToRead => 'plan_to_read',
    MangaReadingStatus.reading => 'reading',
    MangaReadingStatus.caughtUp => 'caught_up',
    MangaReadingStatus.completed => 'completed',
    MangaReadingStatus.paused => 'paused',
    MangaReadingStatus.dropped => 'dropped',
  };

  String get label => switch (this) {
    MangaReadingStatus.planToRead => '想读',
    MangaReadingStatus.reading => '阅读中',
    MangaReadingStatus.caughtUp => '已追到最新',
    MangaReadingStatus.completed => '已读完',
    MangaReadingStatus.paused => '搁置',
    MangaReadingStatus.dropped => '弃读',
  };
}

MangaReadingStatus? mangaReadingStatusFromWire(Object? value) =>
    switch (value) {
      'plan_to_read' => MangaReadingStatus.planToRead,
      'reading' => MangaReadingStatus.reading,
      'caught_up' => MangaReadingStatus.caughtUp,
      'completed' => MangaReadingStatus.completed,
      'paused' => MangaReadingStatus.paused,
      'dropped' => MangaReadingStatus.dropped,
      _ => null,
    };

enum MangaPublicationStatus { ongoing, completed, hiatus, unknown }

extension MangaPublicationStatusWire on MangaPublicationStatus {
  String get wireValue => name;

  String get label => switch (this) {
    MangaPublicationStatus.ongoing => '连载中',
    MangaPublicationStatus.completed => '已完结',
    MangaPublicationStatus.hiatus => '休载中',
    MangaPublicationStatus.unknown => '未知',
  };
}

MangaPublicationStatus? mangaPublicationStatusFromWire(Object? value) =>
    switch (value) {
      'ongoing' => MangaPublicationStatus.ongoing,
      'completed' => MangaPublicationStatus.completed,
      'hiatus' => MangaPublicationStatus.hiatus,
      'unknown' => MangaPublicationStatus.unknown,
      _ => null,
    };

/// 漫画没有单独的章节历史表，阅读位置直接保存在当前卷/章字段中。
class MangaRecord {
  final int id;
  final String uuid;
  final int? bangumiId;
  final String title;
  final String? originalTitle;
  final List<String> aliases;
  final String? coverUrl;
  final String? localCoverPath;
  final MangaReadingStatus status;
  final MangaPublicationStatus publicationStatus;
  final double? score;
  final int? currentVolume;
  final int? currentChapter;
  final int? totalVolumes;
  final int? totalChapters;
  final String? notes;
  final List<String> tags;
  final String? summary;
  final List<String> authors;
  final List<String> illustrators;
  final List<String> publishers;
  final List<String> serializations;
  final String? startDate;
  final String? endDate;
  final String? releaseDate;
  final String createdAt;
  final String updatedAt;

  const MangaRecord({
    required this.id,
    required this.uuid,
    required this.title,
    required this.status,
    required this.publicationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.bangumiId,
    this.originalTitle,
    this.aliases = const <String>[],
    this.coverUrl,
    this.localCoverPath,
    this.score,
    this.currentVolume,
    this.currentChapter,
    this.totalVolumes,
    this.totalChapters,
    this.notes,
    this.tags = const <String>[],
    this.summary,
    this.authors = const <String>[],
    this.illustrators = const <String>[],
    this.publishers = const <String>[],
    this.serializations = const <String>[],
    this.startDate,
    this.endDate,
    this.releaseDate,
  });
}

class MangaDraft {
  final String? uuid;
  final int? bangumiId;
  final String title;
  final String? originalTitle;
  final List<String> aliases;
  final String? coverUrl;
  final MangaReadingStatus status;
  final MangaPublicationStatus publicationStatus;
  final double? score;
  final int? currentVolume;
  final int? currentChapter;
  final int? totalVolumes;
  final int? totalChapters;
  final String? notes;
  final List<String> tags;
  final String? summary;
  final List<String> authors;
  final List<String> illustrators;
  final List<String> publishers;
  final List<String> serializations;
  final String? startDate;
  final String? endDate;
  final String? releaseDate;

  const MangaDraft({
    required this.title,
    this.uuid,
    this.bangumiId,
    this.originalTitle,
    this.aliases = const <String>[],
    this.coverUrl,
    this.status = MangaReadingStatus.planToRead,
    this.publicationStatus = MangaPublicationStatus.unknown,
    this.score,
    this.currentVolume,
    this.currentChapter,
    this.totalVolumes,
    this.totalChapters,
    this.notes,
    this.tags = const <String>[],
    this.summary,
    this.authors = const <String>[],
    this.illustrators = const <String>[],
    this.publishers = const <String>[],
    this.serializations = const <String>[],
    this.startDate,
    this.endDate,
    this.releaseDate,
  });
}

enum MangaIntakeStage { searching, choosing }

class MangaMetadataCandidate {
  final int id;
  final String title;
  final String? originalTitle;
  final List<String> aliases;
  final List<String> authors;
  final List<String> illustrators;
  final List<String> publishers;
  final List<String> serializations;
  final String? releaseDate;
  final String? startDate;
  final String? endDate;
  final int? volumeCount;
  final int? chapterCount;
  final bool? isFinished;
  final String? coverUrl;
  final String? summary;
  final List<String> tags;
  final bool detailLoaded;

  const MangaMetadataCandidate({
    required this.id,
    required this.title,
    this.originalTitle,
    this.aliases = const <String>[],
    this.authors = const <String>[],
    this.illustrators = const <String>[],
    this.publishers = const <String>[],
    this.serializations = const <String>[],
    this.releaseDate,
    this.startDate,
    this.endDate,
    this.volumeCount,
    this.chapterCount,
    this.isFinished,
    this.coverUrl,
    this.summary,
    this.tags = const <String>[],
    this.detailLoaded = false,
  });

  MangaDraft toDraft() => MangaDraft(
    bangumiId: id,
    title: title,
    originalTitle: originalTitle,
    aliases: aliases,
    coverUrl: coverUrl,
    publicationStatus: isFinished == true
        ? MangaPublicationStatus.completed
        : isFinished == false
        ? MangaPublicationStatus.ongoing
        : MangaPublicationStatus.unknown,
    totalVolumes: volumeCount,
    totalChapters: chapterCount,
    summary: summary,
    authors: authors,
    illustrators: illustrators,
    publishers: publishers,
    serializations: serializations,
    startDate: startDate,
    endDate: endDate,
    releaseDate: releaseDate,
    tags: tags,
  );
}

class MangaLookupResult {
  final String input;
  final List<MangaMetadataCandidate> candidates;
  final MangaMetadataCandidate? recommendation;
  final String reason;
  final Object? warning;

  const MangaLookupResult({
    required this.input,
    required this.candidates,
    required this.recommendation,
    required this.reason,
    this.warning,
  });
}
