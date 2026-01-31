import 'dart:convert';

/// Kelas pembungkus untuk menangasni respon utama yang berisi list data
class UserResponse {
  final List<UserData> data;

  UserResponse({required this.data});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      data: (json['data'] as List).map((i) => UserData.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data.map((v) => v.toJson()).toList()};
  }
}

/// Kelas DTO UserData sesuai permintaan
class UserData {
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

  UserData({
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

  bool get isProfileComplete {
    return name.trim().isNotEmpty &&
        (status?.trim().isNotEmpty ?? false) &&
        (nomorHandphone?.trim().isNotEmpty ?? false) &&
        (nip?.trim().isNotEmpty ?? false) &&
        (fotoProfilUrl?.trim().isNotEmpty ?? false);
  }

  // Mengubah JSON Map menjadi Object UserData
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      idUser: json['id_user'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      status: json['status'], // Bisa null
      nomorHandphone: json['nomor_handphone'], // Bisa null
      nip: json['nip'], // Bisa null
      fotoProfilUrl: json['foto_profil_url'], // Bisa null
      role: json['role'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Mengubah Object UserData kembali ke JSON Map
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
    };
  }
}
