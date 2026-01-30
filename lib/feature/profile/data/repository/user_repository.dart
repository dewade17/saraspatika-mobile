import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/profile/data/dto/user.dart';

class UserRepository {
  UserRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<UserData>> fetchUsers({String? query}) async {
    final res = await _api.get(
      Endpoints.userProfile,
      queryParameters: query != null ? {'q': query} : null,
      useToken: true,
    );

    return _parseUsers(res);
  }

  Future<UserData> fetchUserById(String idUser) async {
    final res = await _api.get(_buildUserUrl(idUser), useToken: true);
    return _parseUser(res);
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
    final body = {
      'email': email,
      'password': password,
      'name': name,
      'status': status,
      'nomor_handphone': nomorHandphone,
      'nip': nip,
      'foto_profil_url': fotoProfilUrl,
      'role': role,
    }..removeWhere((_, v) => v == null);

    final res = await _api.post(
      Endpoints.userProfile,
      useToken: true,
      body: body,
    );

    return _parseUser(res);
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
    final body = {
      'email': email,
      'password': password,
      'name': name,
      'status': status,
      'nomor_handphone': nomorHandphone,
      'nip': nip,
      'foto_profil_url': fotoProfilUrl,
      'role': role,
    }..removeWhere((_, v) => v == null);

    final res = await _api.put(
      _buildUserUrl(idUser),
      useToken: true,
      body: body,
    );

    return _parseUser(res);
  }

  Future<void> deleteUser(String idUser) async {
    await _api.delete(_buildUserUrl(idUser), useToken: true);
  }

  String _buildUserUrl(String id) {
    final safeId = Uri.encodeComponent(id);
    return '${Endpoints.userProfile}/$safeId';
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

  List<UserData> _parseUsers(Object? res) {
    if (res is List) {
      return res
          .map((e) => UserData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final json = _asJsonMap(res);
    if (json['data'] is List) {
      return (json['data'] as List)
          .map((e) => UserData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    if (json.isNotEmpty) {
      return [UserData.fromJson(json)];
    }

    return const <UserData>[];
  }

  UserData _parseUser(Object? res) {
    if (res is List) {
      if (res.isEmpty) {
        throw StateError('Response tidak valid: list kosong');
      }
      final first = res.first;
      if (first is Map) {
        return UserData.fromJson(Map<String, dynamic>.from(first));
      }
      throw StateError('Response tidak valid: ${first.runtimeType}');
    }

    final json = _asJsonMap(res);

    final data = json['data'];
    if (data is Map) {
      return UserData.fromJson(Map<String, dynamic>.from(data));
    }
    if (data is List && data.isNotEmpty && data.first is Map) {
      return UserData.fromJson(Map<String, dynamic>.from(data.first as Map));
    }

    return UserData.fromJson(json);
  }
}
