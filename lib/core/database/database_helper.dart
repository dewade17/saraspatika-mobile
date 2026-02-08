import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart'; // Import package uuid
import 'package:saraspatika/feature/absensi/data/dto/jadwal_shift.dart';
import 'package:saraspatika/feature/absensi/data/dto/lokasi_dto.dart';

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
    await _createCachedTables(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _createCachedTables(db);
    }
  }

  Future<void> _createCachedTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_locations (
        id_lokasi TEXT PRIMARY KEY,
        nama_lokasi TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_shifts (
        id_jadwal_shift TEXT PRIMARY KEY,
        id_user TEXT NOT NULL,
        id_pola_kerja TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        nama_pola_kerja TEXT NOT NULL,
        jam_mulai_kerja TEXT NOT NULL,
        jam_selesai_kerja TEXT NOT NULL
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
    final result = await db.query(
      'offline_attendance',
      where: 'status = ?',
      whereArgs: [0],
      orderBy: 'captured_at ASC',
    );

    // Tambahkan ini untuk melihat data di debug console
    debugPrint('Data Offline di SQLite: $result');

    return result;
  }

  Future<Map<String, dynamic>?> getPendingAttendanceById(String id) async {
    final db = await instance.database;
    final rows = await db.query(
      'offline_attendance',
      where: 'id = ? AND status = ?',
      whereArgs: [id, 0],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> getPendingCheckInForUserOnDate(
    String userId,
    DateTime date,
  ) async {
    final db = await instance.database;
    final rows = await db.query(
      'offline_attendance',
      where: 'status = ? AND user_id = ? AND type = ?',
      whereArgs: [0, userId, 'checkin'],
      orderBy: 'captured_at DESC',
    );

    for (final row in rows) {
      final capturedAtRaw = row['captured_at']?.toString();
      if (capturedAtRaw == null) continue;
      final capturedAt = DateTime.tryParse(capturedAtRaw);
      if (capturedAt == null) continue;
      final localCapturedAt = capturedAt.toLocal();
      final localDate = date.toLocal();
      final sameDay =
          localCapturedAt.year == localDate.year &&
          localCapturedAt.month == localDate.month &&
          localCapturedAt.day == localDate.day;
      if (sameDay) return row;
    }

    return null;
  }

  Future<Map<String, dynamic>?> getPendingCheckOutForUserOnDate(
    String userId,
    DateTime date,
  ) async {
    final db = await instance.database;
    final rows = await db.query(
      'offline_attendance',
      where: 'status = ? AND user_id = ? AND type = ?',
      whereArgs: [0, userId, 'checkout'],
      orderBy: 'captured_at DESC',
    );

    final localDate = date.toLocal();
    for (final row in rows) {
      final capturedAtRaw = row['captured_at']?.toString();
      if (capturedAtRaw == null) continue;
      final capturedAt = DateTime.tryParse(capturedAtRaw);
      if (capturedAt == null) continue;
      final localCapturedAt = capturedAt.toLocal();
      if (DateUtils.isSameDay(localCapturedAt, localDate)) {
        return row;
      }
    }

    return null;
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

  Future<int> updatePendingCheckoutId(
    String userId,
    String oldLocalId,
    String newServerId,
  ) async {
    final db = await instance.database;
    return await db.update(
      'offline_attendance',
      {'absensi_id': newServerId},
      where: 'type = ? AND status = ? AND user_id = ? AND absensi_id = ?',
      whereArgs: ['checkout', 0, userId, oldLocalId],
    );
  }

  Future<void> cacheLocations(List<Lokasi> locations) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('cached_locations');
      final batch = txn.batch();
      for (final lokasi in locations) {
        batch.insert('cached_locations', {
          'id_lokasi': lokasi.idLokasi,
          'nama_lokasi': lokasi.namaLokasi,
          'latitude': lokasi.latitude,
          'longitude': lokasi.longitude,
          'radius': lokasi.radius,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Lokasi>> getCachedLocations() async {
    final db = await instance.database;
    final rows = await db.query('cached_locations');
    return rows
        .map(
          (row) => Lokasi(
            idLokasi: row['id_lokasi']?.toString() ?? '',
            namaLokasi: row['nama_lokasi']?.toString() ?? '',
            latitude: (row['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (row['longitude'] as num?)?.toDouble() ?? 0.0,
            radius: (row['radius'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  Future<void> cacheTodayShift(JadwalShift? shift) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('cached_shifts');
      if (shift == null) return;
      await txn.insert('cached_shifts', {
        'id_jadwal_shift': shift.idJadwalShift,
        'id_user': shift.idUser,
        'id_pola_kerja': shift.idPolaKerja,
        'tanggal': shift.tanggal.toIso8601String(),
        'nama_pola_kerja': shift.namaPolaKerja,
        'jam_mulai_kerja': shift.jamMulaiKerja.toIso8601String(),
        'jam_selesai_kerja': shift.jamSelesaiKerja.toIso8601String(),
      });
    });
  }

  Future<JadwalShift?> getCachedTodayShift() async {
    final db = await instance.database;
    final rows = await db.query('cached_shifts', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return JadwalShift(
      idJadwalShift: row['id_jadwal_shift']?.toString() ?? '',
      idUser: row['id_user']?.toString() ?? '',
      idPolaKerja: row['id_pola_kerja']?.toString() ?? '',
      tanggal: DateTime.parse(row['tanggal']?.toString() ?? ''),
      namaPolaKerja: row['nama_pola_kerja']?.toString() ?? '',
      jamMulaiKerja: DateTime.parse(row['jam_mulai_kerja']?.toString() ?? ''),
      jamSelesaiKerja: DateTime.parse(
        row['jam_selesai_kerja']?.toString() ?? '',
      ),
    );
  }
}
