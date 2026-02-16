class AttendanceResponse {
  final List<AttendanceData> data;

  AttendanceResponse({required this.data});

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) =>
      AttendanceResponse(
        data: List<AttendanceData>.from(
          (json["data"] as List).map((x) => AttendanceData.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class AttendanceData {
  final String idAbsensi;
  final String idUser;
  final DateTime tanggal;
  final DateTime? waktuMasuk;
  final DateTime? waktuPulang;
  final String statusMasuk;
  final String statusPulang;
  final UserAttendanceInfo user;
  final AttendancePoint? checkIn;
  final AttendancePoint? checkOut;

  AttendanceData({
    required this.idAbsensi,
    required this.idUser,
    required this.tanggal,
    this.waktuMasuk,
    this.waktuPulang,
    required this.statusMasuk,
    required this.statusPulang,
    required this.user,
    this.checkIn,
    this.checkOut,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
    idAbsensi: json["id_absensi"] ?? "",
    idUser: json["id_user"] ?? "",
    tanggal: DateTime.parse(json["tanggal"]),
    waktuMasuk: json["waktu_masuk"] == null
        ? null
        : DateTime.parse(json["waktu_masuk"]),
    waktuPulang: json["waktu_pulang"] == null
        ? null
        : DateTime.parse(json["waktu_pulang"]),
    statusMasuk: json["status_masuk"] ?? "",
    statusPulang: json["status_pulang"] ?? "",
    user: UserAttendanceInfo.fromJson(json["user"]),
    checkIn: AttendancePoint.tryFromJson(json["in"]),
    checkOut: AttendancePoint.tryFromJson(json["out"]),
  );

  Map<String, dynamic> toJson() => {
    "id_absensi": idAbsensi,
    "id_user": idUser,
    "tanggal":
        "${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}",
    "waktu_masuk": waktuMasuk?.toIso8601String(),
    "waktu_pulang": waktuPulang?.toIso8601String(),
    "status_masuk": statusMasuk,
    "status_pulang": statusPulang,
    "user": user.toJson(),
    "in": checkIn?.toJson(),
    "out": checkOut?.toJson(),
  };
}

class UserAttendanceInfo {
  final String idUser;
  final String name;
  final String nip;
  final String fotoProfilUrl;
  final String role;

  UserAttendanceInfo({
    required this.idUser,
    required this.name,
    required this.nip,
    required this.fotoProfilUrl,
    required this.role,
  });

  factory UserAttendanceInfo.fromJson(Map<String, dynamic> json) =>
      UserAttendanceInfo(
        idUser: json["id_user"] ?? "",
        name: json["name"] ?? "",
        nip: json["nip"] ?? "",
        fotoProfilUrl: json["foto_profil_url"] ?? "",
        role: json["role"] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "id_user": idUser,
    "name": name,
    "nip": nip,
    "foto_profil_url": fotoProfilUrl,
    "role": role,
  };
}

class AttendancePoint {
  final double latitude;
  final double longitude;
  final LocationDetail lokasi;

  AttendancePoint({
    required this.latitude,
    required this.longitude,
    required this.lokasi,
  });

  static AttendancePoint? tryFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final latitude = (map["latitude"] as num?)?.toDouble();
    final longitude = (map["longitude"] as num?)?.toDouble();
    final lokasiRaw = map["lokasi"];
    if (latitude == null || longitude == null || lokasiRaw is! Map) {
      return null;
    }

    return AttendancePoint(
      latitude: latitude,
      longitude: longitude,
      lokasi: LocationDetail.fromJson(Map<String, dynamic>.from(lokasiRaw)),
    );
  }

  factory AttendancePoint.fromJson(Map<String, dynamic> json) =>
      AttendancePoint(
        latitude: (json["latitude"] as num).toDouble(),
        longitude: (json["longitude"] as num).toDouble(),
        lokasi: LocationDetail.fromJson(json["lokasi"]),
      );

  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude,
    "lokasi": lokasi.toJson(),
  };
}

class LocationDetail {
  final String idLokasi;
  final String namaLokasi;
  final double latitude;
  final double longitude;
  final int radius;

  LocationDetail({
    required this.idLokasi,
    required this.namaLokasi,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory LocationDetail.fromJson(Map<String, dynamic> json) => LocationDetail(
    idLokasi: json["id_lokasi"] ?? "",
    namaLokasi: json["nama_lokasi"] ?? "",
    latitude: (json["latitude"] as num).toDouble(),
    longitude: (json["longitude"] as num).toDouble(),
    radius: json["radius"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id_lokasi": idLokasi,
    "nama_lokasi": namaLokasi,
    "latitude": latitude,
    "longitude": longitude,
    "radius": radius,
  };
}
