import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'package:nm_vybe/core/services/audio_handler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Windows handler plays MP3, FLAC and M4A through queue', (
    tester,
  ) async {
    if (!Platform.isWindows) {
      markTestSkipped('This test requires the Windows media_kit backend.');
    }
    JustAudioMediaKit.ensureInitialized(windows: true, linux: false);
    final names = ['sample.mp3', 'sample.flac', 'sample.m4a'];
    final items = names.map((name) {
      final path = File('test/fixtures/$name').absolute.path;
      return MediaItem(
        id: path,
        title: name,
        artist: 'NM VYBE test fixture',
        extras: {'path': path},
      );
    }).toList(growable: false);
    final handler = NmVybeAudioHandler();

    try {
      // Independently exercise loading, playback, seek, pause and EOF on each
      // codec so a decode failure is attributed to the correct fixture.
      for (final item in items) {
        await handler.setQueue([item], autoPlay: false);
        await _waitFor(
          () => handler.player.processingState == ProcessingState.ready,
          'ready state for ${item.title}',
        );
        await handler.play();
        await _waitFor(
          () => handler.position >= const Duration(milliseconds: 250),
          'playback progress for ${item.title}',
        );
        final duration = handler.duration;
        expect(duration, isNotNull, reason: '${item.title} duration is read');
        await handler.seek(duration! - const Duration(milliseconds: 200));
        await handler.pause();
        expect(handler.isPlaying, isFalse, reason: '${item.title} pauses');
        await handler.play();
        await _waitFor(
          () => handler.player.processingState == ProcessingState.completed,
          'end of ${item.title}',
        );
      }

      // Then seek each queued item near its end and verify natural advancement.
      await handler.setQueue(items, autoPlay: false);
      await _waitFor(
        () => handler.player.processingState == ProcessingState.ready,
        'first queue item ready',
      );
      await handler.play();
      for (var expectedIndex = 1; expectedIndex < items.length; expectedIndex++) {
        await _waitFor(
          () => handler.duration != null,
          'duration for ${items[expectedIndex - 1].title}',
        );
        final duration = handler.duration!;
        await handler.seek(duration - const Duration(milliseconds: 200));
        await _waitFor(
          () => handler.currentIndex == expectedIndex,
          'queue advancing to ${items[expectedIndex].title}',
        );
        expect(handler.currentIndex, expectedIndex);
      }
      final finalDuration = handler.duration;
      expect(finalDuration, isNotNull);
      await handler.seek(finalDuration! - const Duration(milliseconds: 200));
      await _waitFor(
        () => handler.player.processingState == ProcessingState.completed,
        'completion of the full format queue',
      );
      expect(handler.currentQueue, hasLength(3));
    } finally {
      await handler.player.dispose();
    }
  });
}

Future<void> _waitFor(bool Function() condition, String description) async {
  final deadline = DateTime.now().add(const Duration(seconds: 12));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for $description.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
