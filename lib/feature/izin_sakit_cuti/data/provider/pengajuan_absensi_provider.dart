import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/core/shared_widgets/app_picked_file.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/data/dto/pengajuan_absensi.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/data/repository/pengajuan_absensi_repository.dart';

class PengajuanAbsensiProvider extends ChangeNotifier {
  PengajuanAbsensiProvider({
    PengajuanAbsensiRepository? repository,
    ApiService? api,
  }) : _repository = repository ?? PengajuanAbsensiRepository(),
       _api = api ?? ApiService();

  final PengajuanAbsensiRepository _repository;
  final ApiService _api;

  bool _loading = false;
  String? _errorMessage;
  List<PengajuanData> _items = const <PengajuanData>[];
  PengajuanData? _selected;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  List<PengajuanData> get items => _items;
  PengajuanData? get selected => _selected;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is StateError) {
      final message = e.message.toString().trim();
      if (message.isNotEmpty) return message;
    }

    if (e is ApiException) {
      final details = e.details;
      if (details is Map) {
        final message =
            details['message'] ??
            details['detail'] ??
            details['error'] ??
            details['msg'];

        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }

      if (e.statusCode == 400) return 'Input pengajuan tidak valid.';
      if (e.statusCode == 401) return 'Unauthorized. Silakan login ulang.';
      if (e.statusCode == 403) return 'Anda tidak memiliki akses.';
      if (e.statusCode == 404) return 'Data pengajuan tidak ditemukan.';
      return 'Terjadi kesalahan jaringan/server.';
    }

    return 'Terjadi kesalahan: $e';
  }

  Future<String> _resolveStoredUserId() async {
    final id = await _api.getUserId();
    if (id == null || id.trim().isEmpty) {
      throw StateError('User ID tidak ditemukan. Silakan login ulang.');
    }

    return id.trim();
  }

  Future<List<PengajuanData>> fetchPengajuan({
    String? status,
    String? jenisPengajuan,
    String? userId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final data = await _repository.fetchPengajuan(
        status: status,
        jenisPengajuan: jenisPengajuan,
        userId: userId,
      );
      _items = data;
      notifyListeners();
      return _items;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<PengajuanData>> fetchMyPengajuan({
    String? status,
    String? jenisPengajuan,
  }) async {
    final userId = await _resolveStoredUserId();
    return fetchPengajuan(
      status: status,
      jenisPengajuan: jenisPengajuan,
      userId: userId,
    );
  }

  Future<PengajuanData?> fetchPengajuanById(String idPengajuan) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final data = await _repository.fetchPengajuanById(idPengajuan);
      _selected = data;
      notifyListeners();
      return _selected;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<PengajuanData> createPengajuan({
    required String jenisPengajuan,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String alasan,
    String? fotoBuktiUrl,
    AppPickedFile? fotoBukti,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final created = await _repository.createPengajuan(
        jenisPengajuan: jenisPengajuan,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        alasan: alasan,
        fotoBuktiUrl: fotoBuktiUrl,
        fotoBukti: fotoBukti,
      );

      _items = [created, ..._items];
      _selected = created;
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<PengajuanData> updateStatusPengajuan(
    String idPengajuan, {
    required String status,
    String? adminNote,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updated = await _repository.updateStatusPengajuan(
        idPengajuan,
        status: status,
        adminNote: adminNote,
      );

      _selected = updated;
      _items = _items
          .map(
            (item) => item.idPengajuan == updated.idPengajuan ? updated : item,
          )
          .toList();
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<PengajuanData> deletePengajuan(String idPengajuan) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final deleted = await _repository.deletePengajuan(idPengajuan);
      _items = _items
          .where((item) => item.idPengajuan != deleted.idPengajuan)
          .toList();
      if (_selected?.idPengajuan == deleted.idPengajuan) {
        _selected = null;
      }
      notifyListeners();
      return deleted;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
