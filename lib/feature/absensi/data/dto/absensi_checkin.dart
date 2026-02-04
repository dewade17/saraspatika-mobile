import 'dart:convert';

class CheckInRequest {
  final String userId;
  final String locationId;
  final double lat;
  final double lng;
  final String? capturedAt; // Waktu saat tombol ditekan (ISO8601)

  CheckInRequest({
    required this.userId,
    required this.locationId,
    required this.lat,
    required this.lng,
    this.capturedAt,
  });

  // Mengubah object ke Map untuk dikirim sebagai fields di MultipartRequest
  Map<String, String> toFormFields() {
    return {
      'user_id': userId,
      'location_id': locationId,
      'lat': lat.toString(),
      'lng': lng.toString(),
      if (capturedAt != null) 'captured_at': capturedAt!,
    };
  }

  // Helper untuk JSON (jika suatu saat dibutuhkan untuk penyimpanan lokal/sqflite)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'location_id': locationId,
      'lat': lat,
      'lng': lng,
      'captured_at': capturedAt,
    };
  }

  factory CheckInRequest.fromMap(Map<String, dynamic> map) {
    return CheckInRequest(
      userId: map['user_id'] ?? '',
      locationId: map['location_id'] ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      capturedAt: map['captured_at'],
    );
  }

  String toJson() => json.encode(toMap());
}
