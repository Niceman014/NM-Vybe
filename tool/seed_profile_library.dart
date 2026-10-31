import 'dart:io';

import 'package:sembast/sembast_io.dart';

/// Creates an isolated synthetic library for manual profile-mode UI checks.
///
/// Usage: `dart run tool/seed_profile_library.dart <path-to-nm_vybe.db>`
/// This intentionally writes only to the explicitly supplied path.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1 || arguments.single.trim().isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/seed_profile_library.dart <path-to-nm_vybe.db>',
    );
    exitCode = 64;
    return;
  }

  final databaseFile = File(arguments.single).absolute;
  await databaseFile.parent.create(recursive: true);
  final database = await databaseFactoryIo.openDatabase(databaseFile.path);
  final songsStore = stringMapStoreFactory.store('songs');
  try {
    final now = DateTime.utc(2026, 10, 31);
    await database.transaction((transaction) async {
      await songsStore.delete(transaction);
      for (final index in Iterable<int>.generate(5000)) {
        final id = 'profile:$index';
        await songsStore.record(id).put(transaction, <String, Object?>{
          'id': id,
          'filePath': 'profile-only/track_$index.mp3',
          'title': 'Profile Track ${index.toString().padLeft(5, '0')}',
          'artist': 'Profile Artist ${index % 100}',
          'album': 'Profile Album ${index % 250}',
          'albumArtist': 'Profile Artist ${index % 100}',
          'durationMs': Duration(minutes: 2 + (index % 7)).inMilliseconds,
          'fileSize': 2 * 1024 * 1024,
          'addedAt': now.add(Duration(seconds: index)).millisecondsSinceEpoch,
          'playCount': 0,
          'isFavorite': false,
          'downloadAllowed': false,
          'isDownloaded': false,
        });
      }
    });
    stdout.writeln('Seeded 5000 synthetic songs in ${databaseFile.path}');
  } finally {
    await database.close();
  }
}
