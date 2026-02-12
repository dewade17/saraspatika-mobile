import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/core/shared_widgets/app_picked_file.dart';
import 'package:saraspatika/feature/agenda/data/dto/agenda.dart';
import 'package:saraspatika/feature/agenda/data/repository/agenda_repository.dart';

class AgendaProvider extends ChangeNotifier {
  AgendaProvider({AgendaRepository? repository, ApiService? api})
    : _repository = repository ?? AgendaRepository(),
      _api = api ?? ApiService();

  final AgendaRepository _repository;
  final ApiService _api;

  final List<Agenda> _agendaList = <Agenda>[];
  bool _isLoading = false;
  String? _errorMessage;

  List<Agenda> get agendaList => List<Agenda>.unmodifiable(_agendaList);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<Agenda>> fetchAgendaList() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final list = await _repository.fetchAgendaList();
      _agendaList
        ..clear()
        ..addAll(list);
      notifyListeners();
      return agendaList;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Agenda> fetchAgendaById(String idAgenda) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final item = await _repository.fetchAgendaById(idAgenda);
      _upsertAgenda(item);
      return item;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Agenda> createAgenda({
    required String deskripsi,
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
    String? buktiPendukungUrl,
    AppPickedFile? buktiPendukung,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final created = await _repository.createAgenda(
        deskripsi: deskripsi,
        tanggal: tanggal,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        buktiPendukungUrl: buktiPendukungUrl,
        buktiPendukung: buktiPendukung,
      );

      _agendaList.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
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
    _setLoading(true);
    _errorMessage = null;

    try {
      final updated = await _repository.updateAgenda(
        idAgenda,
        deskripsi: deskripsi,
        tanggal: tanggal,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        buktiPendukungUrl: buktiPendukungUrl,
        buktiPendukung: buktiPendukung,
      );

      _upsertAgenda(updated);
      return updated;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Agenda> deleteAgenda(String idAgenda) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final deleted = await _repository.deleteAgenda(idAgenda);
      _agendaList.removeWhere((item) => item.idAgenda == deleted.idAgenda);
      notifyListeners();
      return deleted;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String> getCurrentUserId() async {
    final id = await _api.getUserId();
    if (id == null || id.trim().isEmpty) {
      throw StateError('User ID tidak ditemukan. Silakan login ulang.');
    }
    return id.trim();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _upsertAgenda(Agenda item) {
    final index = _agendaList.indexWhere((e) => e.idAgenda == item.idAgenda);
    if (index == -1) {
      _agendaList.insert(0, item);
    } else {
      _agendaList[index] = item;
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      final message = _extractApiErrorMessage(error.details ?? error.message);
      if (message != null && message.isNotEmpty) return message;
      return 'Terjadi kesalahan (${error.statusCode ?? '-'}) saat mengakses agenda.';
    }

    final message = error.toString().trim();
    if (message.startsWith('Exception:')) {
      return message.replaceFirst('Exception:', '').trim();
    }
    return message;
  }

  String? _extractApiErrorMessage(dynamic node) {
    if (node == null) return null;

    if (node is String) {
      final text = node.trim();
      return text.isEmpty ? null : text;
    }

    if (node is Map) {
      final map = Map<String, dynamic>.from(
        node.map((key, value) => MapEntry(key.toString(), value)),
      );

      for (final key in const <String>['message', 'detail', 'error', 'msg']) {
        final extracted = _extractApiErrorMessage(map[key]);
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }

      for (final value in map.values) {
        final extracted = _extractApiErrorMessage(value);
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }
      return null;
    }

    if (node is Iterable) {
      for (final item in node) {
        final extracted = _extractApiErrorMessage(item);
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }
      return null;
    }

    final text = node.toString().trim();
    return text.isEmpty ? null : text;
  }
}
