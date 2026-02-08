import 'dart:convert';

class CheckOutRequest {
  final String userId;
  final String absensiId; // ID unik dari record absensi saat check-in
  final String locationId;
  final double lat;
  final double lng;
  final String? capturedAt; // ISO8601 timestamp untuk mode offline
  final String? correlationId;

  CheckOutRequest({
    required this.userId,
    required this.absensiId,
    required this.locationId,
    required this.lat,
    required this.lng,
    this.capturedAt,
    this.correlationId,
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
      if (correlationId != null && correlationId!.trim().isNotEmpty)
        'correlation_id': correlationId!,
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
      'correlation_id': correlationId,
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
      correlationId: map['correlation_id']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());
}
