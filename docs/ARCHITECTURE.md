# NM VYBE — Architecture & team contract (v1)

> Read this before writing code. The Lead owns this file; if you need an
> interface change, message the Lead instead of editing shared code.

## Product

**NM VYBE** — a proprietary, local-first music player for Android and Windows
v1, planned as a one-time purchase. Local playback and playlists must work
without signing in. Google sign-in and cloud playlist backup are requested
product features but are not implemented yet. Local music files remain on the
device unless the user explicitly enables a future backup feature.

Flutter 3.50 / Dart 3.14. Riverpod 3.x with legacy `StateNotifierProvider`,
`just_audio` 0.10.6 with `just_audio_media_kit` and `media_kit_libs_windows_audio`
on Windows, `audio_service` 0.18.19, and Sembast 3.8.

## Commands

Use a project-root PowerShell terminal. If Flutter reports that it cannot
access `E:\Android Application Development\flutter\bin\cache\lockfile`, run
the Flutter command from a terminal that can access the installed SDK; the
project's `.tmp` directory can be used for `TEMP` and `TMP` when Windows temp
permissions interfere.

```powershell
flutter analyze          # must print "No issues found!"
flutter test             # must pass
flutter build windows --debug
```

## Folder map

```
lib/
  main.dart                     boot: prefs, repository, audio handler, ProviderScope
  app.dart                      MaterialApp, dynamic colour, theme mode
  core/
    constants/                  app_constants, theme_constants
    data/                       library_repository (sembast), in_memory repo
    models/                     library_groups (AlbumGroup/ArtistGroup)
    providers/app_providers.dart  repository/settings/audio/player + derived library providers
    services/                   audio, artwork, settings, database, download, scan, and tag services
    theme/app_theme.dart        Material 3 theme factory
    utils/                      formatters, logger, platform_info
  features/
    library/                    models (Song, Playlist), views, widgets, controllers
    discover/                   source search and licensed download UI
    player/                     controllers (PlayerController), views
    playlists/                  views
    settings/                   views, controllers (equalizer)
  data/                         source interfaces, providers, source adapters, repository
  shared/widgets/               app_shell, mini_player, album_art, song_tile
```

## Ownership (do not edit files outside your scope)

| Area | Owner | Files |
| --- | --- | --- |
| Core, shell, integration, build | Lead | `lib/main.dart`, `lib/app.dart`, `lib/core/**` (except files listed below), `lib/shared/widgets/app_shell.dart`, `pubspec.yaml`, `README.md`, `docs/`, `version.json`, `test/widget_test.dart` |
| Audio platform + equalizer | audio-platform | `android/**`, `lib/features/settings/controllers/equalizer_controller.dart` |
| Scanning, tags, lyrics | library-data | `lib/core/services/tag_reader.dart`, `lib/core/services/scanner_service.dart`, `lib/core/services/lyrics_service.dart`, `lib/features/library/controllers/scan_controller.dart`, `test/tag_reader_test.dart`, `test/lyrics_service_test.dart`, `test/scanner_service_test.dart` |
| Player UI | player-ui | `lib/shared/widgets/album_art.dart`, `lib/shared/widgets/mini_player.dart`, `lib/features/player/views/**`, `lib/features/player/controllers/palette_controller.dart` |
| Library / playlists / settings UI | library-ui | `lib/features/library/views/**`, `lib/features/library/widgets/**`, `lib/features/playlists/views/**`, `lib/features/settings/views/settings_page.dart` |

Never edit `pubspec.yaml`, `analysis_options.yaml`, `lib/core/providers/app_providers.dart`,
`lib/core/services/audio_handler.dart`, or `lib/features/player/controllers/player_controller.dart`
without asking the Lead. If you need a new dependency, ask the Lead.

## Data model (`lib/features/library/models/song_model.dart`)

```dart
Song {
  String id;            // stable hash of canonical file path
  String filePath;
  String title, artist, album, albumArtist;
  String? genre; int? year; int? trackNumber; int? discNumber;
  Duration duration; int fileSize;
  DateTime addedAt; DateTime? modifiedAt;
  int playCount; DateTime? lastPlayedAt; bool isFavorite;
  String? artworkKey;   // artwork cache key
  // display helpers: displayTitle, displayArtist, displayAlbum,
  // displayAlbumArtist, albumGroupKey, hasArtwork; copyWith(...), toMap/fromMap
}
Playlist { String id; String name; List<String> songIds; DateTime createdAt, updatedAt; }
AlbumGroup / ArtistGroup in lib/core/models/library_groups.dart
```

## Providers (`lib/core/providers/app_providers.dart`)

```dart
libraryRepositoryProvider   Provider<LibraryRepository>     (overridden in main)
settingsControllerProvider  StateNotifierProvider<SettingsController, AppSettings>
audioHandlerProvider        Provider<NmVybeAudioHandler>    (overridden in main)
playerControllerProvider    StateNotifierProvider<PlayerController, PlayerState>
songsProvider               StreamProvider<List<Song>>
playlistsProvider           StreamProvider<List<Playlist>>
sortedSongsProvider         Provider<List<Song>>            (respects settings sort)
albumsProvider              Provider<List<AlbumGroup>>
artistsProvider             Provider<List<ArtistGroup>>
favoriteSongsProvider       Provider<List<Song>>
recentlyPlayedProvider      Provider<List<Song>>
searchQueryProvider         StateProvider<String>
searchResultsProvider       Provider<List<Song>>
isLoadingLibraryProvider    Provider<bool>
libraryErrorProvider        Provider<Object?>
lastScanTimeProvider        FutureProvider<DateTime?>
resolvePlaylistSongs(Playlist, List<Song>) -> List<Song>
sortSongs(List<Song>, SongsSortMode, {bool ascending})
```

`SettingsController` methods: `setThemeMode`, `setUseDynamicColor`, `setSeedColorValue`,
`setLibraryFolders`, `setSongsSortMode`, `setSongsSortAscending`, `setAutoScanOnStartup`,
`setShowLyricsInPlayer`, `completeOnboarding`. `AppSettings` has `themeMode`,
`useDynamicColor`, `seedColorValue`, `seedColor`, `libraryFolders`, `songsSortMode`,
`songsSortAscending`, `autoScanOnStartup`, `showLyricsInPlayer`.

## Player API (`PlayerController` — do not edit, call it)

```dart
PlayerState { List<Song> queue; int currentIndex; bool playing, loading;
  Duration position, duration, buffered; AudioServiceRepeatMode repeatMode;
  bool shuffleEnabled; double speed; Duration? sleepTimerRemaining; String? error;
  Song? current; Song? next; bool hasQueue, hasSong; double progress; }

playSongs(List<Song> songs, {int initialIndex = 0, Duration? initialPosition})
playSong(Song song, {List<Song>? context})
togglePlayPause(); next(); previous(); seek(Duration); setSpeed(double);
cycleRepeatMode(); toggleShuffle();
addToQueue(Song); playNext(Song); removeFromQueue(int); reorderQueue(int,int);
clearQueue(); setSleepTimer(Duration?)
```

## Audio handler (`NmVybeAudioHandler` — do not edit)

`setQueue(List<MediaItem>, {initialIndex, initialPosition, autoPlay})`,
`addToQueueEnd`, `addNext`, `removeQueueItemAt`, `moveQueueItem`, `clearQueue`,
`play/pause/stop/seek/skipToNext/skipToPrevious/setVolume/setSpeed/setRepeatMode/setShuffleMode`,
`positionStream`, `durationStream`, `bufferedPositionStream`,
`equalizerBands()`, `setEqualizerGain(int,double)`, `setEqualizerEnabled(bool)`,
`resetEqualizer()`, `supportsEqualizer`, `equalizerEnabled`.

## Artwork (`lib/core/services/artwork_service.dart` — already written)

```dart
artworkServiceProvider       Provider<ArtworkService>
artworkFileProvider          FutureProvider.family<File?, String?>  // artworkKey -> File
ArtworkService.fileForKey(String? key); cacheArtwork(String key, Uint8List bytes);
clear(); prune(Set<String> keepKeys); sizeBytes();
```

## Scan contract (library-data writes, library-ui consumes)

`lib/features/library/controllers/scan_controller.dart`:

```dart
class ScanState {
  final bool scanning; final int processed; final int total;
  final int added; final int updated; final int removed;
  final String? currentFile; final String? error; final DateTime? lastScan;
  bool get hasLibraryChanges; double get progress;
}
final scanControllerProvider = StateNotifierProvider<ScanController, ScanState>(...);
class ScanController {
  ScanController({required LibraryRepository repository});
  Future<void> scanLibrary({bool fullRefresh = false});
  Future<void> addFolder();        // desktop: file_picker folder; Android: trigger MediaStore scan
  Future<void> clearLibrary();
}
```

Android scan uses `on_audio_query` (MediaStore) — request `READ_MEDIA_AUDIO`
(Android 13+) / `READ_EXTERNAL_STORAGE` (≤12) before scanning. Desktop walks the
folders in `AppSettings.libraryFolders` (default: user Music folder) reading tags.

`lib/core/services/lyrics_service.dart`:

```dart
class LyricsLine { final Duration time; final String text; }
class Lyrics { final List<LyricsLine> lines; final bool synced; final String? plainText; }
class LyricsService {
  Future<Lyrics?> loadFor(Song song);  // sidecar .lrc next to the file, then .txt
}
final lyricsServiceProvider = Provider<LyricsService>(...);
```

## Tag reader (`lib/core/services/tag_reader.dart`, library-data)

```dart
class AudioTags {
  String? title, artist, album, albumArtist, genre; int? year, trackNumber, discNumber;
  Duration? duration; Uint8List? picture; String? pictureMimeType;
  bool get isEmpty;
}
class TagReader {
  AudioTags read(File file);            // no plugins; pure Dart
}
```
Support: ID3v2.3/2.4 (+ID3v1 fallback), FLAC Vorbis comments + PICTURE,
MP4/M4A `ilst` (©nam, ©ART, ©alb, aART, ©gen, ©day, trkn, disk, covr),
OGG/Opus Vorbis comments. Duration: MP3 (Xing/VBRI or first frame estimate),
FLAC STREAMINFO, MP4 `mvhd`, OGG last granule. Must never throw on malformed
files — return what was parsed.

## UI conventions

- Material 3 only, colours from `Theme.of(context).colorScheme`; never hard-code
  brand colours except the gradients in `ThemeConstants`.
- Radius: 10/16/24/32 from `ThemeConstants`. Use `AlbumArt` widget for artwork
  (player-ui writes it): `AlbumArt(artworkKey: key, size: 56, borderRadius: 12)`.
- Responsive: `MediaQuery.sizeOf(context).width >= 900` is the desktop breakpoint.
- No new dependencies. No `print` (use `AppLogger`). No direct `File` image
  loading in widgets without the artwork service.
- Every async button must show progress and disable itself while running.
- Empty states and errors are part of the UI.

## Definition of done for your task

1. Code compiles: `flutter analyze` prints `No issues found!`.
2. `flutter test` passes (add unit tests where the logic is testable).
3. No edits outside your write scope.
4. Report back: files touched, what works, what is stubbed, anything the Lead
   must wire up (providers, routes, deps).
