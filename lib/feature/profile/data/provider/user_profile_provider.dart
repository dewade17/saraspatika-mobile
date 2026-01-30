import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/profile/data/dto/user.dart';
import 'package:saraspatika/feature/profile/data/repository/user_repository.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider({UserRepository? repository})
    : _repository = repository ?? UserRepository();

  final UserRepository _repository;

  bool _loading = false;
  String? _errorMessage;
  List<UserData> _users = const <UserData>[];
  UserData? _selectedUser;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  List<UserData> get users => _users;
  UserData? get selectedUser => _selectedUser;

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
      if (e.statusCode == 404) return 'Data tidak ditemukan.';
      return 'Terjadi kesalahan jaringan/server.';
    }
    return 'Terjadi kesalahan: $e';
  }

  Future<List<UserData>> fetchUsers({String? query}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final data = await _repository.fetchUsers(query: query);
      _users = data;
      notifyListeners();
      return _users;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserData?> fetchUserById(String idUser) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _repository.fetchUserById(idUser);
      _selectedUser = user;
      notifyListeners();
      return _selectedUser;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserData> createUser({
    required String email,
    required String password,
    String? name,
    String? status,
    String? nomorHandphone,
    String? nip,
    String? fotoProfilUrl,
    String? role,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final created = await _repository.createUser(
        email: email,
        password: password,
        name: name,
        status: status,
        nomorHandphone: nomorHandphone,
        nip: nip,
        fotoProfilUrl: fotoProfilUrl,
        role: role,
      );

      _users = [..._users, created];
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserData> updateUser(
    String idUser, {
    String? email,
    String? password,
    String? name,
    String? status,
    String? nomorHandphone,
    String? nip,
    String? fotoProfilUrl,
    String? role,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updated = await _repository.updateUser(
        idUser,
        email: email,
        password: password,
        name: name,
        status: status,
        nomorHandphone: nomorHandphone,
        nip: nip,
        fotoProfilUrl: fotoProfilUrl,
        role: role,
      );

      _selectedUser = updated;
      _users = _users
          .map((u) => u.idUser == updated.idUser ? updated : u)
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

  Future<void> deleteUser(String idUser) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.deleteUser(idUser);

      _users = _users.where((u) => u.idUser != idUser).toList();
      if (_selectedUser?.idUser == idUser) {
        _selectedUser = null;
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
