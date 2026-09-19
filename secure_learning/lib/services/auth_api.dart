import 'dart:convert';

import 'api_config.dart';
import 'auth_http_client_stub.dart'
    if (dart.library.html) 'auth_http_client_web.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  const AuthApi._();

  static String? _adminAccessToken;
  static String? _studentAccessToken;
  static Map<String, dynamic>? _cachedStudent;

  static String? get studentAccessToken => _studentAccessToken;
  static Map<String, dynamic>? get cachedStudent => _cachedStudent;

  static String get _baseUrl => ApiConfig.baseUrl;

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
  }) async {
    final response = await _post('/auth/login', {
      'username': username,
      'password': password,
    });
    _studentAccessToken =
        response['accessToken'] as String? ?? response['token'] as String?;
    if (response['student'] != null) {
      _cachedStudent = response['student'] as Map<String, dynamic>;
    }
    return response;
  }

  static Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    final response = await _post('/auth/admin-login', {
      'username': username,
      'password': password,
    });
    _adminAccessToken = response['accessToken'] as String?;
    return response;
  }

  static Future<void> adminHeartbeat() async {
    await _post('/auth/admin-heartbeat', const {}, token: _adminAccessToken);
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String username,
    required String code,
  }) => _post('/auth/verify-email', {'username': username, 'code': code});

  static Future<Map<String, dynamic>> resendEmail({required String username}) =>
      _post('/auth/resend-email', {'username': username});

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _get('/auth/me', token: _studentAccessToken);
    if (response['student'] != null) {
      _cachedStudent = response['student'] as Map<String, dynamic>;
    }
    return response;
  }

  static void logout() {
    _studentAccessToken = null;
    _cachedStudent = null;
    _adminAccessToken = null;
  }

  static Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    final client = createAuthHttpClient();
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body, {
    String? token,
  }) async {
    final client = createAuthHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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
    } finally {
      client.close();
    }
  }
}
