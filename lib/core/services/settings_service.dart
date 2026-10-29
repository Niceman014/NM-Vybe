import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';

/// How the song list is ordered on the Library screen.
enum SongsSortMode {
  title('Title'),
  artist('Artist'),
  album('Album'),
  dateAdded('Date added'),
  duration('Duration');

  const SongsSortMode(this.label);
  final String label;
}

/// Everything the user can tweak. Persisted with shared_preferences.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = false,
    this.seedColorValue = ThemeConstants.defaultSeedValue,
    this.libraryFolders = const <String>[],
    this.songsSortMode = SongsSortMode.title,
    this.songsSortAscending = true,
    this.autoScanOnStartup = true,
    this.showLyricsInPlayer = true,
    this.onboardingComplete = false,
  });

  final ThemeMode themeMode;

  /// Use the Android 12+ system wallpaper palette when available.
  final bool useDynamicColor;
  final int seedColorValue;

  /// Desktop folders to scan. Empty means "detect the default music folder".
  final List<String> libraryFolders;

  final SongsSortMode songsSortMode;
  final bool songsSortAscending;
  final bool autoScanOnStartup;
  final bool showLyricsInPlayer;
  final bool onboardingComplete;

  Color get seedColor => Color(seedColorValue);

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    int? seedColorValue,
    List<String>? libraryFolders,
    SongsSortMode? songsSortMode,
    bool? songsSortAscending,
    bool? autoScanOnStartup,
    bool? showLyricsInPlayer,
    bool? onboardingComplete,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      seedColorValue: seedColorValue ?? this.seedColorValue,
      libraryFolders: libraryFolders ?? this.libraryFolders,
      songsSortMode: songsSortMode ?? this.songsSortMode,
      songsSortAscending: songsSortAscending ?? this.songsSortAscending,
      autoScanOnStartup: autoScanOnStartup ?? this.autoScanOnStartup,
      showLyricsInPlayer: showLyricsInPlayer ?? this.showLyricsInPlayer,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}

/// Reads/writes [AppSettings] and exposes them as Riverpod state.
class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static const String _themeModeKey = '${AppConstants.prefsPrefix}themeMode';
  static const String _dynamicColorKey =
      '${AppConstants.prefsPrefix}useDynamicColor';
  static const String _seedColorKey = '${AppConstants.prefsPrefix}seedColor';
  static const String _libraryFoldersKey =
      '${AppConstants.prefsPrefix}libraryFolders';
  static const String _sortModeKey = '${AppConstants.prefsPrefix}songsSortMode';
  static const String _sortAscendingKey =
      '${AppConstants.prefsPrefix}songsSortAscending';
  static const String _autoScanKey = '${AppConstants.prefsPrefix}autoScan';
  static const String _showLyricsKey = '${AppConstants.prefsPrefix}showLyrics';
  static const String _onboardingKey =
      '${AppConstants.prefsPrefix}onboardingComplete';

  static AppSettings _read(SharedPreferences prefs) {
    final themeModeName = prefs.getString(_themeModeKey);
    final sortModeName = prefs.getString(_sortModeKey);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeName,
        orElse: () => ThemeMode.system,
      ),
      useDynamicColor: prefs.getBool(_dynamicColorKey) ?? false,
      seedColorValue:
          prefs.getInt(_seedColorKey) ?? ThemeConstants.defaultSeedValue,
      libraryFolders: prefs.getStringList(_libraryFoldersKey) ?? const [],
      songsSortMode: SongsSortMode.values.firstWhere(
        (mode) => mode.name == sortModeName,
        orElse: () => SongsSortMode.title,
      ),
      songsSortAscending: prefs.getBool(_sortAscendingKey) ?? true,
      autoScanOnStartup: prefs.getBool(_autoScanKey) ?? true,
      showLyricsInPlayer: prefs.getBool(_showLyricsKey) ?? true,
      onboardingComplete: prefs.getBool(_onboardingKey) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setUseDynamicColor(bool enabled) async {
    state = state.copyWith(useDynamicColor: enabled);
    await _prefs.setBool(_dynamicColorKey, enabled);
  }

  Future<void> setSeedColorValue(int value) async {
    state = state.copyWith(seedColorValue: value);
    await _prefs.setInt(_seedColorKey, value);
  }

  Future<void> setLibraryFolders(List<String> folders) async {
    state = state.copyWith(libraryFolders: folders);
    await _prefs.setStringList(_libraryFoldersKey, folders);
  }

  Future<void> setSongsSortMode(SongsSortMode mode) async {
    state = state.copyWith(songsSortMode: mode);
    await _prefs.setString(_sortModeKey, mode.name);
  }

  Future<void> setSongsSortAscending(bool ascending) async {
    state = state.copyWith(songsSortAscending: ascending);
    await _prefs.setBool(_sortAscendingKey, ascending);
  }

  Future<void> setAutoScanOnStartup(bool enabled) async {
    state = state.copyWith(autoScanOnStartup: enabled);
    await _prefs.setBool(_autoScanKey, enabled);
  }

  Future<void> setShowLyricsInPlayer(bool enabled) async {
    state = state.copyWith(showLyricsInPlayer: enabled);
    await _prefs.setBool(_showLyricsKey, enabled);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingComplete: true);
    await _prefs.setBool(_onboardingKey, true);
  }
}
