import 'dart:io';

import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/absensi_checkin.dart';
import 'package:saraspatika/feature/absensi/data/dto/absensi_checkout.dart';
import 'package:saraspatika/feature/absensi/data/dto/absensi_status.dart';

class AbsensiRepository {
  AbsensiRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<Map<String, dynamic>> checkIn({
    required CheckInRequest request,
    required File imageFile,
  }) async {
    await _ensureFileExists(imageFile, 'Foto check-in tidak ditemukan.');

    final res = await _api.multipart(
      _buildCheckInUrl(),
      fields: request.toFormFields(),
      files: [
        ApiUploadFile.fromBytes(
          fieldName: 'image',
          bytes: await imageFile.readAsBytes(),
          filename: _filenameFromPath(imageFile.path, fallback: 'checkin.jpg'),
        ),
      ],
      useToken: true,
    );

    return _asJsonMap(res);
  }

  Future<Map<String, dynamic>> checkOut({
    required CheckOutRequest request,
    required File imageFile,
  }) async {
    await _ensureFileExists(imageFile, 'Foto check-out tidak ditemukan.');

    final res = await _api.multipart(
      _buildCheckOutUrl(),
      fields: request.toFormFields(),
      files: [
        ApiUploadFile.fromBytes(
          fieldName: 'image',
          bytes: await imageFile.readAsBytes(),
          filename: _filenameFromPath(imageFile.path, fallback: 'checkout.jpg'),
        ),
      ],
      useToken: true,
    );

    return _asJsonMap(res);
  }

  Future<AbsensiStatus> fetchStatus({required String userId}) async {
    final res = await _api.get(
      _buildStatusUrl(),
      queryParameters: {'user_id': userId},
      useToken: true,
    );

    final json = _asJsonMap(res);
    return AbsensiStatus.fromMap(json);
  }

  String _buildCheckInUrl() => Endpoints.absensiCheckin;

  String _buildCheckOutUrl() => Endpoints.absensiCheckout;

  String _buildStatusUrl() => Endpoints.statusAbsensi;

  Future<void> _ensureFileExists(File file, String message) async {
    if (!await file.exists()) {
      throw StateError(message);
    }
  }

  String _filenameFromPath(String path, {required String fallback}) {
    final name = path.split('/').last.trim();
    return name.isEmpty ? fallback : name;
  }

  Map<String, dynamic> _asJsonMap(Object? res) {
    if (res is Map<String, dynamic>) return res;
    if (res is Map) {
      return Map<String, dynamic>.from(
        res.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    throw StateError('Response tidak valid: ${res.runtimeType}');
  }
}
