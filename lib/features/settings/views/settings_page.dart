import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/update_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UpdateService _updateService = UpdateService();
  bool _isChecking = false;
  String _currentVersion = "";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = info.version;
    });
  }

  Future<void> _handleCheckForUpdates() async {
    setState(() => _isChecking = true);

    try {
      final updateInfo = await _updateService.checkForUpdates();
      setState(() => _isChecking = false);

      if (!mounted) return;

      if (updateInfo.hasUpdate) {
        _showUpdateDialog(updateInfo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("NM VYBE is already up to date!")),
        );
      }
    } catch (e) {
      setState(() => _isChecking = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error checking for updates: $e")),
      );
    }
  }

  void _showUpdateDialog(UpdateInfo updateInfo) {
    String downloadStatus = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text("Update Available: v${updateInfo.latestVersion}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("What's New:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(updateInfo.releaseNotes),
                if (downloadStatus.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(downloadStatus, style: const TextStyle(color: Colors.blueAccent)),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Later"),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateService.executeUpdate(
                    updateInfo.downloadUrl,
                    (status) {
                      setModalState(() {
                        downloadStatus = status;
                      });
                    },
                  );
                },
                child: const Text("Update Now"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.palette),
            title: Text("Appearance"),
            subtitle: Text("Customize accent colors and dynamic theme"),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text("Check for Updates"),
            subtitle: Text("Current Version: v$_currentVersion"),
            trailing: _isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isChecking ? null : _handleCheckForUpdates,
          ),
        ],
      ),
    );
  }
}