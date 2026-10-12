import 'package:flutter/material.dart';

const collectionPageSize = 10;
const managementPageSize = 24;

int pageCount(int total, int pageSize) =>
    total == 0 ? 1 : (total / pageSize).ceil();

int boundedPage(int page, int total, int pageSize) =>
    page.clamp(0, pageCount(total, pageSize) - 1);

class PaginationControls extends StatelessWidget {
  final int total;
  final int page;
  final int pageSize;
  final ValueChanged<int> onChanged;
  final bool alignEnd;

  const PaginationControls({
    super.key,
    required this.total,
    required this.page,
    required this.onChanged,
    this.pageSize = collectionPageSize,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final current = boundedPage(page, total, pageSize);
    final count = pageCount(total, pageSize);
    final end = ((current + 1) * pageSize).clamp(0, total);
    final summary = Text(
      total == 0 ? '共 0 条' : '${current * pageSize + 1}–$end 条，共 $total 条',
      style: Theme.of(context).textTheme.bodySmall,
    );
    final actions = Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: current == 0 ? null : () => onChanged(current - 1),
          child: const Text('上一页'),
        ),
        PopupMenuButton<int>(
          tooltip: '跳转页码',
          initialValue: current,
          onSelected: onChanged,
          itemBuilder: (_) => [
            for (var index = 0; index < count; index++)
              PopupMenuItem(value: index, child: Text('第 ${index + 1} 页')),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text('${current + 1} / $count 页'),
          ),
        ),
        TextButton(
          onPressed: current + 1 == count ? null : () => onChanged(current + 1),
          child: const Text('下一页'),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (alignEnd && constraints.maxWidth >= 460) {
            return Row(
              children: [
                Expanded(child: summary),
                actions,
              ],
            );
          }
          return Wrap(
            alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [summary, actions],
          );
        },
      ),
    );
  }
}
