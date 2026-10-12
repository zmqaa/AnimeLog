import 'package:animelog/core/domain/library_statistics.dart';
import 'package:animelog/core/domain/quick_record_models.dart';
import 'package:flutter_test/flutter_test.dart';

AnimeRecord record(
  String uuid, {
  int progress = 0,
  int? duration,
  double? score,
  int? rewatch,
  List<String> tags = const [],
  String? premiere,
}) => AnimeRecord(
  id: 1,
  uuid: uuid,
  metadata: AnimeMetadata(
    title: '同名作品',
    durationMinutes: duration,
    premiereDate: premiere,
  ),
  status: AnimeStatus.watching,
  progress: progress,
  score: score,
  rewatchCount: rewatch,
  tags: tags,
  createdAt: '2026-10-10T00:00:00Z',
  updatedAt: '2026-10-10T00:00:00Z',
);

WatchHistoryRecord event(int id, String date, {String animeUuid = 'a'}) =>
    WatchHistoryRecord(
      id: id,
      uuid: 'history-$id',
      animeUuid: animeUuid,
      episode: 1,
      watchedOn: date,
      // Import/edit timestamps must never move the selected calendar date.
      watchedAt: '2026-12-31T23:59:59Z',
      createdAt: '2026-12-31T23:59:59Z',
    );

void main() {
  test('same-title and rewatch records retain independent progress; missing duration is excluded', () {
    final stats = LibraryStatistics([
      record('a', progress: 10, duration: 20, score: 0),
      record('b', progress: 5, rewatch: 2, score: 10),
      record('c', progress: 3),
    ]);
    expect(stats.episodes, 18);
    expect(stats.rewatchRecords, 1);
    expect(stats.knownMinutes, 200);
    expect(stats.unknownDurationEpisodes, 8);
    expect(stats.averageScore, 5);
    expect(stats.scoreDistribution.first.count, 1);
    expect(stats.scoreDistribution.last.count, 1);
  });

  test('tags count once per record and derived rewatch labels are omitted', () {
    final stats = LibraryStatistics([
      record('a', tags: [' 日常 ', '日常', '二刷', '2刷']),
      record('b', tags: ['日常', '冒险']),
    ]);
    expect(stats.tags.map((b) => (b.label, b.count)).toList(), [
      ('日常', 2),
      ('冒险', 1),
    ]);
  });

  test('week includes today and six preceding dates, excludes future and invalid dates', () {
    final stats = ActivityStatistics.fromHistory(
      [
        event(1, '2026-10-03'),
        event(2, '2026-10-04'),
        event(3, '2026-10-10'),
        event(4, '2026-10-10'),
        event(5, '2026-10-11'),
        event(6, '2026-02-30'),
      ],
      ActivityRange.week,
      DateTime(2026, 10, 10, 23, 59),
    );
    expect(stats.days, 7);
    expect(stats.events, 3);
    expect(stats.activeDays, 2);
    expect(stats.buckets.first.label, '10/4');
    expect(stats.buckets.first.count, 1);
    expect(stats.buckets.last.count, 2);
  });

  test('rolling month crosses year boundaries without inventing history', () {
    final stats = ActivityStatistics.fromHistory(
      [event(1, '2025-12-11'), event(2, '2025-12-12'), event(3, '2026-01-10')],
      ActivityRange.month,
      DateTime(2026, 1, 10),
    );
    expect(stats.days, 30);
    expect(stats.events, 2);
    expect(stats.buckets.first.label, '12/12');
    expect(stats.buckets.last.label, '1/10');
    expect(
      ActivityStatistics.fromHistory(
        [],
        ActivityRange.week,
        DateTime(2026, 1, 10),
      ).events,
      0,
    );
  });

  test(
    'current year includes leap day, groups by month and stops at today',
    () {
      final stats = ActivityStatistics.fromHistory(
        [
          event(1, '2023-12-31'),
          event(2, '2024-02-29'),
          event(3, '2024-03-01'),
          event(4, '2024-03-02'),
        ],
        ActivityRange.year,
        DateTime(2024, 3, 1),
      );
      expect(stats.days, 61);
      expect(stats.events, 2);
      expect(stats.buckets.map((b) => b.count).toList(), [0, 1, 1]);
    },
  );

  test(
    'daily trend tooltips keep full calendar dates and count each work once',
    () {
      final stats = ActivityStatistics.fromHistory(
        [
          event(1, '2025-12-31'),
          event(2, '2025-12-31'),
          event(3, '2025-12-31', animeUuid: 'b'),
          event(4, '2026-01-01'),
          event(5, '2026-01-02', animeUuid: 'c'),
        ],
        ActivityRange.week,
        DateTime(2026, 1, 1),
      );
      final previousDay = stats.buckets[stats.buckets.length - 2];
      expect(previousDay.periodLabel, '2025-12-31');
      expect(previousDay.count, 3);
      expect(previousDay.workCount, 2);
      expect(stats.buckets.last.periodLabel, '2026-01-01');
      expect(stats.buckets.last.workCount, 1);
      expect(stats.buckets.first.workCount, 0);
      expect(stats.events, 4);
    },
  );

  test('monthly tooltip work counts deduplicate across days and exclude future dates', () {
    final stats = ActivityStatistics.fromHistory(
      [
        event(1, '2026-03-01'),
        event(2, '2026-03-02'),
        event(3, '2026-03-02', animeUuid: 'b'),
        event(4, '2026-03-03', animeUuid: 'c'),
      ],
      ActivityRange.year,
      DateTime(2026, 3, 2),
    );
    expect(stats.buckets.last.periodLabel, '2026年3月');
    expect(stats.buckets.last.count, 3);
    expect(stats.buckets.last.workCount, 2);
    expect(stats.buckets.first.workCount, 0);
  });

  test(
    'unknown or invalid premiere dates remain outside year distributions',
    () {
      final stats = LibraryStatistics([
        record('a', premiere: '2020-02-29'),
        record('b', premiere: '2021-02-29'),
        record('c'),
      ]);
      expect(stats.premiereYears.single.label, '2020');
      expect(stats.premiereYears.single.count, 1);
      expect(stats.unknownPremieres, 2);
      expect(stats.averageScore, isNull);
    },
  );
}
