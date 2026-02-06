import 'dart:convert';

// Fungsi helper untuk parsing
JadwalShiftResponse jadwalShiftResponseFromJson(String str) =>
    JadwalShiftResponse.fromJson(json.decode(str));

String jadwalShiftResponseToJson(JadwalShiftResponse data) =>
    json.encode(data.toJson());

class JadwalShiftResponse {
  final JadwalShift? data; // Dibuat nullable jika data tidak ditemukan

  JadwalShiftResponse({required this.data});

  factory JadwalShiftResponse.fromJson(Map<String, dynamic> json) =>
      JadwalShiftResponse(
        // Menangani kemungkinan data null dari API
        data: json["data"] == null ? null : JadwalShift.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"data": data?.toJson()};
}

class JadwalShift {
  final String idJadwalShift;
  final String idUser;
  final String idPolaKerja;
  final DateTime tanggal;
  // Field tambahan baru
  final String namaPolaKerja;
  final DateTime jamMulaiKerja;
  final DateTime jamSelesaiKerja;

  JadwalShift({
    required this.idJadwalShift,
    required this.idUser,
    required this.idPolaKerja,
    required this.tanggal,
    required this.namaPolaKerja,
    required this.jamMulaiKerja,
    required this.jamSelesaiKerja,
  });

  factory JadwalShift.fromJson(Map<String, dynamic> json) => JadwalShift(
    idJadwalShift: json["id_jadwal_shift"] ?? "",
    idUser: json["id_user"] ?? "",
    idPolaKerja: json["id_pola_kerja"] ?? "",
    tanggal: DateTime.parse(json["tanggal"]),
    // Parsing field baru
    namaPolaKerja: json["nama_pola_kerja"] ?? "",
    jamMulaiKerja: DateTime.parse(json["jam_mulai_kerja"]),
    jamSelesaiKerja: DateTime.parse(json["jam_selesai_kerja"]),
  );

  Map<String, dynamic> toJson() => {
    "id_jadwal_shift": idJadwalShift,
    "id_user": idUser,
    "id_pola_kerja": idPolaKerja,
    "tanggal":
        "${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}",
    "nama_pola_kerja": namaPolaKerja,
    "jam_mulai_kerja": jamMulaiKerja.toIso8601String(),
    "jam_selesai_kerja": jamSelesaiKerja.toIso8601String(),
  };
}
