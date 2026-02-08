import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/request_wajah/data/dto/request_wajah.dart';
import 'package:saraspatika/feature/request_wajah/data/repository/request_wajah_repository.dart';

class RequestWajahProvider extends ChangeNotifier {
  RequestWajahProvider({RequestWajahRepository? repository, ApiService? api})
    : _repository = repository ?? RequestWajahRepository(),
      _api = api ?? ApiService();

  final RequestWajahRepository _repository;
  final ApiService _api;

  bool _loading = false;
  String? _errorMessage;
  List<FaceResetRequest> _requests = const <FaceResetRequest>[];
  FaceResetRequest? _selectedRequest;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  List<FaceResetRequest> get requests => _requests;
  FaceResetRequest? get selectedRequest => _selectedRequest;

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
        final msg = d['message'] ?? d['detail'] ?? d['error'] ?? d['msg'];
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

  Future<List<FaceResetRequest>> fetchRequests({
    String? status,
    String? userId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final data = await _repository.fetchRequests(
        status: status,
        userId: userId,
      );
      _requests = data;
      notifyListeners();
      return _requests;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<FaceResetRequest>> fetchMyRequests({String? status}) async {
    final userId = await _resolveStoredUserId();
    return fetchRequests(status: status, userId: userId);
  }

  Future<FaceResetRequest?> fetchRequestById(String id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final data = await _repository.fetchRequestById(id);
      _selectedRequest = data;
      notifyListeners();
      return _selectedRequest;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<FaceResetRequest> createRequest({required String alasan}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final created = await _repository.createRequest(alasan: alasan);
      _requests = [created, ..._requests];
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<FaceResetRequest> updateRequest(
    String id, {
    String? status,
    String? adminNote,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updated = await _repository.updateRequest(
        id,
        status: status,
        adminNote: adminNote,
      );

      _selectedRequest = updated;
      _requests = _requests
          .map((req) => req.idRequest == updated.idRequest ? updated : req)
          .toList();
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteRequest(String id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.deleteRequest(id);
      _requests = _requests.where((req) => req.idRequest != id).toList();
      if (_selectedRequest?.idRequest == id) {
        _selectedRequest = null;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
