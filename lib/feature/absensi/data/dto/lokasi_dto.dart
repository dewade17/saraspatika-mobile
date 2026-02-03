import 'dart:convert';

// Fungsi helper untuk mempermudah parsing string JSON langsung
LokasiResponse lokasiResponseFromJson(String str) =>
    LokasiResponse.fromJson(json.decode(str));

String lokasiResponseToJson(LokasiResponse data) => json.encode(data.toJson());

class LokasiResponse {
  final List<Lokasi> items;
  final bool ok;
  final int page;
  final int pageSize;
  final int total;

  LokasiResponse({
    required this.items,
    required this.ok,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory LokasiResponse.fromJson(Map<String, dynamic> json) => LokasiResponse(
    items: List<Lokasi>.from(json["items"].map((x) => Lokasi.fromJson(x))),
    ok: json["ok"],
    page: json["page"],
    pageSize: json["page_size"],
    total: json["total"],
  );

  Map<String, dynamic> toJson() => {
    "items": List<dynamic>.from(items.map((x) => x.toJson())),
    "ok": ok,
    "page": page,
    "page_size": pageSize,
    "total": total,
  };
}

class Lokasi {
  final String idLokasi;
  final String namaLokasi;
  final double latitude;
  final double longitude;
  final int radius;

  Lokasi({
    required this.idLokasi,
    required this.namaLokasi,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory Lokasi.fromJson(Map<String, dynamic> json) => Lokasi(
    idLokasi: json["id_lokasi"],
    namaLokasi: json["nama_lokasi"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    radius: json["radius"],
  );

  Map<String, dynamic> toJson() => {
    "id_lokasi": idLokasi,
    "nama_lokasi": namaLokasi,
    "latitude": latitude,
    "longitude": longitude,
    "radius": radius,
  };
}
