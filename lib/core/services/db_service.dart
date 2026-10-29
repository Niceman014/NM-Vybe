import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Thin wrapper around the sembast database so tests can open an in-memory
/// instance and production code opens the real file in app-support storage.
class AppDatabase {
  AppDatabase._(this.database, this.path);

  static const AppLogger _log = AppLogger('AppDatabase');

  final Database database;
  final String path;

  static Future<AppDatabase> open({String? overridePath}) async {
    final String dbPath;
    if (overridePath != null) {
      dbPath = overridePath;
    } else {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      dbPath = p.join(directory.path, AppConstants.dbFileName);
    }
    _log.d('Opening database at $dbPath');
    final database = await databaseFactoryIo.openDatabase(dbPath);
    return AppDatabase._(database, dbPath);
  }

  static Future<AppDatabase> openInMemory() async {
    final database =
        await databaseFactoryMemory.openDatabase('nm_vybe_memory.db');
    return AppDatabase._(database, 'memory:nm_vybe_memory.db');
  }

  Future<void> close() => database.close();
}
