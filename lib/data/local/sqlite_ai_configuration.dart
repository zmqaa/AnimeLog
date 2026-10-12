
import '../../core/api/ai_intake.dart';
import 'app_database.dart';

class SqliteAiConfigurationStore implements AiConfigurationStore {
  final AppDatabase db;
  SqliteAiConfigurationStore(this.db);
  @override
  Future<AiConfiguration?> load() async {
    final rows = await (db.select(
      db.appSettings,
    )..where((t) => t.settingKey.isIn(['ai_base_url', 'ai_model']))).get();
    final values = {for (final row in rows) row.settingKey: row.value};
    if (values['ai_base_url'] == null || values['ai_model'] == null) {
      return null;
    }
    return AiConfiguration(
      baseUrl: values['ai_base_url']!,
      model: values['ai_model']!,
    );
  }

  @override
  Future<void> save(AiConfiguration configuration) => db.transaction(() async {
    configuration.validate();
    for (final item in {
      'ai_base_url': configuration.baseUrl,
      'ai_model': configuration.model,
    }.entries) {
      await db
          .into(db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              settingKey: item.key,
              value: item.value,
            ),
          );
    }
  });
}
