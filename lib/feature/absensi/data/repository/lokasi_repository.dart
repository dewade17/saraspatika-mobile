import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/lokasi_dto.dart';

class LokasiWithDistance {
  final Lokasi lokasi;
  final double distanceMeters;

  LokasiWithDistance({required this.lokasi, required this.distanceMeters});

  factory LokasiWithDistance.fromJson(Map<String, dynamic> json) {
    final distance = json['distanceMeters'] ?? json['distance_meters'];

    return LokasiWithDistance(
      lokasi: Lokasi.fromJson(json),
      distanceMeters: (distance is num)
          ? distance.toDouble()
          : double.tryParse(distance?.toString() ?? '') ?? 0,
    );
  }
}

class LokasiRepository {
  LokasiRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<LokasiResponse> fetchLocations({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _api.get(
      Endpoints.location,
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query,
        'page': page,
        'page_size': pageSize,
      },
      useToken: true,
    );

    final json = _asJsonMap(res);
    return LokasiResponse.fromJson(json);
  }

  Future<Lokasi> fetchLocationById(String idLokasi) async {
    final res = await _api.get(_buildLocationUrl(idLokasi), useToken: true);
    return _parseLokasi(res);
  }

  Future<List<LokasiWithDistance>> fetchNearestLocations({
    required double latitude,
    required double longitude,
    double? radiusMeters,
    int limit = 1,
  }) async {
    final res = await _api.get(
      '${Endpoints.location}/nearest',
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
        if (radiusMeters != null) 'radius_m': radiusMeters,
        'limit': limit,
      },
      useToken: true,
    );

    final json = _asJsonMap(res);
    final items = json['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => LokasiWithDistance.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return const <LokasiWithDistance>[];
  }

  String _buildLocationUrl(String id) {
    final safeId = Uri.encodeComponent(id);
    return '${Endpoints.location}/$safeId';
  }

  Map<String, dynamic> _asJsonMap(Object? res) {
    if (res is Map<String, dynamic>) return res;
    if (res is Map) {
      return Map<String, dynamic>.from(
        res.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    throw StateError('Response tidak valid: ${res.runtimeType}');
  }

  Lokasi _parseLokasi(Object? res) {
    if (res is Map<String, dynamic>) {
      if (res['item'] is Map) {
        return Lokasi.fromJson(Map<String, dynamic>.from(res['item'] as Map));
      }
      return Lokasi.fromJson(res);
    }

    if (res is Map) {
      final json = Map<String, dynamic>.from(
        res.map((k, v) => MapEntry(k.toString(), v)),
      );
      final item = json['item'];
      if (item is Map) {
        return Lokasi.fromJson(Map<String, dynamic>.from(item));
      }
      return Lokasi.fromJson(json);
    }

    throw StateError('Response tidak valid: ${res.runtimeType}');
  }
}
