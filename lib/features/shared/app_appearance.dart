import 'package:flutter/material.dart';

enum AppAccent {
  teal('青绿', Color(0xff167a68)),
  blue('蓝色', Color(0xff3568ad)),
  violet('紫色', Color(0xff7955ab)),
  rose('玫瑰', Color(0xffad526c));

  final String label;
  final Color seed;
  const AppAccent(this.label, this.seed);
}

/// Appearance is local configuration, independent of exported library data.
class AppAppearance extends ChangeNotifier {
  ThemeMode mode;
  AppAccent accent;
  final Future<void> Function(ThemeMode)? persist;
  final Future<void> Function(AppAccent)? persistAccent;
  bool saving = false;
  bool _disposed = false;

  AppAppearance({
    this.mode = ThemeMode.light,
    this.accent = AppAccent.teal,
    this.persist,
    this.persistAccent,
  });

  Future<void> selectAccent(AppAccent value) async {
    if (saving || value == accent) return;
    saving = true;
    notifyListeners();
    try {
      await persistAccent?.call(value);
      accent = value;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> select(ThemeMode value) async {
    if (saving || value == mode) return;
    if (value == ThemeMode.system) throw ArgumentError('只支持浅色和深色');
    saving = true;
    notifyListeners();
    try {
      await persist?.call(value);
      mode = value;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class AppearanceScope extends InheritedNotifier<AppAppearance> {
  const AppearanceScope({
    super.key,
    required AppAppearance appearance,
    required super.child,
  }) : super(notifier: appearance);

  static AppAppearance? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;
}
