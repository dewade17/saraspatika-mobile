import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:saraspatika/core/database/database_helper.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/dto/absensi_checkin.dart';
import 'package:saraspatika/feature/absensi/data/dto/absensi_checkout.dart';
import 'package:saraspatika/feature/absensi/data/dto/absensi_status.dart';
import 'package:saraspatika/feature/absensi/data/provider/offline_provider.dart';
import 'package:saraspatika/feature/absensi/data/repository/absensi_repository.dart';

enum AbsensiUiEventType { loading, success, error }

class AbsensiUiEvent {
  final AbsensiUiEventType type;
  final String title;
  final String message;
  final String? confirmText;

  const AbsensiUiEvent({
    required this.type,
    required this.title,
    required this.message,
    this.confirmText,
  });

  factory AbsensiUiEvent.loading() => const AbsensiUiEvent(
    type: AbsensiUiEventType.loading,
    title: 'Memproses...',
    message: 'Mengirim data absensi dan memverifikasi wajah.',
  );

  factory AbsensiUiEvent.success(String message) => AbsensiUiEvent(
    type: AbsensiUiEventType.success,
    title: 'Berhasil!',
    message: message,
    confirmText: 'OK',
  );

  factory AbsensiUiEvent.error(String message) => AbsensiUiEvent(
    type: AbsensiUiEventType.error,
    title: 'Terjadi Kesalahan',
    message: message,
    confirmText: 'Coba Lagi',
  );
}

class AbsensiProvider extends ChangeNotifier {
  AbsensiProvider({AbsensiRepository? repository, ApiService? api})
    : _repository = repository ?? AbsensiRepository(),
      _api = api ?? ApiService();

  final AbsensiRepository _repository;
  final ApiService _api;
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _loading = false;
  String? _errorMessage;

  AbsensiStatus? _status;
  Map<String, dynamic>? _lastCheckInResponse;
  Map<String, dynamic>? _lastCheckOutResponse;
  bool _hasLocalPendingCheckIn = false;

  AbsensiUiEvent? _uiEvent;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;

  AbsensiStatus? get status => _status;
  Map<String, dynamic>? get lastCheckInResponse => _lastCheckInResponse;
  Map<String, dynamic>? get lastCheckOutResponse => _lastCheckOutResponse;

  AbsensiUiEvent? get uiEvent => _uiEvent;

  bool get hasLocalPendingCheckIn => _hasLocalPendingCheckIn;

  void consumeUiEvent() {
    _uiEvent = null;
  }

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
        final msg = d['message'] ?? d['detail'] ?? d['error'] ?? d['msg'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (e.statusCode == 400) return 'Input tidak valid.';
      if (e.statusCode == 401) return 'Unauthorized.';
      if (e.statusCode == 403) return 'Tidak diizinkan.';
      if (e.statusCode == 404) return 'Data tidak ditemukan.';
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

  Future<AbsensiStatus?> fetchStatus({String? userId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final resolvedId = (userId != null && userId.trim().isNotEmpty)
          ? userId.trim()
          : await _resolveStoredUserId();
      final data = await _repository.fetchStatus(userId: resolvedId);
      _hasLocalPendingCheckIn = false;

      final pendingCheckIn = await _db.getPendingCheckInForUserOnDate(
        resolvedId,
        DateTime.now(),
      );

      if (data.item?.waktuMasuk == null && pendingCheckIn != null) {
        final capturedAtRaw = pendingCheckIn['captured_at']?.toString();
        final capturedAt = capturedAtRaw != null
            ? DateTime.tryParse(capturedAtRaw)?.toLocal()
            : null;
        final mergedItem = AbsensiItem(
          idAbsensi: data.item?.idAbsensi ?? '',
          faceVerifiedMasuk: data.item?.faceVerifiedMasuk ?? false,
          faceVerifiedPulang: data.item?.faceVerifiedPulang ?? false,
          statusMasuk: data.item?.statusMasuk ?? 'PENDING',
          statusPulang: data.item?.statusPulang,
          waktuMasuk: capturedAt ?? DateTime.now().toLocal(),
          waktuPulang: data.item?.waktuPulang,
        );
        _status = AbsensiStatus(ok: data.ok, item: mergedItem);
        _hasLocalPendingCheckIn = true;
      } else {
        _status = data;
      }
      notifyListeners();
      return data;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> checkIn({
    required CheckInRequest request,
    required File imageFile,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final resolvedId = request.userId.trim().isNotEmpty
          ? request.userId.trim()
          : await _resolveStoredUserId();

      final req = resolvedId == request.userId.trim()
          ? request
          : CheckInRequest(
              userId: resolvedId,
              locationId: request.locationId,
              lat: request.lat,
              lng: request.lng,
              capturedAt: request.capturedAt,
            );

      final res = await _repository.checkIn(request: req, imageFile: imageFile);
      _lastCheckInResponse = res;

      try {
        await fetchStatus(userId: resolvedId);
      } catch (_) {}

      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required CheckOutRequest request,
    required File imageFile,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final resolvedId = request.userId.trim().isNotEmpty
          ? request.userId.trim()
          : await _resolveStoredUserId();

      final req = resolvedId == request.userId.trim()
          ? request
          : CheckOutRequest(
              userId: resolvedId,
              absensiId: request.absensiId,
              locationId: request.locationId,
              lat: request.lat,
              lng: request.lng,
              capturedAt: request.capturedAt,
            );

      final res = await _repository.checkOut(
        request: req,
        imageFile: imageFile,
      );
      _lastCheckOutResponse = res;

      try {
        await fetchStatus(userId: resolvedId);
      } catch (_) {}

      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitCheckInWithFace({
    required OfflineProvider offlineProvider,
    required File imageFile,
    required String? locationId,
    required double? lat,
    required double? lng,
  }) async {
    if (locationId == null ||
        locationId.trim().isEmpty ||
        lat == null ||
        lng == null) {
      _uiEvent = AbsensiUiEvent.error(
        'Lokasi absensi belum dipilih atau koordinat belum tersedia.',
      );
      notifyListeners();
      return;
    }

    _uiEvent = AbsensiUiEvent.loading();
    notifyListeners();

    try {
      final resolvedId = await _resolveStoredUserId();

      await offlineProvider.processAttendance(
        userId: resolvedId,
        type: 'checkin',
        lat: lat,
        lng: lng,
        imagePath: imageFile.path,
        locationId: locationId.trim(),
      );

      try {
        await fetchStatus(userId: resolvedId);
      } catch (_) {}

      final waktuMasuk =
          _status?.item?.waktuMasuk?.toLocal() ?? DateTime.now().toLocal();
      final jamMasuk = DateFormat('HH:mm').format(waktuMasuk);

      _uiEvent = AbsensiUiEvent.success(
        'Anda berhasil melakukan check-in pada pukul $jamMasuk.',
      );
      notifyListeners();
    } catch (e) {
      final msg = _errorMessage ?? _friendlyError(e);
      _uiEvent = AbsensiUiEvent.error(msg);
      notifyListeners();
    }
  }

  Future<void> submitCheckOutWithFace({
    required OfflineProvider offlineProvider,
    required File imageFile,
    required String absensiId,
    required String? locationId,
    required double? lat,
    required double? lng,
    bool allowEmptyAbsensiId = false,
  }) async {
    if (locationId == null ||
        locationId.trim().isEmpty ||
        (!allowEmptyAbsensiId && absensiId.trim().isEmpty) ||
        lat == null ||
        lng == null) {
      _uiEvent = AbsensiUiEvent.error(
        'Lokasi absensi belum dipilih atau koordinat belum tersedia.',
      );
      notifyListeners();
      return;
    }

    _uiEvent = AbsensiUiEvent.loading();
    notifyListeners();

    try {
      final resolvedId = await _resolveStoredUserId();

      await offlineProvider.processAttendance(
        userId: resolvedId,
        type: 'checkout',
        lat: lat,
        lng: lng,
        imagePath: imageFile.path,
        locationId: locationId.trim(),
        absensiId: absensiId.trim(),
      );

      try {
        await fetchStatus(userId: resolvedId);
      } catch (_) {}

      final waktuPulang =
          _status?.item?.waktuPulang?.toLocal() ?? DateTime.now().toLocal();
      final jamPulang = DateFormat('HH:mm').format(waktuPulang);

      _uiEvent = AbsensiUiEvent.success(
        'You have successfully checked out at $jamPulang.',
      );
      notifyListeners();
    } catch (e) {
      final msg = _errorMessage ?? _friendlyError(e);
      _uiEvent = AbsensiUiEvent.error(msg);
      notifyListeners();
    }
  }
}
