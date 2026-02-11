import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/home/data/dto/history_kehadiran.dart';

class HistoryKehadiranRepository {
  HistoryKehadiranRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<AttendanceData>> fetchHistory({
    String? userId,
    String? role,
    String? startDate,
    String? endDate,
    String? q,
    int? limit,
  }) async {
    final res = await _api.get(
      Endpoints.absensiHistory,
      queryParameters: {
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
        if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
        if (startDate != null && startDate.trim().isNotEmpty)
          'start_date': startDate.trim(),
        if (endDate != null && endDate.trim().isNotEmpty)
          'end_date': endDate.trim(),
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (limit != null && limit > 0) 'limit': limit,
      },
      useToken: true,
    );

    return _parseList(res);
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

  List<AttendanceData> _parseList(Object? res) {
    if (res is List) {
      return res.map((e) => AttendanceData.fromJson(_asJsonMap(e))).toList();
    }

    final json = _asJsonMap(res);
    if (json['data'] is List) {
      return AttendanceResponse.fromJson(json).data;
    }

    if (json['data'] is Map) {
      return [AttendanceData.fromJson(_asJsonMap(json['data']))];
    }

    if (json.isNotEmpty) {
      return [AttendanceData.fromJson(json)];
    }

    return const <AttendanceData>[];
  }
}
