import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/jadwal_shift.dart';
import 'package:saraspatika/feature/absensi/data/repository/jadwal_shift_repository.dart';

class JadwalShiftProvider extends ChangeNotifier {
  JadwalShiftProvider({JadwalShiftRepository? repository, ApiService? api})
    : _repository = repository ?? JadwalShiftRepository(),
      _api = api ?? ApiService();

  final JadwalShiftRepository _repository;
  final ApiService _api;

  bool _loading = false;
  String? _errorMessage;
  JadwalShift? _todayShift;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  JadwalShift? get todayShift => _todayShift;

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

  Future<String> _resolveStoredUserId() async {
    final id = await _api.getUserId();
    if (id == null || id.trim().isEmpty) {
      throw StateError('User ID tidak ditemukan. Silakan login ulang.');
    }
    return id.trim();
  }

  Future<JadwalShift?> fetchTodayShift({String? userId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final resolvedId = userId != null && userId.trim().isNotEmpty
          ? userId.trim()
          : await _resolveStoredUserId();
      final data = await _repository.fetchTodayShift(resolvedId);
      _todayShift = data;
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
