import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/core/shared_widgets/app_picked_file.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/data/dto/pengajuan_absensi.dart';

class PengajuanAbsensiRepository {
  PengajuanAbsensiRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<PengajuanData>> fetchPengajuan({
    String? status,
    String? jenisPengajuan,
    String? userId,
  }) async {
    final res = await _api.get(
      Endpoints.pengajuanAbsensiS,
      queryParameters: {
        if (status != null && status.trim().isNotEmpty)
          'status': status.trim().toUpperCase(),
        if (jenisPengajuan != null && jenisPengajuan.trim().isNotEmpty)
          'jenis_pengajuan': jenisPengajuan.trim().toUpperCase(),
        if (userId != null && userId.trim().isNotEmpty)
          'id_user': userId.trim(),
      },
      useToken: true,
    );

    return _parseList(res);
  }

  Future<PengajuanData> fetchPengajuanById(String idPengajuan) async {
    final res = await _api.get(_buildPengajuanUrl(idPengajuan), useToken: true);
    return _parseSingle(res);
  }

  Future<PengajuanData> createPengajuan({
    required String jenisPengajuan,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String alasan,
    String? fotoBuktiUrl,
    AppPickedFile? fotoBukti,
  }) async {
    final payload = <String, String>{
      'jenis_pengajuan': jenisPengajuan.trim().toUpperCase(),
      'tanggal_mulai': tanggalMulai.trim(),
      'tanggal_selesai': tanggalSelesai.trim(),
      'alasan': alasan.trim(),
      'foto_bukti_url': fotoBuktiUrl?.trim() ?? '',
    };

    if (fotoBukti != null) {
      final bytes = await fotoBukti.file.readAsBytes();
      final uploadFile = ApiUploadFile.fromBytes(
        fieldName: 'foto_bukti',
        bytes: bytes,
        filename: fotoBukti.name,
      );

      final res = await _api.multipart(
        Endpoints.pengajuanAbsensiS,
        method: 'POST',
        fields: payload,
        files: [uploadFile],
        useToken: true,
      );

      return _parseSingle(res);
    }

    final res = await _api.post(
      Endpoints.pengajuanAbsensiS,
      useToken: true,
      body: payload,
    );

    return _parseSingle(res);
  }

  Future<PengajuanData> updateStatusPengajuan(
    String idPengajuan, {
    required String status,
    String? adminNote,
  }) async {
    final res = await _api.patch(
      _buildPengajuanUrl(idPengajuan),
      useToken: true,
      body: {
        'status': status.trim().toUpperCase(),
        if (adminNote != null) 'admin_note': adminNote.trim(),
      },
    );

    return _parseSingle(res);
  }

  Future<PengajuanData> updatePengajuan(
    String idPengajuan, {
    required String jenisPengajuan,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String alasan,
    String? fotoBuktiUrl,
    AppPickedFile? fotoBukti,
  }) async {
    final payload = <String, String>{
      'jenis_pengajuan': jenisPengajuan.trim().toUpperCase(),
      'tanggal_mulai': tanggalMulai.trim(),
      'tanggal_selesai': tanggalSelesai.trim(),
      'alasan': alasan.trim(),
      if (fotoBuktiUrl != null) 'foto_bukti_url': fotoBuktiUrl.trim(),
    };

    if (fotoBukti != null) {
      final bytes = await fotoBukti.file.readAsBytes();
      final uploadFile = ApiUploadFile.fromBytes(
        fieldName: 'foto_bukti',
        bytes: bytes,
        filename: fotoBukti.name,
      );

      final res = await _api.multipart(
        _buildPengajuanUrl(idPengajuan),
        method: 'PATCH',
        fields: payload,
        files: [uploadFile],
        useToken: true,
      );

      return _parseSingle(res);
    }

    final res = await _api.patch(
      _buildPengajuanUrl(idPengajuan),
      useToken: true,
      body: payload,
    );

    return _parseSingle(res);
  }

  Future<PengajuanData> deletePengajuan(String idPengajuan) async {
    final res = await _api.delete(
      _buildPengajuanUrl(idPengajuan),
      useToken: true,
    );
    return _parseSingle(res);
  }

  String _buildPengajuanUrl(String idPengajuan) {
    final id = idPengajuan.trim();
    if (id.isEmpty) {
      throw ArgumentError('idPengajuan tidak boleh kosong');
    }
    return '${Endpoints.pengajuanAbsensiS}/$id';
  }

  List<PengajuanData> _parseList(dynamic response) {
    final root = _asMap(response);
    final data = root['data'];

    if (data is! List) return const <PengajuanData>[];

    return data
        .whereType<Map>()
        .map((e) => PengajuanData.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  PengajuanData _parseSingle(dynamic response) {
    final root = _asMap(response);
    final data = root['data'];

    if (data is! Map) {
      throw StateError(
        'Format response pengajuan tidak valid: field data kosong.',
      );
    }

    return PengajuanData.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw StateError('Format response API tidak valid.');
  }
}
