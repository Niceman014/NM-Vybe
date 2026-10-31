import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nm_vybe/app.dart';
import 'package:nm_vybe/core/data/in_memory_library_repository.dart';
import 'package:nm_vybe/core/providers/app_providers.dart';
import 'package:nm_vybe/core/services/audio_handler.dart';
import 'package:nm_vybe/core/services/settings_service.dart';
import 'package:nm_vybe/core/utils/platform_info.dart';
import 'package:nm_vybe/features/library/models/song_model.dart';

/// Profile-only entry point for exercising the real library UI at 5,000 rows.
/// It uses an in-memory synthetic collection and never touches user library data.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (PlatformInfo.isWindows) {
    JustAudioMediaKit.ensureInitialized(windows: true, linux: false);
  }

  // This profile-only entry point must not read or write the developer's
  // real preferences; this is the supported test binding for the plugin.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  final now = DateTime.utc(2026, 10, 31);
  final repository = InMemoryLibraryRepository(
    songs: List<Song>.generate(
      5000,
      (index) => Song(
        id: 'profile:$index',
        filePath: 'profile-only/track_$index.mp3',
        title: 'Profile Track ${index.toString().padLeft(5, '0')}',
        artist: 'Profile Artist ${index % 100}',
        album: 'Profile Album ${index % 250}',
        albumArtist: 'Profile Artist ${index % 100}',
        duration: Duration(minutes: 2 + (index % 7)),
        fileSize: 2 * 1024 * 1024,
        addedAt: now.add(Duration(seconds: index)),
      ),
    ),
  );
  final preferences = await AppPreferences.open();
  final audioHandler = NmVybeAudioHandler();

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
}
