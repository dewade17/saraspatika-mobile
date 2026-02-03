import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/get_face.dart';
import 'package:saraspatika/feature/absensi/data/repository/get_face_repository.dart';

class GetFaceProvider extends ChangeNotifier {
  GetFaceProvider({GetFaceRepository? repository})
    : _repository = repository ?? GetFaceRepository();

  final GetFaceRepository _repository;

  bool _loading = false;
  String? _errorMessage;
  GetFace? _faceData;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  GetFace? get faceData => _faceData;

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
      if (e.statusCode == 404) return 'Data tidak ditemukan.';
      return 'Terjadi kesalahan jaringan/server.';
    }

    return 'Terjadi kesalahan: $e';
  }

  Future<GetFace?> fetchFaceData(String userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final data = await _repository.fetchFaceData(userId);
      _faceData = data;
      notifyListeners();
      return data;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
