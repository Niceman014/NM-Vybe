import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/data/library_repository.dart';
import 'core/providers/app_providers.dart';
import 'core/services/audio_handler.dart';
import 'core/services/settings_service.dart';
import 'core/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const logger = AppLogger('main');
  final stopwatch = Stopwatch()..start();

  final preferences = await SharedPreferences.getInstance();
  final repository = await SembastLibraryRepository.open();
  final audioHandler = await initAudioHandler();

  logger.i('Booted in ${stopwatch.elapsedMilliseconds}ms');

  runApp(
    ProviderScope(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(repository),
        settingsControllerProvider
            .overrideWith((ref) => SettingsController(preferences)),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const NmVybeApp(),
    ),
  );
}
