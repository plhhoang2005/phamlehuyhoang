import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';
import 'api_client.dart';

class AuthService {
  static Future<UserDto?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('user_data');
    if (jsonStr == null) return null;
    try {
      return UserDto.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  static Future<PreAuthResponse> register({
    required String username,
    required String email,
    required String fullName,
    required String password,
    String? studentCode,
  }) async {
    final res = await ApiClient.post('/api/auth/register', {
      'username': username,
      'email': email,
      'fullName': fullName,
      'password': password,
      'studentCode': studentCode,
    }, requireAuth: false);

    return PreAuthResponse.fromJson(res);
  }

  static Future<PreAuthResponse> login({
    required String username,
    required String password,
  }) async {
    final res = await ApiClient.post('/api/auth/login', {
      'username': username,
      'password': password,
    }, requireAuth: false);

    return PreAuthResponse.fromJson(res);
  }

  static Future<PreAuthResponse> faceLogin({
    required String username,
    required String imageBase64,
  }) async {
    final res = await ApiClient.post('/api/auth/face-login', {
      'username': username,
      'imageBase64': imageBase64,
    }, requireAuth: false);

    return PreAuthResponse.fromJson(res);
  }

  static Future<void> verifyEmail({
    required String ticket,
    required String code,
  }) async {
    await ApiClient.post('/api/auth/verify-email', {
      'ticket': ticket,
      'code': code,
    }, requireAuth: false);
  }

  static Future<AuthResponse> verifyOtp({
    required String ticket,
    required String code,
  }) async {
    final res = await ApiClient.post('/api/auth/verify-otp', {
      'ticket': ticket,
      'code': code,
    }, requireAuth: false);

    final authRes = AuthResponse.fromJson(res);
    await ApiClient.saveAuth(authRes.token, authRes.user.toJson());
    return authRes;
  }

  static Future<PreAuthResponse> resendOtp({required String ticket}) async {
    final res = await ApiClient.post('/api/auth/resend-otp', {
      'ticket': ticket,
    }, requireAuth: false);

    return PreAuthResponse.fromJson(res);
  }

  static Future<void> registerFace(String imageBase64) async {
    await ApiClient.post('/api/auth/register-face', {
      'imageBase64': imageBase64,
    });
  }

  static Future<void> logout() async {
    await ApiClient.clearAuth();
  }
}
