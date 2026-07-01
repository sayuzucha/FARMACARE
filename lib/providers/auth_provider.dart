import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class AuthUser {
  final String id;
  final String nombre;
  final String email;
  final String? telefono;

  const AuthUser({required this.id, required this.nombre, required this.email, this.telefono});

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id']?.toString() ?? '',
        nombre: j['nombre'] ?? '',
        email: j['email'] ?? '',
        telefono: j['telefono'],
      );
}

class AuthProvider extends ChangeNotifier {
  static String get _baseUrl => ApiConstants.baseUrl;
  static const _storage = FlutterSecureStorage();

  AuthUser? _user;
  String? _accessToken;
  bool _loading = true;
  String? _error;

  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get loading => _loading;
  bool get isAuthenticated => _accessToken != null && _user != null;
  String? get error => _error;

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    _loading = true;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        _loading = false;
        notifyListeners();
        return;
      }
      _accessToken = token;
      await _fetchMe();
    } catch (_) {
      await _clearSession();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _fetchMe() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: _authHeaders(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'];
      _user = AuthUser.fromJson(data);
    } else {
      await _clearSession();
    }
  }

  Future<String?> login({required String email, required String password}) async {
    _error = null;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveSession(body['data']);
        return null;
      }
      _error = body['message'] ?? 'Error al iniciar sesión';
      notifyListeners();
      return _error;
    } catch (_) {
      _error = 'Error de conexión';
      notifyListeners();
      return _error;
    }
  }

  Future<String?> register({required String nombre, required String email, required String password}) async {
    _error = null;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre, 'email': email, 'password': password}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 201) {
        await _saveSession(body['data']);
        return null;
      }
      _error = body['message'] ?? 'Error al registrarse';
      notifyListeners();
      return _error;
    } catch (_) {
      _error = 'Error de conexión';
      notifyListeners();
      return _error;
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode == 200) return null;
      return jsonDecode(res.body)['message'] ?? 'Error';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      }
    } catch (_) {}
    await _clearSession();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _accessToken = data['accessToken'];
    _user = AuthUser.fromJson(data['user']);
    await _storage.write(key: 'access_token', value: _accessToken);
    await _storage.write(key: 'refresh_token', value: data['refreshToken']);
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Map<String, String> _authHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      };

  Map<String, String> authHeaders() => _authHeaders();
}
