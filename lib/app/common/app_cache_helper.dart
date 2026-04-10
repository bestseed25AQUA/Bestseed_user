import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppCacheHelper {
  static Database? _database;
  static const String _dbName = 'app_cache.db';
  static const String _table = 'api_cache';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            cache_key TEXT PRIMARY KEY,
            response TEXT,
            cached_at INTEGER
          )
        ''');
      },
    );
  }

  static Future<void> save(String key, String jsonResponse) async {
    final db = await database;
    await db.insert(
      _table,
      {
        'cache_key': key,
        'response': jsonResponse,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> get(String key) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'cache_key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['response'] as String?;
  }

  /// Same as `get()` but ignores entries older than `maxAge`. Use this for
  /// API responses that must not be served stale (e.g. Google Directions
  /// results — we want a 24 h freshness window so a recomputed road or a
  /// changed pickup location eventually overrides the cache).
  ///
  /// Stale rows are deleted opportunistically on miss so the table doesn't
  /// grow unbounded over the lifetime of the app.
  static Future<String?> getFresh(String key, Duration maxAge) async {
    final db = await database;
    final maps = await db.query(
      _table,
      where: 'cache_key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    final cachedAt = (maps.first['cached_at'] as int?) ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    if (age > maxAge.inMilliseconds) {
      await db.delete(_table, where: 'cache_key = ?', whereArgs: [key]);
      return null;
    }
    return maps.first['response'] as String?;
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }
}
