import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/home/data/dto/history_kehadiran.dart';
import 'package:saraspatika/feature/home/data/repository/history_kehadiran_repository.dart';

class HistoryKehadiranProvider extends ChangeNotifier {
  HistoryKehadiranProvider({
    HistoryKehadiranRepository? repository,
    ApiService? api,
  }) : _repository = repository ?? HistoryKehadiranRepository(),
       _api = api ?? ApiService();

  final HistoryKehadiranRepository _repository;
  final ApiService _api;

  bool _loading = false;
  String? _errorMessage;
  List<AttendanceData> _history = const <AttendanceData>[];

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  List<AttendanceData> get history => _history;

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
        final msg = d['message'] ?? d['error'] ?? d['msg'];
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

  Future<List<AttendanceData>> fetchHistory({
    String? userId,
    String? role,
    String? startDate,
    String? endDate,
    String? q,
    int? limit,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final data = await _repository.fetchHistory(
        userId: userId,
        role: role,
        startDate: startDate,
        endDate: endDate,
        q: q,
        limit: limit,
      );
      _history = data;
      notifyListeners();
      return _history;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<AttendanceData>> fetchMyHistory({
    String? role,
    String? startDate,
    String? endDate,
    String? q,
    int? limit,
  }) async {
    final userId = await _resolveStoredUserId();
    return fetchHistory(
      userId: userId,
      role: role,
      startDate: startDate,
      endDate: endDate,
      q: q,
      limit: limit,
    );
  }
}
