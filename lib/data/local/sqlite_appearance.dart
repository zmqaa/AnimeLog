import 'package:flutter/material.dart' show ThemeMode;

import 'app_database.dart';
import '../../features/shared/app_appearance.dart' show AppAccent;

class SqliteAppearanceStore {
  final AppDatabase db;
  SqliteAppearanceStore(this.db);

  Future<ThemeMode> load() async {
    final row = await (db.select(
      db.appSettings,
    )..where((t) => t.settingKey.equals('appearance_mode'))).getSingleOrNull();
    return row?.value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> save(ThemeMode mode) async {
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            settingKey: 'appearance_mode',
            value: mode == ThemeMode.dark ? 'dark' : 'light',
          ),
        );
  }

  Future<AppAccent> loadAccent() async {
    final row =
        await (db.select(db.appSettings)
              ..where((t) => t.settingKey.equals('appearance_accent')))
            .getSingleOrNull();
    return AppAccent.values.firstWhere(
      (accent) => accent.name == row?.value,
      orElse: () => AppAccent.teal,
    );
  }

  Future<void> saveAccent(AppAccent accent) async {
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            settingKey: 'appearance_accent',
            value: accent.name,
          ),
        );
  }
}
