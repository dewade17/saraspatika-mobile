import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart'; // Import package uuid

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Objek untuk membuat UUID
  static const _uuid = Uuid();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('saraspatika_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, 
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_attendance (
        id TEXT PRIMARY KEY,          -- Sekarang menggunakan TEXT untuk UUID
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,           -- 'checkin' atau 'checkout'
        location_id TEXT,             -- Digunakan saat checkin
        absensi_id TEXT,              -- Digunakan saat checkout
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        image_path TEXT NOT NULL,
        captured_at TEXT NOT NULL,    -- Timestamp ISO8601 (Penting!)
        status INTEGER DEFAULT 0      -- 0: Pending, 1: Synced
      )
    ''');
  }

  // Fungsi insert yang otomatis membuat UUID jika tidak disertakan
  Future<int> insertAttendance(Map<String, dynamic> data) async {
    final db = await instance.database;

    // Pastikan data memiliki ID berupa UUID
    final Map<String, dynamic> record = Map.from(data);
    if (!record.containsKey('id')) {
      record['id'] = _uuid.v4(); // Menghasilkan UUID v4 (Random)
    }

    return await db.insert('offline_attendance', record);
  }

  Future<List<Map<String, dynamic>>> getPendingAttendance() async {
    final db = await instance.database;
    return await db.query(
      'offline_attendance',
      where: 'status = ?',
      whereArgs: [0],
      orderBy: 'captured_at ASC',
    );
  }

  Future<int> deleteAttendance(String id) async {
    // Parameter ID sekarang TEXT
    final db = await instance.database;
    return await db.delete(
      'offline_attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
