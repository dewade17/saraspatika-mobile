import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/login/data/dto/login.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  bool _loading = false;
  String? _errorMessage;
  String? _token;
  PrivateUserData? _me;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  PrivateUserData? get me => _me;

  bool get isAuthenticated => (_token != null && _token!.trim().isNotEmpty);

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is ApiException) {
      final d = e.details;
      if (d is Map) {
        final msg = d['message'] ?? d['error'] ?? d['msg'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (e.statusCode == 401) return 'Sesi berakhir atau tidak sah.';
      if (e.statusCode == 400) return 'Permintaan tidak valid.';
      return 'Terjadi kesalahan jaringan/server.';
    }
    return 'Terjadi kesalahan: $e';
  }

  Future<bool> restoreSession() async {
    Future.microtask(() => _setLoading(true));
    try {
      final t = await _api.getToken();
      if (t == null || t.trim().isEmpty) {
        _token = null;
        _me = null;
        _errorMessage = null;
        return false;
      }

      _token = t;
      notifyListeners();

      await fetchPrivateUserData();
      _errorMessage = null;
      return true;
    } catch (_) {
      await logout();
      _errorMessage = null;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final req = LoginRequest(email: email, password: password);

      final res = await _api.post(
        Endpoints.login,
        useToken: false,
        body: req.toJson(),
      );

      if (res is! Map) {
        throw StateError('Response login tidak valid.');
      }

      final map = Map<String, dynamic>.from(
        res.map((k, v) => MapEntry(k.toString(), v)),
      );

      final loginRes = LoginResponse.fromJson(map);
      final tokenValue = loginRes.token.toString().trim();

      if (tokenValue.isEmpty) {
        throw StateError('Token tidak ditemukan.');
      }

      _token = tokenValue;
      await _api.saveToken(tokenValue);

      await fetchPrivateUserData();

      notifyListeners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<PrivateUserData?> fetchPrivateUserData() async {
    try {
      final res = await _api.get(
        Endpoints.getdataprivate,
        useToken: true,
        tokenOverride:
            _token, // Menggunakan token dari memori agar lebih cepat & pasti
      );

      if (res is Map<String, dynamic>) {
        _me = PrivateUserData.fromJson(res);
        notifyListeners();
        return _me;
      }

      if (res is Map) {
        final map = Map<String, dynamic>.from(
          res.map((k, v) => MapEntry(k.toString(), v)),
        );
        _me = PrivateUserData.fromJson(map);
        notifyListeners();
        return _me;
      }

      return null;
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await logout();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      _token = null;
      _me = null;
      _errorMessage = null;
      await _api.clearToken();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
