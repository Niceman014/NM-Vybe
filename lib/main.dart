import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app.dart';
import 'core/data/library_repository.dart';
import 'core/providers/app_providers.dart';
import 'core/services/audio_handler.dart';
import 'core/services/db_service.dart';
import 'core/services/download_storage.dart';
import 'core/services/settings_service.dart';
import 'core/utils/logger.dart';
import 'core/utils/platform_info.dart';
import 'features/updates/services/windows_installer_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformInfo.isWindows) {
    JustAudioMediaKit.ensureInitialized(windows: true, linux: false);
  }

  const logger = AppLogger('main');
  final stopwatch = Stopwatch()..start();
  SembastLibraryRepository? repository;

  try {
    if (PlatformInfo.isWindows) {
      try {
        await WindowsInstallerStrategy.cleanupPartialFiles();
      } catch (error, stackTrace) {
        logger.w(
          'Could not clean interrupted updater downloads',
          error,
          stackTrace,
        );
      }
    }
    await AppDatabase.prepareStorage();
    await DownloadStorage.cleanupPartialFiles();
    final preferences = await AppPreferences.open();
    repository = await SembastLibraryRepository.open();
    final audioHandler = await initAudioHandler();

    logger.i('Booted in ${stopwatch.elapsedMilliseconds}ms');

    runApp(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(repository),
          settingsControllerProvider.overrideWith(
            (ref) => SettingsController(preferences),
          ),
          audioHandlerProvider.overrideWithValue(audioHandler),
        ],
        child: const NmVybeApp(),
      ),
    );
  } catch (error, stackTrace) {
    logger.e('Application startup failed', error, stackTrace);
    await repository?.close();
    runApp(_StartupFailureApp(error: error));
  }
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NM VYBE',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_off_rounded, size: 52),
                  const SizedBox(height: 20),
                  Text(
                    'NM VYBE could not start',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'The app could not open its local data or audio service. '
                    'Check that app storage is available, then try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => main(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
