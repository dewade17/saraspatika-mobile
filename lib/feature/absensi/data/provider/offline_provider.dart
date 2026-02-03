import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/database/database_helper.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/core/constants/endpoints.dart';

class OfflineProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final DatabaseHelper _db = DatabaseHelper.instance;

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
          imagePath: imagePath,
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
          imagePath,
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
        imagePath,
        capturedAt,
        locationId,
        absensiId,
      );
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

    for (var data in pendingData) {
      try {
        await _sendToApi(
          userId: data['user_id'],
          type: data['type'],
          lat: data['lat'],
          lng: data['lng'],
          imagePath: data['image_path'],
          capturedAt: data['captured_at'],
          locationId: data['location_id'],
          absensiId: data['absensi_id'],
        );
        // Hapus dari SQLite jika sukses terkirim
        await _db.deleteAttendance(data['id']);
      } catch (e) {
        debugPrint("Gagal sinkronisasi ID ${data['id']}: $e");
      }
    }

    _isSyncing = false;
    notifyListeners();
  }

  // Helper untuk memanggil API Flask Anda
  Future<void> _sendToApi({
    required String userId,
    required String type,
    required double lat,
    required double lng,
    required String imagePath,
    required String capturedAt,
    String? locationId,
    String? absensiId,
  }) async {
    final endpoint = type == 'checkin'
        ? "${Endpoints.baseURL}/absensi/checkin"
        : "${Endpoints.baseURL}/absensi/checkout";

    final fields = <String, String>{
      'user_id': userId,
      'lat': lat.toString(),
      'lng': lng.toString(),
      'captured_at': capturedAt,
    };

    if (locationId != null) fields['location_id'] = locationId;
    if (absensiId != null) fields['absensi_id'] = absensiId;

    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('File foto tidak ditemukan: $imagePath');
    }

    final length = await imageFile.length();

    await _api.multipart(
      endpoint,
      fields: fields,
      files: [
        ApiUploadFile.fromStream(
          fieldName: 'image',
          stream: imageFile.openRead(),
          length: length,
          filename: 'face_verify.jpg',
        ),
      ],
    );
  }
}
