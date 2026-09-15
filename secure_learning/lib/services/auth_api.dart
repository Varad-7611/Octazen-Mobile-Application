import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  const AuthApi._();

  static String get _baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://127.0.0.1:5000/api';
  }

  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String mobile,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) => _post('/auth/signup', {
    'fullName': fullName,
    'mobile': mobile,
    'email': email,
    'username': username,
    'password': password,
    'confirmPassword': confirmPassword,
  });

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) => _post('/auth/login', {'username': username, 'password': password});

  static Future<Map<String, dynamic>> verifyEmail({
    required String username,
    required String code,
  }) => _post('/auth/verify-email', {'username': username, 'code': code});

  static Future<Map<String, dynamic>> resendEmail({required String username}) =>
      _post('/auth/resend-email', {'username': username});

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(data['message'] as String? ?? 'Request failed.');
      }
      return data;
    } on AuthApiException {
      rethrow;
    } on Exception {
      throw const AuthApiException(
        'Unable to reach the server. Check that the backend is running.',
      );
    }
  }
}
