import 'dart:convert';

class AbsensiStatus {
  final bool ok;
  final AbsensiItem? item;

  AbsensiStatus({required this.ok, this.item});

  factory AbsensiStatus.fromJson(String str) =>
      AbsensiStatus.fromMap(json.decode(str));

  factory AbsensiStatus.fromMap(Map<String, dynamic> json) => AbsensiStatus(
    ok: json["ok"] ?? false,
    item: json["item"] == null ? null : AbsensiItem.fromMap(json["item"]),
  );
}

class AbsensiItem {
  final String idAbsensi;
  final bool faceVerifiedMasuk;
  final bool faceVerifiedPulang;
  final String? statusMasuk;
  final String? statusPulang;
  final DateTime? waktuMasuk;
  final DateTime? waktuPulang;

  AbsensiItem({
    required this.idAbsensi,
    required this.faceVerifiedMasuk,
    required this.faceVerifiedPulang,
    this.statusMasuk,
    this.statusPulang,
    this.waktuMasuk,
    this.waktuPulang,
  });

  factory AbsensiItem.fromMap(Map<String, dynamic> json) => AbsensiItem(
    idAbsensi: json["id_absensi"] ?? "",
    faceVerifiedMasuk: json["face_verified_masuk"] ?? false,
    faceVerifiedPulang: json["face_verified_pulang"] ?? false,
    statusMasuk: json["status_masuk"],
    statusPulang: json["status_pulang"],
    // Mengonversi String ISO8601 dari server ke DateTime Dart
    waktuMasuk: json["waktu_masuk"] == null
        ? null
        : DateTime.parse(json["waktu_masuk"]),
    waktuPulang: json["waktu_pulang"] == null
        ? null
        : DateTime.parse(json["waktu_pulang"]),
  );

  Map<String, dynamic> toMap() => {
    "id_absensi": idAbsensi,
    "face_verified_masuk": faceVerifiedMasuk,
    "face_verified_pulang": faceVerifiedPulang,
    "status_masuk": statusMasuk,
    "status_pulang": statusPulang,
    "waktu_masuk": waktuMasuk?.toIso8601String(),
    "waktu_pulang": waktuPulang?.toIso8601String(),
  };
}
