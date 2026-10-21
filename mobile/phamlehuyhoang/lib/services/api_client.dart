import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';
  static const String _baseUrlKey = 'custom_api_base_url';

  // Mặc định:
  // Android Emulator: http://10.0.2.2:5000
  // Khác (Web/Windows): http://127.0.0.1:5000
  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://127.0.0.1:5000' : 'http://10.0.2.2:5000',
  );

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? _defaultUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveAuth(String token, Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userJson));
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requireAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<dynamic> get(String path, {bool requireAuth = true}) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders(requireAuth: requireAuth);

    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  static Future<dynamic> post(String path, dynamic body, {bool requireAuth = true}) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders(requireAuth: requireAuth);

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String path, dynamic body, {bool requireAuth = true}) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders(requireAuth: requireAuth);

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String path, {bool requireAuth = true}) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders(requireAuth: requireAuth);

    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
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
      if (body is Map && body.containsKey('message')) {
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
