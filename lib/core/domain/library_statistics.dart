import 'quick_record_models.dart';

enum ActivityRange { week, month, year }

class StatisticBucket {
  final String label;
  final int count;
  final String? periodLabel;
  final int? workCount;
  const StatisticBucket(
    this.label,
    this.count, {
    this.periodLabel,
    this.workCount,
  });
}

class ActivityStatistics {
  final List<StatisticBucket> buckets;
  final int events;
  final int activeDays;
  final int days;
  const ActivityStatistics(
    this.buckets,
    this.events,
    this.activeDays,
    this.days,
  );

  factory ActivityStatistics.fromHistory(
    List<WatchHistoryRecord> history,
    ActivityRange range,
    DateTime now,
  ) {
    // UTC dates are used only for calendar arithmetic, never to shift watchedOn.
    final today = DateTime.utc(now.year, now.month, now.day);
    final start = range == ActivityRange.year
        ? DateTime.utc(now.year)
        : today.subtract(Duration(days: range == ActivityRange.week ? 6 : 29));
    final daily = <String, int>{};
    final monthly = <int, int>{};
    final dailyWorks = <String, Set<String>>{};
    final monthlyWorks = <int, Set<String>>{};
    var events = 0;
    for (final event in history) {
      final date = _calendarDate(event.watchedOn);
      if (date == null || date.isBefore(start) || date.isAfter(today)) continue;
      daily.update(event.watchedOn, (n) => n + 1, ifAbsent: () => 1);
      monthly.update(date.month, (n) => n + 1, ifAbsent: () => 1);
      dailyWorks.putIfAbsent(event.watchedOn, () => {}).add(event.animeUuid);
      monthlyWorks.putIfAbsent(date.month, () => {}).add(event.animeUuid);
      events++;
    }
    final days = today.difference(start).inDays + 1;
    final buckets = range == ActivityRange.year
        ? [
            for (var month = 1; month <= now.month; month++)
              StatisticBucket(
                '$month月',
                monthly[month] ?? 0,
                periodLabel: '${now.year}年$month月',
                workCount: monthlyWorks[month]?.length ?? 0,
              ),
          ]
        : [
            for (var i = 0; i < days; i++)
              StatisticBucket(
                '${start.add(Duration(days: i)).month}/${start.add(Duration(days: i)).day}',
                daily[start
                        .add(Duration(days: i))
                        .toIso8601String()
                        .substring(0, 10)] ??
                    0,
                periodLabel: start
                    .add(Duration(days: i))
                    .toIso8601String()
                    .substring(0, 10),
                workCount:
                    dailyWorks[start
                            .add(Duration(days: i))
                            .toIso8601String()
                            .substring(0, 10)]
                        ?.length ??
                    0,
              ),
          ];
    return ActivityStatistics(buckets, events, daily.length, days);
  }
}

class LibraryStatistics {
  final List<AnimeRecord> records;
  late final int episodes = records.fold(0, (n, a) => n + a.progress);
  late final int rewatchRecords = records
      .where((a) => (a.rewatchCount ?? 0) >= 2)
      .length;
  late final int knownMinutes = records.fold(
    0,
    (n, a) => n + a.progress * (a.metadata.durationMinutes ?? 0),
  );
  late final int unknownDurationEpisodes = records
      .where((a) => a.metadata.durationMinutes == null)
      .fold(0, (n, a) => n + a.progress);
  late final List<double> scores = records
      .where((a) => a.score != null)
      .map((a) => a.score!)
      .toList();
  double? get averageScore =>
      scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
  int countStatus(AnimeStatus status) =>
      records.where((a) => a.status == status).length;

  LibraryStatistics(this.records);

  List<StatisticBucket> get scoreDistribution => [
    for (var score = 0; score <= 10; score++)
      StatisticBucket('$score', scores.where((v) => v.floor() == score).length),
  ];

  List<StatisticBucket> get allTags {
    final counts = <String, int>{};
    final reserved = RegExp(r'^([0-9]+|[一二两三四五六七八九十百零〇]+)刷$');
    for (final a in records) {
      for (final tag in a.tags.map((t) => t.trim()).toSet()) {
        if (tag.isEmpty || reserved.hasMatch(tag)) continue;
        counts.update(tag, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });
    return entries.map((e) => StatisticBucket(e.key, e.value)).toList();
  }

  List<StatisticBucket> get tags => allTags.take(8).toList();

  List<StatisticBucket> get premiereYears {
    final counts = <int, int>{};
    for (final a in records) {
      final date = _calendarDate(a.metadata.premiereDate ?? '');
      if (date == null) continue;
      counts.update(date.year, (n) => n + 1, ifAbsent: () => 1);
    }
    final years = counts.keys.toList()..sort();
    return years.map((y) => StatisticBucket('$y', counts[y]!)).toList();
  }

  int get unknownPremieres =>
      records.length - premiereYears.fold(0, (n, b) => n + b.count);

  List<StatisticBucket> get metadataCoverage => [
    StatisticBucket(
      '封面',
      records.where((a) => _present(a.metadata.coverUrl)).length,
    ),
    StatisticBucket(
      '简介',
      records.where((a) => _present(a.metadata.summary)).length,
    ),
    StatisticBucket(
      '总集数',
      records.where((a) => a.metadata.totalEpisodes != null).length,
    ),
    StatisticBucket(
      '单集时长',
      records.where((a) => a.metadata.durationMinutes != null).length,
    ),
    StatisticBucket('首播日期', records.length - unknownPremieres),
  ];
}

bool _present(String? value) => value != null && value.trim().isNotEmpty;

DateTime? _calendarDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final date = DateTime.tryParse('${value}T00:00:00Z');
  return date?.toIso8601String().substring(0, 10) == value ? date : null;
}
