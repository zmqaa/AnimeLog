import 'package:flutter/material.dart';

import '../../application/manual_library.dart';
import '../../application/backup_service.dart';
import '../../application/manga_intake.dart';
import '../../core/anime_log_core.dart';
import '../../core/api/library_repository.dart';
import '../../core/api/manga_repository.dart';
import '../../core/domain/library_statistics.dart';
import '../detail/detail_page.dart';
import '../intake/editor_controller.dart';
import '../intake/editor_page.dart';
import 'library_controller.dart';
import '../../application/ai_intake.dart';
import '../../core/api/ai_intake.dart';
import '../intake/intake_controller.dart';
import '../intake/intake_page.dart';
import '../settings/settings_page.dart';
import '../shared/app_theme.dart';
import '../shared/collection_card.dart';
import '../shared/collection_sidebar.dart';
import '../shared/page_state.dart';
import '../shared/appearance_controls.dart';
import '../shared/pagination.dart';
import '../overview/overview_page.dart';
import '../../application/metadata_completion.dart';
import '../manga/manga_page.dart';
import '../management/data_management_page.dart';
import '../timeline/timeline_page.dart';

class LibraryPage extends StatefulWidget {
  final ManualLibrary useCases;
  final IntakeDraftStore drafts;
  final BackupService? backups;
  final AiIntake? aiIntake;
  final CoverStore? covers;
  final MetadataCompletionService? metadataCompletion;
  final MangaRepository? mangaRepository;
  final MangaIntake? mangaIntake;
  const LibraryPage({
    super.key,
    required this.useCases,
    required this.drafts,
    this.backups,
    this.aiIntake,
    this.covers,
    this.metadataCompletion,
    this.mangaRepository,
    this.mangaIntake,
  });
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final c = LibraryController(widget.useCases.records);
  int destination = 0;
  final navigationHistory = <int>[];
  bool opening = false;
  CollectionView collectionView = CollectionView.posters;
  final search = TextEditingController();
  final libraryScroll = ScrollController();
  static const destinations = ['总览', '动漫库', '漫画库', '时间轴', '数据管理', '设置'];
  static const mobilePrimaryDestinations = [0, 1, 3];
  @override
  void dispose() {
    search.dispose();
    libraryScroll.dispose();
    c.dispose();
    super.dispose();
  }

  void _failure(Object error) => ScaffoldMessenger.of(context).showSnackBar(
    appSnackBar(context, error: true, content: Text('操作未完成：$error')),
  );

  void _navigateTo(int nextDestination) {
    if (nextDestination == destination) return;
    setState(() {
      navigationHistory.add(destination);
      destination = nextDestination;
    });
  }

  void _returnToPreviousDestination() {
    if (navigationHistory.isEmpty || !mounted) return;
    final previousDestination = navigationHistory.removeLast();
    setState(() => destination = previousDestination);
  }

  Future<void> _add() async {
    if (opening) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => opening = true);
    try {
      var restored = await widget.drafts.load();
      if (!mounted) return;
      if (restored != null) {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('发现未提交草稿'),
            content: const Text('可以继续填写，也可以丢弃后添加另一部作品。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'discard'),
                child: const Text('丢弃草稿'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'continue'),
                child: const Text('继续填写'),
              ),
            ],
          ),
        );
        if (choice == null) return;
        if (choice == 'discard') {
          await widget.drafts.clear();
          restored = null;
        }
      }
      if (!mounted) return;
      final recognize =
          widget.aiIntake != null &&
          (restored == null || restored['intakeMode'] == 'recognition');
      final uuid = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          allowSnapshotting: false,
          builder: (_) => recognize
              ? IntakePage(
                  controller: IntakeController(
                    widget.aiIntake!,
                    widget.drafts,
                    restored: restored,
                  ),
                  useCases: widget.useCases,
                  covers: widget.covers,
                )
              : EditorPage(
                  controller: EditorController(
                    useCases: widget.useCases,
                    store: widget.drafts,
                    restored: restored,
                  ),
                  covers: widget.covers,
                ),
        ),
      );
      if (uuid != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(appSnackBar(context, content: Text('记录已保存')));
      }
    } catch (error) {
      if (mounted) _failure(error);
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> _increment(String uuid) async {
    try {
      final receipt = await c.increment(uuid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        appSnackBar(
          context,
          duration: const Duration(seconds: 6),
          content: const Text('已看一集 · 已记录今天'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () async {
              try {
                await c.repository.undoIncrement(receipt);
              } catch (error) {
                if (mounted) _failure(error);
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (mounted) _failure(error);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => LayoutBuilder(
      builder: (context, size) {
        final wide = size.maxWidth >= 840;
        return PopScope<void>(
          canPop: wide || navigationHistory.isEmpty,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !wide) _returnToPreviousDestination();
          },
          child: Scaffold(
            appBar: wide
                ? null
                : AppBar(
                    titleSpacing: 8,
                    title: _mobilePrimaryTabs(),
                    actions: [_navigationMenu()],
                  ),
            body: SafeArea(
              child: Row(
                children: [
                  if (wide) _sidebar(),
                  Expanded(
                    child: IndexedStack(
                      index: destination,
                      children: [
                        OverviewPage(
                          records: c.records,
                          repository: c.repository,
                          covers: widget.covers,
                          loading: c.loading,
                          error: c.error,
                          onRetry: c.retry,
                          onAdd: _add,
                          onOpen: _openRecord,
                          onLibrary: (status) {
                            search.clear();
                            c.search('');
                            c.selectStatus(status);
                            _navigateTo(1);
                          },
                        ),
                        _library(),
                        widget.mangaRepository == null
                            ? const _MangaUnavailable()
                            : MangaPage(
                                repository: widget.mangaRepository!,
                                covers: widget.covers,
                                intake: widget.mangaIntake,
                              ),
                        TimelinePage(
                          records: c.records,
                          repository: c.repository,
                          covers: widget.covers,
                          loading: c.loading,
                          error: c.error,
                          onRetry: c.retry,
                          onOpen: _openRecord,
                        ),
                        DataManagementPage(
                          useCases: widget.useCases,
                          onLibrary: () => _navigateTo(1),
                          covers: widget.covers,
                          metadataCompletion: widget.metadataCompletion,
                        ),
                        SettingsPage(
                          animeCount: c.records.length,
                          ai: widget.aiIntake?.settings,
                          backups: widget.backups,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _mobilePrimaryTabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final index in mobilePrimaryDestinations)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Semantics(
              button: true,
              selected: destination == index,
              label: destinations[index],
              child: InkWell(
                key: Key('mobile-primary-tab-$index'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => _navigateTo(index),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: destination == index
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    destinations[index],
                    style: TextStyle(
                      color: destination == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: destination == index
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _navigationMenu() => PopupMenuButton<int>(
    key: const Key('page-navigation-menu'),
    tooltip: '切换页面',
    icon: const Icon(Icons.menu_rounded),
    position: PopupMenuPosition.under,
    constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
    onSelected: _navigateTo,
    itemBuilder: (context) {
      final colors = Theme.of(context).colorScheme;
      return [
        for (final item in destinations.indexed) ...[
          if (item.$1 == 4) const PopupMenuDivider(),
          PopupMenuItem<int>(
            value: item.$1,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              selected: destination == item.$1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: destination == item.$1
                      ? colors.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: destination == item.$1
                        ? colors.primary
                        : colors.onSurface,
                    fontWeight: destination == item.$1
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ];
    },
  );

  Widget _sidebar() => Container(
    width: 224,
    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, size) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'AnimeLog',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 36),
                  for (final item in destinations.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          mouseCursor: WidgetStateMouseCursor.clickable,
                          selected: destination == item.$1,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          hoverColor: Theme.of(context).colorScheme.primary
                              .withValues(alpha: .08),
                          focusColor: Theme.of(context).colorScheme.primary
                              .withValues(alpha: .16),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: destination == item.$1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          onTap: () => _navigateTo(item.$1),
                        ),
                      ),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 48, 8, 0),
                child: AppearanceControls(),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _selectLibraryPage(int page) {
    c.selectPage(page);
    if (libraryScroll.hasClients) libraryScroll.jumpTo(0);
  }

  Future<void> _decrement(AnimeRecord record) async {
    if (c.busy.contains(record.uuid)) return;
    try {
      await c.decrement(record.uuid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        appSnackBar(
          context,
          content: const Text('进度 −1 · 已清理高于新进度的历史'),
          action: SnackBarAction(
            label: '管理历史',
            onPressed: () => _openRecord(record),
          ),
        ),
      );
    } catch (error) {
      if (mounted) _failure(error);
    }
  }

  Widget _progressActions(AnimeRecord record, bool canAdd) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      Tooltip(
        message: '进度减一',
        child: TextButton(
          key: Key('decrement-${record.uuid}'),
          onPressed: record.progress > 0 && !c.busy.contains(record.uuid)
              ? () => _decrement(record)
              : null,
          style: TextButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.all(8),
          ),
          child: const Text('−1'),
        ),
      ),
      Tooltip(
        message: '进度加一',
        child: TextButton(
          key: Key('increment-${record.uuid}'),
          onPressed: canAdd ? () => _increment(record.uuid) : null,
          style: TextButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.all(8),
          ),
          child: const Text('+1'),
        ),
      ),
    ],
  );

  Widget _posterProgressActions(AnimeRecord record, bool canAdd) {
    final total = record.metadata.totalEpisodes;
    final finished = total != null && record.progress >= total;
    final colors = Theme.of(context).colorScheme;
    final busy = c.busy.contains(record.uuid);
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(fontWeight: FontWeight.w700, fontSize: 11);
    final height = collectionActionHeight(context);
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: '进度减一',
            child: OutlinedButton(
              key: Key('decrement-${record.uuid}'),
              onPressed: record.progress > 0 && !busy
                  ? () => _decrement(record)
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, height),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                textStyle: style,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('−1'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton(
            key: Key('increment-${record.uuid}'),
            onPressed: canAdd ? () => _increment(record.uuid) : null,
            style: FilledButton.styleFrom(
              minimumSize: Size(0, height),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              textStyle: style,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              disabledBackgroundColor: colors.primary.withValues(alpha: .12),
              disabledForegroundColor: colors.primary.withValues(alpha: .7),
            ),
            child: Text(
              busy
                  ? '保存中…'
                  : finished
                  ? '已看完'
                  : '+ 看一集',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _librarySidebar() {
    final stats = LibraryStatistics(c.records);
    final knownHours = (stats.knownMinutes / 60).toStringAsFixed(1);
    return CollectionSidebar(
      key: const Key('anime-library-sidebar'),
      primaryStats: [
        CollectionSidebarStat('收藏记录', '${c.records.length}', '条'),
        CollectionSidebarStat(
          '已经看完',
          '${stats.countStatus(AnimeStatus.completed)}',
          '条',
        ),
      ],
      details: [
        CollectionSidebarStat(
          '在看',
          '${stats.countStatus(AnimeStatus.watching)}',
          '条',
        ),
        CollectionSidebarStat(
          '想看',
          '${stats.countStatus(AnimeStatus.planToWatch)}',
          '条',
        ),
        CollectionSidebarStat(
          '弃番',
          '${stats.countStatus(AnimeStatus.dropped)}',
          '条',
        ),
        CollectionSidebarStat('累计进度', '${stats.episodes}', '集'),
        CollectionSidebarStat('重刷记录', '${stats.rewatchRecords}', '条'),
        CollectionSidebarStat('已知时长', knownHours, '小时'),
      ],
      tags: [
        for (final tag in stats.allTags)
          CollectionSidebarTag(tag.label, tag.count),
      ],
      people: [
        for (final person in buildCollectionTagStats(
          c.records.map((record) => record.metadata.cast),
        ).take(10))
          CollectionSidebarTag(person.label, person.count),
      ],
      selectedTag: c.tagFilter,
      onTagSelected: c.selectTag,
      selectedPerson: c.castFilter,
      onPersonSelected: c.selectCast,
    );
  }

  Widget _library() => LayoutBuilder(
    builder: (context, size) {
      final narrow = size.maxWidth < 600;
      final showSidebar =
          size.maxWidth >= 1180 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.4;
      final inset = narrow ? 20.0 : 32.0;
      final visible = c.visible;
      final pageRecords = visible
          .skip(c.page * collectionPageSize)
          .take(collectionPageSize)
          .toList();
      final content = CustomScrollView(
        primary: false,
        key: const Key('library-scroll'),
        controller: libraryScroll,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(inset, 20, inset, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeading(
                    compact: true,
                    title: '我的动漫库',
                    subtitle:
                        '已收藏 ${c.records.length} 条记录 · 在看 ${c.records.where((a) => a.status == AnimeStatus.watching).length} 条',
                    action: FilledButton(
                      key: const Key('add-anime'),
                      onPressed: opening ? null : _add,
                      child: const Text('添加动漫'),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: CollectionFilters(
                      search: TextField(
                        key: const Key('library-search'),
                        controller: search,
                        decoration: InputDecoration(
                          hintText: '搜索标题、原名、声优或标签',
                          suffixIcon: c.query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: '清空搜索',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    search.clear();
                                    c.search('');
                                  },
                                ),
                        ),
                        onChanged: c.search,
                        onSubmitted: c.search,
                        textInputAction: TextInputAction.search,
                      ),
                      filters: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            mouseCursor: WidgetStateMouseCursor.clickable,
                            label: Text('全部 ${c.records.length}'),
                            selected: c.filter == null,
                            onSelected: (_) => c.selectStatus(null),
                          ),
                          for (final status in AnimeStatus.values)
                            ChoiceChip(
                              mouseCursor: WidgetStateMouseCursor.clickable,
                              label: Text(
                                '${statusLabel(status)} ${c.records.where((a) => a.status == status).length}',
                              ),
                              selected: c.filter == status,
                              onSelected: (_) => c.selectStatus(status),
                            ),
                          if (c.tagFilter != null)
                            FilterChip(
                              mouseCursor: WidgetStateMouseCursor.clickable,
                              label: Text('#${c.tagFilter}'),
                              selected: true,
                              showCheckmark: false,
                              onSelected: (_) => c.selectTag(null),
                            ),
                          if (c.castFilter != null)
                            FilterChip(
                              mouseCursor: WidgetStateMouseCursor.clickable,
                              label: Text('声优：${c.castFilter}'),
                              selected: true,
                              showCheckmark: false,
                              onSelected: (_) => c.selectCast(null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        c.query.isEmpty &&
                                c.filter == null &&
                                c.tagFilter == null &&
                                c.castFilter == null
                            ? '全部作品'
                            : '找到 ${visible.length} 部作品',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      PopupMenuButton<LibrarySort>(
                        tooltip: '选择排序方式',
                        initialValue: c.sort,
                        onSelected: c.selectSort,
                        itemBuilder: (_) => [
                          for (final sort in LibrarySort.values)
                            CheckedPopupMenuItem(
                              value: sort,
                              checked: c.sort == sort,
                              child: Text(sortLabel(sort)),
                            ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(sortLabel(c.sort)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      CollectionViewPicker(
                        key: const Key('library-view'),
                        selected: collectionView,
                        onChanged: (value) =>
                            setState(() => collectionView = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (c.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: PageStatePanel(
                title: '正在读取收藏',
                message: '你的本机记录即将显示。',
                loading: true,
              ),
            )
          else if (c.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: PageStatePanel(
                title: '暂时无法读取收藏',
                message: '可以重试读取本机记录。',
                details: c.error.toString(),
                error: true,
                action: FilledButton(
                  onPressed: c.retry,
                  child: const Text('重试'),
                ),
              ),
            )
          else if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: PageStatePanel(
                title: c.records.isEmpty ? '故事，从第一部开始' : '没有符合条件的记录',
                message: c.records.isEmpty
                    ? '点击右上角的添加按钮，留下你的观看记录。'
                    : '试试其他关键词或观看状态。',
                action: c.records.isEmpty
                    ? FilledButton(
                        onPressed: opening ? null : _add,
                        child: const Text('添加第一部动漫'),
                      )
                    : OutlinedButton(
                        onPressed: () {
                          search.clear();
                          c.resetFilters();
                        },
                        child: const Text('清除搜索与筛选'),
                      ),
              ),
            )
          else if (collectionView == CollectionView.list)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 0, inset, 16),
              sliver: SliverList.builder(
                itemCount: pageRecords.length,
                itemBuilder: (context, index) =>
                    _listRecordCard(pageRecords[index]),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 0, inset, 16),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = collectionColumns(
                    context,
                    constraints.crossAxisExtent,
                  );
                  final cardHeight = collectionCardHeight(
                    context,
                    constraints,
                    columns,
                  );
                  // Rows size themselves for long titles and large system text.
                  return SliverList.builder(
                    itemCount: (pageRecords.length / columns).ceil(),
                    itemBuilder: (context, row) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var column = 0; column < columns; column++) ...[
                          if (column > 0)
                            const SizedBox(width: collectionCardSpacing),
                          Expanded(
                            child: row * columns + column < pageRecords.length
                                ? _recordCard(
                                    pageRecords[row * columns + column],
                                    height: cardHeight,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          if (!c.loading && c.error == null && visible.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 0, inset, 16),
              sliver: SliverToBoxAdapter(
                child: PaginationControls(
                  total: visible.length,
                  page: c.page,
                  onChanged: _selectLibraryPage,
                  alignEnd: true,
                ),
              ),
            ),
        ],
      );
      final noScrollbars = ScrollConfiguration.of(context)
          .copyWith(scrollbars: false);
      if (!showSidebar) {
        return ScrollConfiguration(behavior: noScrollbars, child: content);
      }
      return ScrollConfiguration(
        behavior: noScrollbars,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            const SizedBox(width: 20),
            SizedBox(
              width: 340,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 28, 32, 24),
                child: _librarySidebar(),
              ),
            ),
          ],
        ),
      );
    },
  );

  void _openRecord(AnimeRecord a) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.push(
      context,
      MaterialPageRoute(
        allowSnapshotting: false,
        builder: (_) => DetailPage(
          uuid: a.uuid,
          useCases: widget.useCases,
          covers: widget.covers,
          metadataCompletion: widget.metadataCompletion,
        ),
      ),
    );
  }

  Widget _recordCard(AnimeRecord a, {double? height}) {
    final total = a.metadata.totalEpisodes;
    final canAdd =
        (total == null || a.progress < total) && !c.busy.contains(a.uuid);
    return CollectionCard(
      key: ValueKey(a.uuid),
      tapKey: Key('anime-${a.uuid}'),
      height: height,
      title: a.metadata.title,
      subtitle: a.metadata.originalTitle,
      summary: a.metadata.summary,
      coverUrl: a.metadata.coverUrl,
      covers: widget.covers,
      status: statusLabel(a.status),
      publicationLabel: a.metadata.isFinished == null
          ? null
          : a.metadata.isFinished!
          ? '已完结'
          : '未完结',
      onTap: () => _openRecord(a),
      progress: CollectionProgress(
        label: '剧集进度',
        value: '${a.progress} / ${total ?? '?'} 集',
        fraction: total != null && total > 0 ? a.progress / total : null,
      ),
      actions: _posterProgressActions(a, canAdd),
    );
  }

  Widget _listRecordCard(AnimeRecord a) {
    final total = a.metadata.totalEpisodes;
    final canAdd =
        (total == null || a.progress < total) && !c.busy.contains(a.uuid);
    final metadata = [
      if (a.metadata.entryType != null)
        a.metadata.entryType!.name.toUpperCase(),
      if (a.metadata.season != null) '第 ${a.metadata.season} 季',
      ...a.tags.map((tag) => '#$tag'),
    ].join(' · ');
    return CollectionListCard(
      key: ValueKey(a.uuid),
      tapKey: Key('anime-${a.uuid}'),
      title: a.metadata.title,
      subtitle: metadata.isEmpty ? a.metadata.originalTitle : metadata,
      coverUrl: a.metadata.coverUrl,
      covers: widget.covers,
      onTap: () => _openRecord(a),
      badges: [RecordBadge(label: statusLabel(a.status))],
      footer: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${a.progress} / ${total ?? '?'} 集',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Semantics(
                  label: '观看进度',
                  value: '${a.progress} / ${total ?? '未知'} 集',
                  child: LinearProgressIndicator(
                    value: total != null && total > 0
                        ? (a.progress / total).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _progressActions(a, canAdd),
        ],
      ),
    );
  }
}

class _MangaUnavailable extends StatelessWidget {
  const _MangaUnavailable();

  @override
  Widget build(BuildContext context) => const Center(child: Text('漫画模块未连接'));
}
