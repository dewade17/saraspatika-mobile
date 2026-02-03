import 'dart:convert';

// Fungsi helper untuk parsing
JadwalShiftResponse jadwalShiftResponseFromJson(String str) =>
    JadwalShiftResponse.fromJson(json.decode(str));

String jadwalShiftResponseToJson(JadwalShiftResponse data) =>
    json.encode(data.toJson());

class JadwalShiftResponse {
  final JadwalShift data;

  JadwalShiftResponse({required this.data});

  factory JadwalShiftResponse.fromJson(Map<String, dynamic> json) =>
      JadwalShiftResponse(data: JadwalShift.fromJson(json["data"]));

  Map<String, dynamic> toJson() => {"data": data.toJson()};
}

class JadwalShift {
  final String idJadwalShift;
  final String idUser;
  final String idPolaKerja;
  final DateTime tanggal;

  JadwalShift({
    required this.idJadwalShift,
    required this.idUser,
    required this.idPolaKerja,
    required this.tanggal,
  });

  factory JadwalShift.fromJson(Map<String, dynamic> json) => JadwalShift(
    idJadwalShift: json["id_jadwal_shift"],
    idUser: json["id_user"],
    idPolaKerja: json["id_pola_kerja"],
    // Parsing string "2026-02-03" menjadi objek DateTime
    tanggal: DateTime.parse(json["tanggal"]),
  );

  Map<String, dynamic> toJson() => {
    "id_jadwal_shift": idJadwalShift,
    "id_user": idUser,
    "id_pola_kerja": idPolaKerja,
    // Mengubah DateTime kembali ke string YYYY-MM-DD
    "tanggal":
        "${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}",
  };
}
