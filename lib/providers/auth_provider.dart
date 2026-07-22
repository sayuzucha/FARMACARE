import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'safe_change_notifier.dart';
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

class AuthProvider extends SafeChangeNotifier {
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

  /// Decodifica el payload del JWT (base64url) y extrae {id, nombre, email}.
  /// Devuelve null si el token no tiene esos campos.
  AuthUser? _parseTokenUser(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // base64url → base64 estándar
      String seg = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (seg.length % 4 != 0) seg += '=';
      final decoded = jsonDecode(utf8.decode(Uint8List.fromList(base64Decode(seg))));
      if (decoded['id'] == null || decoded['nombre'] == null) return null;
      return AuthUser(
        id: decoded['id'].toString(),
        nombre: decoded['nombre'],
        email: decoded['email'] ?? '',
        telefono: decoded['telefono'],
      );
    } catch (_) {
      return null;
    }
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
      // Intenta leer datos del usuario directo del payload del JWT
      final userFromToken = _parseTokenUser(token);
      if (userFromToken != null) {
        _user = userFromToken;
      } else {
        // Fallback: llamar a /users/me (tokens sin los campos en payload)
        await _fetchMe();
      }
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

  Future<void> refreshUser() async {
    await _fetchMe();
    notifyListeners();
  }

  /// POST con timeout de 20s y un reintento automático si falla
  Future<http.Response> _post(String path, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final h = {'Content-Type': 'application/json', ...?headers};
    final b = jsonEncode(body);
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        return await http.post(uri, headers: h, body: b).timeout(const Duration(seconds: 20));
      } catch (_) {
        if (attempt == 1) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Sin respuesta del servidor');
  }

  Future<String?> login({required String email, required String password}) async {
    _error = null;
    try {
      final res = await _post('/auth/login', {'email': email, 'password': password});
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveSession(body['data']);
        return null;
      }
      _error = body['message'] ?? 'Error al iniciar sesión';
      notifyListeners();
      return _error;
    } catch (_) {
      _error = 'El servidor tardó en responder. Intenta de nuevo.';
      notifyListeners();
      return _error;
    }
  }

  Future<String?> register({required String nombre, required String email, required String password}) async {
    _error = null;
    try {
      final res = await _post('/auth/register', {'nombre': nombre, 'email': email, 'password': password});
      final body = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return null;
      }
      _error = body['message'] ?? 'Error al registrarse';
      notifyListeners();
      return _error;
    } catch (_) {
      _error = 'El servidor tardó en responder. Intenta de nuevo.';
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
    // Preferir datos del payload JWT; si no los trae, usar data['user']
    final userFromToken = _parseTokenUser(_accessToken!);
    _user = userFromToken ?? (data['user'] != null ? AuthUser.fromJson(data['user']) : null);
    await _storage.write(key: 'access_token', value: _accessToken);
    if (data['refreshToken'] != null) {
      await _storage.write(key: 'refresh_token', value: data['refreshToken']);
    }
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
