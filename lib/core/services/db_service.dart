import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';
import 'app_storage.dart';

/// Thin wrapper around the sembast database so tests can open an in-memory
/// instance and production code opens the real file in app-support storage.
class AppDatabase {
  AppDatabase._(this.database, this.path);

  static const AppLogger _log = AppLogger('AppDatabase');
  static bool _storagePrepared = false;

  final Database database;
  final String path;

  /// Prepares persistent storage before preferences are loaded. Windows keys
  /// its support folder from the executable's version metadata, so move the
  /// previous com.example/nm_vybe data forward after the identity change.
  static Future<void> prepareStorage() async {
    if (_storagePrepared) return;

    final configuredDirectory = Platform.environment['NM_VYBE_DATA_DIR']
        ?.trim();
    final directory = await AppStorage.supportDirectory();

    if (Platform.isWindows &&
        (configuredDirectory == null || configuredDirectory.isEmpty)) {
      await _migrateLegacyWindowsData(directory);
    }
    _storagePrepared = true;
  }

  static Future<void> _migrateLegacyWindowsData(Directory destination) async {
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.trim().isEmpty) return;
    final legacy = Directory(p.join(appData, 'com.example', 'nm_vybe'));

    try {
      if (!await legacy.exists()) return;
      await for (final entity in legacy.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final relativePath = p.relative(entity.path, from: legacy.path);
        final target = File(p.join(destination.path, relativePath));
        if (await target.exists()) continue;
        await target.parent.create(recursive: true);
        await entity.copy(target.path);
      }
      _log.i('Migrated existing Windows app data');
    } catch (error, stackTrace) {
      // A failed legacy copy must not prevent a fresh install from opening.
      _log.w('Could not migrate legacy Windows app data', error, stackTrace);
    }
  }

  static Future<AppDatabase> open({String? overridePath}) async {
    final String dbPath;
    if (overridePath != null) {
      dbPath = overridePath;
    } else {
      await prepareStorage();
      final directory = await AppStorage.supportDirectory();
      dbPath = p.join(directory.path, AppConstants.dbFileName);
    }
    _log.d('Opening database at $dbPath');
    final database = await databaseFactoryIo.openDatabase(dbPath);
    return AppDatabase._(database, dbPath);
  }

  static Future<AppDatabase> openInMemory() async {
    final database = await databaseFactoryMemory.openDatabase(
      'nm_vybe_memory.db',
    );
    return AppDatabase._(database, 'memory:nm_vybe_memory.db');
  }

  Future<void> close() => database.close();
}
