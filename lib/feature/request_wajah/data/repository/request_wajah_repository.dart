import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/request_wajah/data/dto/request_wajah.dart';

class RequestWajahRepository {
  RequestWajahRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<FaceResetRequest>> fetchRequests({
    String? status,
    String? userId,
  }) async {
    final res = await _api.get(
      Endpoints.faceResetRequests,
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (userId != null && userId.trim().isNotEmpty)
          'id_user': userId.trim(),
      },
      useToken: true,
    );

    return _parseList(res);
  }

  Future<FaceResetRequest> fetchRequestById(String id) async {
    final res = await _api.get(_buildRequestUrl(id), useToken: true);
    return _parseSingle(res);
  }

  Future<FaceResetRequest> createRequest({required String alasan}) async {
    final res = await _api.post(
      Endpoints.faceResetRequests,
      useToken: true,
      body: {'alasan': alasan},
    );

    return _parseSingle(res);
  }

  Future<FaceResetRequest> updateRequest(
    String id, {
    String? status,
    String? adminNote,
  }) async {
    final body = {'status': status, 'admin_note': adminNote}
      ..removeWhere((_, v) => v == null);

    final res = await _api.patch(
      _buildRequestUrl(id),
      useToken: true,
      body: body,
    );

    return _parseSingle(res);
  }

  Future<void> deleteRequest(String id) async {
    await _api.delete(_buildRequestUrl(id), useToken: true);
  }

  String _buildRequestUrl(String id) {
    final safeId = Uri.encodeComponent(id);
    return '${Endpoints.faceResetRequests}/$safeId';
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

  List<FaceResetRequest> _parseList(Object? res) {
    if (res is List) {
      return res.map((e) => FaceResetRequest.fromJson(_asJsonMap(e))).toList();
    }

    final json = _asJsonMap(res);
    final data = json['data'];
    if (data is List) {
      return data.map((e) => FaceResetRequest.fromJson(_asJsonMap(e))).toList();
    }
    if (data is Map) {
      return [FaceResetRequest.fromJson(_asJsonMap(data))];
    }

    if (json.isNotEmpty) {
      return [FaceResetRequest.fromJson(json)];
    }

    return const <FaceResetRequest>[];
  }

  FaceResetRequest _parseSingle(Object? res) {
    if (res is List) {
      if (res.isEmpty) {
        throw StateError('Response tidak valid: list kosong');
      }
      return FaceResetRequest.fromJson(_asJsonMap(res.first));
    }

    final json = _asJsonMap(res);
    final data = json['data'];
    if (data is Map) {
      return FaceResetRequest.fromJson(_asJsonMap(data));
    }
    if (data is List && data.isNotEmpty) {
      return FaceResetRequest.fromJson(_asJsonMap(data.first));
    }

    return FaceResetRequest.fromJson(json);
  }
}
