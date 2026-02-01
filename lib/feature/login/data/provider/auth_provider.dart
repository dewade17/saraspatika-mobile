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
        final msg = d['detail'] ?? d['message'] ?? d['error'] ?? d['msg'];

        if (msg != null && msg.toString().trim().isNotEmpty) {
          if (msg.toString() == 'Invalid credentials') {
            return 'Email atau password salah.';
          }
          return msg.toString();
        }
      }

      if (e.statusCode == 400) return 'Input tidak valid.';
      if (e.statusCode == 401) {
        return 'Email atau password salah.';
      }
      if (e.statusCode == 404) return 'Data tidak ditemukan.';
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

      await fetchPrivateUserData(); // ini sekarang juga menyimpan id_user
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
        throw StateError('Response login tidak valid: ${res.runtimeType}');
      }

      final map = Map<String, dynamic>.from(
        res.map((k, v) => MapEntry(k.toString(), v)),
      );

      final parsed = LoginResponse.fromJson(map);
      final tokenValue = parsed.token.trim();
      if (tokenValue.isEmpty) {
        throw StateError('Token tidak ditemukan dari response login.');
      }

      _token = tokenValue;
      await _api.saveToken(tokenValue);

      final me = await fetchPrivateUserData(); // persist permissions + id_user
      if (me != null && me.idUser.trim().isNotEmpty) {
        try {
          await _api.saveUserId(me.idUser);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to persist id_user: $e');
          }
        }
      }

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
        tokenOverride: _token,
      );

      Map<String, dynamic>? map;
      if (res is Map<String, dynamic>) {
        map = res;
      } else if (res is Map) {
        map = Map<String, dynamic>.from(
          res.map((k, v) => MapEntry(k.toString(), v)),
        );
      }

      if (map == null) return null;

      _me = PrivateUserData.fromJson(map);

      try {
        await _api.savePermissions(_me!.permissions);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to persist permissions: $e');
        }
      }

      // IMPORTANT: persist id_user (UUID string)
      try {
        final id = _me!.idUser.trim();
        if (id.isNotEmpty) {
          await _api.saveUserId(id);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to persist id_user: $e');
        }
      }

      notifyListeners();
      return _me;
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
      await _api.clearAuthData();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
