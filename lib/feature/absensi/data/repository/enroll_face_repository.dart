import 'dart:typed_data';

import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/enroll_face.dart';

class EnrollFaceRepository {
  EnrollFaceRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<EnrollFace> enrollFace({
    required String userId,
    required List<Uint8List> images,
    List<String>? filenames,
  }) async {
    if (images.isEmpty) {
      throw StateError('Minimal 1 gambar diperlukan untuk registrasi wajah.');
    }

    final files = <ApiUploadFile>[];
    for (var i = 0; i < images.length; i++) {
      final fallbackName = 'face_$i.jpg';
      final name = (filenames != null && i < filenames.length)
          ? (filenames[i].trim().isEmpty ? fallbackName : filenames[i].trim())
          : fallbackName;

      files.add(
        ApiUploadFile.fromBytes(
          fieldName: 'images',
          bytes: images[i],
          filename: name,
        ),
      );
    }

    final res = await _api.multipart(
      Endpoints.faceEnroll,
      fields: {'user_id': userId},
      files: files,
      useToken: true,
    );

    final json = _asJsonMap(res);
    return EnrollFace.fromJson(json);
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
