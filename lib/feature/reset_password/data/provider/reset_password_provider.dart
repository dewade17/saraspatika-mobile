import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/reset_password/data/dto/reset_password.dart';

class ResetPasswordProvider extends ChangeNotifier {
  ResetPasswordProvider({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  bool _loading = false;
  String? _errorMessage;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
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
      if (e.statusCode == 400) return 'Input tidak valid.';
      if (e.statusCode == 401) return 'Unauthorized.';
      return 'Terjadi kesalahan jaringan/server.';
    }
    return 'Terjadi kesalahan: $e';
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

  /// POST /auth/request-token body: { email }
  /// Backend: selalu { ok: true } (anti-enumeration)
  Future<bool> requestResetToken({required String email}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final req = ForgotPasswordRequest(email: email);

      final res = await _api.post(
        Endpoints.resetRequestToken,
        useToken: false,
        body: req.toJson(),
      );

      final json = _asJsonMap(res);
      final base = BaseResponse.fromJson(json);
      return base.ok;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// POST /auth/reset-password body: { email, code, newPassword }
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final req = ResetPasswordRequest(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      final res = await _api.post(
        Endpoints.resetConfirm,
        useToken: false,
        body: req.toJson(),
      );

      final json = _asJsonMap(res);
      final base = BaseResponse.fromJson(json);
      return base.ok;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
