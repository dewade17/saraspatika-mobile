import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum ApiResponseType { json, text, bytes }

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Uri uri;
  final String method;
  final dynamic details;

  ApiException({
    required this.message,
    required this.uri,
    required this.method,
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, method: $method, uri: $uri, message: $message, details: $details)';
  }
}

class ApiUploadFile {
  final http.MultipartFile _file;

  ApiUploadFile._(this._file);

  http.MultipartFile get file => _file;

  factory ApiUploadFile.fromBytes({
    required String fieldName,
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return ApiUploadFile._(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: contentType != null ? _parseMediaType(contentType) : null,
      ),
    );
  }

  factory ApiUploadFile.fromStream({
    required String fieldName,
    required Stream<List<int>> stream,
    required int length,
    required String filename,
    String? contentType,
  }) {
    return ApiUploadFile._(
      http.MultipartFile(
        fieldName,
        stream,
        length,
        filename: filename,
        contentType: contentType != null ? _parseMediaType(contentType) : null,
      ),
    );
  }

  factory ApiUploadFile.fromMultipartFile(http.MultipartFile file) {
    return ApiUploadFile._(file);
  }

  static dynamic _parseMediaType(String contentType) {
    return null;
  }
}

class ApiService {
  ApiService._internal() : _client = http.Client();

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String _tokenKey = 'token';

  static const String _permissionsKey = 'permissions';

  http.Client _client;

  void configure({http.Client? client}) {
    if (client != null) _client = client;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> savePermissions(List<String> permissions) async {
    final normalized =
        permissions
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_permissionsKey, normalized);
  }

  Future<List<String>> getPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_permissionsKey) ?? const <String>[];
  }

  Future<void> clearPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionsKey);
  }

  /// Clears all local auth data (token + permissions). Intended for logout.
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_permissionsKey);
  }

  Uri _parseUrl(Object url) {
    final s = url.toString().trim();
    final uri = Uri.parse(s);

    if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw ArgumentError(
        'Harus kirim URL absolut (http/https), bukan path relatif: $s',
      );
    }

    return uri;
  }

  Uri _buildUri(Object endpoint, {Map<String, dynamic>? queryParameters}) {
    final base = _parseUrl(endpoint);

    if (queryParameters == null || queryParameters.isEmpty) return base;

    final qp = <String, String>{};
    for (final entry in queryParameters.entries) {
      final v = entry.value;
      if (v == null) continue;
      qp[entry.key] = v.toString();
    }

    return base.replace(queryParameters: {...base.queryParameters, ...qp});
  }

  Future<Map<String, String>> _buildHeaders({
    required bool useToken,
    Map<String, String>? headers,
    bool setJsonContentType = false,
    String? tokenOverride,
  }) async {
    final out = <String, String>{'Accept': 'application/json'};

    if (setJsonContentType) {
      out['Content-Type'] = 'application/json';
    }

    if (headers != null) {
      out.addAll(headers);
    }

    if (useToken) {
      final token = tokenOverride ?? await getToken();
      if (token != null && token.isNotEmpty) {
        out['Authorization'] = 'Bearer $token';
      }
    }

    return out;
  }

  void _logRequest({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    Object? body,
  }) {
    if (!kDebugMode) return;

    final safeHeaders = Map<String, String>.from(headers);
    if (safeHeaders.containsKey('Authorization')) {
      safeHeaders['Authorization'] = 'Bearer ***';
    }

    debugPrint('\n[API REQUEST]');
    debugPrint('Method : $method');
    debugPrint('URL    : $url');
    debugPrint('Headers: $safeHeaders');

    if (body != null) {
      final bodyStr = body is String ? body : body.toString();
      debugPrint('Body   : ${_truncate(bodyStr)}');
    }
  }

  void _logResponse({
    required String method,
    required Uri url,
    required int statusCode,
    required String bodyPreview,
  }) {
    if (!kDebugMode) return;

    debugPrint('[API RESPONSE]');
    debugPrint('Method : $method');
    debugPrint('URL    : $url');
    debugPrint('Status : $statusCode');
    if (bodyPreview.isNotEmpty) {
      debugPrint('Body   : ${_truncate(bodyPreview)}\n');
    } else {
      debugPrint('Body   : <empty>\n');
    }
  }

  String _truncate(String s, {int max = 1500}) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…(truncated)';
  }

  bool _isJsonContentType(Map<String, String> headers) {
    final ct = headers.entries
        .firstWhere(
          (e) => e.key.toLowerCase() == 'content-type',
          orElse: () => const MapEntry('', ''),
        )
        .value;
    return ct.toLowerCase().contains('application/json') ||
        ct.toLowerCase().contains('+json');
  }

  String _decodeText(Uint8List bytes) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  dynamic _decodeBody({
    required Uint8List bytes,
    required Map<String, String> headers,
    required ApiResponseType responseType,
  }) {
    if (bytes.isEmpty) return null;

    if (responseType == ApiResponseType.bytes) {
      return bytes;
    }

    final text = _decodeText(bytes);

    if (responseType == ApiResponseType.text) {
      return text;
    }

    if (_isJsonContentType(headers)) {
      return jsonDecode(text);
    }

    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }

  void _throwForStatus({
    required int statusCode,
    required String method,
    required Uri uri,
    required dynamic decodedBody,
  }) {
    final msg = switch (statusCode) {
      400 => 'Bad Request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not Found',
      408 => 'Request Timeout',
      409 => 'Conflict',
      422 => 'Unprocessable Entity',
      429 => 'Too Many Requests',
      500 => 'Server Error',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      _ => 'HTTP Error',
    };

    throw ApiException(
      message: msg,
      uri: uri,
      method: method,
      statusCode: statusCode,
      details: decodedBody,
    );
  }

  Future<dynamic> request(
    Object endpoint, {
    required String method,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    bool useToken = true,
    String? tokenOverride,
    Duration timeout = const Duration(seconds: 30),
    ApiResponseType responseType = ApiResponseType.json,
  }) async {
    final upperMethod = method.toUpperCase();
    final uri = _buildUri(endpoint, queryParameters: queryParameters);

    final bool willSendBody = !(upperMethod == 'GET' || upperMethod == 'HEAD');
    final bool isJsonBody = body is Map || body is List;

    final builtHeaders = await _buildHeaders(
      useToken: useToken,
      headers: headers,
      setJsonContentType:
          willSendBody &&
          isJsonBody &&
          !(headers?.keys.any((k) => k.toLowerCase() == 'content-type') ??
              false),
      tokenOverride: tokenOverride,
    );

    Object? requestBodyForLog = body;
    http.BaseRequest req;

    if (willSendBody) {
      final r = http.Request(upperMethod, uri);

      if (body == null) {
      } else if (isJsonBody) {
        r.body = jsonEncode(body);
      } else if (body is String) {
        r.body = body;
      } else if (body is Uint8List) {
        r.bodyBytes = body;
        r.headers.putIfAbsent('Content-Type', () => 'application/octet-stream');
      } else if (body is List<int>) {
        r.bodyBytes = Uint8List.fromList(body);
        r.headers.putIfAbsent('Content-Type', () => 'application/octet-stream');
      } else {
        r.body = body.toString();
        r.headers.putIfAbsent('Content-Type', () => 'text/plain');
      }

      r.headers.addAll(builtHeaders);
      req = r;
    } else {
      final r = http.Request(upperMethod, uri);
      r.headers.addAll(builtHeaders);
      req = r;
      requestBodyForLog = null;
    }

    _logRequest(
      method: upperMethod,
      url: uri,
      headers: builtHeaders,
      body: requestBodyForLog,
    );

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(req).timeout(timeout);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out',
        uri: uri,
        method: upperMethod,
      );
    } catch (e) {
      throw ApiException(
        message: 'Network error: $e',
        uri: uri,
        method: upperMethod,
      );
    }

    final bytes = await streamed.stream.toBytes();
    final decoded = _decodeBody(
      bytes: bytes,
      headers: streamed.headers,
      responseType: responseType,
    );

    _logResponse(
      method: upperMethod,
      url: uri,
      statusCode: streamed.statusCode,
      bodyPreview: decoded is Uint8List
          ? '<bytes ${decoded.length}>'
          : (decoded?.toString() ?? ''),
    );

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      _throwForStatus(
        statusCode: streamed.statusCode,
        method: upperMethod,
        uri: uri,
        decodedBody: decoded,
      );
    }

    return decoded;
  }

  Future<dynamic> multipart(
    Object endpoint, {
    String method = 'POST',
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<ApiUploadFile>? files,
    bool useToken = true,
    String? tokenOverride,
    Duration timeout = const Duration(seconds: 60),
    ApiResponseType responseType = ApiResponseType.json,
  }) async {
    final upperMethod = method.toUpperCase();
    final uri = _buildUri(endpoint, queryParameters: queryParameters);

    final builtHeaders = await _buildHeaders(
      useToken: useToken,
      headers: headers,
      setJsonContentType: false,
      tokenOverride: tokenOverride,
    );

    final req = http.MultipartRequest(upperMethod, uri);
    req.headers.addAll(builtHeaders);

    if (fields != null && fields.isNotEmpty) {
      req.fields.addAll(fields);
    }

    if (files != null && files.isNotEmpty) {
      for (final f in files) {
        req.files.add(f.file);
      }
    }

    _logRequest(
      method: upperMethod,
      url: uri,
      headers: builtHeaders,
      body: {
        'fields': fields ?? const {},
        'files': (files ?? const []).map((e) => e.file.filename).toList(),
      },
    );

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(req).timeout(timeout);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out',
        uri: uri,
        method: upperMethod,
      );
    } catch (e) {
      throw ApiException(
        message: 'Network error: $e',
        uri: uri,
        method: upperMethod,
      );
    }

    final bytes = await streamed.stream.toBytes();
    final decoded = _decodeBody(
      bytes: bytes,
      headers: streamed.headers,
      responseType: responseType,
    );

    _logResponse(
      method: upperMethod,
      url: uri,
      statusCode: streamed.statusCode,
      bodyPreview: decoded is Uint8List
          ? '<bytes ${decoded.length}>'
          : (decoded?.toString() ?? ''),
    );

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      _throwForStatus(
        statusCode: streamed.statusCode,
        method: upperMethod,
        uri: uri,
        decodedBody: decoded,
      );
    }

    return decoded;
  }

  Future<dynamic> get(
    Object endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool useToken = true,
    String? tokenOverride,
    Duration timeout = const Duration(seconds: 30),
    ApiResponseType responseType = ApiResponseType.json,
  }) {
    return request(
      endpoint,
      method: 'GET',
      queryParameters: queryParameters,
      headers: headers,
      useToken: useToken,
      tokenOverride: tokenOverride,
      timeout: timeout,
      responseType: responseType,
    );
  }

  Future<dynamic> post(
    Object endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    bool useToken = true,
    String? tokenOverride,
    Duration timeout = const Duration(seconds: 30),
    ApiResponseType responseType = ApiResponseType.json,
  }) {
    return request(
      endpoint,
      method: 'POST',
      queryParameters: queryParameters,
      headers: headers,
      body: body,
      useToken: useToken,
      tokenOverride: tokenOverride,
      timeout: timeout,
      responseType: responseType,
    );
  }

  Future<dynamic> put(
    Object endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    bool useToken = true,
    String? tokenOverride,
    Duration timeout = const Duration(seconds: 30),
    ApiResponseType responseType = ApiResponseType.json,
  }) {
    return request(
      endpoint,
      method: 'PUT',
      queryParameters: queryParameters,
      headers: headers,
      body: body,
      useToken: useToken,
      tokenOverride: tokenOverride,
      timeout: timeout,
      responseType: responseType,
    );
  }

  Future<dynamic> patch(
    Object endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    bool useToken = true,
    String? tokenOverride,
    Duration timeout = const Duration(seconds: 30),
    ApiResponseType responseType = ApiResponseType.json,
  }) {
    return request(
      endpoint,
      method: 'PATCH',
      queryParameters: queryParameters,
      headers: headers,
      body: body,
      useToken: useToken,
      tokenOverride: tokenOverride,
      timeout: timeout,
      responseType: responseType,
    );
  }

  Future<dynamic> delete(
    Object endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    bool useToken = true,
    String? tokenOverride,
    Duration timeout = const Duration(seconds: 30),
    ApiResponseType responseType = ApiResponseType.json,
  }) {
    return request(
      endpoint,
      method: 'DELETE',
      queryParameters: queryParameters,
      headers: headers,
      body: body,
      useToken: useToken,
      tokenOverride: tokenOverride,
      timeout: timeout,
      responseType: responseType,
    );
  }

  Future<dynamic> head(
    Object endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool useToken = true,
    String? tokenOverride,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return request(
      endpoint,
      method: 'HEAD',
      queryParameters: queryParameters,
      headers: headers,
      useToken: useToken,
      tokenOverride: tokenOverride,
      timeout: timeout,
      responseType: ApiResponseType.text,
    );
  }

  Future<dynamic> options(
    Object endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool useToken = true,
    String? tokenOverride,
    Duration timeout = const Duration(seconds: 30),
    ApiResponseType responseType = ApiResponseType.text,
  }) {
    return request(
      endpoint,
      method: 'OPTIONS',
      queryParameters: queryParameters,
      headers: headers,
      useToken: useToken,
      tokenOverride: tokenOverride,
      timeout: timeout,
      responseType: responseType,
    );
  }
}
