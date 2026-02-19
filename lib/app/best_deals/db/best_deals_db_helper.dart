import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BestDealsDbHelper {
  static Database? _database;
  static const String _dbName = 'best_deals.db';
  static const String _listTable = 'best_deals';
  static const String _detailTable = 'best_deal_details';

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
          CREATE TABLE $_listTable (
            id INTEGER PRIMARY KEY,
            title TEXT,
            subtitle TEXT,
            media_type TEXT,
            media_path TEXT,
            media_files TEXT,
            media_types TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $_detailTable (
            id INTEGER PRIMARY KEY,
            title TEXT,
            subtitle TEXT,
            description TEXT,
            media_type TEXT,
            media_path TEXT,
            media_files TEXT,
            media_types TEXT,
            call_number TEXT,
            whatsapp_number TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  // ---- LIST operations ----

  static Future<void> saveDeals(List<dynamic> deals) async {
    final db = await database;
    final batch = db.batch();
    batch.delete(_listTable);
    for (var deal in deals) {
      batch.insert(_listTable, {
        'id': deal['id'],
        'title': deal['title'],
        'subtitle': deal['subtitle'],
        'media_type': deal['media_type'],
        'media_path': deal['media_path'],
        'media_files': deal['media_files'] != null
            ? json.encode(deal['media_files'])
            : null,
        'media_types': deal['media_types'] != null
            ? json.encode(deal['media_types'])
            : null,
        'created_at': deal['created_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getDeals() async {
    final db = await database;
    final maps = await db.query(_listTable);
    return maps.map((map) {
      return {
        ...map,
        'media_files': map['media_files'] != null
            ? json.decode(map['media_files'] as String)
            : null,
        'media_types': map['media_types'] != null
            ? json.decode(map['media_types'] as String)
            : null,
      };
    }).toList();
  }

  // ---- DETAIL operations ----

  static Future<void> saveDealDetail(Map<String, dynamic> detail) async {
    final db = await database;
    await db.insert(_detailTable, {
      'id': detail['id'],
      'title': detail['title'],
      'subtitle': detail['subtitle'],
      'description': detail['description'],
      'media_type': detail['media_type'],
      'media_path': detail['media_path'],
      'media_files': detail['media_files'] != null
          ? json.encode(detail['media_files'])
          : null,
      'media_types': detail['media_types'] != null
          ? json.encode(detail['media_types'])
          : null,
      'call_number': detail['call_number'],
      'whatsapp_number': detail['whatsapp_number'],
      'created_at': detail['created_at'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getDealDetail(int id) async {
    final db = await database;
    final maps = await db.query(
      _detailTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final map = maps.first;
    return {
      ...map,
      'media_files': map['media_files'] != null
          ? json.decode(map['media_files'] as String)
          : null,
      'media_types': map['media_types'] != null
          ? json.decode(map['media_types'] as String)
          : null,
    };
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete(_listTable);
    await db.delete(_detailTable);
  }
}
