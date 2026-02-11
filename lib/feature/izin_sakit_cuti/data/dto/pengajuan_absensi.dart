import 'dart:convert';

// Fungsi untuk memudahkan konversi dari string JSON ke Objek
PengajuanResponse pengajuanResponseFromJson(String str) =>
    PengajuanResponse.fromJson(json.decode(str));

class PengajuanResponse {
  bool ok;
  PengajuanData data;

  PengajuanResponse({required this.ok, required this.data});

  factory PengajuanResponse.fromJson(Map<String, dynamic> json) =>
      PengajuanResponse(
        ok: json["ok"],
        data: PengajuanData.fromJson(json["data"]),
      );
}

class PengajuanData {
  String idPengajuan;
  String idUser;
  String jenisPengajuan;
  DateTime tanggalMulai;
  DateTime tanggalSelesai;
  String alasan;
  String fotoBuktiUrl;
  String status;
  String? adminNote; // Gunakan ? karena bisa null
  String? idAdmin; // Gunakan ? karena bisa null
  DateTime createdAt;
  DateTime updatedAt;
  User user;
  dynamic
  admin; // Gunakan dynamic atau buat class Admin jika strukturnya sudah jelas

  PengajuanData({
    required this.idPengajuan,
    required this.idUser,
    required this.jenisPengajuan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.alasan,
    required this.fotoBuktiUrl,
    required this.status,
    this.adminNote,
    this.idAdmin,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    this.admin,
  });

  factory PengajuanData.fromJson(Map<String, dynamic> json) => PengajuanData(
    idPengajuan: json["id_pengajuan"],
    idUser: json["id_user"],
    jenisPengajuan: json["jenis_pengajuan"],
    tanggalMulai: DateTime.parse(json["tanggal_mulai"]),
    tanggalSelesai: DateTime.parse(json["tanggal_selesai"]),
    alasan: json["alasan"],
    fotoBuktiUrl: json["foto_bukti_url"],
    status: json["status"],
    adminNote: json["admin_note"],
    idAdmin: json["id_admin"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    user: User.fromJson(json["user"]),
    admin: json["admin"],
  );
}

class User {
  String idUser;
  String email;
  String name;
  String role;
  String fotoProfilUrl;

  User({
    required this.idUser,
    required this.email,
    required this.name,
    required this.role,
    required this.fotoProfilUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    idUser: json["id_user"],
    email: json["email"],
    name: json["name"],
    role: json["role"],
    fotoProfilUrl: json["foto_profil_url"],
  );
}
