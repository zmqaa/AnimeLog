import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/manga_intake.dart';
import '../../core/api/ai_intake.dart';
import '../../core/api/manga_repository.dart';
import '../../core/anime_log_core.dart';
import '../shared/app_theme.dart';
import '../shared/collection_card.dart';
import '../shared/collection_sidebar.dart';
import '../shared/page_state.dart';
import '../shared/pagination.dart';
import '../shared/date_input.dart';
import '../shared/form_controls.dart';
import 'manga_detail_page.dart';
import 'manga_intake_page.dart';

class MangaPage extends StatefulWidget {
  final MangaRepository repository;
  final CoverStore? covers;
  final MangaIntake? intake;

  const MangaPage({
    super.key,
    required this.repository,
    this.covers,
    this.intake,
  });

  @override
  State<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  StreamSubscription<List<MangaRecord>>? subscription;
  List<MangaRecord> records = [];
  String query = '';
  MangaReadingStatus? filter;
  String? tagFilter;
  bool loading = true;
  CollectionView collectionView = CollectionView.posters;
  Object? error;
  final search = TextEditingController();
  final scroll = ScrollController();
  int page = 0;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    subscription = widget.repository.watchAll().listen(
      (value) {
        if (!mounted) return;
        setState(() {
          records = value;
          page = boundedPage(page, visible.length, collectionPageSize);
          loading = false;
          error = null;
        });
      },
      onError: (Object failure) {
        if (!mounted) return;
        setState(() {
          loading = false;
          error = failure;
        });
      },
    );
  }

  Future<void> _retry() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await subscription?.cancel();
      if (mounted) _listen();
    } catch (failure) {
      if (mounted) {
        setState(() {
          loading = false;
          error = failure;
        });
      }
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  List<MangaRecord> get visible {
    final needle = query.trim().toLowerCase();
    final result = records
        .where(
          (m) =>
              (filter == null || m.status == filter) &&
              (tagFilter == null ||
                  m.tags.any((tag) => tag.trim() == tagFilter)) &&
              ('${m.title} ${m.originalTitle ?? ''} ${m.aliases.join(' ')} '
                      '${m.tags.join(' ')} ${m.authors.join(' ')}')
                  .toLowerCase()
                  .contains(needle),
        )
        .toList();
    result.sort((a, b) {
      final order = b.updatedAt.compareTo(a.updatedAt);
      return order == 0 ? a.title.compareTo(b.title) : order;
    });
    return result;
  }

  Future<void> _edit([MangaRecord? record]) async {
    MangaDraft? initial;
    if (record == null && widget.intake != null) {
      initial = await showFormPanel<MangaDraft>(
        context: context,
        builder: (_) =>
            MangaLookupPanel(intake: widget.intake!, covers: widget.covers),
      );
      if (initial == null || !mounted) return;
    }
    final draft = await showFormPanel<MangaDraft>(
      context: context,
      builder: (_) => MangaEditorDialog(record: record, initial: initial),
    );
    if (draft == null || !mounted) return;
    try {
      if (record == null) {
        await widget.repository.create(draft);
      } else {
        await widget.repository.edit(record.uuid, draft);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          appSnackBar(
            context,
            content: Text(record == null ? '漫画已添加' : '漫画已保存'),
          ),
        );
      }
    } catch (failure) {
      if (mounted) _failure(failure);
    }
  }

  Future<void> _delete(MangaRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除漫画记录？'),
        content: Text('“${record.title}”的本地记录会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.delete(record.uuid);
    } catch (failure) {
      if (mounted) _failure(failure);
    }
  }

  void _failure(Object failure) => ScaffoldMessenger.of(context).showSnackBar(
    appSnackBar(context, error: true, content: Text('操作未完成：$failure')),
  );

  void _selectTag(String? value) {
    setState(() {
      tagFilter = value;
      page = 0;
    });
  }

  Widget _librarySidebar() {
    int count(MangaReadingStatus status) =>
        records.where((manga) => manga.status == status).length;
    final withProgress = records
        .where(
          (manga) =>
              manga.currentVolume != null || manga.currentChapter != null,
        )
        .length;
    final ongoing = records
        .where(
          (manga) => manga.publicationStatus == MangaPublicationStatus.ongoing,
        )
        .length;
    return CollectionSidebar(
      key: const Key('manga-library-sidebar'),
      primaryStats: [
        CollectionSidebarStat('收藏记录', '${records.length}', '条'),
        CollectionSidebarStat(
          '已经读完',
          '${count(MangaReadingStatus.completed)}',
          '条',
        ),
      ],
      details: [
        CollectionSidebarStat(
          '阅读中',
          '${count(MangaReadingStatus.reading)}',
          '条',
        ),
        CollectionSidebarStat(
          '已追到最新',
          '${count(MangaReadingStatus.caughtUp)}',
          '条',
        ),
        CollectionSidebarStat(
          '想读',
          '${count(MangaReadingStatus.planToRead)}',
          '条',
        ),
        CollectionSidebarStat('有阅读进度', '$withProgress', '条'),
        CollectionSidebarStat('连载中', '$ongoing', '部'),
      ],
      tags: buildCollectionTagStats(records.map((manga) => manga.tags)),
      selectedTag: tagFilter,
      onTagSelected: _selectTag,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, size) {
        final inset = size.maxWidth < 600 ? 20.0 : 32.0;
        final showSidebar =
            size.maxWidth >= 1180 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.4;
        final results = visible;
        final pageRecords = results
            .skip(page * collectionPageSize)
            .take(collectionPageSize)
            .toList();
        final content = CustomScrollView(
          primary: false,
          controller: scroll,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 20, inset, 0),
              sliver: SliverToBoxAdapter(
                child: PageHeading(
                  compact: true,
                  title: '我的漫画库',
                  subtitle: '已收藏 ${records.length} 条记录 · 把阅读留在日常里。',
                  action: FilledButton(
                    onPressed: () => _edit(),
                    child: const Text('添加漫画'),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              sliver: SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                      controller: search,
                      onChanged: (value) => setState(() {
                        query = value;
                        page = 0;
                      }),
                      decoration: InputDecoration(
                        hintText: '搜索标题、别名、标签或作者',
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: '清空搜索',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  search.clear();
                                  setState(() {
                                    query = '';
                                    page = 0;
                                  });
                                },
                              ),
                      ),
                    ),
                    filters: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            mouseCursor: WidgetStateMouseCursor.clickable,
                            label: Text('全部 ${records.length}'),
                            selected: filter == null,
                            onSelected: (_) => setState(() {
                              filter = null;
                              page = 0;
                            }),
                          ),
                          for (final status in MangaReadingStatus.values)
                            ChoiceChip(
                              mouseCursor: WidgetStateMouseCursor.clickable,
                              label: Text(
                                '${status.label} ${records.where((m) => m.status == status).length}',
                              ),
                              selected: filter == status,
                              onSelected: (_) => setState(() {
                                filter = status;
                                page = 0;
                              }),
                            ),
                          if (tagFilter != null)
                            FilterChip(
                              mouseCursor: WidgetStateMouseCursor.clickable,
                              label: Text('#$tagFilter'),
                              selected: true,
                              showCheckmark: false,
                              onSelected: (_) => _selectTag(null),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 0, inset, 8),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      query.isEmpty && filter == null && tagFilter == null
                          ? '全部漫画'
                          : '找到 ${visible.length} 条记录',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    CollectionViewPicker(
                      key: const Key('manga-view'),
                      selected: collectionView,
                      onChanged: (value) =>
                          setState(() => collectionView = value),
                    ),
                  ],
                ),
              ),
            ),
            if (loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: PageStatePanel(
                  title: '正在读取漫画收藏',
                  message: '你的本机记录即将显示。',
                  loading: true,
                ),
              )
            else if (error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: PageStatePanel(
                  title: '暂时无法读取漫画',
                  message: '可以重试读取本机记录。',
                  details: error.toString(),
                  error: true,
                  action: FilledButton(
                    onPressed: _retry,
                    child: const Text('重试'),
                  ),
                ),
              )
            else if (visible.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _emptyState())
            else if (collectionView == CollectionView.list)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset, 0, inset, 16),
                sliver: SliverList.builder(
                  itemCount: pageRecords.length,
                  itemBuilder: (context, index) =>
                      _listCard(pageRecords[index]),
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
                                  ? _card(
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
            if (!loading && error == null && results.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset, 0, inset, 16),
                sliver: SliverToBoxAdapter(
                  child: PaginationControls(
                    total: results.length,
                    page: page,
                    onChanged: _changePage,
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
    ),
  );

  void _changePage(int value) {
    setState(
      () => page = boundedPage(value, visible.length, collectionPageSize),
    );
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Widget _emptyState() => PageStatePanel(
    title: records.isEmpty ? '还没有漫画记录' : '没有符合条件的漫画',
    message: records.isEmpty ? '可以从备份导入，也可以直接添加一条。' : '试试其他关键词或阅读状态。',
    action: records.isEmpty
        ? FilledButton(onPressed: () => _edit(), child: const Text('添加第一部漫画'))
        : OutlinedButton(
            onPressed: () {
              search.clear();
              setState(() {
                query = '';
                filter = null;
                tagFilter = null;
                page = 0;
              });
            },
            child: const Text('清除搜索与筛选'),
          ),
  );

  Widget _card(MangaRecord manga, {double? height}) {
    final progress = _progress(manga);
    final useChapters =
        manga.currentChapter != null &&
        manga.totalChapters != null &&
        manga.totalChapters! > 0;
    final current = useChapters ? manga.currentChapter : manga.currentVolume;
    final total = useChapters ? manga.totalChapters : manga.totalVolumes;
    final actionHeight = collectionActionHeight(context);
    return CollectionCard(
      key: ValueKey(manga.uuid),
      height: height,
      title: manga.title,
      subtitle:
          manga.originalTitle ??
          (manga.authors.isEmpty ? null : manga.authors.join('、')),
      summary: manga.summary,
      coverUrl: manga.coverUrl,
      covers: widget.covers,
      status: manga.status.label,
      publicationLabel:
          manga.publicationStatus == MangaPublicationStatus.unknown
          ? null
          : manga.publicationStatus.label,
      onTap: () => _openDetails(manga),
      progress: CollectionProgress(
        label: '阅读进度',
        value: progress.isEmpty ? '尚未记录' : progress,
        fraction: current != null && total != null && total > 0
            ? current / total
            : null,
      ),
      actions: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _edit(manga),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, actionHeight),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                textStyle: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('编辑记录'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: actionHeight,
            height: actionHeight,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              tooltip: '漫画操作',
              onSelected: (value) {
                if (value == 'edit') _edit(manga);
                if (value == 'delete') _delete(manga);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listCard(MangaRecord manga) => CollectionListCard(
    key: ValueKey(manga.uuid),
    title: manga.title,
    subtitle: manga.authors.isEmpty
        ? manga.originalTitle
        : manga.authors.join('、'),
    coverUrl: manga.coverUrl,
    covers: widget.covers,
    onTap: () => _openDetails(manga),
    badges: [RecordBadge(label: manga.status.label)],
    footer: Row(
      children: [
        Expanded(
          child: Text(
            _progress(manga).isEmpty ? '尚未记录阅读进度' : _progress(manga),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: '漫画操作',
          onSelected: (value) {
            if (value == 'edit') _edit(manga);
            if (value == 'delete') _delete(manga);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('编辑')),
            PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ],
    ),
  );

  String _progress(MangaRecord manga) {
    final volume = manga.currentVolume == null && manga.totalVolumes == null
        ? null
        : '卷 ${manga.currentVolume ?? '?'} / ${manga.totalVolumes ?? '?'}';
    final chapter = manga.currentChapter == null && manga.totalChapters == null
        ? null
        : '话 ${manga.currentChapter ?? '?'} / ${manga.totalChapters ?? '?'}';
    return [?volume, ?chapter].join(' · ');
  }

  Future<void> _openDetails(MangaRecord manga) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        allowSnapshotting: false,
        builder: (_) => MangaDetailPage(
          uuid: manga.uuid,
          repository: widget.repository,
          covers: widget.covers,
          editor: (context, record) => showFormPanel<MangaDraft>(
            context: context,
            builder: (_) => MangaEditorDialog(record: record),
          ),
        ),
      ),
    );
  }
}

class MangaEditorDialog extends StatefulWidget {
  final MangaRecord? record;
  final MangaDraft? initial;
  const MangaEditorDialog({super.key, this.record, this.initial});

  @override
  State<MangaEditorDialog> createState() => _MangaEditorDialogState();
}

class _MangaEditorDialogState extends State<MangaEditorDialog> {
  late final title = _controller(widget.record?.title ?? widget.initial?.title);
  late final originalTitle = _controller(
    widget.record?.originalTitle ?? widget.initial?.originalTitle,
  );
  late final aliases = _controller(
    widget.record?.aliases.join(', ') ?? widget.initial?.aliases.join(', '),
  );
  late final coverUrl = _controller(
    widget.record?.coverUrl ?? widget.initial?.coverUrl,
  );
  late final score = _controller(
    widget.record?.score?.toString() ?? widget.initial?.score?.toString(),
  );
  late final currentVolume = _controller(
    widget.record?.currentVolume?.toString() ??
        widget.initial?.currentVolume?.toString(),
  );
  late final currentChapter = _controller(
    widget.record?.currentChapter?.toString() ??
        widget.initial?.currentChapter?.toString(),
  );
  late final totalVolumes = _controller(
    widget.record?.totalVolumes?.toString() ??
        widget.initial?.totalVolumes?.toString(),
  );
  late final totalChapters = _controller(
    widget.record?.totalChapters?.toString() ??
        widget.initial?.totalChapters?.toString(),
  );
  late final notes = _controller(widget.record?.notes ?? widget.initial?.notes);
  late final tags = _controller(
    widget.record?.tags.join(', ') ?? widget.initial?.tags.join(', '),
  );
  late final summary = _controller(
    widget.record?.summary ?? widget.initial?.summary,
  );
  late final authors = _controller(
    widget.record?.authors.join(', ') ?? widget.initial?.authors.join(', '),
  );
  late final illustrators = _controller(
    widget.record?.illustrators.join(', ') ??
        widget.initial?.illustrators.join(', '),
  );
  late final publishers = _controller(
    widget.record?.publishers.join(', ') ??
        widget.initial?.publishers.join(', '),
  );
  late final serializations = _controller(
    widget.record?.serializations.join(', ') ??
        widget.initial?.serializations.join(', '),
  );
  late final startDate = _controller(
    widget.record?.startDate ?? widget.initial?.startDate,
  );
  late final endDate = _controller(
    widget.record?.endDate ?? widget.initial?.endDate,
  );
  late final releaseDate = _controller(
    widget.record?.releaseDate ?? widget.initial?.releaseDate,
  );
  MangaReadingStatus status = MangaReadingStatus.planToRead;
  MangaPublicationStatus publicationStatus = MangaPublicationStatus.unknown;
  final form = GlobalKey<FormState>();

  TextEditingController _controller(String? value) =>
      TextEditingController(text: value ?? '');

  List<TextEditingController> get _controllers => [
    title,
    originalTitle,
    aliases,
    coverUrl,
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
  ];

  @override
  void initState() {
    super.initState();
    status = widget.record?.status ?? widget.initial?.status ?? status;
    publicationStatus =
        widget.record?.publicationStatus ??
        widget.initial?.publicationStatus ??
        publicationStatus;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: FormPanel(
      title: widget.record == null ? '添加漫画' : '编辑漫画',
      subtitle: '先记下阅读位置，作品资料可以慢慢补充。',
      onSave: _save,
      saveLabel: '保存漫画',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: '阅读记录',
            children: [
              _field(title, '作品标题'),
              const SizedBox(height: 20),
              ChoiceField<MangaReadingStatus>(
                label: '阅读状态',
                value: status,
                choices: [
                  for (final value in MangaReadingStatus.values)
                    FormChoice(value, value.label),
                ],
                onChanged: (value) => setState(() => status = value),
              ),
              const SizedBox(height: 20),
              FormRow(
                children: [
                  IntegerInput(
                    controller: currentVolume,
                    label: '当前卷',
                    validator: (_) => _numberError(currentVolume),
                  ),
                  IntegerInput(
                    controller: currentChapter,
                    label: '当前话',
                    validator: (_) => _numberError(currentChapter),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormRow(
                children: [
                  _field(totalVolumes, '总卷数', number: true, hint: '未知可留空'),
                  _field(totalChapters, '总话数', number: true, hint: '未知可留空'),
                ],
              ),
              const SizedBox(height: 16),
              FormRow(
                children: [
                  _dateField(startDate, '开始日期'),
                  _dateField(endDate, '结束日期'),
                ],
              ),
            ],
          ),
          SectionCard(
            title: '评价与感想',
            children: [
              _field(score, '评分', number: true, hint: '0–10，可留空'),
              const SizedBox(height: 16),
              TokenInput(controller: tags, label: '标签'),
              const SizedBox(height: 16),
              _field(notes, '备注', maxLines: 4, hint: '记下此刻的阅读感受…'),
            ],
          ),
          SectionCard(
            title: '更多作品资料',
            collapsible: true,
            children: [
              _field(originalTitle, '原名'),
              const SizedBox(height: 16),
              TokenInput(controller: aliases, label: '别名'),
              const SizedBox(height: 16),
              ChoiceField<MangaPublicationStatus>(
                label: '连载状态',
                value: publicationStatus,
                choices: [
                  for (final value in MangaPublicationStatus.values)
                    FormChoice(value, value.label),
                ],
                onChanged: (value) => setState(() => publicationStatus = value),
              ),
              const SizedBox(height: 16),
              TokenInput(controller: authors, label: '作者'),
              const SizedBox(height: 16),
              TokenInput(controller: illustrators, label: '作画'),
              const SizedBox(height: 16),
              TokenInput(controller: publishers, label: '出版社'),
              const SizedBox(height: 16),
              TokenInput(controller: serializations, label: '连载杂志'),
              const SizedBox(height: 16),
              _field(coverUrl, '封面 URL'),
              const SizedBox(height: 16),
              _dateField(releaseDate, '出版日期'),
              const SizedBox(height: 16),
              _field(summary, '简介', maxLines: 4),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
    int maxLines = 1,
    String? hint,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: number
        ? TextInputType.numberWithOptions(decimal: controller == score)
        : maxLines > 1
        ? TextInputType.multiline
        : controller == coverUrl
        ? TextInputType.url
        : TextInputType.text,
    textInputAction: maxLines > 1
        ? TextInputAction.newline
        : TextInputAction.next,
    decoration: InputDecoration(labelText: label, hintText: hint),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (controller == title) {
        return text.isEmpty
            ? '请填写作品标题'
            : text.length > 500
            ? '标题最多 500 个字符'
            : null;
      }
      if (text.isEmpty) return null;
      if (controller == score) {
        final value = double.tryParse(text);
        return value == null || !value.isFinite || value < 0 || value > 10
            ? '评分范围为 0–10'
            : null;
      }
      return number ? _numberError(controller) : null;
    },
  );

  String? _numberError(TextEditingController controller) {
    if (controller.text.trim().isEmpty) return null;
    final number = int.tryParse(controller.text.trim());
    final minimum = controller == totalVolumes || controller == totalChapters
        ? 1
        : 0;
    return number == null || number < minimum ? '请填写不小于 $minimum 的整数' : null;
  }

  Widget _dateField(TextEditingController controller, String label) =>
      DateInput(
        controller: controller,
        label: label,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return null;
          if (normalizeDateString(text) != text) return '请选择有效日期';
          if (controller == endDate &&
              startDate.text.trim().isNotEmpty &&
              startDate.text.trim().compareTo(text) > 0) {
            return '结束日期不能早于开始日期';
          }
          return null;
        },
      );

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (form.currentState?.validate() == false) return;
    double? parseScore() =>
        score.text.trim().isEmpty ? null : double.tryParse(score.text.trim());
    String? optionalText(TextEditingController controller) =>
        controller.text.trim().isEmpty ? null : controller.text.trim();
    int? parseInt(TextEditingController controller) =>
        controller.text.trim().isEmpty
        ? null
        : int.tryParse(controller.text.trim());
    List<String> parseList(TextEditingController controller) => controller.text
        .split(RegExp('[,，\\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final parsedScore = parseScore();
    bool invalidInt(TextEditingController controller) =>
        controller.text.trim().isNotEmpty && parseInt(controller) == null;
    if (title.text.trim().isEmpty ||
        (score.text.trim().isNotEmpty &&
            (parsedScore == null || !parsedScore.isFinite)) ||
        [
          currentVolume,
          currentChapter,
          totalVolumes,
          totalChapters,
        ].any(invalidInt)) {
      // The repository performs the authoritative validation; this handles
      // only the most common typo without closing the editor.
      ScaffoldMessenger.of(context).showSnackBar(
        appSnackBar(
          context,
          error: true,
          content: const Text('请检查标题、评分和卷话数格式'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      MangaDraft(
        uuid: widget.record?.uuid,
        bangumiId: widget.record?.bangumiId ?? widget.initial?.bangumiId,
        title: title.text,
        originalTitle: optionalText(originalTitle),
        aliases: parseList(aliases),
        coverUrl: optionalText(coverUrl),
        status: status,
        publicationStatus: publicationStatus,
        score: parsedScore,
        currentVolume: parseInt(currentVolume),
        currentChapter: parseInt(currentChapter),
        totalVolumes: parseInt(totalVolumes),
        totalChapters: parseInt(totalChapters),
        notes: optionalText(notes),
        tags: parseList(tags),
        summary: optionalText(summary),
        authors: parseList(authors),
        illustrators: parseList(illustrators),
        publishers: parseList(publishers),
        serializations: parseList(serializations),
        startDate: optionalText(startDate),
        endDate: optionalText(endDate),
        releaseDate: optionalText(releaseDate),
      ),
    );
  }
}
