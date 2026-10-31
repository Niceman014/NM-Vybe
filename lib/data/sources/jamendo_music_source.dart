import '../../core/services/jamendo_service.dart';
import 'music_source.dart';

class JamendoMusicSource implements MusicSource {
  const JamendoMusicSource(this._service);

  final JamendoService _service;

  @override
  String get id => 'jamendo';

  @override
  bool get isConfigured => _service.isConfigured;

  @override
  bool get canDownload => false;

  @override
  Future<List<MusicTrack>> search(String query, {required int page}) async {
    return _service.search(query, page: page);
  }

  @override
  Future<String?> getStreamUrl(String trackId) =>
      _service.getStreamUrl(trackId);

  @override
  DownloadTask startDownload(
    MusicTrack track, {
    required DownloadProgressCallback onProgress,
  }) => throw StateError('Jamendo is stream-only in NM VYBE.');

  @override
  String attributionFor(MusicTrack track) {
    final license = track.licenseUrl;
    final licenseText = license == null ? '' : ' License: $license';
    return '“${track.title}” by ${track.artist} via Jamendo.$licenseText';
  }

  @override
  void close() => _service.close();
}
