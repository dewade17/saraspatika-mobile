class PrivateUserData {
  final int idUser;
  final String role;
  final String namaPengguna;
  final List<String> permissions;

  const PrivateUserData({
    required this.idUser,
    required this.role,
    required this.namaPengguna,
    required this.permissions,
  });

  factory PrivateUserData.fromJson(Map<String, dynamic> json) {
    final permsRaw = json['permissions'];
    final perms = <String>[];

    if (permsRaw is List) {
      for (final v in permsRaw) {
        if (v == null) continue;
        perms.add(v.toString());
      }
    }

    return PrivateUserData(
      idUser: (json['id_user'] is num) ? (json['id_user'] as num).toInt() : 0,
      role: (json['role'] ?? '').toString(),
      namaPengguna: (json['nama_pengguna'] ?? json['name'] ?? '').toString(),
      permissions: perms,
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class LoginResponse {
  final bool ok;
  final String token;
  final Map<String, dynamic>? user;

  LoginResponse({required this.ok, required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = (json['token'] ?? '').toString();
    final ok = (json['ok'] is bool)
        ? (json['ok'] as bool)
        : token.trim().isNotEmpty;

    Map<String, dynamic>? user;
    final u = json['user'];
    if (u is Map<String, dynamic>) {
      user = u;
    } else if (u is Map) {
      user = Map<String, dynamic>.from(
        u.map((k, v) => MapEntry(k.toString(), v)),
      );
    }

    return LoginResponse(ok: ok, token: token, user: user);
  }
}
