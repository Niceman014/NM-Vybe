/// Global, compile-time constants for NM VYBE.
class AppConstants {
  AppConstants._();

  static const String appName = 'NM VYBE';
  static const String appTagline = 'Your music. Your vibe.';
  static const String appVersion = '1.0.0';

  static const String repoUrl = 'https://github.com/Niceman014/nm_vybe';
  static const String releasesUrl = '$repoUrl/releases';
  static const String issuesUrl = '$repoUrl/issues';
  static const String versionJsonUrl =
      'https://raw.githubusercontent.com/Niceman014/nm_vybe/main/version.json';

  /// File extensions treated as audio by the desktop scanner.
  static const Set<String> audioExtensions = {
    '.mp3',
    '.m4a',
    '.m4b',
    '.aac',
    '.flac',
    '.wav',
    '.ogg',
    '.opus',
    '.wma',
    '.aiff',
    '.aif',
    '.alac',
  };

  /// Image file names considered artwork when nothing is embedded.
  static const Set<String> artworkFileNames = {
    'cover.jpg',
    'cover.jpeg',
    'cover.png',
    'folder.jpg',
    'folder.jpeg',
    'folder.png',
    'album.jpg',
    'album.png',
    'albumart.jpg',
    'albumart.png',
    'front.jpg',
    'front.png',
  };

  static const String dbFileName = 'nm_vybe.db';
  static const String artworkDirName = 'artwork';
  static const String prefsPrefix = 'nm_vybe.';

  /// Default folder names probed when auto-importing on desktop.
  static const List<String> desktopMusicFolderNames = ['Music', 'Musique', 'Música'];
}
