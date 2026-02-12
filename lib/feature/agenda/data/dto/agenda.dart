import 'dart:convert';

class AgendaResponse {
  final List<Agenda> data;
  final String message;

  AgendaResponse({required this.data, required this.message});

  factory AgendaResponse.fromRawJson(String str) =>
      AgendaResponse.fromJson(json.decode(str));

  factory AgendaResponse.fromJson(Map<String, dynamic> json) => AgendaResponse(
    data: List<Agenda>.from(json["data"].map((x) => Agenda.fromJson(x))),
    message: json["message"],
  );
}

class Agenda {
  final String idAgenda;
  final String idUser;
  final String deskripsi;
  final String kategoriAgenda;
  final DateTime tanggal;
  final DateTime jamMulai;
  final DateTime jamSelesai;
  final String? buktiPendukungUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Agenda({
    required this.idAgenda,
    required this.idUser,
    required this.deskripsi,
    required this.kategoriAgenda,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    this.buktiPendukungUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) => Agenda(
    idAgenda: json["id_agenda"],
    idUser: json["id_user"],
    deskripsi: json["deskripsi"],
    kategoriAgenda: json["kategori_agenda"],
    tanggal: DateTime.parse(json["tanggal"]),
    jamMulai: DateTime.parse(json["jam_mulai"]),
    jamSelesai: DateTime.parse(json["jam_selesai"]),
    buktiPendukungUrl: json["bukti_pendukung_url"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id_agenda": idAgenda,
    "id_user": idUser,
    "deskripsi": deskripsi,
    "kategori_agenda": kategoriAgenda,
    "tanggal": tanggal.toIso8601String(),
    "jam_mulai": jamMulai.toIso8601String(),
    "jam_selesai": jamSelesai.toIso8601String(),
    "bukti_pendukung_url": buktiPendukungUrl,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}
