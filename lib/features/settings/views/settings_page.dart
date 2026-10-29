import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/update_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/platform_info.dart';


class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final UpdateService _updateService = UpdateService();
  String _version = '';
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      if (mounted) setState(() => _version = AppConstants.appVersion);
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checkingUpdate = true);
    try {
      final info = await _updateService.checkForUpdates();
      if (!mounted) return;
      setState(() => _checkingUpdate = false);
      if (!info.hasUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are on the latest NM VYBE.')),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Update to v${info.latestVersion}'),
          content: Text(info.releaseNotes),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateService.executeUpdate(info.downloadUrl, (status) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(status)));
                });
              },
              child: const Text('Update now'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _checkingUpdate = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update check failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final lastScan = ref.watch(lastScanTimeProvider).valueOrNull;
    final player = ref.watch(playerControllerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Settings', style: theme.textTheme.headlineSmall),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const _SectionHeader(title: 'Appearance'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) =>
                      settingsController.setThemeMode(selection.first),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < ThemeConstants.accentValues.length; i++)
                      _AccentDot(
                        color: Color(ThemeConstants.accentValues[i]),
                        selected:
                            settings.seedColorValue == ThemeConstants.accentValues[i],
                        onTap: () => settingsController
                            .setSeedColorValue(ThemeConstants.accentValues[i]),
                        tooltip: ThemeConstants.accentNames[i],
                      ),
                  ],
                ),
              ),
              if (PlatformInfo.supportsBackgroundAudio)
                SwitchListTile(
                  title: const Text('Dynamic colour'),
                  subtitle:
                      const Text('Match the accent to your wallpaper (Android 12+)'),
                  value: settings.useDynamicColor,
                  onChanged: settingsController.setUseDynamicColor,
                ),
              const Divider(height: 32),
              const _SectionHeader(title: 'Library'),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Music folders'),
                subtitle: Text(
                  settings.libraryFolders.isEmpty
                      ? 'Default music folder'
                      : '${settings.libraryFolders.length} folder(s)',
                ),
              ),
              SwitchListTile(
                title: const Text('Scan on launch'),
                subtitle: const Text('Pick up new files automatically'),
                value: settings.autoScanOnStartup,
                onChanged: settingsController.setAutoScanOnStartup,
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Last scan'),
                subtitle: Text(
                  lastScan == null ? 'Never scanned' : formatRelativeDate(lastScan),
                ),
              ),
              const Divider(height: 32),
              const _SectionHeader(title: 'Player'),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Playback speed'),
                subtitle: Text(formatPlaybackSpeed(player.speed)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSpeedSheet(context),
              ),
              ListTile(
                leading: const Icon(Icons.bedtime_outlined),
                title: const Text('Sleep timer'),
                subtitle: Text(
                  player.sleepTimerRemaining == null
                      ? 'Off'
                      : 'Stops in ${formatDuration(player.sleepTimerRemaining!)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSleepTimerSheet(context),
              ),
              const Divider(height: 32),
              const _SectionHeader(title: 'About'),
              ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: const Text('Check for updates'),
                subtitle: Text('NM VYBE v$_version'),
                trailing: _checkingUpdate
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _checkingUpdate ? null : _checkForUpdates,
              ),
              const ListTile(
                leading: Icon(Icons.code),
                title: Text('Open source'),
                subtitle: Text('Free software. No ads. No tracking.'),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _showSpeedSheet(BuildContext context) async {
    final controller = ref.read(playerControllerProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final speed in const [0.75, 1.0, 1.25, 1.5, 2.0])
              ListTile(
                title: Text(formatPlaybackSpeed(speed)),
                trailing: ref.watch(playerControllerProvider).speed == speed
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  controller.setSpeed(speed);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSleepTimerSheet(BuildContext context) async {
    final controller = ref.read(playerControllerProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final minutes in const [15, 30, 45, 60])
              ListTile(
                leading: const Icon(Icons.bedtime_outlined),
                title: Text('$minutes minutes'),
                onTap: () {
                  controller.setSleepTimer(Duration(minutes: minutes));
                  Navigator.of(context).pop();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Turn off'),
              onTap: () {
                controller.setSleepTimer(null);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.tooltip,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 3,
                  )
                : null,
          ),
          child: selected
              ? const Icon(Icons.check, size: 20, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
