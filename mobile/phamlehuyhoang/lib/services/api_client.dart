import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';
  static const String _baseUrlKey = 'custom_api_base_url';

  // Điện thoại thật cần URL Conveyor/LAN, hoặc localhost qua adb reverse.
  // Địa chỉ 10.0.2.2 chỉ được chọn khi chạy Android Emulator.
  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://127.0.0.1:5000' : '',
  );
  static const _requestTimeout = Duration(seconds: 15);

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? _defaultUrl;
  }

  static String _normalizeBaseUrl(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.host.contains(RegExp(r'\s')) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ApiException(
        'Vui lòng mở Cài đặt máy chủ và nhập URL HTTP/HTTPS hợp lệ.',
        0,
      );
    }
    return normalized;
  }

  static Future<void> setBaseUrl(String url) async {
    final normalized = _normalizeBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveAuth(
    String token,
    Map<String, dynamic> userJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userJson));
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<Map<String, String>> _getHeaders({
    bool requireAuth = true,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (requireAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<dynamic> get(String path, {bool requireAuth = true}) =>
      _request('GET', path, requireAuth: requireAuth);

  static Future<dynamic> post(
    String path,
    dynamic body, {
    bool requireAuth = true,
  }) => _request('POST', path, body: body, requireAuth: requireAuth);

  static Future<dynamic> put(
    String path,
    dynamic body, {
    bool requireAuth = true,
  }) => _request('PUT', path, body: body, requireAuth: requireAuth);

  static Future<dynamic> delete(String path, {bool requireAuth = true}) =>
      _request('DELETE', path, requireAuth: requireAuth);

  static String _connectionMessage(Uri url, {bool timedOut = false}) {
    final reason = timedOut
        ? 'Máy chủ không phản hồi sau 15 giây.'
        : 'Không kết nối được máy chủ.';
    final guidance = url.host == '10.0.2.2'
        ? '10.0.2.2 chỉ dùng cho Android Emulator. Điện thoại thật cần URL Conveyor hoặc IP LAN của máy tính.'
        : 'Kiểm tra WebAPI đang chạy và địa chỉ trong Cài đặt máy chủ.';
    return '$reason $guidance';
  }

  static Future<dynamic> _request(
    String method,
    String path, {
    dynamic body,
    required bool requireAuth,
  }) async {
    final baseUrl = _normalizeBaseUrl(await getBaseUrl());
    final url = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders(requireAuth: requireAuth);
    final client = http.Client();
    try {
      final Future<http.Response> pending = switch (method) {
        'GET' => client.get(url, headers: headers),
        'POST' => client.post(url, headers: headers, body: jsonEncode(body)),
        'PUT' => client.put(url, headers: headers, body: jsonEncode(body)),
        'DELETE' => client.delete(url, headers: headers),
        _ => throw ArgumentError.value(method, 'method'),
      };
      final response = await pending.timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(_connectionMessage(url, timedOut: true), 0);
    } on http.ClientException {
      throw ApiException(_connectionMessage(url), 0);
    } finally {
      client.close();
    }
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String msg = 'Lỗi hệ thống (${response.statusCode})';
      if (body is Map && body['message'] is String) {
        msg = body['message'];
      }
      throw ApiException(msg, response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
