import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:saraspatika/core/database/database_helper.dart';
import 'package:saraspatika/feature/absensi/data/dto/absensi_checkin.dart';
import 'package:saraspatika/feature/absensi/data/dto/absensi_checkout.dart';
import 'package:saraspatika/feature/absensi/data/repository/absensi_repository.dart';

class OfflineProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AbsensiRepository _repository = AbsensiRepository();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // Fungsi Utama: Memutuskan simpan lokal atau kirim API
  Future<void> processAttendance({
    required String userId,
    required String type, // 'checkin' atau 'checkout'
    required double lat,
    required double lng,
    required String imagePath,
    String? locationId,
    String? absensiId,
  }) async {
    final capturedAt = DateTime.now().toIso8601String();
    final persistedImagePath = await _moveImageToDocuments(imagePath);

    // Cek koneksi internet

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        // Jika online, coba kirim langsung
        await _sendToApi(
          userId: userId,
          type: type,
          lat: lat,
          lng: lng,
          imagePath: persistedImagePath,
          capturedAt: capturedAt,
          locationId: locationId,
          absensiId: absensiId,
        );
        debugPrint("Berhasil kirim langsung (Online)");
      } catch (e) {
        // Jika gagal kirim karena gangguan jaringan mendadak, simpan ke SQLite
        await _saveLocally(
          userId,
          type,
          lat,
          lng,
          persistedImagePath,
          capturedAt,
          locationId,
          absensiId,
        );
      }
    } else {
      // Jika benar-benar offline, langsung simpan ke SQLite
      await _saveLocally(
        userId,
        type,
        lat,
        lng,
        persistedImagePath,
        capturedAt,
        locationId,
        absensiId,
      );
    }
  }

  Future<String> _moveImageToDocuments(String imagePath) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      return imagePath;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(documentsDir.path, 'attendance_images'));
    await targetDir.create(recursive: true);

    final targetPath = p.join(targetDir.path, p.basename(imagePath));
    if (p.normalize(targetPath) == p.normalize(imagePath)) {
      return imagePath;
    }

    try {
      final moved = await imageFile.rename(targetPath);
      return moved.path;
    } catch (_) {
      final copied = await imageFile.copy(targetPath);
      await imageFile.delete();
      return copied.path;
    }
  }

  Future<void> _saveLocally(
    String userId,
    String type,
    double lat,
    double lng,
    String imagePath,
    String capturedAt,
    String? locationId,
    String? absensiId,
  ) async {
    await _db.insertAttendance({
      'user_id': userId,
      'type': type,
      'lat': lat,
      'lng': lng,
      'image_path': imagePath,
      'captured_at': capturedAt,
      'location_id': locationId,
      'absensi_id': absensiId,
      'status': 0,
    });
    notifyListeners();
    debugPrint("Presensi disimpan di SQLite (Offline)");
  }

  // Fungsi Sinkronisasi: Mengirim data yang tertunda di SQLite ke Server
  Future<void> syncPendingData() async {
    if (_isSyncing) return;

    final pendingData = await _db.getPendingAttendance();
    if (pendingData.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final queue = List<Map<String, dynamic>>.from(pendingData)
        ..sort(_compareSyncQueue);

      for (final data in queue) {
        final localId = data['id']?.toString();
        if (localId == null || localId.isEmpty) {
          debugPrint('Lewati data offline tanpa id lokal: $data');
          continue;
        }

        try {
          // Selalu refresh dari SQLite sesaat sebelum kirim agar dapat ID terbaru.
          final latestData = await _db.getPendingAttendanceById(localId);
          if (latestData == null) continue;

          final response = await _sendToApi(
            userId: latestData['user_id']?.toString() ?? '',
            type: latestData['type']?.toString() ?? '',
            lat: _toDouble(latestData['lat']),
            lng: _toDouble(latestData['lng']),
            imagePath: latestData['image_path']?.toString() ?? '',
            capturedAt: latestData['captured_at']?.toString() ?? '',
            locationId: latestData['location_id']?.toString(),
            absensiId: latestData['absensi_id']?.toString(),
            correlationId: localId,
          );

          if (latestData['type']?.toString() == 'checkin') {
            final serverAbsensiId = _extractAbsensiId(response);
            if (serverAbsensiId != null && serverAbsensiId.isNotEmpty) {
              await DatabaseHelper.instance.updatePendingCheckoutId(
                latestData['user_id']?.toString() ?? '',
                localId,
                serverAbsensiId,
              );
            }
          }

          await _db.deleteAttendance(localId);
        } catch (e) {
          debugPrint("Gagal sinkronisasi ID $localId: $e");
        }
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  int _compareSyncQueue(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aUser = a['user_id']?.toString() ?? '';
    final bUser = b['user_id']?.toString() ?? '';

    if (aUser == bUser) {
      final typeCompare = _syncTypePriority(
        a['type']?.toString(),
      ).compareTo(_syncTypePriority(b['type']?.toString()));
      if (typeCompare != 0) return typeCompare;
    }

    final aCapturedAt = DateTime.tryParse(a['captured_at']?.toString() ?? '');
    final bCapturedAt = DateTime.tryParse(b['captured_at']?.toString() ?? '');
    if (aCapturedAt != null && bCapturedAt != null) {
      final capturedCompare = aCapturedAt.compareTo(bCapturedAt);
      if (capturedCompare != 0) return capturedCompare;
    } else if (aCapturedAt != null) {
      return -1;
    } else if (bCapturedAt != null) {
      return 1;
    }

    return (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? '');
  }

  int _syncTypePriority(String? type) {
    if (type == 'checkin') return 0;
    if (type == 'checkout') return 1;
    return 2;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String? _extractAbsensiId(Map<String, dynamic> response) {
    final direct = response['absensi_id']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final data = response['data'];
    if (data is Map) {
      final nested = data['absensi_id']?.toString();
      if (nested != null && nested.isNotEmpty) return nested;
    }
    return null;
  }

  Future<Map<String, dynamic>> _sendToApi({
    required String userId,
    required String type,
    required double lat,
    required double lng,
    required String imagePath,
    required String capturedAt,
    String? locationId,
    String? absensiId,
    String? correlationId,
  }) async {
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('File foto tidak ditemukan: $imagePath');
    }

    if (type == 'checkin') {
      final safeLocationId = locationId?.trim() ?? '';
      if (safeLocationId.isEmpty) {
        throw StateError('location_id checkin kosong.');
      }

      return _repository.checkIn(
        request: CheckInRequest(
          userId: userId,
          locationId: safeLocationId,
          lat: lat,
          lng: lng,
          capturedAt: capturedAt,
          correlationId: correlationId,
        ),
        imageFile: imageFile,
      );
    }

    if (type == 'checkout') {
      final safeLocationId = locationId?.trim() ?? '';
      final safeAbsensiId = absensiId?.trim() ?? '';
      if (safeLocationId.isEmpty) {
        throw StateError('location_id checkout kosong.');
      }
      if (safeAbsensiId.isEmpty) {
        throw StateError('absensi_id checkout kosong.');
      }

      return _repository.checkOut(
        request: CheckOutRequest(
          userId: userId,
          absensiId: safeAbsensiId,
          locationId: safeLocationId,
          lat: lat,
          lng: lng,
          capturedAt: capturedAt,
          correlationId: correlationId,
        ),
        imageFile: imageFile,
      );
    }

    throw StateError('Tipe absensi tidak valid: $type');
  }
}
