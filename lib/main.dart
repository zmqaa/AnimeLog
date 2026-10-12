import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;

import 'application/manual_library.dart';
import 'application/backup_service.dart';
import 'core/api/library_repository.dart';
import 'core/api/manga_repository.dart';
import 'data/local/app_database.dart';
import 'data/local/sqlite_library_repository.dart';
import 'data/local/sqlite_manga_repository.dart';
import 'data/local/sqlite_backup_repository.dart';
import 'data/platform/backup_files.dart';
import 'data/platform/local_files.dart';
import 'features/library/library_page.dart';
import 'application/ai_intake.dart';
import 'application/ai_settings.dart';
import 'application/manga_intake.dart';
import 'core/api/ai_intake.dart';
import 'data/local/sqlite_ai_configuration.dart';
import 'data/platform/secure_api_key.dart';
import 'data/platform/cover_cache.dart';
import 'data/remote/json_http.dart';
import 'data/remote/compatible_ai_client.dart';
import 'data/remote/bangumi_source.dart';
import 'data/remote/manga_source.dart';
import 'application/metadata_completion.dart';
import 'features/shared/app_theme.dart';
import 'features/shared/app_appearance.dart';
import 'features/shared/app_click_cursor.dart';
import 'data/local/sqlite_appearance.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class AnimeLogApp extends StatefulWidget {
  final ManualLibrary useCases;
  final IntakeDraftStore drafts;
  final BackupService? backups;
  final AiIntake? aiIntake;
  final CoverStore? covers;
  final MetadataCompletionService? metadataCompletion;
  final MangaRepository? mangaRepository;
  final MangaIntake? mangaIntake;
  final AppAppearance? appearance;
  const AnimeLogApp({
    super.key,
    required this.useCases,
    required this.drafts,
    this.backups,
    this.aiIntake,
    this.covers,
    this.metadataCompletion,
    this.mangaRepository,
    this.mangaIntake,
    this.appearance,
  });

  @override
  State<AnimeLogApp> createState() => _AnimeLogAppState();
}

class _AnimeLogAppState extends State<AnimeLogApp> {
  late final AppAppearance appearance = widget.appearance ?? AppAppearance();

  @override
  void dispose() {
    if (widget.appearance == null) appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppearanceScope(
    appearance: appearance,
    child: ListenableBuilder(
      listenable: appearance,
      builder: (context, _) => MaterialApp(
        title: 'AnimeLog',
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        theme: animeLogTheme(accent: appearance.accent),
        darkTheme: animeLogTheme(
          brightness: Brightness.dark,
          accent: appearance.accent,
        ),
        themeMode: appearance.mode,
        builder: (context, child) => AppClickCursor(child: child!),
        home: LibraryPage(
          useCases: widget.useCases,
          drafts: widget.drafts,
          backups: widget.backups,
          aiIntake: widget.aiIntake,
          covers: widget.covers,
          metadataCompletion: widget.metadataCompletion,
          mangaRepository: widget.mangaRepository,
          mangaIntake: widget.mangaIntake,
        ),
      ),
    ),
  );
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  AppDatabase? database;
  ManualLibrary? useCases;
  IntakeDraftStore? drafts;
  BackupService? backups;
  AiIntake? aiIntake;
  CoverStore? covers;
  MetadataCompletionService? metadataCompletion;
  MangaRepository? mangaRepository;
  MangaIntake? mangaIntake;
  AppAppearance? appearance;
  Object? error;
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => error = null);
    AppDatabase? opening;
    try {
      final directory = await applicationDirectory();
      opening = AppDatabase.file(
        File(p.join(directory.path, 'animelog.sqlite')),
      );
      final repository = SqliteLibraryRepository(opening);
      final mangaRepository = SqliteMangaRepository(opening);
      await repository.all();
      final appearanceStore = SqliteAppearanceStore(opening);
      final mode = await appearanceStore.load();
      final accent = await appearanceStore.loadAccent();
      if (!mounted) {
        await opening.close();
        return;
      }
      setState(() {
        database = opening;
        appearance = AppAppearance(
          mode: mode,
          accent: accent,
          persist: appearanceStore.save,
          persistAccent: appearanceStore.saveAccent,
        );
        useCases = ManualLibrary(repository, repository);
        this.mangaRepository = mangaRepository;
        drafts = FileIntakeDraftStore(
          File(p.join(directory.path, 'intake-draft.json')),
        );
        final transport = JsonHttp();
        final source = BangumiSourceProvider(transport);
        metadataCompletion = MetadataCompletionService(repository, source);
        final configuredAi = AiIntake(
          AiSettings(
            SqliteAiConfigurationStore(opening!),
            SecureApiKeyStore(),
            CompatibleAiClient(transport),
          ),
          source,
        );
        aiIntake = configuredAi;
        mangaIntake = MangaIntake(
          configuredAi.settings,
          BangumiMangaSource(transport),
        );
        covers = FileCoverCache(
          Directory(p.join(directory.path, 'covers')),
          transport,
        );
        backups = BackupService(
          SqliteBackupRepository(
            opening,
            onImported: repository.invalidateUndoReceipts,
          ),
          PlatformBackupFiles(directory),
          drafts!,
        );
      });
    } catch (failure) {
      await opening?.close();
      if (mounted) setState(() => error = failure);
    }
  }

  @override
  void dispose() {
    appearance?.dispose();
    database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => useCases != null
      ? AnimeLogApp(
          useCases: useCases!,
          drafts: drafts!,
          backups: backups!,
          aiIntake: aiIntake,
          covers: covers,
          metadataCompletion: metadataCompletion,
          mangaRepository: mangaRepository,
          mangaIntake: mangaIntake,
          appearance: appearance,
        )
      : MaterialApp(
          builder: (context, child) => AppClickCursor(child: child!),
          home: Scaffold(
            body: Center(
              child: error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('本地数据打开失败'),
                          const SizedBox(height: 12),
                          Text('$error'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _open,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
}
