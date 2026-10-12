import '../../core/anime_log_core.dart';
import '../../core/api/library_repository.dart';

String clockLabel(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String historyTimeLabel(WatchHistoryRecord event) {
  final moment = event.watchedAt == null
      ? null
      : DateTime.tryParse(event.watchedAt!);
  return moment == null ? '时间未记录' : clockLabel(moment.toLocal());
}

String historyMomentLabel(WatchHistoryRecord event) =>
    '${event.watchedOn}  ${historyTimeLabel(event)}';

String historyUndoImpactLabel(HistoryUndoPreview preview) {
  final progress = preview.currentProgress == preview.targetProgress
      ? '进度保持第 ${preview.currentProgress} 集'
      : '进度将从第 ${preview.currentProgress} 集回退至 ${preview.targetProgress} 集';
  return '$progress，并删除第 ${preview.targetProgress + 1} 集及之后的 '
      '${preview.events.length} 条观看历史。此操作不可撤销。';
}

String localTimestampLabel(String value) {
  final moment = DateTime.tryParse(value)?.toLocal();
  return moment == null
      ? '未记录'
      : '${moment.toIso8601String().substring(0, 10)} ${clockLabel(moment)}';
}
