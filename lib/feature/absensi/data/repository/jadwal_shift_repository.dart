import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/jadwal_shift.dart';

class JadwalShiftRepository {
  JadwalShiftRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<JadwalShift?> fetchTodayShift(String userId) async {
    final url = _buildTodayShiftUrl(userId);
    final res = await _api.get(url, useToken: true);
    final json = _asJsonMap(res);
    final data = json['data'];

    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      return JadwalShift.fromJson(data);
    }

    if (data is Map) {
      return JadwalShift.fromJson(Map<String, dynamic>.from(data));
    }

    throw StateError('Response tidak valid: ${data.runtimeType}');
  }

  String _buildTodayShiftUrl(String userId) {
    final safeId = Uri.encodeComponent(userId);
    return '${Endpoints.jadwalShift}/today/$safeId';
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
}
