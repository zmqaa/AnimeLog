import 'package:animelog/data/local/app_database.dart';
import 'package:animelog/data/local/sqlite_appearance.dart';
import 'package:animelog/features/shared/app_appearance.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'appearance persists without overwriting other local settings',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              settingKey: 'ai_model',
              value: 'my-model',
            ),
          );
      final store = SqliteAppearanceStore(db);
      expect(await store.load(), ThemeMode.light);
      expect(await store.loadAccent(), AppAccent.teal);
      final appearance = AppAppearance(
        persist: store.save,
        persistAccent: store.saveAccent,
      );
      addTearDown(appearance.dispose);
      await appearance.select(ThemeMode.dark);
      expect(appearance.mode, ThemeMode.dark);
      expect(await SqliteAppearanceStore(db).load(), ThemeMode.dark);
      await appearance.selectAccent(AppAccent.blue);
      expect(await SqliteAppearanceStore(db).loadAccent(), AppAccent.blue);
      expect(await store.load(), ThemeMode.dark);
      expect(
        (await (db.select(
          db.appSettings,
        )..where((t) => t.settingKey.equals('ai_model'))).getSingle()).value,
        'my-model',
      );
      await appearance.select(ThemeMode.light);
      expect(await store.load(), ThemeMode.light);
      expect(await store.loadAccent(), AppAccent.blue);
    },
  );

  test(
    'failed preference writes retain the previous theme and permit retry',
    () async {
      var fail = true;
      final appearance = AppAppearance(
        persist: (_) async {
          if (fail) throw StateError('storage unavailable');
        },
      );
      addTearDown(appearance.dispose);
      await expectLater(appearance.select(ThemeMode.dark), throwsStateError);
      expect(appearance.mode, ThemeMode.light);
      expect(appearance.saving, false);
      fail = false;
      await appearance.select(ThemeMode.dark);
      expect(appearance.mode, ThemeMode.dark);
    },
  );

  test(
    'failed accent writes retain the selected color and allow retry',
    () async {
      var fail = true;
      final appearance = AppAppearance(
        persistAccent: (_) async {
          if (fail) throw StateError('storage unavailable');
        },
      );
      addTearDown(appearance.dispose);
      await expectLater(
        appearance.selectAccent(AppAccent.violet),
        throwsStateError,
      );
      expect(appearance.accent, AppAccent.teal);
      expect(appearance.saving, false);
      fail = false;
      await appearance.selectAccent(AppAccent.violet);
      expect(appearance.accent, AppAccent.violet);
    },
  );
}
