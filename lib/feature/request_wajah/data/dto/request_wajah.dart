class FaceResetRequestResponse {
  final List<FaceResetRequest> data;

  FaceResetRequestResponse({required this.data});

  factory FaceResetRequestResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    if (raw is List) {
      return FaceResetRequestResponse(
        data: raw.map((e) => FaceResetRequest.fromJson(_asJsonMap(e))).toList(),
      );
    }
    if (raw is Map) {
      return FaceResetRequestResponse(
        data: [FaceResetRequest.fromJson(_asJsonMap(raw))],
      );
    }
    return FaceResetRequestResponse(data: const <FaceResetRequest>[]);
  }

  Map<String, dynamic> toJson() {
    return {'data': data.map((v) => v.toJson()).toList()};
  }

  static Map<String, dynamic> _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return const <String, dynamic>{};
  }
}

class FaceResetRequest {
  final String idRequest;
  final String idUser;
  final String alasan;
  final String status;
  final String? adminNote;
  final String? idAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserSummary? user;
  final UserSummary? admin;

  FaceResetRequest({
    required this.idRequest,
    required this.idUser,
    required this.alasan,
    required this.status,
    this.adminNote,
    this.idAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.admin,
  });

  factory FaceResetRequest.fromJson(Map<String, dynamic> json) {
    return FaceResetRequest(
      idRequest: json['id_request']?.toString() ?? '',
      idUser: json['id_user']?.toString() ?? '',
      alasan: json['alasan']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      adminNote: json['admin_note']?.toString(),
      idAdmin: json['id_admin']?.toString(),
      createdAt:
          _parseDate(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _parseDate(json['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      user: json['user'] is Map
          ? UserSummary.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
      admin: json['admin'] is Map
          ? UserSummary.fromJson(Map<String, dynamic>.from(json['admin']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_request': idRequest,
      'id_user': idUser,
      'alasan': alasan,
      'status': status,
      'admin_note': adminNote,
      'id_admin': idAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user?.toJson(),
      'admin': admin?.toJson(),
    }..removeWhere((_, v) => v == null);
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}

class UserSummary {
  final String idUser;
  final String email;
  final String name;
  final String? status;
  final String? nomorHandphone;
  final String? nip;
  final String? fotoProfilUrl;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSummary({
    required this.idUser,
    required this.email,
    required this.name,
    this.status,
    this.nomorHandphone,
    this.nip,
    this.fotoProfilUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      idUser: json['id_user']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString(),
      nomorHandphone: json['nomor_handphone']?.toString(),
      nip: json['nip']?.toString(),
      fotoProfilUrl: json['foto_profil_url']?.toString(),
      role: json['role']?.toString() ?? '',
      createdAt:
          FaceResetRequest._parseDate(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          FaceResetRequest._parseDate(json['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'email': email,
      'name': name,
      'status': status,
      'nomor_handphone': nomorHandphone,
      'nip': nip,
      'foto_profil_url': fotoProfilUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    }..removeWhere((_, v) => v == null);
  }
}
