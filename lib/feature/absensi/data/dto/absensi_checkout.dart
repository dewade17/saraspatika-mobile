import 'dart:convert';

class CheckOutRequest {
  final String userId;
  final String absensiId; // ID unik dari record absensi saat check-in
  final String locationId;
  final double lat;
  final double lng;
  final String? capturedAt; // ISO8601 timestamp untuk mode offline

  CheckOutRequest({
    required this.userId,
    required this.absensiId,
    required this.locationId,
    required this.lat,
    required this.lng,
    this.capturedAt,
  });

  // Digunakan untuk mengirim data lewat MultipartRequest
  Map<String, String> toFormFields() {
    return {
      'user_id': userId,
      'absensi_id': absensiId,
      'location_id': locationId,
      'lat': lat.toString(),
      'lng': lng.toString(),
      if (capturedAt != null) 'captured_at': capturedAt!,
    };
  }

  // Helper jika ingin menyimpan data ke database lokal (SQLite/Isar)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'absensi_id': absensiId,
      'lat': lat,
      'lng': lng,
      'captured_at': capturedAt,
    };
  }

  factory CheckOutRequest.fromMap(Map<String, dynamic> map) {
    return CheckOutRequest(
      userId: map['user_id'] ?? '',
      absensiId: map['absensi_id'] ?? '',
      locationId: map['location_id'] ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      capturedAt: map['captured_at'],
    );
  }

  String toJson() => json.encode(toMap());
}
