import 'package:flutter/material.dart';
import 'dart:ui' show FrameTiming;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nm_vybe/app.dart';
import 'package:nm_vybe/core/data/in_memory_library_repository.dart';
import 'package:nm_vybe/core/providers/app_providers.dart';
import 'package:nm_vybe/core/services/audio_handler.dart';
import 'package:nm_vybe/core/services/settings_service.dart';
import 'package:nm_vybe/core/utils/platform_info.dart';
import 'package:nm_vybe/features/library/models/song_model.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile scroll of a 5,000-song library', (tester) async {
    if (PlatformInfo.isWindows) {
      JustAudioMediaKit.ensureInitialized(windows: true, linux: false);
    }
    // Isolate test preferences from real user data.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'nm_vybe.autoScan': false,
    });
    final date = DateTime.utc(2026, 10, 31);
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
          duration: Duration(minutes: 2 + index % 7),
          fileSize: 2 * 1024 * 1024,
          addedAt: date.add(Duration(seconds: index)),
        ),
      ),
    );
    final preferences = await AppPreferences.open();
    final handler = NmVybeAudioHandler();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(repository),
          settingsControllerProvider.overrideWith(
            (ref) => SettingsController(preferences),
          ),
          audioHandlerProvider.overrideWithValue(handler),
        ],
        child: const NmVybeApp(),
      ),
    );
    // Avoid pumpAndSettle: the app contains intentionally continuous player
    // animations, so wait a fixed, bounded interval for providers/layout.
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final scrollable = find.byType(Scrollable).first;
    expect(find.text('Profile Track 00000'), findsOneWidget);
    final timings = <FrameTiming>[];
    WidgetsBinding.instance.addTimingsCallback(timings.addAll);
    await binding.traceAction(() async {
      // Fixed deterministic path in 400 logical-pixel increments. Large
      // jumps force SliverList to lay out every skipped row to estimate its
      // extent, which tests an artificial seek rather than smooth scrolling.
      final position = tester.state<ScrollableState>(scrollable).position;
      var steps = 0;
      while (position.pixels < position.maxScrollExtent && steps < 1200) {
        final next = (position.pixels + 400).clamp(
          0.0,
          position.maxScrollExtent,
        );
        position.jumpTo(next);
        await tester.pump(const Duration(milliseconds: 16));
        steps++;
      }
      expect(steps, lessThan(1200), reason: 'Scroll reached the end of list.');
      expect(find.text('Profile Track 04999'), findsOneWidget);
      for (var step = 0; step < 80 && position.pixels > 0; step++) {
        position.jumpTo((position.pixels - 400).clamp(0.0, position.maxScrollExtent));
        await tester.pump(const Duration(milliseconds: 16));
      }
    }, reportKey: 'library_5000_scroll_timeline');
    WidgetsBinding.instance.removeTimingsCallback(timings.addAll);
    expect(timings, isNotEmpty, reason: 'Profile run must capture frame timings.');
    binding.reportData!['library_5000_frame_summary'] =
        FrameTimingSummarizer(timings).summary;
    await repository.close();
  });
}
