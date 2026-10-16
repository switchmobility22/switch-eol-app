import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/local_eol_record.dart';

class EolLocalStorageService with ChangeNotifier {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'eol_station_queue.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE eol_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mac TEXT NOT NULL,
            brandId TEXT NOT NULL,
            brandName TEXT NOT NULL,
            model TEXT NOT NULL,
            name TEXT NOT NULL,
            colour TEXT NOT NULL,
            wheelSizeInches REAL NOT NULL,
            wheelCircumferenceMm INTEGER NOT NULL,
            imageAsset TEXT NOT NULL,
            assemblerId TEXT NOT NULL,
            assemblerName TEXT NOT NULL,
            stationId TEXT NOT NULL,
            initialErrorCode TEXT NOT NULL,
            qcPassed INTEGER NOT NULL,
            syncStatus TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            syncedAt TEXT
          )
        ''');
      },
    );
  }

  // Fast offline commit (< 5ms)
  Future<int> insertRecord(LocalEolRecord record) async {
    final db = await database;
    final id = await db.insert(
      'eol_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('💾 [Local SQLite] Committed EOL bike #$id (${record.mac}) in < 5ms');
    notifyListeners();
    return id;
  }

  Future<List<LocalEolRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('eol_records', orderBy: 'id DESC');
    return maps.map((m) => LocalEolRecord.fromMap(m)).toList();
  }

  Future<List<LocalEolRecord>> getPendingRecords() async {
    final db = await database;
    final maps = await db.query(
      'eol_records',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
      orderBy: 'id ASC',
    );
    return maps.map((m) => LocalEolRecord.fromMap(m)).toList();
  }

  Future<void> markRecordSynced(int id) async {
    final db = await database;
    await db.update(
      'eol_records',
      {
        'syncStatus': 'synced',
        'syncedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('✅ [Local SQLite] Marked record #$id as SYNCED to cloud');
    notifyListeners();
  }

  Future<Map<String, int>> getQueueStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM eol_records'),
        ) ??
        0;
    final pending = Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM eol_records WHERE syncStatus = "pending"'),
        ) ??
        0;
    final synced = Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM eol_records WHERE syncStatus = "synced"'),
        ) ??
        0;

    return {
      'total': total,
      'pending': pending,
      'synced': synced,
    };
  }
}
