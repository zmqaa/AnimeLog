import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.file(File file) =>
      AppDatabase(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement('PRAGMA foreign_keys = OFF');
        await transaction(() async {
          await migrator.alterTable(TableMigration(anime));
          final broken = await customSelect('PRAGMA foreign_key_check').get();
          if (broken.isNotEmpty) throw StateError('数据库迁移出现无效关系，已回滚');
        });
      }
      if (from < 3) {
        final columns = await customSelect('PRAGMA table_info(anime)').get();
        final names = columns.map((row) => row.data['name']).toSet();
        if (!names.contains('cast')) {
          await customStatement(
            "ALTER TABLE anime ADD COLUMN \"cast\" TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (!names.contains('cast_aliases')) {
          await customStatement(
            "ALTER TABLE anime ADD COLUMN cast_aliases TEXT NOT NULL DEFAULT '[]'",
          );
        }
        await migrator.createTable(manga);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
