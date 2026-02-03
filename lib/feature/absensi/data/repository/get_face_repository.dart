import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/get_face.dart';

class GetFaceRepository {
  GetFaceRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<GetFace> fetchFaceData(String userId) async {
    final url = _buildGetFaceUrl(userId);
    final res = await _api.get(url, useToken: true);
    final json = _asJsonMap(res);
    return GetFace.fromJson(json);
  }

  String _buildGetFaceUrl(String userId) {
    final safeId = Uri.encodeComponent(userId);
    return '${Endpoints.getFace}/$safeId';
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