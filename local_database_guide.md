# Local Database (SQLite) in Flutter - Integration Guide

## What is SQLite in Flutter?

SQLite is a local database that stores data **inside the user's phone**. Even if internet is OFF, the app can show data from SQLite.

```
WITHOUT SQLite (Current approach):
  Open app -> Call API -> Wait for internet -> Show data
  No internet? -> Error / blank screen

WITH SQLite:
  Open app -> Show data from local DB (INSTANT) -> Call API in background -> Update local DB
  No internet? -> Still shows last saved data
```

---

## When to Use SQLite vs When NOT to Use

| Use SQLite | Don't Use SQLite |
|------------|-----------------|
| Data that user needs offline (products, deals, news) | Real-time data (live chat, live tracking) |
| Data that doesn't change frequently | Data that changes every second |
| Large lists that take time to load | Small one-time API calls (login, OTP) |
| Caching API responses for faster loading | Form submissions (create, update, delete) |
| User's personal data (profile, favorites, cart) | Data that MUST be fresh every time |

### Best Deals Example:
```
Best Deals list changes rarely (admin adds/edits occasionally)
-> Good candidate for SQLite caching
-> Show cached data instantly, refresh from API in background
```

---

## Package: sqflite

```yaml
# pubspec.yaml
dependencies:
  sqflite: ^2.3.0        # SQLite database
  path: ^1.8.3            # To get database file path
```

```bash
flutter pub get
```

---

## Folder Structure (WITH local database)

```
lib/app/best_deals/
    |
    ├── model/
    |   ├── best_deals_list_model.dart       # Same as before (API parsing)
    |   └── best_deal_detail_model.dart      # Same as before (API parsing)
    |
    ├── controller/
    |   └── best_deals_controller.dart       # Modified: API + DB logic
    |
    ├── view/
    |   ├── best_deals_screen.dart           # Same as before (no changes)
    |   └── best_deal_detail_screen.dart     # Same as before (no changes)
    |
    └── db/                                  # NEW FOLDER
        └── best_deals_db_helper.dart        # NEW FILE: SQLite operations
```

**Key Point:** Screens don't change at all. Only Controller and a new DB helper file change.

---

## Architecture Comparison

### WITHOUT SQLite (Current - 3 layers):
```
Screen (UI)  <-->  Controller  <-->  API Server
                      |
                      v
                 Model.fromJson()
```

### WITH SQLite (4 layers):
```
Screen (UI)  <-->  Controller  <-->  API Server
                      |
                      v
                  DB Helper  <-->  SQLite (local phone storage)
                      |
                      v
                 Model.fromJson() / Model.toMap()
```

---

## The New File: DB Helper (`best_deals_db_helper.dart`)

### What does it do?
- Creates the SQLite table (like creating a table in MySQL)
- Saves API data to local database
- Reads data from local database
- Deletes old data when new data comes from API

### SQLite vs MySQL Comparison:
```
MySQL (Server):                    SQLite (Phone):
- Runs on server                   - Runs inside the app
- Accessed via API                 - Accessed directly with Dart code
- Shared by all users              - Private to each user's phone
- CREATE TABLE (same)              - CREATE TABLE (same SQL syntax)
- INSERT, SELECT, UPDATE (same)    - INSERT, SELECT, UPDATE (same SQL syntax)
```

### Complete Code:

```dart
// lib/app/best_deals/db/best_deals_db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BestDealsDbHelper {
  static Database? _database;
  static const String tableName = 'best_deals';
  static const String detailTableName = 'best_deal_details';

  // ============================================================
  // 1. GET DATABASE (Create if not exists)
  // ============================================================
  // This is like connecting to MySQL, but it's a file on the phone
  // First time: creates the database file + tables
  // After that: just opens the existing file

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    // Get the phone's database directory path
    // Android: /data/data/com.yourapp/databases/
    // iOS: Documents directory
    String path = join(await getDatabasesPath(), 'best_deals.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // ============================================================
        // 2. CREATE TABLES (runs only first time)
        // ============================================================
        // This is exactly like MySQL CREATE TABLE

        // Table for LIST items
        await db.execute('''
          CREATE TABLE $tableName (
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
        // NOTE: media_files and media_types are stored as JSON strings
        // because SQLite doesn't have JSON/Array column type
        // We convert: List<String> -> JSON string (to save)
        //             JSON string -> List<String> (to read)

        // Table for DETAIL items (has extra columns)
        await db.execute('''
          CREATE TABLE $detailTableName (
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

  // ============================================================
  // 3. SAVE LIST DATA (Insert/Replace all deals)
  // ============================================================
  // Called after API returns list data successfully
  // Deletes old data and inserts fresh data

  static Future<void> saveDeals(List<Map<String, dynamic>> deals) async {
    final db = await database;

    // Use a batch for better performance (like MySQL transaction)
    final batch = db.batch();

    // Delete all old records first
    batch.delete(tableName);

    // Insert each deal
    for (var deal in deals) {
      batch.insert(
        tableName,
        {
          'id': deal['id'],
          'title': deal['title'],
          'subtitle': deal['subtitle'],
          'media_type': deal['media_type'],
          'media_path': deal['media_path'],
          // Convert List to JSON string for storage
          // ['image1.jpg', 'image2.jpg'] -> '["image1.jpg","image2.jpg"]'
          'media_files': deal['media_files'] != null
              ? _listToJson(deal['media_files'])
              : null,
          'media_types': deal['media_types'] != null
              ? _listToJson(deal['media_types'])
              : null,
          'created_at': deal['created_at'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // ============================================================
  // 4. GET LIST DATA (Read from local DB)
  // ============================================================
  // Called when app opens or when there's no internet

  static Future<List<Map<String, dynamic>>> getDeals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    // Convert JSON strings back to Lists
    return maps.map((map) {
      return {
        ...map,
        'media_files': map['media_files'] != null
            ? _jsonToList(map['media_files'] as String)
            : null,
        'media_types': map['media_types'] != null
            ? _jsonToList(map['media_types'] as String)
            : null,
      };
    }).toList();
  }

  // ============================================================
  // 5. SAVE DETAIL DATA
  // ============================================================
  // Called after detail API returns successfully

  static Future<void> saveDealDetail(Map<String, dynamic> detail) async {
    final db = await database;
    await db.insert(
      detailTableName,
      {
        'id': detail['id'],
        'title': detail['title'],
        'subtitle': detail['subtitle'],
        'description': detail['description'],
        'media_type': detail['media_type'],
        'media_path': detail['media_path'],
        'media_files': detail['media_files'] != null
            ? _listToJson(detail['media_files'])
            : null,
        'media_types': detail['media_types'] != null
            ? _listToJson(detail['media_types'])
            : null,
        'call_number': detail['call_number'],
        'whatsapp_number': detail['whatsapp_number'],
        'created_at': detail['created_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,  // Update if exists
    );
  }

  // ============================================================
  // 6. GET DETAIL DATA
  // ============================================================

  static Future<Map<String, dynamic>?> getDealDetail(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      detailTableName,
      where: 'id = ?',       // Like MySQL: SELECT * FROM details WHERE id = ?
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return {
      ...map,
      'media_files': map['media_files'] != null
          ? _jsonToList(map['media_files'] as String)
          : null,
      'media_types': map['media_types'] != null
          ? _jsonToList(map['media_types'] as String)
          : null,
    };
  }

  // ============================================================
  // 7. DELETE ALL DATA (for logout or cache clear)
  // ============================================================

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableName);
    await db.delete(detailTableName);
  }

  // ============================================================
  // HELPER: Convert between List and JSON string
  // ============================================================
  // SQLite can't store arrays, so we convert:
  //   Save: ['a', 'b'] -> '["a","b"]'
  //   Read: '["a","b"]' -> ['a', 'b']

  static String _listToJson(List list) {
    return list.toString();
    // Or use: import 'dart:convert'; json.encode(list);
  }

  static List<String> _jsonToList(String jsonStr) {
    // Remove brackets and split
    // '["a","b"]' -> ['a', 'b']
    try {
      // Using dart:convert for proper parsing
      // import 'dart:convert';
      // return List<String>.from(json.decode(jsonStr));

      // Simple approach without import:
      String cleaned = jsonStr.replaceAll('[', '').replaceAll(']', '');
      if (cleaned.isEmpty) return [];
      return cleaned.split(',').map((e) => e.trim()).toList();
    } catch (e) {
      return [];
    }
  }
}
```

---

## How Controller Changes (WITH SQLite)

### WITHOUT SQLite (Current):
```dart
fetchList() {
  isLoading = true;
  response = await API call;
  data = parse JSON;          // Only source of data
  isLoading = false;
}
```

### WITH SQLite (New approach):
```dart
fetchList() {
  isLoading = true;

  // STEP 1: Load from local DB first (INSTANT, no internet needed)
  localData = await DB.getDeals();
  if (localData.isNotEmpty) {
    data = localData;          // Show cached data immediately
    isLoading = false;         // User sees data instantly!
  }

  // STEP 2: Fetch from API in background (to get fresh data)
  try {
    response = await API call;
    freshData = parse JSON;
    data = freshData;          // Update UI with fresh data

    // STEP 3: Save fresh data to local DB (for next time)
    await DB.saveDeals(freshData);
  } catch (e) {
    // API failed? No problem! User already sees cached data
    if (localData.isEmpty) {
      show error;              // Only show error if no cached data either
    }
  }
}
```

### Complete Modified Controller Code:

```dart
// best_deals_controller.dart (WITH SQLite version)

import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/best_deals/model/best_deal_detail_model.dart';
import 'package:seedsuser/app/best_deals/model/best_deals_list_model.dart';
import 'package:seedsuser/app/best_deals/db/best_deals_db_helper.dart';  // NEW
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class BestDealsController extends GetxController {
  var isLoading = true.obs;
  var isDetailLoading = true.obs;
  Rx<BestDealsListModel?> bestDealsData = Rx<BestDealsListModel?>(null);
  Rx<BestDealDetailModel?> bestDealDetail = Rx<BestDealDetailModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchList();
  }

  Future<void> fetchList() async {
    try {
      isLoading.value = true;

      // ========== NEW: Step 1 - Load from local DB first ==========
      final cachedDeals = await BestDealsDbHelper.getDeals();
      if (cachedDeals.isNotEmpty) {
        // Convert cached maps to model (reuse same fromJson)
        bestDealsData.value = BestDealsListModel.fromJson({
          'status': true,
          'message': 'From cache',
          'data': cachedDeals,
        });
        isLoading.value = false;  // Show cached data immediately
      }

      // ========== Step 2 - Fetch fresh data from API ==========
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/best-deals",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        bestDealsData.value = BestDealsListModel.fromJson(data);

        // ========== NEW: Step 3 - Save fresh data to local DB ==========
        if (data['data'] != null && data['data'] is List) {
          await BestDealsDbHelper.saveDeals(
            List<Map<String, dynamic>>.from(data['data']),
          );
        }
      } else {
        if (cachedDeals.isEmpty) {
          CustomToast.error("Failed to fetch Best Deals");
        }
      }
    } catch (e) {
      // API failed but we might have cached data - that's OK
      final cachedDeals = await BestDealsDbHelper.getDeals();
      if (cachedDeals.isEmpty) {
        CustomToast.error("Something went wrong");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDetail(String id) async {
    try {
      isDetailLoading.value = true;

      // ========== NEW: Step 1 - Load from local DB first ==========
      final cachedDetail = await BestDealsDbHelper.getDealDetail(int.parse(id));
      if (cachedDetail != null) {
        bestDealDetail.value = BestDealDetailModel.fromJson({
          'status': true,
          'message': 'From cache',
          'data': cachedDetail,
        });
        isDetailLoading.value = false;
      }

      // ========== Step 2 - Fetch from API ==========
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/best-deals/$id",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        bestDealDetail.value = BestDealDetailModel.fromJson(data);

        // ========== NEW: Step 3 - Save to local DB ==========
        if (data['data'] != null) {
          await BestDealsDbHelper.saveDealDetail(
            Map<String, dynamic>.from(data['data']),
          );
        }
      } else {
        if (cachedDetail == null) {
          CustomToast.error("Failed to fetch details");
        }
      }
    } catch (e) {
      final cachedDetail = await BestDealsDbHelper.getDealDetail(int.parse(id));
      if (cachedDetail == null) {
        CustomToast.error("Something went wrong");
      }
    } finally {
      isDetailLoading.value = false;
    }
  }
}
```

---

## Data Flow Comparison

### WITHOUT SQLite:
```
User opens app
    |
    v
Controller calls API -----> Waiting... (shimmer shows)
    |                           |
    v                           v
No internet?              Got response?
    |                           |
    v                           v
ERROR! Blank screen       Parse JSON -> Show data
```

### WITH SQLite:
```
User opens app
    |
    v
Controller reads local DB -----> Has cached data?
    |                                  |
    |                             YES  |  NO
    |                              |   |   |
    |                              v   |   v
    |                         Show cached  Show shimmer
    |                         data (INSTANT)
    |
    v
Controller calls API (in background)
    |
    |-----> Got response?
    |           |
    |      YES  |  NO (no internet)
    |       |   |   |
    |       v   |   v
    |   Update UI   Already showing cached data!
    |   Save to DB  User doesn't even notice
    |
    v
Next time user opens app -> Cached data shows instantly
```

---

## Model Changes: Adding toMap()

For SQLite, models need a `toMap()` method (opposite of `fromJson()`):

```dart
// fromJson: JSON (from API) -> Dart Object    (READING)
// toMap:    Dart Object -> Map (for SQLite)    (SAVING)

class BestDealItem {
  int? id;
  String? title;
  // ... other fields

  // Already exists - reads from JSON/Map
  factory BestDealItem.fromJson(Map<String, dynamic> json) { ... }

  // NEW - converts object to Map for saving to SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'media_type': mediaType,
      'media_path': mediaPath,
      'media_files': mediaFiles,   // DB helper will convert List to JSON string
      'media_types': mediaTypes,
      'created_at': createdAt,
    };
  }
}
```

**But in our approach**, we save the raw API JSON maps directly to DB, so we don't even need `toMap()`. We just pass `data['data']` (which is already a `List<Map>`) to the DB helper.

---

## SQLite Operations = SQL Queries

If you know MySQL, you already know SQLite:

| Operation | MySQL | SQLite (sqflite) |
|-----------|-------|-------------------|
| Create table | `CREATE TABLE deals (...)` | `db.execute('CREATE TABLE deals (...)')` |
| Insert | `INSERT INTO deals VALUES (...)` | `db.insert('deals', map)` |
| Select all | `SELECT * FROM deals` | `db.query('deals')` |
| Select one | `SELECT * FROM deals WHERE id = 1` | `db.query('deals', where: 'id = ?', whereArgs: [1])` |
| Update | `UPDATE deals SET title = 'new' WHERE id = 1` | `db.update('deals', map, where: 'id = ?', whereArgs: [1])` |
| Delete | `DELETE FROM deals WHERE id = 1` | `db.delete('deals', where: 'id = ?', whereArgs: [1])` |
| Delete all | `DELETE FROM deals` | `db.delete('deals')` |
| Count | `SELECT COUNT(*) FROM deals` | `Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM deals'))` |

---

## Where is the Database Stored?

```
Android: /data/data/com.example.seedsuser/databases/best_deals.db
iOS:     <app_directory>/Documents/best_deals.db

- User CANNOT see this file (it's in app's private storage)
- Deleted when app is uninstalled
- NOT shared between apps
- NOT backed up to Google Drive / iCloud (by default)
```

---

## Common Patterns

### Pattern 1: Cache First, API Second (Best for lists)
```dart
// Show cached data instantly, then refresh from API
fetchList() {
  cached = await DB.getAll();
  if (cached.isNotEmpty) show(cached);    // Instant!
  fresh = await API.getAll();
  show(fresh);                            // Update
  DB.saveAll(fresh);                      // Cache for next time
}
```

### Pattern 2: API First, Cache as Fallback (Best for detail pages)
```dart
// Try API first, fall back to cache if offline
fetchDetail(id) {
  try {
    fresh = await API.get(id);
    show(fresh);
    DB.save(fresh);
  } catch (e) {
    cached = await DB.get(id);
    if (cached != null) show(cached);     // Offline fallback
    else showError();
  }
}
```

### Pattern 3: Cache Only with Periodic Sync (Best for rarely changing data)
```dart
// Only call API once per day, rest of the time use cache
fetchList() {
  lastSync = await getLastSyncTime();
  if (DateTime.now().difference(lastSync).inHours < 24) {
    cached = await DB.getAll();
    show(cached);                         // Use cache (less than 24hrs old)
    return;
  }
  fresh = await API.getAll();             // Refresh after 24hrs
  show(fresh);
  DB.saveAll(fresh);
  saveLastSyncTime(DateTime.now());
}
```

---

## Alternative: get_storage (Simpler, for small data)

If you don't need SQL queries and just want to cache API responses:

```yaml
# Already in your project!
dependencies:
  get_storage: ^2.1.1
```

```dart
// Much simpler than SQLite - just key-value storage
import 'package:get_storage/get_storage.dart';

final box = GetStorage();

// Save entire API response as JSON string
box.write('best_deals_list', response.body);

// Read it back
String? cached = box.read('best_deals_list');
if (cached != null) {
  final data = json.decode(cached);
  bestDealsData.value = BestDealsListModel.fromJson(data);
}
```

### When to use which?

| Feature | get_storage | SQLite (sqflite) |
|---------|-------------|------------------|
| Setup complexity | Very simple | More setup needed |
| Store full API response | Good | Overkill |
| Query specific items | Not possible | `WHERE id = ?`, `ORDER BY`, etc. |
| Store 10-50 items | Good | Good |
| Store 1000+ items | Slow | Fast (indexed) |
| Search/filter locally | Not possible | Full SQL support |
| Multiple tables | Messy | Clean |
| Relationships (joins) | Not possible | Supported |

**Recommendation for Best Deals:** `get_storage` is enough (small data, simple caching).
Use SQLite only if you need to search/filter/sort locally without API.

---

## Complete Flow WITH SQLite

```
=============================================
App Opens -> Home Screen
=============================================
        |
        v
User taps "Best Deals"
        |
        v
=============================================
BestDealsScreen created
  -> Get.put(BestDealsController())
  -> onInit() -> fetchList()
=============================================
        |
        v
=============================================
fetchList() - STEP 1: Read Local DB
=============================================
  DB.getDeals()
    -> SELECT * FROM best_deals
    -> Returns cached rows (or empty if first time)
        |
        |-- Has cached data?
        |     YES -> bestDealsData.value = cached
        |            isLoading = false (show list instantly!)
        |     NO  -> Keep showing shimmer
        |
        v
=============================================
fetchList() - STEP 2: Call API
=============================================
  GET /farmer/best-deals
    -> Server returns JSON
    -> json.decode() -> BestDealsListModel.fromJson()
    -> bestDealsData.value = freshData
    -> Obx() rebuilds UI with fresh data
        |
        v
=============================================
fetchList() - STEP 3: Save to Local DB
=============================================
  DB.saveDeals(freshData)
    -> DELETE FROM best_deals (clear old)
    -> INSERT INTO best_deals VALUES (...) (save new)
    -> Next time app opens, this data loads instantly
        |
        v
=============================================
User taps a card -> Detail Screen
=============================================
  BestDealDetailScreen(id: "1", title: "Fish Foods", ...)
    -> initState() -> fetchDetail("1")
        |
        v
=============================================
fetchDetail() - Same pattern
=============================================
  1. Read from detail DB (instant)
  2. Call detail API (background)
  3. Save to detail DB (for next time)
        |
        v
=============================================
User sees: Title + Image (instant from constructor)
           Description (from cache or API)
           Enquiry + WhatsApp buttons (active when data loads)
=============================================
```

---

## Summary: What Changes When Adding SQLite

| Layer | Without SQLite | With SQLite |
|-------|---------------|-------------|
| **Models** | `fromJson()` only | Same (optionally add `toMap()`) |
| **DB Helper** | Does not exist | NEW file with CRUD operations |
| **Controller** | API only | API + DB (load cache first, save after API) |
| **Screens** | No changes | No changes at all |
| **pubspec.yaml** | No sqflite | Add `sqflite` + `path` packages |

**The screens never know whether data came from API or SQLite. They just read from the controller's observable variables. This is the power of separation of concerns.**
