// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class Anime extends Table with TableInfo<Anime, AnimeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Anime(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 200)',
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta(
    'originalTitle',
  );
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (season > 0)',
  );
  static const VerificationMeta _entryTypeMeta = const VerificationMeta(
    'entryType',
  );
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
    'entry_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (entry_type IN (\'tv\', \'movie\', \'ova\', \'ona\', \'special\'))',
  );
  static const VerificationMeta _sourceProviderMeta = const VerificationMeta(
    'sourceProvider',
  );
  late final GeneratedColumn<String> sourceProvider = GeneratedColumn<String>(
    'source_provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _totalEpisodesMeta = const VerificationMeta(
    'totalEpisodes',
  );
  late final GeneratedColumn<int> totalEpisodes = GeneratedColumn<int>(
    'total_episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (total_episodes > 0)',
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (duration_minutes > 0)',
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _premiereDateMeta = const VerificationMeta(
    'premiereDate',
  );
  late final GeneratedColumn<String> premiereDate = GeneratedColumn<String>(
    'premiere_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _isFinishedMeta = const VerificationMeta(
    'isFinished',
  );
  late final GeneratedColumn<bool> isFinished = GeneratedColumn<bool>(
    'is_finished',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _castMeta = const VerificationMeta('cast');
  late final GeneratedColumn<String> cast = GeneratedColumn<String>(
    'cast',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid("cast") AND json_type("cast") = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _castAliasesMeta = const VerificationMeta(
    'castAliases',
  );
  late final GeneratedColumn<String> castAliases = GeneratedColumn<String>(
    'cast_aliases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid(cast_aliases) AND json_type(cast_aliases) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _localCoverPathMeta = const VerificationMeta(
    'localCoverPath',
  );
  late final GeneratedColumn<String> localCoverPath = GeneratedColumn<String>(
    'local_cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'watching\', \'completed\', \'dropped\', \'plan_to_watch\'))',
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (progress >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (score >= 0 AND score <= 10)',
  );
  static const VerificationMeta _rewatchCountMeta = const VerificationMeta(
    'rewatchCount',
  );
  late final GeneratedColumn<int> rewatchCount = GeneratedColumn<int>(
    'rewatch_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (rewatch_count >= 2)',
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid(tags) AND json_type(tags) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _startDateSourceMeta = const VerificationMeta(
    'startDateSource',
  );
  late final GeneratedColumn<String> startDateSource = GeneratedColumn<String>(
    'start_date_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (start_date_source IN (\'manual\', \'history\'))',
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    title,
    originalTitle,
    season,
    entryType,
    sourceProvider,
    sourceId,
    totalEpisodes,
    durationMinutes,
    summary,
    coverUrl,
    premiereDate,
    isFinished,
    cast,
    castAliases,
    localCoverPath,
    status,
    progress,
    score,
    rewatchCount,
    tags,
    notes,
    startDate,
    startDateSource,
    endDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anime';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnimeData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(
          data['original_title']!,
          _originalTitleMeta,
        ),
      );
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    }
    if (data.containsKey('entry_type')) {
      context.handle(
        _entryTypeMeta,
        entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta),
      );
    }
    if (data.containsKey('source_provider')) {
      context.handle(
        _sourceProviderMeta,
        sourceProvider.isAcceptableOrUnknown(
          data['source_provider']!,
          _sourceProviderMeta,
        ),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('total_episodes')) {
      context.handle(
        _totalEpisodesMeta,
        totalEpisodes.isAcceptableOrUnknown(
          data['total_episodes']!,
          _totalEpisodesMeta,
        ),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('premiere_date')) {
      context.handle(
        _premiereDateMeta,
        premiereDate.isAcceptableOrUnknown(
          data['premiere_date']!,
          _premiereDateMeta,
        ),
      );
    }
    if (data.containsKey('is_finished')) {
      context.handle(
        _isFinishedMeta,
        isFinished.isAcceptableOrUnknown(data['is_finished']!, _isFinishedMeta),
      );
    }
    if (data.containsKey('cast')) {
      context.handle(
        _castMeta,
        cast.isAcceptableOrUnknown(data['cast']!, _castMeta),
      );
    }
    if (data.containsKey('cast_aliases')) {
      context.handle(
        _castAliasesMeta,
        castAliases.isAcceptableOrUnknown(
          data['cast_aliases']!,
          _castAliasesMeta,
        ),
      );
    }
    if (data.containsKey('local_cover_path')) {
      context.handle(
        _localCoverPathMeta,
        localCoverPath.isAcceptableOrUnknown(
          data['local_cover_path']!,
          _localCoverPathMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('rewatch_count')) {
      context.handle(
        _rewatchCountMeta,
        rewatchCount.isAcceptableOrUnknown(
          data['rewatch_count']!,
          _rewatchCountMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('start_date_source')) {
      context.handle(
        _startDateSourceMeta,
        startDateSource.isAcceptableOrUnknown(
          data['start_date_source']!,
          _startDateSourceMeta,
        ),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnimeData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimeData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_title'],
      ),
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      ),
      entryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_type'],
      ),
      sourceProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_provider'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      totalEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_episodes'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      premiereDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}premiere_date'],
      ),
      isFinished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_finished'],
      ),
      cast: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cast'],
      )!,
      castAliases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cast_aliases'],
      )!,
      localCoverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_cover_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      ),
      rewatchCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rewatch_count'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      startDateSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date_source'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  Anime createAlias(String alias) {
    return Anime(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((source_provider IS NULL AND source_id IS NULL)OR(length(trim(source_provider)) > 0 AND length(trim(source_id)) > 0 AND source_provider IS NOT NULL AND source_id IS NOT NULL))',
    'CHECK(total_episodes IS NULL OR progress <= total_episodes)',
    'CHECK(status != \'plan_to_watch\' OR progress = 0)',
    'CHECK(status != \'completed\' OR total_episodes IS NULL OR progress = total_episodes)',
    'CHECK(status = \'completed\' OR end_date IS NULL)',
    'CHECK(start_date IS NULL OR end_date IS NULL OR start_date <= end_date)',
    'CHECK(start_date IS NOT NULL OR start_date_source IS NULL)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AnimeData extends DataClass implements Insertable<AnimeData> {
  final int id;
  final String uuid;
  final String title;
  final String? originalTitle;
  final int? season;
  final String? entryType;
  final String? sourceProvider;
  final String? sourceId;
  final int? totalEpisodes;
  final int? durationMinutes;
  final String? summary;
  final String? coverUrl;
  final String? premiereDate;
  final bool? isFinished;
  final String cast;
  final String castAliases;
  final String? localCoverPath;
  final String status;
  final int progress;
  final double? score;
  final int? rewatchCount;
  final String tags;
  final String? notes;
  final String? startDate;
  final String? startDateSource;
  final String? endDate;
  final String createdAt;
  final String updatedAt;
  const AnimeData({
    required this.id,
    required this.uuid,
    required this.title,
    this.originalTitle,
    this.season,
    this.entryType,
    this.sourceProvider,
    this.sourceId,
    this.totalEpisodes,
    this.durationMinutes,
    this.summary,
    this.coverUrl,
    this.premiereDate,
    this.isFinished,
    required this.cast,
    required this.castAliases,
    this.localCoverPath,
    required this.status,
    required this.progress,
    this.score,
    this.rewatchCount,
    required this.tags,
    this.notes,
    this.startDate,
    this.startDateSource,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || originalTitle != null) {
      map['original_title'] = Variable<String>(originalTitle);
    }
    if (!nullToAbsent || season != null) {
      map['season'] = Variable<int>(season);
    }
    if (!nullToAbsent || entryType != null) {
      map['entry_type'] = Variable<String>(entryType);
    }
    if (!nullToAbsent || sourceProvider != null) {
      map['source_provider'] = Variable<String>(sourceProvider);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || totalEpisodes != null) {
      map['total_episodes'] = Variable<int>(totalEpisodes);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || premiereDate != null) {
      map['premiere_date'] = Variable<String>(premiereDate);
    }
    if (!nullToAbsent || isFinished != null) {
      map['is_finished'] = Variable<bool>(isFinished);
    }
    map['cast'] = Variable<String>(cast);
    map['cast_aliases'] = Variable<String>(castAliases);
    if (!nullToAbsent || localCoverPath != null) {
      map['local_cover_path'] = Variable<String>(localCoverPath);
    }
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<int>(progress);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    if (!nullToAbsent || rewatchCount != null) {
      map['rewatch_count'] = Variable<int>(rewatchCount);
    }
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || startDateSource != null) {
      map['start_date_source'] = Variable<String>(startDateSource);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AnimeCompanion toCompanion(bool nullToAbsent) {
    return AnimeCompanion(
      id: Value(id),
      uuid: Value(uuid),
      title: Value(title),
      originalTitle: originalTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTitle),
      season: season == null && nullToAbsent
          ? const Value.absent()
          : Value(season),
      entryType: entryType == null && nullToAbsent
          ? const Value.absent()
          : Value(entryType),
      sourceProvider: sourceProvider == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceProvider),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      totalEpisodes: totalEpisodes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalEpisodes),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      premiereDate: premiereDate == null && nullToAbsent
          ? const Value.absent()
          : Value(premiereDate),
      isFinished: isFinished == null && nullToAbsent
          ? const Value.absent()
          : Value(isFinished),
      cast: Value(cast),
      castAliases: Value(castAliases),
      localCoverPath: localCoverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localCoverPath),
      status: Value(status),
      progress: Value(progress),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      rewatchCount: rewatchCount == null && nullToAbsent
          ? const Value.absent()
          : Value(rewatchCount),
      tags: Value(tags),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      startDateSource: startDateSource == null && nullToAbsent
          ? const Value.absent()
          : Value(startDateSource),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AnimeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimeData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String?>(json['original_title']),
      season: serializer.fromJson<int?>(json['season']),
      entryType: serializer.fromJson<String?>(json['entry_type']),
      sourceProvider: serializer.fromJson<String?>(json['source_provider']),
      sourceId: serializer.fromJson<String?>(json['source_id']),
      totalEpisodes: serializer.fromJson<int?>(json['total_episodes']),
      durationMinutes: serializer.fromJson<int?>(json['duration_minutes']),
      summary: serializer.fromJson<String?>(json['summary']),
      coverUrl: serializer.fromJson<String?>(json['cover_url']),
      premiereDate: serializer.fromJson<String?>(json['premiere_date']),
      isFinished: serializer.fromJson<bool?>(json['is_finished']),
      cast: serializer.fromJson<String>(json['cast']),
      castAliases: serializer.fromJson<String>(json['cast_aliases']),
      localCoverPath: serializer.fromJson<String?>(json['local_cover_path']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<int>(json['progress']),
      score: serializer.fromJson<double?>(json['score']),
      rewatchCount: serializer.fromJson<int?>(json['rewatch_count']),
      tags: serializer.fromJson<String>(json['tags']),
      notes: serializer.fromJson<String?>(json['notes']),
      startDate: serializer.fromJson<String?>(json['start_date']),
      startDateSource: serializer.fromJson<String?>(json['start_date_source']),
      endDate: serializer.fromJson<String?>(json['end_date']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'title': serializer.toJson<String>(title),
      'original_title': serializer.toJson<String?>(originalTitle),
      'season': serializer.toJson<int?>(season),
      'entry_type': serializer.toJson<String?>(entryType),
      'source_provider': serializer.toJson<String?>(sourceProvider),
      'source_id': serializer.toJson<String?>(sourceId),
      'total_episodes': serializer.toJson<int?>(totalEpisodes),
      'duration_minutes': serializer.toJson<int?>(durationMinutes),
      'summary': serializer.toJson<String?>(summary),
      'cover_url': serializer.toJson<String?>(coverUrl),
      'premiere_date': serializer.toJson<String?>(premiereDate),
      'is_finished': serializer.toJson<bool?>(isFinished),
      'cast': serializer.toJson<String>(cast),
      'cast_aliases': serializer.toJson<String>(castAliases),
      'local_cover_path': serializer.toJson<String?>(localCoverPath),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<int>(progress),
      'score': serializer.toJson<double?>(score),
      'rewatch_count': serializer.toJson<int?>(rewatchCount),
      'tags': serializer.toJson<String>(tags),
      'notes': serializer.toJson<String?>(notes),
      'start_date': serializer.toJson<String?>(startDate),
      'start_date_source': serializer.toJson<String?>(startDateSource),
      'end_date': serializer.toJson<String?>(endDate),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  AnimeData copyWith({
    int? id,
    String? uuid,
    String? title,
    Value<String?> originalTitle = const Value.absent(),
    Value<int?> season = const Value.absent(),
    Value<String?> entryType = const Value.absent(),
    Value<String?> sourceProvider = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
    Value<int?> totalEpisodes = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    Value<String?> summary = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> premiereDate = const Value.absent(),
    Value<bool?> isFinished = const Value.absent(),
    String? cast,
    String? castAliases,
    Value<String?> localCoverPath = const Value.absent(),
    String? status,
    int? progress,
    Value<double?> score = const Value.absent(),
    Value<int?> rewatchCount = const Value.absent(),
    String? tags,
    Value<String?> notes = const Value.absent(),
    Value<String?> startDate = const Value.absent(),
    Value<String?> startDateSource = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => AnimeData(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    originalTitle: originalTitle.present
        ? originalTitle.value
        : this.originalTitle,
    season: season.present ? season.value : this.season,
    entryType: entryType.present ? entryType.value : this.entryType,
    sourceProvider: sourceProvider.present
        ? sourceProvider.value
        : this.sourceProvider,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    totalEpisodes: totalEpisodes.present
        ? totalEpisodes.value
        : this.totalEpisodes,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    summary: summary.present ? summary.value : this.summary,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    premiereDate: premiereDate.present ? premiereDate.value : this.premiereDate,
    isFinished: isFinished.present ? isFinished.value : this.isFinished,
    cast: cast ?? this.cast,
    castAliases: castAliases ?? this.castAliases,
    localCoverPath: localCoverPath.present
        ? localCoverPath.value
        : this.localCoverPath,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    score: score.present ? score.value : this.score,
    rewatchCount: rewatchCount.present ? rewatchCount.value : this.rewatchCount,
    tags: tags ?? this.tags,
    notes: notes.present ? notes.value : this.notes,
    startDate: startDate.present ? startDate.value : this.startDate,
    startDateSource: startDateSource.present
        ? startDateSource.value
        : this.startDateSource,
    endDate: endDate.present ? endDate.value : this.endDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AnimeData copyWithCompanion(AnimeCompanion data) {
    return AnimeData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      season: data.season.present ? data.season.value : this.season,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      sourceProvider: data.sourceProvider.present
          ? data.sourceProvider.value
          : this.sourceProvider,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      totalEpisodes: data.totalEpisodes.present
          ? data.totalEpisodes.value
          : this.totalEpisodes,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      summary: data.summary.present ? data.summary.value : this.summary,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      premiereDate: data.premiereDate.present
          ? data.premiereDate.value
          : this.premiereDate,
      isFinished: data.isFinished.present
          ? data.isFinished.value
          : this.isFinished,
      cast: data.cast.present ? data.cast.value : this.cast,
      castAliases: data.castAliases.present
          ? data.castAliases.value
          : this.castAliases,
      localCoverPath: data.localCoverPath.present
          ? data.localCoverPath.value
          : this.localCoverPath,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      score: data.score.present ? data.score.value : this.score,
      rewatchCount: data.rewatchCount.present
          ? data.rewatchCount.value
          : this.rewatchCount,
      tags: data.tags.present ? data.tags.value : this.tags,
      notes: data.notes.present ? data.notes.value : this.notes,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      startDateSource: data.startDateSource.present
          ? data.startDateSource.value
          : this.startDateSource,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimeData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('season: $season, ')
          ..write('entryType: $entryType, ')
          ..write('sourceProvider: $sourceProvider, ')
          ..write('sourceId: $sourceId, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('summary: $summary, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('premiereDate: $premiereDate, ')
          ..write('isFinished: $isFinished, ')
          ..write('cast: $cast, ')
          ..write('castAliases: $castAliases, ')
          ..write('localCoverPath: $localCoverPath, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('score: $score, ')
          ..write('rewatchCount: $rewatchCount, ')
          ..write('tags: $tags, ')
          ..write('notes: $notes, ')
          ..write('startDate: $startDate, ')
          ..write('startDateSource: $startDateSource, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    title,
    originalTitle,
    season,
    entryType,
    sourceProvider,
    sourceId,
    totalEpisodes,
    durationMinutes,
    summary,
    coverUrl,
    premiereDate,
    isFinished,
    cast,
    castAliases,
    localCoverPath,
    status,
    progress,
    score,
    rewatchCount,
    tags,
    notes,
    startDate,
    startDateSource,
    endDate,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimeData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.season == this.season &&
          other.entryType == this.entryType &&
          other.sourceProvider == this.sourceProvider &&
          other.sourceId == this.sourceId &&
          other.totalEpisodes == this.totalEpisodes &&
          other.durationMinutes == this.durationMinutes &&
          other.summary == this.summary &&
          other.coverUrl == this.coverUrl &&
          other.premiereDate == this.premiereDate &&
          other.isFinished == this.isFinished &&
          other.cast == this.cast &&
          other.castAliases == this.castAliases &&
          other.localCoverPath == this.localCoverPath &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.score == this.score &&
          other.rewatchCount == this.rewatchCount &&
          other.tags == this.tags &&
          other.notes == this.notes &&
          other.startDate == this.startDate &&
          other.startDateSource == this.startDateSource &&
          other.endDate == this.endDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AnimeCompanion extends UpdateCompanion<AnimeData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> title;
  final Value<String?> originalTitle;
  final Value<int?> season;
  final Value<String?> entryType;
  final Value<String?> sourceProvider;
  final Value<String?> sourceId;
  final Value<int?> totalEpisodes;
  final Value<int?> durationMinutes;
  final Value<String?> summary;
  final Value<String?> coverUrl;
  final Value<String?> premiereDate;
  final Value<bool?> isFinished;
  final Value<String> cast;
  final Value<String> castAliases;
  final Value<String?> localCoverPath;
  final Value<String> status;
  final Value<int> progress;
  final Value<double?> score;
  final Value<int?> rewatchCount;
  final Value<String> tags;
  final Value<String?> notes;
  final Value<String?> startDate;
  final Value<String?> startDateSource;
  final Value<String?> endDate;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const AnimeCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.season = const Value.absent(),
    this.entryType = const Value.absent(),
    this.sourceProvider = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.summary = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.premiereDate = const Value.absent(),
    this.isFinished = const Value.absent(),
    this.cast = const Value.absent(),
    this.castAliases = const Value.absent(),
    this.localCoverPath = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.score = const Value.absent(),
    this.rewatchCount = const Value.absent(),
    this.tags = const Value.absent(),
    this.notes = const Value.absent(),
    this.startDate = const Value.absent(),
    this.startDateSource = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AnimeCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String title,
    this.originalTitle = const Value.absent(),
    this.season = const Value.absent(),
    this.entryType = const Value.absent(),
    this.sourceProvider = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.summary = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.premiereDate = const Value.absent(),
    this.isFinished = const Value.absent(),
    this.cast = const Value.absent(),
    this.castAliases = const Value.absent(),
    this.localCoverPath = const Value.absent(),
    required String status,
    this.progress = const Value.absent(),
    this.score = const Value.absent(),
    this.rewatchCount = const Value.absent(),
    this.tags = const Value.absent(),
    this.notes = const Value.absent(),
    this.startDate = const Value.absent(),
    this.startDateSource = const Value.absent(),
    this.endDate = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : uuid = Value(uuid),
       title = Value(title),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AnimeData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<int>? season,
    Expression<String>? entryType,
    Expression<String>? sourceProvider,
    Expression<String>? sourceId,
    Expression<int>? totalEpisodes,
    Expression<int>? durationMinutes,
    Expression<String>? summary,
    Expression<String>? coverUrl,
    Expression<String>? premiereDate,
    Expression<bool>? isFinished,
    Expression<String>? cast,
    Expression<String>? castAliases,
    Expression<String>? localCoverPath,
    Expression<String>? status,
    Expression<int>? progress,
    Expression<double>? score,
    Expression<int>? rewatchCount,
    Expression<String>? tags,
    Expression<String>? notes,
    Expression<String>? startDate,
    Expression<String>? startDateSource,
    Expression<String>? endDate,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (season != null) 'season': season,
      if (entryType != null) 'entry_type': entryType,
      if (sourceProvider != null) 'source_provider': sourceProvider,
      if (sourceId != null) 'source_id': sourceId,
      if (totalEpisodes != null) 'total_episodes': totalEpisodes,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (summary != null) 'summary': summary,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (premiereDate != null) 'premiere_date': premiereDate,
      if (isFinished != null) 'is_finished': isFinished,
      if (cast != null) 'cast': cast,
      if (castAliases != null) 'cast_aliases': castAliases,
      if (localCoverPath != null) 'local_cover_path': localCoverPath,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (score != null) 'score': score,
      if (rewatchCount != null) 'rewatch_count': rewatchCount,
      if (tags != null) 'tags': tags,
      if (notes != null) 'notes': notes,
      if (startDate != null) 'start_date': startDate,
      if (startDateSource != null) 'start_date_source': startDateSource,
      if (endDate != null) 'end_date': endDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AnimeCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? title,
    Value<String?>? originalTitle,
    Value<int?>? season,
    Value<String?>? entryType,
    Value<String?>? sourceProvider,
    Value<String?>? sourceId,
    Value<int?>? totalEpisodes,
    Value<int?>? durationMinutes,
    Value<String?>? summary,
    Value<String?>? coverUrl,
    Value<String?>? premiereDate,
    Value<bool?>? isFinished,
    Value<String>? cast,
    Value<String>? castAliases,
    Value<String?>? localCoverPath,
    Value<String>? status,
    Value<int>? progress,
    Value<double?>? score,
    Value<int?>? rewatchCount,
    Value<String>? tags,
    Value<String?>? notes,
    Value<String?>? startDate,
    Value<String?>? startDateSource,
    Value<String?>? endDate,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return AnimeCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      season: season ?? this.season,
      entryType: entryType ?? this.entryType,
      sourceProvider: sourceProvider ?? this.sourceProvider,
      sourceId: sourceId ?? this.sourceId,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      summary: summary ?? this.summary,
      coverUrl: coverUrl ?? this.coverUrl,
      premiereDate: premiereDate ?? this.premiereDate,
      isFinished: isFinished ?? this.isFinished,
      cast: cast ?? this.cast,
      castAliases: castAliases ?? this.castAliases,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      score: score ?? this.score,
      rewatchCount: rewatchCount ?? this.rewatchCount,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      startDateSource: startDateSource ?? this.startDateSource,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (sourceProvider.present) {
      map['source_provider'] = Variable<String>(sourceProvider.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (totalEpisodes.present) {
      map['total_episodes'] = Variable<int>(totalEpisodes.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (premiereDate.present) {
      map['premiere_date'] = Variable<String>(premiereDate.value);
    }
    if (isFinished.present) {
      map['is_finished'] = Variable<bool>(isFinished.value);
    }
    if (cast.present) {
      map['cast'] = Variable<String>(cast.value);
    }
    if (castAliases.present) {
      map['cast_aliases'] = Variable<String>(castAliases.value);
    }
    if (localCoverPath.present) {
      map['local_cover_path'] = Variable<String>(localCoverPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (rewatchCount.present) {
      map['rewatch_count'] = Variable<int>(rewatchCount.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (startDateSource.present) {
      map['start_date_source'] = Variable<String>(startDateSource.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimeCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('season: $season, ')
          ..write('entryType: $entryType, ')
          ..write('sourceProvider: $sourceProvider, ')
          ..write('sourceId: $sourceId, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('summary: $summary, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('premiereDate: $premiereDate, ')
          ..write('isFinished: $isFinished, ')
          ..write('cast: $cast, ')
          ..write('castAliases: $castAliases, ')
          ..write('localCoverPath: $localCoverPath, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('score: $score, ')
          ..write('rewatchCount: $rewatchCount, ')
          ..write('tags: $tags, ')
          ..write('notes: $notes, ')
          ..write('startDate: $startDate, ')
          ..write('startDateSource: $startDateSource, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class WatchHistory extends Table
    with TableInfo<WatchHistory, WatchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WatchHistory(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _animeUuidMeta = const VerificationMeta(
    'animeUuid',
  );
  late final GeneratedColumn<String> animeUuid = GeneratedColumn<String>(
    'anime_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES anime(uuid)ON DELETE CASCADE',
  );
  static const VerificationMeta _episodeMeta = const VerificationMeta(
    'episode',
  );
  late final GeneratedColumn<int> episode = GeneratedColumn<int>(
    'episode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (episode > 0)',
  );
  static const VerificationMeta _watchedOnMeta = const VerificationMeta(
    'watchedOn',
  );
  late final GeneratedColumn<String> watchedOn = GeneratedColumn<String>(
    'watched_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  late final GeneratedColumn<String> watchedAt = GeneratedColumn<String>(
    'watched_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    animeUuid,
    episode,
    watchedOn,
    watchedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('anime_uuid')) {
      context.handle(
        _animeUuidMeta,
        animeUuid.isAcceptableOrUnknown(data['anime_uuid']!, _animeUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_animeUuidMeta);
    }
    if (data.containsKey('episode')) {
      context.handle(
        _episodeMeta,
        episode.isAcceptableOrUnknown(data['episode']!, _episodeMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeMeta);
    }
    if (data.containsKey('watched_on')) {
      context.handle(
        _watchedOnMeta,
        watchedOn.isAcceptableOrUnknown(data['watched_on']!, _watchedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_watchedOnMeta);
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      animeUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_uuid'],
      )!,
      episode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode'],
      )!,
      watchedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}watched_on'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}watched_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  WatchHistory createAlias(String alias) {
    return WatchHistory(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WatchHistoryData extends DataClass
    implements Insertable<WatchHistoryData> {
  final int id;
  final String uuid;
  final String animeUuid;
  final int episode;
  final String watchedOn;
  final String? watchedAt;
  final String createdAt;
  const WatchHistoryData({
    required this.id,
    required this.uuid,
    required this.animeUuid,
    required this.episode,
    required this.watchedOn,
    this.watchedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['anime_uuid'] = Variable<String>(animeUuid);
    map['episode'] = Variable<int>(episode);
    map['watched_on'] = Variable<String>(watchedOn);
    if (!nullToAbsent || watchedAt != null) {
      map['watched_at'] = Variable<String>(watchedAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  WatchHistoryCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryCompanion(
      id: Value(id),
      uuid: Value(uuid),
      animeUuid: Value(animeUuid),
      episode: Value(episode),
      watchedOn: Value(watchedOn),
      watchedAt: watchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(watchedAt),
      createdAt: Value(createdAt),
    );
  }

  factory WatchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      animeUuid: serializer.fromJson<String>(json['anime_uuid']),
      episode: serializer.fromJson<int>(json['episode']),
      watchedOn: serializer.fromJson<String>(json['watched_on']),
      watchedAt: serializer.fromJson<String?>(json['watched_at']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'anime_uuid': serializer.toJson<String>(animeUuid),
      'episode': serializer.toJson<int>(episode),
      'watched_on': serializer.toJson<String>(watchedOn),
      'watched_at': serializer.toJson<String?>(watchedAt),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  WatchHistoryData copyWith({
    int? id,
    String? uuid,
    String? animeUuid,
    int? episode,
    String? watchedOn,
    Value<String?> watchedAt = const Value.absent(),
    String? createdAt,
  }) => WatchHistoryData(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    animeUuid: animeUuid ?? this.animeUuid,
    episode: episode ?? this.episode,
    watchedOn: watchedOn ?? this.watchedOn,
    watchedAt: watchedAt.present ? watchedAt.value : this.watchedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  WatchHistoryData copyWithCompanion(WatchHistoryCompanion data) {
    return WatchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      animeUuid: data.animeUuid.present ? data.animeUuid.value : this.animeUuid,
      episode: data.episode.present ? data.episode.value : this.episode,
      watchedOn: data.watchedOn.present ? data.watchedOn.value : this.watchedOn,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('animeUuid: $animeUuid, ')
          ..write('episode: $episode, ')
          ..write('watchedOn: $watchedOn, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    animeUuid,
    episode,
    watchedOn,
    watchedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.animeUuid == this.animeUuid &&
          other.episode == this.episode &&
          other.watchedOn == this.watchedOn &&
          other.watchedAt == this.watchedAt &&
          other.createdAt == this.createdAt);
}

class WatchHistoryCompanion extends UpdateCompanion<WatchHistoryData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> animeUuid;
  final Value<int> episode;
  final Value<String> watchedOn;
  final Value<String?> watchedAt;
  final Value<String> createdAt;
  const WatchHistoryCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.animeUuid = const Value.absent(),
    this.episode = const Value.absent(),
    this.watchedOn = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WatchHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String animeUuid,
    required int episode,
    required String watchedOn,
    this.watchedAt = const Value.absent(),
    required String createdAt,
  }) : uuid = Value(uuid),
       animeUuid = Value(animeUuid),
       episode = Value(episode),
       watchedOn = Value(watchedOn),
       createdAt = Value(createdAt);
  static Insertable<WatchHistoryData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? animeUuid,
    Expression<int>? episode,
    Expression<String>? watchedOn,
    Expression<String>? watchedAt,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (animeUuid != null) 'anime_uuid': animeUuid,
      if (episode != null) 'episode': episode,
      if (watchedOn != null) 'watched_on': watchedOn,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WatchHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? animeUuid,
    Value<int>? episode,
    Value<String>? watchedOn,
    Value<String?>? watchedAt,
    Value<String>? createdAt,
  }) {
    return WatchHistoryCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      animeUuid: animeUuid ?? this.animeUuid,
      episode: episode ?? this.episode,
      watchedOn: watchedOn ?? this.watchedOn,
      watchedAt: watchedAt ?? this.watchedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (animeUuid.present) {
      map['anime_uuid'] = Variable<String>(animeUuid.value);
    }
    if (episode.present) {
      map['episode'] = Variable<int>(episode.value);
    }
    if (watchedOn.present) {
      map['watched_on'] = Variable<String>(watchedOn.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<String>(watchedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('animeUuid: $animeUuid, ')
          ..write('episode: $episode, ')
          ..write('watchedOn: $watchedOn, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class AnimeNotes extends Table with TableInfo<AnimeNotes, AnimeNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AnimeNotes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _animeUuidMeta = const VerificationMeta(
    'animeUuid',
  );
  late final GeneratedColumn<String> animeUuid = GeneratedColumn<String>(
    'anime_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES anime(uuid)ON DELETE CASCADE',
  );
  static const VerificationMeta _episodeMeta = const VerificationMeta(
    'episode',
  );
  late final GeneratedColumn<int> episode = GeneratedColumn<int>(
    'episode',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (episode > 0)',
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(content)) > 0)',
  );
  static const VerificationMeta _notedOnMeta = const VerificationMeta(
    'notedOn',
  );
  late final GeneratedColumn<String> notedOn = GeneratedColumn<String>(
    'noted_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    animeUuid,
    episode,
    content,
    notedOn,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anime_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnimeNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('anime_uuid')) {
      context.handle(
        _animeUuidMeta,
        animeUuid.isAcceptableOrUnknown(data['anime_uuid']!, _animeUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_animeUuidMeta);
    }
    if (data.containsKey('episode')) {
      context.handle(
        _episodeMeta,
        episode.isAcceptableOrUnknown(data['episode']!, _episodeMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('noted_on')) {
      context.handle(
        _notedOnMeta,
        notedOn.isAcceptableOrUnknown(data['noted_on']!, _notedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_notedOnMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  AnimeNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimeNote(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      animeUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_uuid'],
      )!,
      episode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      notedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}noted_on'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  AnimeNotes createAlias(String alias) {
    return AnimeNotes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AnimeNote extends DataClass implements Insertable<AnimeNote> {
  final String uuid;
  final String animeUuid;
  final int? episode;
  final String content;
  final String notedOn;
  final String createdAt;
  final String updatedAt;
  const AnimeNote({
    required this.uuid,
    required this.animeUuid,
    this.episode,
    required this.content,
    required this.notedOn,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['anime_uuid'] = Variable<String>(animeUuid);
    if (!nullToAbsent || episode != null) {
      map['episode'] = Variable<int>(episode);
    }
    map['content'] = Variable<String>(content);
    map['noted_on'] = Variable<String>(notedOn);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AnimeNotesCompanion toCompanion(bool nullToAbsent) {
    return AnimeNotesCompanion(
      uuid: Value(uuid),
      animeUuid: Value(animeUuid),
      episode: episode == null && nullToAbsent
          ? const Value.absent()
          : Value(episode),
      content: Value(content),
      notedOn: Value(notedOn),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AnimeNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimeNote(
      uuid: serializer.fromJson<String>(json['uuid']),
      animeUuid: serializer.fromJson<String>(json['anime_uuid']),
      episode: serializer.fromJson<int?>(json['episode']),
      content: serializer.fromJson<String>(json['content']),
      notedOn: serializer.fromJson<String>(json['noted_on']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'anime_uuid': serializer.toJson<String>(animeUuid),
      'episode': serializer.toJson<int?>(episode),
      'content': serializer.toJson<String>(content),
      'noted_on': serializer.toJson<String>(notedOn),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  AnimeNote copyWith({
    String? uuid,
    String? animeUuid,
    Value<int?> episode = const Value.absent(),
    String? content,
    String? notedOn,
    String? createdAt,
    String? updatedAt,
  }) => AnimeNote(
    uuid: uuid ?? this.uuid,
    animeUuid: animeUuid ?? this.animeUuid,
    episode: episode.present ? episode.value : this.episode,
    content: content ?? this.content,
    notedOn: notedOn ?? this.notedOn,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AnimeNote copyWithCompanion(AnimeNotesCompanion data) {
    return AnimeNote(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      animeUuid: data.animeUuid.present ? data.animeUuid.value : this.animeUuid,
      episode: data.episode.present ? data.episode.value : this.episode,
      content: data.content.present ? data.content.value : this.content,
      notedOn: data.notedOn.present ? data.notedOn.value : this.notedOn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimeNote(')
          ..write('uuid: $uuid, ')
          ..write('animeUuid: $animeUuid, ')
          ..write('episode: $episode, ')
          ..write('content: $content, ')
          ..write('notedOn: $notedOn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    animeUuid,
    episode,
    content,
    notedOn,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimeNote &&
          other.uuid == this.uuid &&
          other.animeUuid == this.animeUuid &&
          other.episode == this.episode &&
          other.content == this.content &&
          other.notedOn == this.notedOn &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AnimeNotesCompanion extends UpdateCompanion<AnimeNote> {
  final Value<String> uuid;
  final Value<String> animeUuid;
  final Value<int?> episode;
  final Value<String> content;
  final Value<String> notedOn;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const AnimeNotesCompanion({
    this.uuid = const Value.absent(),
    this.animeUuid = const Value.absent(),
    this.episode = const Value.absent(),
    this.content = const Value.absent(),
    this.notedOn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnimeNotesCompanion.insert({
    required String uuid,
    required String animeUuid,
    this.episode = const Value.absent(),
    required String content,
    required String notedOn,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       animeUuid = Value(animeUuid),
       content = Value(content),
       notedOn = Value(notedOn),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AnimeNote> custom({
    Expression<String>? uuid,
    Expression<String>? animeUuid,
    Expression<int>? episode,
    Expression<String>? content,
    Expression<String>? notedOn,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (animeUuid != null) 'anime_uuid': animeUuid,
      if (episode != null) 'episode': episode,
      if (content != null) 'content': content,
      if (notedOn != null) 'noted_on': notedOn,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnimeNotesCompanion copyWith({
    Value<String>? uuid,
    Value<String>? animeUuid,
    Value<int?>? episode,
    Value<String>? content,
    Value<String>? notedOn,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return AnimeNotesCompanion(
      uuid: uuid ?? this.uuid,
      animeUuid: animeUuid ?? this.animeUuid,
      episode: episode ?? this.episode,
      content: content ?? this.content,
      notedOn: notedOn ?? this.notedOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (animeUuid.present) {
      map['anime_uuid'] = Variable<String>(animeUuid.value);
    }
    if (episode.present) {
      map['episode'] = Variable<int>(episode.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (notedOn.present) {
      map['noted_on'] = Variable<String>(notedOn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimeNotesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('animeUuid: $animeUuid, ')
          ..write('episode: $episode, ')
          ..write('content: $content, ')
          ..write('notedOn: $notedOn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class IntakeCommits extends Table with TableInfo<IntakeCommits, IntakeCommit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  IntakeCommits(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _draftIdMeta = const VerificationMeta(
    'draftId',
  );
  late final GeneratedColumn<String> draftId = GeneratedColumn<String>(
    'draft_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _animeUuidMeta = const VerificationMeta(
    'animeUuid',
  );
  late final GeneratedColumn<String> animeUuid = GeneratedColumn<String>(
    'anime_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES anime(uuid)ON DELETE CASCADE',
  );
  @override
  List<GeneratedColumn> get $columns => [draftId, animeUuid];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_commits';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntakeCommit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('draft_id')) {
      context.handle(
        _draftIdMeta,
        draftId.isAcceptableOrUnknown(data['draft_id']!, _draftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_draftIdMeta);
    }
    if (data.containsKey('anime_uuid')) {
      context.handle(
        _animeUuidMeta,
        animeUuid.isAcceptableOrUnknown(data['anime_uuid']!, _animeUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_animeUuidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {draftId};
  @override
  IntakeCommit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeCommit(
      draftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_id'],
      )!,
      animeUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_uuid'],
      )!,
    );
  }

  @override
  IntakeCommits createAlias(String alias) {
    return IntakeCommits(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class IntakeCommit extends DataClass implements Insertable<IntakeCommit> {
  final String draftId;
  final String animeUuid;
  const IntakeCommit({required this.draftId, required this.animeUuid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['draft_id'] = Variable<String>(draftId);
    map['anime_uuid'] = Variable<String>(animeUuid);
    return map;
  }

  IntakeCommitsCompanion toCompanion(bool nullToAbsent) {
    return IntakeCommitsCompanion(
      draftId: Value(draftId),
      animeUuid: Value(animeUuid),
    );
  }

  factory IntakeCommit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeCommit(
      draftId: serializer.fromJson<String>(json['draft_id']),
      animeUuid: serializer.fromJson<String>(json['anime_uuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'draft_id': serializer.toJson<String>(draftId),
      'anime_uuid': serializer.toJson<String>(animeUuid),
    };
  }

  IntakeCommit copyWith({String? draftId, String? animeUuid}) => IntakeCommit(
    draftId: draftId ?? this.draftId,
    animeUuid: animeUuid ?? this.animeUuid,
  );
  IntakeCommit copyWithCompanion(IntakeCommitsCompanion data) {
    return IntakeCommit(
      draftId: data.draftId.present ? data.draftId.value : this.draftId,
      animeUuid: data.animeUuid.present ? data.animeUuid.value : this.animeUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeCommit(')
          ..write('draftId: $draftId, ')
          ..write('animeUuid: $animeUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(draftId, animeUuid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeCommit &&
          other.draftId == this.draftId &&
          other.animeUuid == this.animeUuid);
}

class IntakeCommitsCompanion extends UpdateCompanion<IntakeCommit> {
  final Value<String> draftId;
  final Value<String> animeUuid;
  final Value<int> rowid;
  const IntakeCommitsCompanion({
    this.draftId = const Value.absent(),
    this.animeUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntakeCommitsCompanion.insert({
    required String draftId,
    required String animeUuid,
    this.rowid = const Value.absent(),
  }) : draftId = Value(draftId),
       animeUuid = Value(animeUuid);
  static Insertable<IntakeCommit> custom({
    Expression<String>? draftId,
    Expression<String>? animeUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (draftId != null) 'draft_id': draftId,
      if (animeUuid != null) 'anime_uuid': animeUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntakeCommitsCompanion copyWith({
    Value<String>? draftId,
    Value<String>? animeUuid,
    Value<int>? rowid,
  }) {
    return IntakeCommitsCompanion(
      draftId: draftId ?? this.draftId,
      animeUuid: animeUuid ?? this.animeUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (draftId.present) {
      map['draft_id'] = Variable<String>(draftId.value);
    }
    if (animeUuid.present) {
      map['anime_uuid'] = Variable<String>(animeUuid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeCommitsCompanion(')
          ..write('draftId: $draftId, ')
          ..write('animeUuid: $animeUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AppSettings extends Table with TableInfo<AppSettings, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [settingKey, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  AppSettings createAlias(String alias) {
    return AppSettings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String settingKey;
  final String value;
  const AppSetting({required this.settingKey, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      settingKey: Value(settingKey),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      settingKey: serializer.fromJson<String>(json['setting_key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setting_key': serializer.toJson<String>(settingKey),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? settingKey, String? value}) => AppSetting(
    settingKey: settingKey ?? this.settingKey,
    value: value ?? this.value,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('settingKey: $settingKey, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.settingKey == this.settingKey &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> settingKey;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.settingKey = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String settingKey,
    required String value,
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? settingKey,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      settingKey: settingKey ?? this.settingKey,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LegacyImports extends Table with TableInfo<LegacyImports, LegacyImport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LegacyImports(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  late final GeneratedColumn<String> importedAt = GeneratedColumn<String>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [fingerprint, importedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyImport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fingerprint};
  @override
  LegacyImport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyImport(
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  LegacyImports createAlias(String alias) {
    return LegacyImports(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class LegacyImport extends DataClass implements Insertable<LegacyImport> {
  final String fingerprint;
  final String importedAt;
  const LegacyImport({required this.fingerprint, required this.importedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fingerprint'] = Variable<String>(fingerprint);
    map['imported_at'] = Variable<String>(importedAt);
    return map;
  }

  LegacyImportsCompanion toCompanion(bool nullToAbsent) {
    return LegacyImportsCompanion(
      fingerprint: Value(fingerprint),
      importedAt: Value(importedAt),
    );
  }

  factory LegacyImport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyImport(
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      importedAt: serializer.fromJson<String>(json['imported_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fingerprint': serializer.toJson<String>(fingerprint),
      'imported_at': serializer.toJson<String>(importedAt),
    };
  }

  LegacyImport copyWith({String? fingerprint, String? importedAt}) =>
      LegacyImport(
        fingerprint: fingerprint ?? this.fingerprint,
        importedAt: importedAt ?? this.importedAt,
      );
  LegacyImport copyWithCompanion(LegacyImportsCompanion data) {
    return LegacyImport(
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegacyImport(')
          ..write('fingerprint: $fingerprint, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fingerprint, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegacyImport &&
          other.fingerprint == this.fingerprint &&
          other.importedAt == this.importedAt);
}

class LegacyImportsCompanion extends UpdateCompanion<LegacyImport> {
  final Value<String> fingerprint;
  final Value<String> importedAt;
  final Value<int> rowid;
  const LegacyImportsCompanion({
    this.fingerprint = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LegacyImportsCompanion.insert({
    required String fingerprint,
    required String importedAt,
    this.rowid = const Value.absent(),
  }) : fingerprint = Value(fingerprint),
       importedAt = Value(importedAt);
  static Insertable<LegacyImport> custom({
    Expression<String>? fingerprint,
    Expression<String>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LegacyImportsCompanion copyWith({
    Value<String>? fingerprint,
    Value<String>? importedAt,
    Value<int>? rowid,
  }) {
    return LegacyImportsCompanion(
      fingerprint: fingerprint ?? this.fingerprint,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<String>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyImportsCompanion(')
          ..write('fingerprint: $fingerprint, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Manga extends Table with TableInfo<Manga, MangaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Manga(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _bangumiIdMeta = const VerificationMeta(
    'bangumiId',
  );
  late final GeneratedColumn<int> bangumiId = GeneratedColumn<int>(
    'bangumi_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 500)',
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta(
    'originalTitle',
  );
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _aliasesMeta = const VerificationMeta(
    'aliases',
  );
  late final GeneratedColumn<String> aliases = GeneratedColumn<String>(
    'aliases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid(aliases) AND json_type(aliases) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _localCoverPathMeta = const VerificationMeta(
    'localCoverPath',
  );
  late final GeneratedColumn<String> localCoverPath = GeneratedColumn<String>(
    'local_cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'plan_to_read\', \'reading\', \'caught_up\', \'completed\', \'paused\', \'dropped\'))',
  );
  static const VerificationMeta _publicationStatusMeta = const VerificationMeta(
    'publicationStatus',
  );
  late final GeneratedColumn<String> publicationStatus =
      GeneratedColumn<String>(
        'publication_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL CHECK (publication_status IN (\'ongoing\', \'completed\', \'hiatus\', \'unknown\'))',
      );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (score >= 0 AND score <= 10)',
  );
  static const VerificationMeta _currentVolumeMeta = const VerificationMeta(
    'currentVolume',
  );
  late final GeneratedColumn<int> currentVolume = GeneratedColumn<int>(
    'current_volume',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (current_volume >= 0)',
  );
  static const VerificationMeta _currentChapterMeta = const VerificationMeta(
    'currentChapter',
  );
  late final GeneratedColumn<int> currentChapter = GeneratedColumn<int>(
    'current_chapter',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (current_chapter >= 0)',
  );
  static const VerificationMeta _totalVolumesMeta = const VerificationMeta(
    'totalVolumes',
  );
  late final GeneratedColumn<int> totalVolumes = GeneratedColumn<int>(
    'total_volumes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (total_volumes > 0)',
  );
  static const VerificationMeta _totalChaptersMeta = const VerificationMeta(
    'totalChapters',
  );
  late final GeneratedColumn<int> totalChapters = GeneratedColumn<int>(
    'total_chapters',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (total_chapters > 0)',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid(tags) AND json_type(tags) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _authorsMeta = const VerificationMeta(
    'authors',
  );
  late final GeneratedColumn<String> authors = GeneratedColumn<String>(
    'authors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid(authors) AND json_type(authors) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _illustratorsMeta = const VerificationMeta(
    'illustrators',
  );
  late final GeneratedColumn<String> illustrators = GeneratedColumn<String>(
    'illustrators',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid(illustrators) AND json_type(illustrators) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _publishersMeta = const VerificationMeta(
    'publishers',
  );
  late final GeneratedColumn<String> publishers = GeneratedColumn<String>(
    'publishers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid(publishers) AND json_type(publishers) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _serializationsMeta = const VerificationMeta(
    'serializations',
  );
  late final GeneratedColumn<String> serializations = GeneratedColumn<String>(
    'serializations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid(serializations) AND json_type(serializations) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    bangumiId,
    title,
    originalTitle,
    aliases,
    coverUrl,
    localCoverPath,
    status,
    publicationStatus,
    score,
    currentVolume,
    currentChapter,
    totalVolumes,
    totalChapters,
    notes,
    tags,
    summary,
    authors,
    illustrators,
    publishers,
    serializations,
    startDate,
    endDate,
    releaseDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manga';
  @override
  VerificationContext validateIntegrity(
    Insertable<MangaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('bangumi_id')) {
      context.handle(
        _bangumiIdMeta,
        bangumiId.isAcceptableOrUnknown(data['bangumi_id']!, _bangumiIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(
          data['original_title']!,
          _originalTitleMeta,
        ),
      );
    }
    if (data.containsKey('aliases')) {
      context.handle(
        _aliasesMeta,
        aliases.isAcceptableOrUnknown(data['aliases']!, _aliasesMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('local_cover_path')) {
      context.handle(
        _localCoverPathMeta,
        localCoverPath.isAcceptableOrUnknown(
          data['local_cover_path']!,
          _localCoverPathMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('publication_status')) {
      context.handle(
        _publicationStatusMeta,
        publicationStatus.isAcceptableOrUnknown(
          data['publication_status']!,
          _publicationStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicationStatusMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('current_volume')) {
      context.handle(
        _currentVolumeMeta,
        currentVolume.isAcceptableOrUnknown(
          data['current_volume']!,
          _currentVolumeMeta,
        ),
      );
    }
    if (data.containsKey('current_chapter')) {
      context.handle(
        _currentChapterMeta,
        currentChapter.isAcceptableOrUnknown(
          data['current_chapter']!,
          _currentChapterMeta,
        ),
      );
    }
    if (data.containsKey('total_volumes')) {
      context.handle(
        _totalVolumesMeta,
        totalVolumes.isAcceptableOrUnknown(
          data['total_volumes']!,
          _totalVolumesMeta,
        ),
      );
    }
    if (data.containsKey('total_chapters')) {
      context.handle(
        _totalChaptersMeta,
        totalChapters.isAcceptableOrUnknown(
          data['total_chapters']!,
          _totalChaptersMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('authors')) {
      context.handle(
        _authorsMeta,
        authors.isAcceptableOrUnknown(data['authors']!, _authorsMeta),
      );
    }
    if (data.containsKey('illustrators')) {
      context.handle(
        _illustratorsMeta,
        illustrators.isAcceptableOrUnknown(
          data['illustrators']!,
          _illustratorsMeta,
        ),
      );
    }
    if (data.containsKey('publishers')) {
      context.handle(
        _publishersMeta,
        publishers.isAcceptableOrUnknown(data['publishers']!, _publishersMeta),
      );
    }
    if (data.containsKey('serializations')) {
      context.handle(
        _serializationsMeta,
        serializations.isAcceptableOrUnknown(
          data['serializations']!,
          _serializationsMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MangaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MangaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      bangumiId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bangumi_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_title'],
      ),
      aliases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      localCoverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_cover_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      publicationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication_status'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      ),
      currentVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_volume'],
      ),
      currentChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_chapter'],
      ),
      totalVolumes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_volumes'],
      ),
      totalChapters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chapters'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      authors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authors'],
      )!,
      illustrators: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}illustrators'],
      )!,
      publishers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publishers'],
      )!,
      serializations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serializations'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  Manga createAlias(String alias) {
    return Manga(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK(start_date IS NULL OR end_date IS NULL OR start_date <= end_date)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class MangaData extends DataClass implements Insertable<MangaData> {
  final int id;
  final String uuid;
  final int? bangumiId;
  final String title;
  final String? originalTitle;
  final String aliases;
  final String? coverUrl;
  final String? localCoverPath;
  final String status;
  final String publicationStatus;
  final double? score;
  final int? currentVolume;
  final int? currentChapter;
  final int? totalVolumes;
  final int? totalChapters;
  final String? notes;
  final String tags;
  final String? summary;
  final String authors;
  final String illustrators;
  final String publishers;
  final String serializations;
  final String? startDate;
  final String? endDate;
  final String? releaseDate;
  final String createdAt;
  final String updatedAt;
  const MangaData({
    required this.id,
    required this.uuid,
    this.bangumiId,
    required this.title,
    this.originalTitle,
    required this.aliases,
    this.coverUrl,
    this.localCoverPath,
    required this.status,
    required this.publicationStatus,
    this.score,
    this.currentVolume,
    this.currentChapter,
    this.totalVolumes,
    this.totalChapters,
    this.notes,
    required this.tags,
    this.summary,
    required this.authors,
    required this.illustrators,
    required this.publishers,
    required this.serializations,
    this.startDate,
    this.endDate,
    this.releaseDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || bangumiId != null) {
      map['bangumi_id'] = Variable<int>(bangumiId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || originalTitle != null) {
      map['original_title'] = Variable<String>(originalTitle);
    }
    map['aliases'] = Variable<String>(aliases);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || localCoverPath != null) {
      map['local_cover_path'] = Variable<String>(localCoverPath);
    }
    map['status'] = Variable<String>(status);
    map['publication_status'] = Variable<String>(publicationStatus);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    if (!nullToAbsent || currentVolume != null) {
      map['current_volume'] = Variable<int>(currentVolume);
    }
    if (!nullToAbsent || currentChapter != null) {
      map['current_chapter'] = Variable<int>(currentChapter);
    }
    if (!nullToAbsent || totalVolumes != null) {
      map['total_volumes'] = Variable<int>(totalVolumes);
    }
    if (!nullToAbsent || totalChapters != null) {
      map['total_chapters'] = Variable<int>(totalChapters);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    map['authors'] = Variable<String>(authors);
    map['illustrators'] = Variable<String>(illustrators);
    map['publishers'] = Variable<String>(publishers);
    map['serializations'] = Variable<String>(serializations);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  MangaCompanion toCompanion(bool nullToAbsent) {
    return MangaCompanion(
      id: Value(id),
      uuid: Value(uuid),
      bangumiId: bangumiId == null && nullToAbsent
          ? const Value.absent()
          : Value(bangumiId),
      title: Value(title),
      originalTitle: originalTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTitle),
      aliases: Value(aliases),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      localCoverPath: localCoverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localCoverPath),
      status: Value(status),
      publicationStatus: Value(publicationStatus),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      currentVolume: currentVolume == null && nullToAbsent
          ? const Value.absent()
          : Value(currentVolume),
      currentChapter: currentChapter == null && nullToAbsent
          ? const Value.absent()
          : Value(currentChapter),
      totalVolumes: totalVolumes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalVolumes),
      totalChapters: totalChapters == null && nullToAbsent
          ? const Value.absent()
          : Value(totalChapters),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      tags: Value(tags),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      authors: Value(authors),
      illustrators: Value(illustrators),
      publishers: Value(publishers),
      serializations: Value(serializations),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MangaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MangaData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      bangumiId: serializer.fromJson<int?>(json['bangumi_id']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String?>(json['original_title']),
      aliases: serializer.fromJson<String>(json['aliases']),
      coverUrl: serializer.fromJson<String?>(json['cover_url']),
      localCoverPath: serializer.fromJson<String?>(json['local_cover_path']),
      status: serializer.fromJson<String>(json['status']),
      publicationStatus: serializer.fromJson<String>(
        json['publication_status'],
      ),
      score: serializer.fromJson<double?>(json['score']),
      currentVolume: serializer.fromJson<int?>(json['current_volume']),
      currentChapter: serializer.fromJson<int?>(json['current_chapter']),
      totalVolumes: serializer.fromJson<int?>(json['total_volumes']),
      totalChapters: serializer.fromJson<int?>(json['total_chapters']),
      notes: serializer.fromJson<String?>(json['notes']),
      tags: serializer.fromJson<String>(json['tags']),
      summary: serializer.fromJson<String?>(json['summary']),
      authors: serializer.fromJson<String>(json['authors']),
      illustrators: serializer.fromJson<String>(json['illustrators']),
      publishers: serializer.fromJson<String>(json['publishers']),
      serializations: serializer.fromJson<String>(json['serializations']),
      startDate: serializer.fromJson<String?>(json['start_date']),
      endDate: serializer.fromJson<String?>(json['end_date']),
      releaseDate: serializer.fromJson<String?>(json['release_date']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'bangumi_id': serializer.toJson<int?>(bangumiId),
      'title': serializer.toJson<String>(title),
      'original_title': serializer.toJson<String?>(originalTitle),
      'aliases': serializer.toJson<String>(aliases),
      'cover_url': serializer.toJson<String?>(coverUrl),
      'local_cover_path': serializer.toJson<String?>(localCoverPath),
      'status': serializer.toJson<String>(status),
      'publication_status': serializer.toJson<String>(publicationStatus),
      'score': serializer.toJson<double?>(score),
      'current_volume': serializer.toJson<int?>(currentVolume),
      'current_chapter': serializer.toJson<int?>(currentChapter),
      'total_volumes': serializer.toJson<int?>(totalVolumes),
      'total_chapters': serializer.toJson<int?>(totalChapters),
      'notes': serializer.toJson<String?>(notes),
      'tags': serializer.toJson<String>(tags),
      'summary': serializer.toJson<String?>(summary),
      'authors': serializer.toJson<String>(authors),
      'illustrators': serializer.toJson<String>(illustrators),
      'publishers': serializer.toJson<String>(publishers),
      'serializations': serializer.toJson<String>(serializations),
      'start_date': serializer.toJson<String?>(startDate),
      'end_date': serializer.toJson<String?>(endDate),
      'release_date': serializer.toJson<String?>(releaseDate),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  MangaData copyWith({
    int? id,
    String? uuid,
    Value<int?> bangumiId = const Value.absent(),
    String? title,
    Value<String?> originalTitle = const Value.absent(),
    String? aliases,
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> localCoverPath = const Value.absent(),
    String? status,
    String? publicationStatus,
    Value<double?> score = const Value.absent(),
    Value<int?> currentVolume = const Value.absent(),
    Value<int?> currentChapter = const Value.absent(),
    Value<int?> totalVolumes = const Value.absent(),
    Value<int?> totalChapters = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? tags,
    Value<String?> summary = const Value.absent(),
    String? authors,
    String? illustrators,
    String? publishers,
    String? serializations,
    Value<String?> startDate = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    Value<String?> releaseDate = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => MangaData(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    bangumiId: bangumiId.present ? bangumiId.value : this.bangumiId,
    title: title ?? this.title,
    originalTitle: originalTitle.present
        ? originalTitle.value
        : this.originalTitle,
    aliases: aliases ?? this.aliases,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    localCoverPath: localCoverPath.present
        ? localCoverPath.value
        : this.localCoverPath,
    status: status ?? this.status,
    publicationStatus: publicationStatus ?? this.publicationStatus,
    score: score.present ? score.value : this.score,
    currentVolume: currentVolume.present
        ? currentVolume.value
        : this.currentVolume,
    currentChapter: currentChapter.present
        ? currentChapter.value
        : this.currentChapter,
    totalVolumes: totalVolumes.present ? totalVolumes.value : this.totalVolumes,
    totalChapters: totalChapters.present
        ? totalChapters.value
        : this.totalChapters,
    notes: notes.present ? notes.value : this.notes,
    tags: tags ?? this.tags,
    summary: summary.present ? summary.value : this.summary,
    authors: authors ?? this.authors,
    illustrators: illustrators ?? this.illustrators,
    publishers: publishers ?? this.publishers,
    serializations: serializations ?? this.serializations,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MangaData copyWithCompanion(MangaCompanion data) {
    return MangaData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      bangumiId: data.bangumiId.present ? data.bangumiId.value : this.bangumiId,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      aliases: data.aliases.present ? data.aliases.value : this.aliases,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      localCoverPath: data.localCoverPath.present
          ? data.localCoverPath.value
          : this.localCoverPath,
      status: data.status.present ? data.status.value : this.status,
      publicationStatus: data.publicationStatus.present
          ? data.publicationStatus.value
          : this.publicationStatus,
      score: data.score.present ? data.score.value : this.score,
      currentVolume: data.currentVolume.present
          ? data.currentVolume.value
          : this.currentVolume,
      currentChapter: data.currentChapter.present
          ? data.currentChapter.value
          : this.currentChapter,
      totalVolumes: data.totalVolumes.present
          ? data.totalVolumes.value
          : this.totalVolumes,
      totalChapters: data.totalChapters.present
          ? data.totalChapters.value
          : this.totalChapters,
      notes: data.notes.present ? data.notes.value : this.notes,
      tags: data.tags.present ? data.tags.value : this.tags,
      summary: data.summary.present ? data.summary.value : this.summary,
      authors: data.authors.present ? data.authors.value : this.authors,
      illustrators: data.illustrators.present
          ? data.illustrators.value
          : this.illustrators,
      publishers: data.publishers.present
          ? data.publishers.value
          : this.publishers,
      serializations: data.serializations.present
          ? data.serializations.value
          : this.serializations,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MangaData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bangumiId: $bangumiId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('aliases: $aliases, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('localCoverPath: $localCoverPath, ')
          ..write('status: $status, ')
          ..write('publicationStatus: $publicationStatus, ')
          ..write('score: $score, ')
          ..write('currentVolume: $currentVolume, ')
          ..write('currentChapter: $currentChapter, ')
          ..write('totalVolumes: $totalVolumes, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('notes: $notes, ')
          ..write('tags: $tags, ')
          ..write('summary: $summary, ')
          ..write('authors: $authors, ')
          ..write('illustrators: $illustrators, ')
          ..write('publishers: $publishers, ')
          ..write('serializations: $serializations, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    bangumiId,
    title,
    originalTitle,
    aliases,
    coverUrl,
    localCoverPath,
    status,
    publicationStatus,
    score,
    currentVolume,
    currentChapter,
    totalVolumes,
    totalChapters,
    notes,
    tags,
    summary,
    authors,
    illustrators,
    publishers,
    serializations,
    startDate,
    endDate,
    releaseDate,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MangaData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.bangumiId == this.bangumiId &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.aliases == this.aliases &&
          other.coverUrl == this.coverUrl &&
          other.localCoverPath == this.localCoverPath &&
          other.status == this.status &&
          other.publicationStatus == this.publicationStatus &&
          other.score == this.score &&
          other.currentVolume == this.currentVolume &&
          other.currentChapter == this.currentChapter &&
          other.totalVolumes == this.totalVolumes &&
          other.totalChapters == this.totalChapters &&
          other.notes == this.notes &&
          other.tags == this.tags &&
          other.summary == this.summary &&
          other.authors == this.authors &&
          other.illustrators == this.illustrators &&
          other.publishers == this.publishers &&
          other.serializations == this.serializations &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.releaseDate == this.releaseDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MangaCompanion extends UpdateCompanion<MangaData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int?> bangumiId;
  final Value<String> title;
  final Value<String?> originalTitle;
  final Value<String> aliases;
  final Value<String?> coverUrl;
  final Value<String?> localCoverPath;
  final Value<String> status;
  final Value<String> publicationStatus;
  final Value<double?> score;
  final Value<int?> currentVolume;
  final Value<int?> currentChapter;
  final Value<int?> totalVolumes;
  final Value<int?> totalChapters;
  final Value<String?> notes;
  final Value<String> tags;
  final Value<String?> summary;
  final Value<String> authors;
  final Value<String> illustrators;
  final Value<String> publishers;
  final Value<String> serializations;
  final Value<String?> startDate;
  final Value<String?> endDate;
  final Value<String?> releaseDate;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const MangaCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.bangumiId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.aliases = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.localCoverPath = const Value.absent(),
    this.status = const Value.absent(),
    this.publicationStatus = const Value.absent(),
    this.score = const Value.absent(),
    this.currentVolume = const Value.absent(),
    this.currentChapter = const Value.absent(),
    this.totalVolumes = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.notes = const Value.absent(),
    this.tags = const Value.absent(),
    this.summary = const Value.absent(),
    this.authors = const Value.absent(),
    this.illustrators = const Value.absent(),
    this.publishers = const Value.absent(),
    this.serializations = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MangaCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    this.bangumiId = const Value.absent(),
    required String title,
    this.originalTitle = const Value.absent(),
    this.aliases = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.localCoverPath = const Value.absent(),
    required String status,
    required String publicationStatus,
    this.score = const Value.absent(),
    this.currentVolume = const Value.absent(),
    this.currentChapter = const Value.absent(),
    this.totalVolumes = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.notes = const Value.absent(),
    this.tags = const Value.absent(),
    this.summary = const Value.absent(),
    this.authors = const Value.absent(),
    this.illustrators = const Value.absent(),
    this.publishers = const Value.absent(),
    this.serializations = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.releaseDate = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : uuid = Value(uuid),
       title = Value(title),
       status = Value(status),
       publicationStatus = Value(publicationStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MangaData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? bangumiId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<String>? aliases,
    Expression<String>? coverUrl,
    Expression<String>? localCoverPath,
    Expression<String>? status,
    Expression<String>? publicationStatus,
    Expression<double>? score,
    Expression<int>? currentVolume,
    Expression<int>? currentChapter,
    Expression<int>? totalVolumes,
    Expression<int>? totalChapters,
    Expression<String>? notes,
    Expression<String>? tags,
    Expression<String>? summary,
    Expression<String>? authors,
    Expression<String>? illustrators,
    Expression<String>? publishers,
    Expression<String>? serializations,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? releaseDate,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (bangumiId != null) 'bangumi_id': bangumiId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (aliases != null) 'aliases': aliases,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (localCoverPath != null) 'local_cover_path': localCoverPath,
      if (status != null) 'status': status,
      if (publicationStatus != null) 'publication_status': publicationStatus,
      if (score != null) 'score': score,
      if (currentVolume != null) 'current_volume': currentVolume,
      if (currentChapter != null) 'current_chapter': currentChapter,
      if (totalVolumes != null) 'total_volumes': totalVolumes,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (notes != null) 'notes': notes,
      if (tags != null) 'tags': tags,
      if (summary != null) 'summary': summary,
      if (authors != null) 'authors': authors,
      if (illustrators != null) 'illustrators': illustrators,
      if (publishers != null) 'publishers': publishers,
      if (serializations != null) 'serializations': serializations,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (releaseDate != null) 'release_date': releaseDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MangaCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int?>? bangumiId,
    Value<String>? title,
    Value<String?>? originalTitle,
    Value<String>? aliases,
    Value<String?>? coverUrl,
    Value<String?>? localCoverPath,
    Value<String>? status,
    Value<String>? publicationStatus,
    Value<double?>? score,
    Value<int?>? currentVolume,
    Value<int?>? currentChapter,
    Value<int?>? totalVolumes,
    Value<int?>? totalChapters,
    Value<String?>? notes,
    Value<String>? tags,
    Value<String?>? summary,
    Value<String>? authors,
    Value<String>? illustrators,
    Value<String>? publishers,
    Value<String>? serializations,
    Value<String?>? startDate,
    Value<String?>? endDate,
    Value<String?>? releaseDate,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return MangaCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bangumiId: bangumiId ?? this.bangumiId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      aliases: aliases ?? this.aliases,
      coverUrl: coverUrl ?? this.coverUrl,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      status: status ?? this.status,
      publicationStatus: publicationStatus ?? this.publicationStatus,
      score: score ?? this.score,
      currentVolume: currentVolume ?? this.currentVolume,
      currentChapter: currentChapter ?? this.currentChapter,
      totalVolumes: totalVolumes ?? this.totalVolumes,
      totalChapters: totalChapters ?? this.totalChapters,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      summary: summary ?? this.summary,
      authors: authors ?? this.authors,
      illustrators: illustrators ?? this.illustrators,
      publishers: publishers ?? this.publishers,
      serializations: serializations ?? this.serializations,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      releaseDate: releaseDate ?? this.releaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (bangumiId.present) {
      map['bangumi_id'] = Variable<int>(bangumiId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (aliases.present) {
      map['aliases'] = Variable<String>(aliases.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (localCoverPath.present) {
      map['local_cover_path'] = Variable<String>(localCoverPath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (publicationStatus.present) {
      map['publication_status'] = Variable<String>(publicationStatus.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (currentVolume.present) {
      map['current_volume'] = Variable<int>(currentVolume.value);
    }
    if (currentChapter.present) {
      map['current_chapter'] = Variable<int>(currentChapter.value);
    }
    if (totalVolumes.present) {
      map['total_volumes'] = Variable<int>(totalVolumes.value);
    }
    if (totalChapters.present) {
      map['total_chapters'] = Variable<int>(totalChapters.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (authors.present) {
      map['authors'] = Variable<String>(authors.value);
    }
    if (illustrators.present) {
      map['illustrators'] = Variable<String>(illustrators.value);
    }
    if (publishers.present) {
      map['publishers'] = Variable<String>(publishers.value);
    }
    if (serializations.present) {
      map['serializations'] = Variable<String>(serializations.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MangaCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bangumiId: $bangumiId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('aliases: $aliases, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('localCoverPath: $localCoverPath, ')
          ..write('status: $status, ')
          ..write('publicationStatus: $publicationStatus, ')
          ..write('score: $score, ')
          ..write('currentVolume: $currentVolume, ')
          ..write('currentChapter: $currentChapter, ')
          ..write('totalVolumes: $totalVolumes, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('notes: $notes, ')
          ..write('tags: $tags, ')
          ..write('summary: $summary, ')
          ..write('authors: $authors, ')
          ..write('illustrators: $illustrators, ')
          ..write('publishers: $publishers, ')
          ..write('serializations: $serializations, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Anime anime = Anime(this);
  late final Index animeStatus = Index(
    'anime_status',
    'CREATE INDEX anime_status ON anime (status)',
  );
  late final Index animeUpdated = Index(
    'anime_updated',
    'CREATE INDEX anime_updated ON anime (updated_at)',
  );
  late final Index animeTitle = Index(
    'anime_title',
    'CREATE INDEX anime_title ON anime (title)',
  );
  late final Index animeSource = Index(
    'anime_source',
    'CREATE INDEX anime_source ON anime (source_provider, source_id)',
  );
  late final WatchHistory watchHistory = WatchHistory(this);
  late final Index historyAnime = Index(
    'history_anime',
    'CREATE INDEX history_anime ON watch_history (anime_uuid, watched_on)',
  );
  late final AnimeNotes animeNotes = AnimeNotes(this);
  late final Index overallNote = Index(
    'overall_note',
    'CREATE UNIQUE INDEX overall_note ON anime_notes (anime_uuid) WHERE episode IS NULL',
  );
  late final IntakeCommits intakeCommits = IntakeCommits(this);
  late final AppSettings appSettings = AppSettings(this);
  late final LegacyImports legacyImports = LegacyImports(this);
  late final Manga manga = Manga(this);
  late final Index mangaStatus = Index(
    'manga_status',
    'CREATE INDEX manga_status ON manga (status)',
  );
  late final Index mangaUpdated = Index(
    'manga_updated',
    'CREATE INDEX manga_updated ON manga (updated_at)',
  );
  late final Index mangaTitle = Index(
    'manga_title',
    'CREATE INDEX manga_title ON manga (title)',
  );
  late final Index mangaBangumi = Index(
    'manga_bangumi',
    'CREATE INDEX manga_bangumi ON manga (bangumi_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    anime,
    animeStatus,
    animeUpdated,
    animeTitle,
    animeSource,
    watchHistory,
    historyAnime,
    animeNotes,
    overallNote,
    intakeCommits,
    appSettings,
    legacyImports,
    manga,
    mangaStatus,
    mangaUpdated,
    mangaTitle,
    mangaBangumi,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('watch_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('anime_notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('intake_commits', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $AnimeCreateCompanionBuilder = AnimeCompanion Function({
  Value<int> id,
  required String uuid,
  required String title,
  Value<String?> originalTitle,
  Value<int?> season,
  Value<String?> entryType,
  Value<String?> sourceProvider,
  Value<String?> sourceId,
  Value<int?> totalEpisodes,
  Value<int?> durationMinutes,
  Value<String?> summary,
  Value<String?> coverUrl,
  Value<String?> premiereDate,
  Value<bool?> isFinished,
  Value<String> cast,
  Value<String> castAliases,
  Value<String?> localCoverPath,
  required String status,
  Value<int> progress,
  Value<double?> score,
  Value<int?> rewatchCount,
  Value<String> tags,
  Value<String?> notes,
  Value<String?> startDate,
  Value<String?> startDateSource,
  Value<String?> endDate,
  required String createdAt,
  required String updatedAt,
});
typedef $AnimeUpdateCompanionBuilder = AnimeCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> title,
  Value<String?> originalTitle,
  Value<int?> season,
  Value<String?> entryType,
  Value<String?> sourceProvider,
  Value<String?> sourceId,
  Value<int?> totalEpisodes,
  Value<int?> durationMinutes,
  Value<String?> summary,
  Value<String?> coverUrl,
  Value<String?> premiereDate,
  Value<bool?> isFinished,
  Value<String> cast,
  Value<String> castAliases,
  Value<String?> localCoverPath,
  Value<String> status,
  Value<int> progress,
  Value<double?> score,
  Value<int?> rewatchCount,
  Value<String> tags,
  Value<String?> notes,
  Value<String?> startDate,
  Value<String?> startDateSource,
  Value<String?> endDate,
  Value<String> createdAt,
  Value<String> updatedAt,
});

final class $AnimeReferences
    extends BaseReferences<_$AppDatabase, Anime, AnimeData> {
  $AnimeReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<WatchHistory, List<WatchHistoryData>>
  _watchHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.watchHistory,
    aliasName: 'anime__uuid__watch_history__anime_uuid',
  );

  $WatchHistoryProcessedTableManager get watchHistoryRefs {
    final manager = $WatchHistoryTableManager(
      $_db,
      $_db.watchHistory,
    ).filter((f) => f.animeUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!));

    final cache = $_typedResult.readTableOrNull(_watchHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<AnimeNotes, List<AnimeNote>> _animeNotesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.animeNotes,
    aliasName: 'anime__uuid__anime_notes__anime_uuid',
  );

  $AnimeNotesProcessedTableManager get animeNotesRefs {
    final manager = $AnimeNotesTableManager(
      $_db,
      $_db.animeNotes,
    ).filter((f) => f.animeUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!));

    final cache = $_typedResult.readTableOrNull(_animeNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<IntakeCommits, List<IntakeCommit>>
  _intakeCommitsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.intakeCommits,
    aliasName: 'anime__uuid__intake_commits__anime_uuid',
  );

  $IntakeCommitsProcessedTableManager get intakeCommitsRefs {
    final manager = $IntakeCommitsTableManager(
      $_db,
      $_db.intakeCommits,
    ).filter((f) => f.animeUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!));

    final cache = $_typedResult.readTableOrNull(_intakeCommitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $AnimeFilterComposer extends Composer<_$AppDatabase, Anime> {
  $AnimeFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceProvider => $composableBuilder(
    column: $table.sourceProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get premiereDate => $composableBuilder(
    column: $table.premiereDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cast => $composableBuilder(
    column: $table.cast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get castAliases => $composableBuilder(
    column: $table.castAliases,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localCoverPath => $composableBuilder(
    column: $table.localCoverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDateSource => $composableBuilder(
    column: $table.startDateSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> watchHistoryRefs(
    Expression<bool> Function($WatchHistoryFilterComposer f) f,
  ) {
    final $WatchHistoryFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.animeUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WatchHistoryFilterComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> animeNotesRefs(
    Expression<bool> Function($AnimeNotesFilterComposer f) f,
  ) {
    final $AnimeNotesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.animeNotes,
      getReferencedColumn: (t) => t.animeUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeNotesFilterComposer(
            $db: $db,
            $table: $db.animeNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> intakeCommitsRefs(
    Expression<bool> Function($IntakeCommitsFilterComposer f) f,
  ) {
    final $IntakeCommitsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.intakeCommits,
      getReferencedColumn: (t) => t.animeUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $IntakeCommitsFilterComposer(
            $db: $db,
            $table: $db.intakeCommits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $AnimeOrderingComposer extends Composer<_$AppDatabase, Anime> {
  $AnimeOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceProvider => $composableBuilder(
    column: $table.sourceProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get premiereDate => $composableBuilder(
    column: $table.premiereDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cast => $composableBuilder(
    column: $table.cast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get castAliases => $composableBuilder(
    column: $table.castAliases,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localCoverPath => $composableBuilder(
    column: $table.localCoverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDateSource => $composableBuilder(
    column: $table.startDateSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AnimeAnnotationComposer extends Composer<_$AppDatabase, Anime> {
  $AnimeAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<String> get sourceProvider => $composableBuilder(
    column: $table.sourceProvider,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get premiereDate => $composableBuilder(
    column: $table.premiereDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => column);

  GeneratedColumn<String> get castAliases => $composableBuilder(
    column: $table.castAliases,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localCoverPath => $composableBuilder(
    column: $table.localCoverPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get rewatchCount => $composableBuilder(
    column: $table.rewatchCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get startDateSource => $composableBuilder(
    column: $table.startDateSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> watchHistoryRefs<T extends Object>(
    Expression<T> Function($WatchHistoryAnnotationComposer a) f,
  ) {
    final $WatchHistoryAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.animeUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WatchHistoryAnnotationComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> animeNotesRefs<T extends Object>(
    Expression<T> Function($AnimeNotesAnnotationComposer a) f,
  ) {
    final $AnimeNotesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.animeNotes,
      getReferencedColumn: (t) => t.animeUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeNotesAnnotationComposer(
            $db: $db,
            $table: $db.animeNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> intakeCommitsRefs<T extends Object>(
    Expression<T> Function($IntakeCommitsAnnotationComposer a) f,
  ) {
    final $IntakeCommitsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.intakeCommits,
      getReferencedColumn: (t) => t.animeUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $IntakeCommitsAnnotationComposer(
            $db: $db,
            $table: $db.intakeCommits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $AnimeTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Anime,
          AnimeData,
          $AnimeFilterComposer,
          $AnimeOrderingComposer,
          $AnimeAnnotationComposer,
          $AnimeCreateCompanionBuilder,
          $AnimeUpdateCompanionBuilder,
          (AnimeData, $AnimeReferences),
          AnimeData,
          PrefetchHooks Function({
            bool watchHistoryRefs,
            bool animeNotesRefs,
            bool intakeCommitsRefs,
          })
        > {
  $AnimeTableManager(_$AppDatabase db, Anime table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AnimeFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AnimeOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AnimeAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> season = const Value.absent(),
                Value<String?> entryType = const Value.absent(),
                Value<String?> sourceProvider = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int?> totalEpisodes = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> premiereDate = const Value.absent(),
                Value<bool?> isFinished = const Value.absent(),
                Value<String> cast = const Value.absent(),
                Value<String> castAliases = const Value.absent(),
                Value<String?> localCoverPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<int?> rewatchCount = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> startDateSource = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => AnimeCompanion(
                id: id,
                uuid: uuid,
                title: title,
                originalTitle: originalTitle,
                season: season,
                entryType: entryType,
                sourceProvider: sourceProvider,
                sourceId: sourceId,
                totalEpisodes: totalEpisodes,
                durationMinutes: durationMinutes,
                summary: summary,
                coverUrl: coverUrl,
                premiereDate: premiereDate,
                isFinished: isFinished,
                cast: cast,
                castAliases: castAliases,
                localCoverPath: localCoverPath,
                status: status,
                progress: progress,
                score: score,
                rewatchCount: rewatchCount,
                tags: tags,
                notes: notes,
                startDate: startDate,
                startDateSource: startDateSource,
                endDate: endDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String title,
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> season = const Value.absent(),
                Value<String?> entryType = const Value.absent(),
                Value<String?> sourceProvider = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int?> totalEpisodes = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> premiereDate = const Value.absent(),
                Value<bool?> isFinished = const Value.absent(),
                Value<String> cast = const Value.absent(),
                Value<String> castAliases = const Value.absent(),
                Value<String?> localCoverPath = const Value.absent(),
                required String status,
                Value<int> progress = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<int?> rewatchCount = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> startDateSource = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => AnimeCompanion.insert(
                id: id,
                uuid: uuid,
                title: title,
                originalTitle: originalTitle,
                season: season,
                entryType: entryType,
                sourceProvider: sourceProvider,
                sourceId: sourceId,
                totalEpisodes: totalEpisodes,
                durationMinutes: durationMinutes,
                summary: summary,
                coverUrl: coverUrl,
                premiereDate: premiereDate,
                isFinished: isFinished,
                cast: cast,
                castAliases: castAliases,
                localCoverPath: localCoverPath,
                status: status,
                progress: progress,
                score: score,
                rewatchCount: rewatchCount,
                tags: tags,
                notes: notes,
                startDate: startDate,
                startDateSource: startDateSource,
                endDate: endDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Anime, AnimeData>(table),
                  $AnimeReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                watchHistoryRefs = false,
                animeNotesRefs = false,
                intakeCommitsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (watchHistoryRefs) db.watchHistory,
                    if (animeNotesRefs) db.animeNotes,
                    if (intakeCommitsRefs) db.intakeCommits,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (watchHistoryRefs)
                        await $_getPrefetchedData<
                          AnimeData,
                          Anime,
                          WatchHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $AnimeReferences
                              ._watchHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $AnimeReferences(db, table, p0).watchHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.animeUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (animeNotesRefs)
                        await $_getPrefetchedData<AnimeData, Anime, AnimeNote>(
                          currentTable: table,
                          referencedTable: $AnimeReferences
                              ._animeNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $AnimeReferences(db, table, p0).animeNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.animeUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (intakeCommitsRefs)
                        await $_getPrefetchedData<
                          AnimeData,
                          Anime,
                          IntakeCommit
                        >(
                          currentTable: table,
                          referencedTable: $AnimeReferences
                              ._intakeCommitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $AnimeReferences(db, table, p0).intakeCommitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.animeUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $AnimeProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Anime,
      AnimeData,
      $AnimeFilterComposer,
      $AnimeOrderingComposer,
      $AnimeAnnotationComposer,
      $AnimeCreateCompanionBuilder,
      $AnimeUpdateCompanionBuilder,
      (AnimeData, $AnimeReferences),
      AnimeData,
      PrefetchHooks Function({
        bool watchHistoryRefs,
        bool animeNotesRefs,
        bool intakeCommitsRefs,
      })
    >;
typedef $WatchHistoryCreateCompanionBuilder = WatchHistoryCompanion Function({
  Value<int> id,
  required String uuid,
  required String animeUuid,
  required int episode,
  required String watchedOn,
  Value<String?> watchedAt,
  required String createdAt,
});
typedef $WatchHistoryUpdateCompanionBuilder = WatchHistoryCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> animeUuid,
  Value<int> episode,
  Value<String> watchedOn,
  Value<String?> watchedAt,
  Value<String> createdAt,
});

final class $WatchHistoryReferences
    extends BaseReferences<_$AppDatabase, WatchHistory, WatchHistoryData> {
  $WatchHistoryReferences(super.$_db, super.$_table, super.$_typedResult);

  static Anime _animeUuidTable(_$AppDatabase db) =>
      db.anime.createAlias('watch_history__anime_uuid__anime__uuid');

  $AnimeProcessedTableManager get animeUuid {
    final $_column = $_itemColumn<String>('anime_uuid')!;

    final manager = $AnimeTableManager(
      $_db,
      $_db.anime,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_animeUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $WatchHistoryFilterComposer
    extends Composer<_$AppDatabase, WatchHistory> {
  $WatchHistoryFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episode => $composableBuilder(
    column: $table.episode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get watchedOn => $composableBuilder(
    column: $table.watchedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $AnimeFilterComposer get animeUuid {
    final $AnimeFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeUuid,
      referencedTable: $db.anime,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeFilterComposer(
            $db: $db,
            $table: $db.anime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WatchHistoryOrderingComposer
    extends Composer<_$AppDatabase, WatchHistory> {
  $WatchHistoryOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episode => $composableBuilder(
    column: $table.episode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get watchedOn => $composableBuilder(
    column: $table.watchedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $AnimeOrderingComposer get animeUuid {
    final $AnimeOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeUuid,
      referencedTable: $db.anime,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeOrderingComposer(
            $db: $db,
            $table: $db.anime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WatchHistoryAnnotationComposer
    extends Composer<_$AppDatabase, WatchHistory> {
  $WatchHistoryAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get episode =>
      $composableBuilder(column: $table.episode, builder: (column) => column);

  GeneratedColumn<String> get watchedOn =>
      $composableBuilder(column: $table.watchedOn, builder: (column) => column);

  GeneratedColumn<String> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $AnimeAnnotationComposer get animeUuid {
    final $AnimeAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeUuid,
      referencedTable: $db.anime,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeAnnotationComposer(
            $db: $db,
            $table: $db.anime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WatchHistoryTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          WatchHistory,
          WatchHistoryData,
          $WatchHistoryFilterComposer,
          $WatchHistoryOrderingComposer,
          $WatchHistoryAnnotationComposer,
          $WatchHistoryCreateCompanionBuilder,
          $WatchHistoryUpdateCompanionBuilder,
          (WatchHistoryData, $WatchHistoryReferences),
          WatchHistoryData,
          PrefetchHooks Function({bool animeUuid})
        > {
  $WatchHistoryTableManager(_$AppDatabase db, WatchHistory table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $WatchHistoryFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $WatchHistoryOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $WatchHistoryAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> animeUuid = const Value.absent(),
                Value<int> episode = const Value.absent(),
                Value<String> watchedOn = const Value.absent(),
                Value<String?> watchedAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => WatchHistoryCompanion(
                id: id,
                uuid: uuid,
                animeUuid: animeUuid,
                episode: episode,
                watchedOn: watchedOn,
                watchedAt: watchedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String animeUuid,
                required int episode,
                required String watchedOn,
                Value<String?> watchedAt = const Value.absent(),
                required String createdAt,
              }) => WatchHistoryCompanion.insert(
                id: id,
                uuid: uuid,
                animeUuid: animeUuid,
                episode: episode,
                watchedOn: watchedOn,
                watchedAt: watchedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<WatchHistory, WatchHistoryData>(table),
                  $WatchHistoryReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({animeUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (animeUuid) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.animeUuid,
                        referencedTable: $WatchHistoryReferences
                            ._animeUuidTable(db),
                        referencedColumn: $WatchHistoryReferences
                            ._animeUuidTable(db)
                            .uuid,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $WatchHistoryProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      WatchHistory,
      WatchHistoryData,
      $WatchHistoryFilterComposer,
      $WatchHistoryOrderingComposer,
      $WatchHistoryAnnotationComposer,
      $WatchHistoryCreateCompanionBuilder,
      $WatchHistoryUpdateCompanionBuilder,
      (WatchHistoryData, $WatchHistoryReferences),
      WatchHistoryData,
      PrefetchHooks Function({bool animeUuid})
    >;
typedef $AnimeNotesCreateCompanionBuilder = AnimeNotesCompanion Function({
  required String uuid,
  required String animeUuid,
  Value<int?> episode,
  required String content,
  required String notedOn,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $AnimeNotesUpdateCompanionBuilder = AnimeNotesCompanion Function({
  Value<String> uuid,
  Value<String> animeUuid,
  Value<int?> episode,
  Value<String> content,
  Value<String> notedOn,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $AnimeNotesReferences
    extends BaseReferences<_$AppDatabase, AnimeNotes, AnimeNote> {
  $AnimeNotesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Anime _animeUuidTable(_$AppDatabase db) =>
      db.anime.createAlias('anime_notes__anime_uuid__anime__uuid');

  $AnimeProcessedTableManager get animeUuid {
    final $_column = $_itemColumn<String>('anime_uuid')!;

    final manager = $AnimeTableManager(
      $_db,
      $_db.anime,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_animeUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AnimeNotesFilterComposer extends Composer<_$AppDatabase, AnimeNotes> {
  $AnimeNotesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episode => $composableBuilder(
    column: $table.episode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notedOn => $composableBuilder(
    column: $table.notedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $AnimeFilterComposer get animeUuid {
    final $AnimeFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeUuid,
      referencedTable: $db.anime,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeFilterComposer(
            $db: $db,
            $table: $db.anime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AnimeNotesOrderingComposer extends Composer<_$AppDatabase, AnimeNotes> {
  $AnimeNotesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episode => $composableBuilder(
    column: $table.episode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notedOn => $composableBuilder(
    column: $table.notedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $AnimeOrderingComposer get animeUuid {
    final $AnimeOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeUuid,
      referencedTable: $db.anime,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeOrderingComposer(
            $db: $db,
            $table: $db.anime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AnimeNotesAnnotationComposer
    extends Composer<_$AppDatabase, AnimeNotes> {
  $AnimeNotesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get episode =>
      $composableBuilder(column: $table.episode, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get notedOn =>
      $composableBuilder(column: $table.notedOn, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $AnimeAnnotationComposer get animeUuid {
    final $AnimeAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeUuid,
      referencedTable: $db.anime,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeAnnotationComposer(
            $db: $db,
            $table: $db.anime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AnimeNotesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          AnimeNotes,
          AnimeNote,
          $AnimeNotesFilterComposer,
          $AnimeNotesOrderingComposer,
          $AnimeNotesAnnotationComposer,
          $AnimeNotesCreateCompanionBuilder,
          $AnimeNotesUpdateCompanionBuilder,
          (AnimeNote, $AnimeNotesReferences),
          AnimeNote,
          PrefetchHooks Function({bool animeUuid})
        > {
  $AnimeNotesTableManager(_$AppDatabase db, AnimeNotes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AnimeNotesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AnimeNotesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AnimeNotesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> animeUuid = const Value.absent(),
                Value<int?> episode = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> notedOn = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnimeNotesCompanion(
                uuid: uuid,
                animeUuid: animeUuid,
                episode: episode,
                content: content,
                notedOn: notedOn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String animeUuid,
                Value<int?> episode = const Value.absent(),
                required String content,
                required String notedOn,
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AnimeNotesCompanion.insert(
                uuid: uuid,
                animeUuid: animeUuid,
                episode: episode,
                content: content,
                notedOn: notedOn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<AnimeNotes, AnimeNote>(table),
                  $AnimeNotesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({animeUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (animeUuid) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.animeUuid,
                        referencedTable: $AnimeNotesReferences._animeUuidTable(
                          db,
                        ),
                        referencedColumn: $AnimeNotesReferences
                            ._animeUuidTable(db)
                            .uuid,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $AnimeNotesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      AnimeNotes,
      AnimeNote,
      $AnimeNotesFilterComposer,
      $AnimeNotesOrderingComposer,
      $AnimeNotesAnnotationComposer,
      $AnimeNotesCreateCompanionBuilder,
      $AnimeNotesUpdateCompanionBuilder,
      (AnimeNote, $AnimeNotesReferences),
      AnimeNote,
      PrefetchHooks Function({bool animeUuid})
    >;
typedef $IntakeCommitsCreateCompanionBuilder = IntakeCommitsCompanion Function({
  required String draftId,
  required String animeUuid,
  Value<int> rowid,
});
typedef $IntakeCommitsUpdateCompanionBuilder = IntakeCommitsCompanion Function({
  Value<String> draftId,
  Value<String> animeUuid,
  Value<int> rowid,
});

final class $IntakeCommitsReferences
    extends BaseReferences<_$AppDatabase, IntakeCommits, IntakeCommit> {
  $IntakeCommitsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Anime _animeUuidTable(_$AppDatabase db) =>
      db.anime.createAlias('intake_commits__anime_uuid__anime__uuid');

  $AnimeProcessedTableManager get animeUuid {
    final $_column = $_itemColumn<String>('anime_uuid')!;

    final manager = $AnimeTableManager(
      $_db,
      $_db.anime,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_animeUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $IntakeCommitsFilterComposer
    extends Composer<_$AppDatabase, IntakeCommits> {
  $IntakeCommitsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get draftId => $composableBuilder(
    column: $table.draftId,
    builder: (column) => ColumnFilters(column),
  );

  $AnimeFilterComposer get animeUuid {
    final $AnimeFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeUuid,
      referencedTable: $db.anime,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeFilterComposer(
            $db: $db,
            $table: $db.anime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $IntakeCommitsOrderingComposer
    extends Composer<_$AppDatabase, IntakeCommits> {
  $IntakeCommitsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get draftId => $composableBuilder(
    column: $table.draftId,
    builder: (column) => ColumnOrderings(column),
  );

  $AnimeOrderingComposer get animeUuid {
    final $AnimeOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeUuid,
      referencedTable: $db.anime,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeOrderingComposer(
            $db: $db,
            $table: $db.anime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $IntakeCommitsAnnotationComposer
    extends Composer<_$AppDatabase, IntakeCommits> {
  $IntakeCommitsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get draftId =>
      $composableBuilder(column: $table.draftId, builder: (column) => column);

  $AnimeAnnotationComposer get animeUuid {
    final $AnimeAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeUuid,
      referencedTable: $db.anime,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AnimeAnnotationComposer(
            $db: $db,
            $table: $db.anime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $IntakeCommitsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          IntakeCommits,
          IntakeCommit,
          $IntakeCommitsFilterComposer,
          $IntakeCommitsOrderingComposer,
          $IntakeCommitsAnnotationComposer,
          $IntakeCommitsCreateCompanionBuilder,
          $IntakeCommitsUpdateCompanionBuilder,
          (IntakeCommit, $IntakeCommitsReferences),
          IntakeCommit,
          PrefetchHooks Function({bool animeUuid})
        > {
  $IntakeCommitsTableManager(_$AppDatabase db, IntakeCommits table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $IntakeCommitsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $IntakeCommitsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $IntakeCommitsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> draftId = const Value.absent(),
                Value<String> animeUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntakeCommitsCompanion(
                draftId: draftId,
                animeUuid: animeUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String draftId,
                required String animeUuid,
                Value<int> rowid = const Value.absent(),
              }) => IntakeCommitsCompanion.insert(
                draftId: draftId,
                animeUuid: animeUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<IntakeCommits, IntakeCommit>(table),
                  $IntakeCommitsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({animeUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (animeUuid) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.animeUuid,
                        referencedTable: $IntakeCommitsReferences
                            ._animeUuidTable(db),
                        referencedColumn: $IntakeCommitsReferences
                            ._animeUuidTable(db)
                            .uuid,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $IntakeCommitsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      IntakeCommits,
      IntakeCommit,
      $IntakeCommitsFilterComposer,
      $IntakeCommitsOrderingComposer,
      $IntakeCommitsAnnotationComposer,
      $IntakeCommitsCreateCompanionBuilder,
      $IntakeCommitsUpdateCompanionBuilder,
      (IntakeCommit, $IntakeCommitsReferences),
      IntakeCommit,
      PrefetchHooks Function({bool animeUuid})
    >;
typedef $AppSettingsCreateCompanionBuilder = AppSettingsCompanion Function({
  required String settingKey,
  required String value,
  Value<int> rowid,
});
typedef $AppSettingsUpdateCompanionBuilder = AppSettingsCompanion Function({
  Value<String> settingKey,
  Value<String> value,
  Value<int> rowid,
});

class $AppSettingsFilterComposer extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $AppSettingsOrderingComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AppSettingsAnnotationComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $AppSettingsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          AppSettings,
          AppSetting,
          $AppSettingsFilterComposer,
          $AppSettingsOrderingComposer,
          $AppSettingsAnnotationComposer,
          $AppSettingsCreateCompanionBuilder,
          $AppSettingsUpdateCompanionBuilder,
          (AppSetting, BaseReferences<_$AppDatabase, AppSettings, AppSetting>),
          AppSetting,
          PrefetchHooks Function()
        > {
  $AppSettingsTableManager(_$AppDatabase db, AppSettings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AppSettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AppSettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AppSettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> settingKey = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                settingKey: settingKey,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String settingKey,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                settingKey: settingKey,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<AppSettings, AppSetting>(table),
                  BaseReferences<_$AppDatabase, AppSettings, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AppSettingsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      AppSettings,
      AppSetting,
      $AppSettingsFilterComposer,
      $AppSettingsOrderingComposer,
      $AppSettingsAnnotationComposer,
      $AppSettingsCreateCompanionBuilder,
      $AppSettingsUpdateCompanionBuilder,
      (AppSetting, BaseReferences<_$AppDatabase, AppSettings, AppSetting>),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $LegacyImportsCreateCompanionBuilder = LegacyImportsCompanion Function({
  required String fingerprint,
  required String importedAt,
  Value<int> rowid,
});
typedef $LegacyImportsUpdateCompanionBuilder = LegacyImportsCompanion Function({
  Value<String> fingerprint,
  Value<String> importedAt,
  Value<int> rowid,
});

class $LegacyImportsFilterComposer
    extends Composer<_$AppDatabase, LegacyImports> {
  $LegacyImportsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $LegacyImportsOrderingComposer
    extends Composer<_$AppDatabase, LegacyImports> {
  $LegacyImportsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LegacyImportsAnnotationComposer
    extends Composer<_$AppDatabase, LegacyImports> {
  $LegacyImportsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );
}

class $LegacyImportsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          LegacyImports,
          LegacyImport,
          $LegacyImportsFilterComposer,
          $LegacyImportsOrderingComposer,
          $LegacyImportsAnnotationComposer,
          $LegacyImportsCreateCompanionBuilder,
          $LegacyImportsUpdateCompanionBuilder,
          (
            LegacyImport,
            BaseReferences<_$AppDatabase, LegacyImports, LegacyImport>,
          ),
          LegacyImport,
          PrefetchHooks Function()
        > {
  $LegacyImportsTableManager(_$AppDatabase db, LegacyImports table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LegacyImportsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LegacyImportsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LegacyImportsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fingerprint = const Value.absent(),
                Value<String> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LegacyImportsCompanion(
                fingerprint: fingerprint,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fingerprint,
                required String importedAt,
                Value<int> rowid = const Value.absent(),
              }) => LegacyImportsCompanion.insert(
                fingerprint: fingerprint,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LegacyImports, LegacyImport>(table),
                  BaseReferences<_$AppDatabase, LegacyImports, LegacyImport>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LegacyImportsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      LegacyImports,
      LegacyImport,
      $LegacyImportsFilterComposer,
      $LegacyImportsOrderingComposer,
      $LegacyImportsAnnotationComposer,
      $LegacyImportsCreateCompanionBuilder,
      $LegacyImportsUpdateCompanionBuilder,
      (
        LegacyImport,
        BaseReferences<_$AppDatabase, LegacyImports, LegacyImport>,
      ),
      LegacyImport,
      PrefetchHooks Function()
    >;
typedef $MangaCreateCompanionBuilder = MangaCompanion Function({
  Value<int> id,
  required String uuid,
  Value<int?> bangumiId,
  required String title,
  Value<String?> originalTitle,
  Value<String> aliases,
  Value<String?> coverUrl,
  Value<String?> localCoverPath,
  required String status,
  required String publicationStatus,
  Value<double?> score,
  Value<int?> currentVolume,
  Value<int?> currentChapter,
  Value<int?> totalVolumes,
  Value<int?> totalChapters,
  Value<String?> notes,
  Value<String> tags,
  Value<String?> summary,
  Value<String> authors,
  Value<String> illustrators,
  Value<String> publishers,
  Value<String> serializations,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<String?> releaseDate,
  required String createdAt,
  required String updatedAt,
});
typedef $MangaUpdateCompanionBuilder = MangaCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int?> bangumiId,
  Value<String> title,
  Value<String?> originalTitle,
  Value<String> aliases,
  Value<String?> coverUrl,
  Value<String?> localCoverPath,
  Value<String> status,
  Value<String> publicationStatus,
  Value<double?> score,
  Value<int?> currentVolume,
  Value<int?> currentChapter,
  Value<int?> totalVolumes,
  Value<int?> totalChapters,
  Value<String?> notes,
  Value<String> tags,
  Value<String?> summary,
  Value<String> authors,
  Value<String> illustrators,
  Value<String> publishers,
  Value<String> serializations,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<String?> releaseDate,
  Value<String> createdAt,
  Value<String> updatedAt,
});

class $MangaFilterComposer extends Composer<_$AppDatabase, Manga> {
  $MangaFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bangumiId => $composableBuilder(
    column: $table.bangumiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localCoverPath => $composableBuilder(
    column: $table.localCoverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicationStatus => $composableBuilder(
    column: $table.publicationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentVolume => $composableBuilder(
    column: $table.currentVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentChapter => $composableBuilder(
    column: $table.currentChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalVolumes => $composableBuilder(
    column: $table.totalVolumes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authors => $composableBuilder(
    column: $table.authors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get illustrators => $composableBuilder(
    column: $table.illustrators,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishers => $composableBuilder(
    column: $table.publishers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serializations => $composableBuilder(
    column: $table.serializations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $MangaOrderingComposer extends Composer<_$AppDatabase, Manga> {
  $MangaOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bangumiId => $composableBuilder(
    column: $table.bangumiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localCoverPath => $composableBuilder(
    column: $table.localCoverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicationStatus => $composableBuilder(
    column: $table.publicationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentVolume => $composableBuilder(
    column: $table.currentVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentChapter => $composableBuilder(
    column: $table.currentChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalVolumes => $composableBuilder(
    column: $table.totalVolumes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authors => $composableBuilder(
    column: $table.authors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get illustrators => $composableBuilder(
    column: $table.illustrators,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishers => $composableBuilder(
    column: $table.publishers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serializations => $composableBuilder(
    column: $table.serializations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MangaAnnotationComposer extends Composer<_$AppDatabase, Manga> {
  $MangaAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get bangumiId =>
      $composableBuilder(column: $table.bangumiId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aliases =>
      $composableBuilder(column: $table.aliases, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get localCoverPath => $composableBuilder(
    column: $table.localCoverPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get publicationStatus => $composableBuilder(
    column: $table.publicationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get currentVolume => $composableBuilder(
    column: $table.currentVolume,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentChapter => $composableBuilder(
    column: $table.currentChapter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalVolumes => $composableBuilder(
    column: $table.totalVolumes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get authors =>
      $composableBuilder(column: $table.authors, builder: (column) => column);

  GeneratedColumn<String> get illustrators => $composableBuilder(
    column: $table.illustrators,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publishers => $composableBuilder(
    column: $table.publishers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serializations => $composableBuilder(
    column: $table.serializations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $MangaTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Manga,
          MangaData,
          $MangaFilterComposer,
          $MangaOrderingComposer,
          $MangaAnnotationComposer,
          $MangaCreateCompanionBuilder,
          $MangaUpdateCompanionBuilder,
          (MangaData, BaseReferences<_$AppDatabase, Manga, MangaData>),
          MangaData,
          PrefetchHooks Function()
        > {
  $MangaTableManager(_$AppDatabase db, Manga table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MangaFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MangaOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MangaAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int?> bangumiId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalTitle = const Value.absent(),
                Value<String> aliases = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> localCoverPath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> publicationStatus = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<int?> currentVolume = const Value.absent(),
                Value<int?> currentChapter = const Value.absent(),
                Value<int?> totalVolumes = const Value.absent(),
                Value<int?> totalChapters = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String> authors = const Value.absent(),
                Value<String> illustrators = const Value.absent(),
                Value<String> publishers = const Value.absent(),
                Value<String> serializations = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => MangaCompanion(
                id: id,
                uuid: uuid,
                bangumiId: bangumiId,
                title: title,
                originalTitle: originalTitle,
                aliases: aliases,
                coverUrl: coverUrl,
                localCoverPath: localCoverPath,
                status: status,
                publicationStatus: publicationStatus,
                score: score,
                currentVolume: currentVolume,
                currentChapter: currentChapter,
                totalVolumes: totalVolumes,
                totalChapters: totalChapters,
                notes: notes,
                tags: tags,
                summary: summary,
                authors: authors,
                illustrators: illustrators,
                publishers: publishers,
                serializations: serializations,
                startDate: startDate,
                endDate: endDate,
                releaseDate: releaseDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                Value<int?> bangumiId = const Value.absent(),
                required String title,
                Value<String?> originalTitle = const Value.absent(),
                Value<String> aliases = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> localCoverPath = const Value.absent(),
                required String status,
                required String publicationStatus,
                Value<double?> score = const Value.absent(),
                Value<int?> currentVolume = const Value.absent(),
                Value<int?> currentChapter = const Value.absent(),
                Value<int?> totalVolumes = const Value.absent(),
                Value<int?> totalChapters = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String> authors = const Value.absent(),
                Value<String> illustrators = const Value.absent(),
                Value<String> publishers = const Value.absent(),
                Value<String> serializations = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => MangaCompanion.insert(
                id: id,
                uuid: uuid,
                bangumiId: bangumiId,
                title: title,
                originalTitle: originalTitle,
                aliases: aliases,
                coverUrl: coverUrl,
                localCoverPath: localCoverPath,
                status: status,
                publicationStatus: publicationStatus,
                score: score,
                currentVolume: currentVolume,
                currentChapter: currentChapter,
                totalVolumes: totalVolumes,
                totalChapters: totalChapters,
                notes: notes,
                tags: tags,
                summary: summary,
                authors: authors,
                illustrators: illustrators,
                publishers: publishers,
                serializations: serializations,
                startDate: startDate,
                endDate: endDate,
                releaseDate: releaseDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Manga, MangaData>(table),
                  BaseReferences<_$AppDatabase, Manga, MangaData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $MangaProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Manga,
      MangaData,
      $MangaFilterComposer,
      $MangaOrderingComposer,
      $MangaAnnotationComposer,
      $MangaCreateCompanionBuilder,
      $MangaUpdateCompanionBuilder,
      (MangaData, BaseReferences<_$AppDatabase, Manga, MangaData>),
      MangaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $AnimeTableManager get anime => $AnimeTableManager(_db, _db.anime);
  $WatchHistoryTableManager get watchHistory =>
      $WatchHistoryTableManager(_db, _db.watchHistory);
  $AnimeNotesTableManager get animeNotes =>
      $AnimeNotesTableManager(_db, _db.animeNotes);
  $IntakeCommitsTableManager get intakeCommits =>
      $IntakeCommitsTableManager(_db, _db.intakeCommits);
  $AppSettingsTableManager get appSettings =>
      $AppSettingsTableManager(_db, _db.appSettings);
  $LegacyImportsTableManager get legacyImports =>
      $LegacyImportsTableManager(_db, _db.legacyImports);
  $MangaTableManager get manga => $MangaTableManager(_db, _db.manga);
}
