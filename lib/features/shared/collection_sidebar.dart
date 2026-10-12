import 'package:flutter/material.dart';

class CollectionSidebarStat {
  final String label;
  final String value;
  final String unit;

  const CollectionSidebarStat(this.label, this.value, [this.unit = '']);
}

class CollectionSidebarTag {
  final String label;
  final int count;

  const CollectionSidebarTag(this.label, this.count);
}

bool isCollectionSidebarTagVisible(String label) {
  final normalized = label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceFirst(RegExp(r'^#'), '');
  const metadataTags = {
    '漫画改',
    '漫改',
    '漫画改编',
    'tv',
    'tv动画',
    '电视动画',
    'ova',
    'ona',
    'oad',
    'web',
    'movie',
    'special',
    '剧场版',
    '剧场版动画',
    '电影',
    '网络动画',
    '特别篇',
  };
  if (metadataTags.contains(normalized)) return false;
  return !RegExp(
    r'^(?:19|20)\d{2}(?:年)?(?:[./-]?(?:0?[1-9]|1[0-2])月?|[春夏秋冬](?:季|番)?|第?[一二三四1-4]季度)?(?:动画|动漫|漫画|番|新番)?$',
  ).hasMatch(normalized);
}

List<CollectionSidebarTag> buildCollectionTagStats(
  Iterable<Iterable<String>> tagGroups,
) {
  final counts = <String, int>{};
  for (final group in tagGroups) {
    for (final raw in group) {
      final tag = raw.trim();
      if (tag.isEmpty) continue;
      counts.update(tag, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount == 0 ? a.key.compareTo(b.key) : byCount;
    });
  return [
    for (final entry in entries) CollectionSidebarTag(entry.key, entry.value),
  ];
}

class CollectionSidebar extends StatelessWidget {
  final List<CollectionSidebarStat> primaryStats;
  final List<CollectionSidebarStat> details;
  final List<CollectionSidebarTag> tags;
  final List<CollectionSidebarTag> people;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;
  final String? selectedPerson;
  final ValueChanged<String?>? onPersonSelected;
  final String peopleTitle;

  const CollectionSidebar({
    super.key,
    required this.primaryStats,
    required this.details,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
    this.people = const [],
    this.selectedPerson,
    this.onPersonSelected,
    this.peopleTitle = '声优统计',
  });

  @override
  Widget build(BuildContext context) {
    final visibleTags = tags
        .where((tag) => isCollectionSidebarTagVisible(tag.label))
        .take(20)
        .toList();
    return Column(
      children: [
        _panel(
          context,
          title: '库统计',
          icon: Icons.dashboard_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (primaryStats.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < primaryStats.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: _primaryStat(context, primaryStats[i])),
                    ],
                  ],
                ),
              if (primaryStats.isNotEmpty && details.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 4),
              ],
              for (final stat in details) _detailStat(context, stat),
            ],
          ),
        ),
        _panel(
          context,
          title: '标签统计',
          icon: Icons.sell_outlined,
          child: visibleTags.isEmpty
              ? Text('暂无类型标签', style: Theme.of(context).textTheme.bodySmall)
              : _filterChips(context, visibleTags, selectedTag, onTagSelected),
        ),
        if (people.isNotEmpty && onPersonSelected != null)
          _panel(
            context,
            title: peopleTitle,
            icon: Icons.record_voice_over_outlined,
            child: _filterChips(
              context,
              people,
              selectedPerson,
              onPersonSelected!,
            ),
          ),
      ],
    );
  }

  Widget _filterChips(
    BuildContext context,
    List<CollectionSidebarTag> values,
    String? selected,
    ValueChanged<String?> onSelected,
  ) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final value in values)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: FilterChip(
            mouseCursor: WidgetStateMouseCursor.clickable,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            labelStyle: Theme.of(context).textTheme.bodySmall,
            label: Text('${value.label} ${value.count}'),
            selected: selected == value.label,
            showCheckmark: false,
            onSelected: (_) =>
                onSelected(selected == value.label ? null : value.label),
          ),
        ),
    ],
  );

  Widget _panel(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  icon,
                  color: colors.onSurfaceVariant.withValues(alpha: .32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _primaryStat(BuildContext context, CollectionSidebarStat stat) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat.label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (stat.unit.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(stat.unit, style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailStat(BuildContext context, CollectionSidebarStat stat) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                stat.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              stat.value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (stat.unit.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(stat.unit, style: Theme.of(context).textTheme.labelSmall),
            ],
          ],
        ),
      );
}
