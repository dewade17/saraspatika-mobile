import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/lokasi_dto.dart';
import 'package:saraspatika/feature/absensi/data/repository/lokasi_repository.dart';

class LokasiProvider extends ChangeNotifier {
  LokasiProvider({LokasiRepository? repository})
    : _repository = repository ?? LokasiRepository();

  final LokasiRepository _repository;

  bool _loading = false;
  String? _errorMessage;
  List<Lokasi> _locations = const <Lokasi>[];
  Lokasi? _selectedLocation;
  List<LokasiWithDistance> _nearestLocations = const <LokasiWithDistance>[];

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  List<Lokasi> get locations => _locations;
  Lokasi? get selectedLocation => _selectedLocation;
  List<LokasiWithDistance> get nearestLocations => _nearestLocations;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    if (_loading == v) return;
    _loading = v;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is StateError) {
      final msg = e.message.toString().trim();
      if (msg.isNotEmpty) return msg;
    }

    if (e is ApiException) {
      final d = e.details;
      if (d is Map) {
        final msg = d['message'] ?? d['error'] ?? d['msg'] ?? d['detail'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (e.statusCode == 400) return 'Input tidak valid.';
      if (e.statusCode == 401) return 'Unauthorized.';
      if (e.statusCode == 404) return 'Data tidak ditemukan.';
      return 'Terjadi kesalahan jaringan/server.';
    }

    return 'Terjadi kesalahan: $e';
  }

  Future<LokasiResponse> fetchLocations({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final res = await _repository.fetchLocations(
        query: query,
        page: page,
        pageSize: pageSize,
      );
      _locations = res.items;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Lokasi?> fetchLocationById(String idLokasi) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final lokasi = await _repository.fetchLocationById(idLokasi);
      _selectedLocation = lokasi;
      notifyListeners();
      return _selectedLocation;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<LokasiWithDistance>> fetchNearestLocations({
    required double latitude,
    required double longitude,
    double? radiusMeters,
    int limit = 1,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final items = await _repository.fetchNearestLocations(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        limit: limit,
      );
      _nearestLocations = items;
      notifyListeners();
      return _nearestLocations;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
