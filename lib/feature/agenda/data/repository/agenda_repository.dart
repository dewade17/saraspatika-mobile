import 'package:saraspatika/core/constants/endpoints.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/core/shared_widgets/app_picked_file.dart';
import 'package:saraspatika/feature/agenda/data/dto/agenda.dart';

class AgendaRepository {
  AgendaRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<Agenda>> fetchAgendaList({String? userId}) async {
    final response = await _api.get(
      Endpoints.agenda,
      queryParameters: {
        if (userId != null && userId.trim().isNotEmpty)
          'id_user': userId.trim(),
      },
      useToken: true,
    );
    return _parseList(response);
  }

  Future<Agenda> fetchAgendaById(String idAgenda) async {
    final response = await _api.get(_agendaByIdUrl(idAgenda), useToken: true);
    return _parseSingle(response);
  }

  Future<Agenda> createAgenda({
    required String deskripsi,
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
    String? buktiPendukungUrl,
    AppPickedFile? buktiPendukung,
  }) async {
    final payload = <String, String>{
      'deskripsi': deskripsi.trim(),
      'tanggal': tanggal.trim(),
      'jam_mulai': jamMulai.trim(),
      'jam_selesai': jamSelesai.trim(),
      if (buktiPendukungUrl != null)
        'bukti_pendukung_url': buktiPendukungUrl.trim(),
    };

    if (buktiPendukung != null) {
      final bytes = await buktiPendukung.file.readAsBytes();
      final uploadFile = ApiUploadFile.fromBytes(
        fieldName: 'bukti_pendukung',
        bytes: bytes,
        filename: buktiPendukung.name,
      );

      final response = await _api.multipart(
        Endpoints.agenda,
        method: 'POST',
        fields: payload,
        files: [uploadFile],
        useToken: true,
      );

      return _parseSingle(response);
    }

    final response = await _api.post(
      Endpoints.agenda,
      useToken: true,
      body: payload,
    );

    return _parseSingle(response);
  }

  Future<Agenda> updateAgenda(
    String idAgenda, {
    String? deskripsi,
    String? tanggal,
    String? jamMulai,
    String? jamSelesai,
    String? buktiPendukungUrl,
    AppPickedFile? buktiPendukung,
  }) async {
    final payload = <String, String>{
      if (deskripsi != null) 'deskripsi': deskripsi.trim(),
      if (tanggal != null) 'tanggal': tanggal.trim(),
      if (jamMulai != null) 'jam_mulai': jamMulai.trim(),
      if (jamSelesai != null) 'jam_selesai': jamSelesai.trim(),
      if (buktiPendukungUrl != null)
        'bukti_pendukung_url': buktiPendukungUrl.trim(),
    };

    if (buktiPendukung != null) {
      final bytes = await buktiPendukung.file.readAsBytes();
      final uploadFile = ApiUploadFile.fromBytes(
        fieldName: 'bukti_pendukung',
        bytes: bytes,
        filename: buktiPendukung.name,
      );

      final response = await _api.multipart(
        _agendaByIdUrl(idAgenda),
        method: 'PATCH',
        fields: payload,
        files: [uploadFile],
        useToken: true,
      );

      return _parseSingle(response);
    }

    final response = await _api.patch(
      _agendaByIdUrl(idAgenda),
      useToken: true,
      body: payload,
    );

    return _parseSingle(response);
  }

  Future<Agenda> deleteAgenda(String idAgenda) async {
    final response = await _api.delete(
      _agendaByIdUrl(idAgenda),
      useToken: true,
    );
    return _parseSingle(response);
  }

  String _agendaByIdUrl(String idAgenda) {
    final id = idAgenda.trim();
    if (id.isEmpty) {
      throw ArgumentError('idAgenda tidak boleh kosong');
    }
    return '${Endpoints.agenda}/$id';
  }

  List<Agenda> _parseList(dynamic response) {
    final root = _asMap(response);
    final data = root['data'];

    if (data is! List) return const <Agenda>[];

    return data
        .whereType<Map>()
        .map((e) => Agenda.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Agenda _parseSingle(dynamic response) {
    final root = _asMap(response);
    final data = root['data'];

    if (data is! Map) {
      throw StateError(
        'Format response agenda tidak valid: field data kosong.',
      );
    }

    return Agenda.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw StateError('Format response API tidak valid.');
  }
}
