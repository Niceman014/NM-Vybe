import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ota_update/ota_update.dart';

class UpdateInfo {
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final bool hasUpdate;

  UpdateInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.hasUpdate,
  });
}

class UpdateService {
  static const String versionApiUrl = 
      "https://raw.githubusercontent.com/Niceman014/nm_vybe/main/version.json";

  Future<UpdateInfo> checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.version;

    try {
      final response = await http.get(Uri.parse(versionApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersion = data['version'];
        final String releaseNotes = data['notes'] ?? 'General fixes and improvements.';
        final String downloadUrl = data['download_url'];

        bool isUpdateAvailable = _isVersionHigher(currentVersion, latestVersion);

        return UpdateInfo(
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          hasUpdate: isUpdateAvailable,
        );
      } else {
        throw Exception("Failed to check for updates.");
      }
    } catch (e) {
      rethrow;
    }
  }

  bool _isVersionHigher(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  Future<void> executeUpdate(String downloadUrl, Function(String status) onProgress) async {
    if (Platform.isAndroid) {
      try {
        OtaUpdate().execute(downloadUrl, destinationFilename: 'nm_vybe_update.apk').listen(
          (OtaEvent event) {
            onProgress("Downloading: ${event.value}%");
          },
          onError: (error) {
            onProgress("Update Error: $error");
          },
        );
      } catch (e) {
        await _launchURL(downloadUrl);
      }
    } else {
      await _launchURL(downloadUrl);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}