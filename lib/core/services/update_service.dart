import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Routes users to the platform store that owns app installation and updates.
/// Store-managed updates avoid installing binaries from a public custom feed.
class UpdateService {
  Future<void> openStoreUpdates() async {
    final Uri uri;
    if (Platform.isAndroid) {
      final packageInfo = await PackageInfo.fromPlatform();
      uri = Uri.https(
        'play.google.com',
        '/store/apps/details',
        <String, String>{'id': packageInfo.packageName},
      );
    } else if (Platform.isWindows) {
      uri = Uri.parse('ms-windows-store://downloadsandupdates');
    } else {
      throw UnsupportedError(
        'Store updates are not configured for this platform.',
      );
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw StateError('Could not open the platform store.');
    }
  }
}
