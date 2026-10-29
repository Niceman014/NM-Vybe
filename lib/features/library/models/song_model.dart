import 'package:path/path.dart' as p;

/// A single audio track in the local library.
///
/// [id] is a stable hash of the canonical file path so re-scanning the same
/// folder updates rows instead of duplicating them.
class Song {
  const Song({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtist,
    required this.duration,
    required this.fileSize,
    required this.addedAt,
    this.genre,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.modifiedAt,
    this.playCount = 0,
    this.lastPlayedAt,
    this.isFavorite = false,
    this.artworkKey,
  });

  final String id;
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final Duration duration;
  final int fileSize;
  final DateTime addedAt;
  final DateTime? modifiedAt;
  final int playCount;
  final DateTime? lastPlayedAt;
  final bool isFavorite;

  /// Identifier for the cached artwork file (album level), if any.
  final String? artworkKey;

  String get displayTitle =>
      title.trim().isEmpty ? p.basenameWithoutExtension(filePath) : title.trim();

  String get displayArtist =>
      artist.trim().isEmpty ? 'Unknown artist' : artist.trim();

  String get displayAlbum => album.trim().isEmpty ? 'Unknown album' : album.trim();

  String get displayAlbumArtist {
    final value = albumArtist.trim().isEmpty ? artist.trim() : albumArtist.trim();
    return value.isEmpty ? 'Unknown artist' : value;
  }

  bool get hasArtwork => artworkKey != null && artworkKey!.isNotEmpty;

  /// Key used to group tracks into albums.
  String get albumGroupKey =>
      '${displayAlbumArtist.toLowerCase()}::${displayAlbum.toLowerCase()}';

  Song copyWith({
    String? id,
    String? filePath,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    int? year,
    int? trackNumber,
    int? discNumber,
    Duration? duration,
    int? fileSize,
    DateTime? addedAt,
    DateTime? modifiedAt,
    int? playCount,
    DateTime? lastPlayedAt,
    bool? isFavorite,
    String? artworkKey,
    bool clearArtwork = false,
  }) {
    return Song(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      addedAt: addedAt ?? this.addedAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      artworkKey: clearArtwork ? null : (artworkKey ?? this.artworkKey),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'filePath': filePath,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArtist': albumArtist,
      'genre': genre,
      'year': year,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'durationMs': duration.inMilliseconds,
      'fileSize': fileSize,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'modifiedAt': modifiedAt?.millisecondsSinceEpoch,
      'playCount': playCount,
      'lastPlayedAt': lastPlayedAt?.millisecondsSinceEpoch,
      'isFavorite': isFavorite,
      'artworkKey': artworkKey,
    };
  }

  factory Song.fromMap(Map<Object?, Object?> map) {
    final durationMs = _asInt(map['durationMs']);
    final addedAtMs = _asInt(map['addedAt']);
    final modifiedAtMs = _asInt(map['modifiedAt']);
    final lastPlayedAtMs = _asInt(map['lastPlayedAt']);
    return Song(
      id: _asString(map['id']),
      filePath: _asString(map['filePath']),
      title: _asString(map['title']),
      artist: _asString(map['artist']),
      album: _asString(map['album']),
      albumArtist: _asString(map['albumArtist']),
      genre: _asNullableString(map['genre']),
      year: _asNullableInt(map['year']),
      trackNumber: _asNullableInt(map['trackNumber']),
      discNumber: _asNullableInt(map['discNumber']),
      duration: Duration(milliseconds: durationMs ?? 0),
      fileSize: _asInt(map['fileSize']) ?? 0,
      addedAt: addedAtMs == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(addedAtMs),
      modifiedAt: modifiedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(modifiedAtMs),
      playCount: _asInt(map['playCount']) ?? 0,
      lastPlayedAt: lastPlayedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastPlayedAtMs),
      isFavorite: map['isFavorite'] == true,
      artworkKey: _asNullableString(map['artworkKey']),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static int? _asNullableInt(Object? value) => _asInt(value);

  static String _asString(Object? value) => value?.toString() ?? '';

  static String? _asNullableString(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song($id, $displayTitle, $displayArtist)';
}
