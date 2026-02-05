import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/registrasi_wajah/data/dto/enroll_face.dart';
import 'package:saraspatika/feature/registrasi_wajah/data/repository/enroll_face_repository.dart';

class EnrollFaceProvider extends ChangeNotifier {
  EnrollFaceProvider({EnrollFaceRepository? repository})
    : _repository = repository ?? EnrollFaceRepository();

  final EnrollFaceRepository _repository;

  bool _loading = false;
  String? _errorMessage;
  EnrollFace? _lastResult;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  EnrollFace? get lastResult => _lastResult;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    if (_loading == v) return;
    _loading = v;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is StateError) {
      final msg = e.message.toString().trim();
      if (msg.isNotEmpty) return msg;
    }

    if (e is ApiException) {
      final d = e.details;
      if (d is Map) {
        final msg = d['message'] ?? d['error'] ?? d['msg'] ?? d['detail'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (e.statusCode == 400) return 'Input tidak valid.';
      if (e.statusCode == 401) return 'Unauthorized.';
      if (e.statusCode == 403) return 'Tidak diizinkan.';
      if (e.statusCode == 404) return 'User tidak ditemukan.';
      return 'Terjadi kesalahan jaringan/server.';
    }

    return 'Terjadi kesalahan: $e';
  }

  Future<EnrollFace> enrollFace({
    required String userId,
    required List<Uint8List> images,
    List<String>? filenames,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final res = await _repository.enrollFace(
        userId: userId,
        images: images,
        filenames: filenames,
      );
      _lastResult = res;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
