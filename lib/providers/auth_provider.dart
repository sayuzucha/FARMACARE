import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'safe_change_notifier.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/api_error.dart';

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

  // ── Autenticación de 2 pasos ──────────────────────────────────────────
  // Mientras haya un twoFactorToken pendiente, el usuario pasó email+password
  // pero todavía no tiene sesión: falta que ingrese el código del correo.
  String? _twoFactorToken;
  String? _twoFactorEmail;

  // ── Verificación de correo al registrarse ─────────────────────────────
  // La cuenta NO se crea hasta que se confirma el código; mientras tanto
  // solo existe este token pendiente (nada se guarda en el backend todavía).
  String? _registrationToken;
  String? _registrationEmail;

  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get loading => _loading;
  bool get isAuthenticated => _accessToken != null && _user != null;
  String? get error => _error;
  bool get needsTwoFactor => _twoFactorToken != null;
  String? get twoFactorEmail => _twoFactorEmail;
  bool get needsRegistrationVerification => _registrationToken != null;
  String? get registrationEmail => _registrationEmail;

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

  /// Ping al servidor para despertarlo (se llama al iniciar la app)
  static Future<void> warmUp() async {
    try {
      await http
          .get(Uri.parse('${ApiConstants.baseUrl.replaceAll('/api/v1', '')}/health'))
          .timeout(const Duration(seconds: 50));
    } catch (_) {}
  }

  /// POST con timeout de 45s y un reintento automático si falla
  Future<http.Response> _post(String path, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final h = {'Content-Type': 'application/json', ...?headers};
    final b = jsonEncode(body);
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        return await http.post(uri, headers: h, body: b).timeout(const Duration(seconds: 45));
      } catch (_) {
        if (attempt == 1) rethrow;
        await Future.delayed(const Duration(seconds: 3));
      }
    }
    throw Exception('Sin respuesta del servidor');
  }

  /// Paso 1 del login (email + password). Si las credenciales son correctas
  /// pero la cuenta requiere 2FA, NO inicia sesión: deja `needsTwoFactor` en
  /// true y el llamador debe navegar a la pantalla de verificación y usar
  /// `verifyTwoFactor`. Devuelve un mensaje de error, o null si todo bien
  /// (ya sea que abrió sesión directo o quedó pendiente de 2FA).
  Future<String?> login({required String email, required String password}) async {
    _error = null;
    _twoFactorToken = null;
    _twoFactorEmail = null;
    try {
      final res = await _post('/auth/login', {'email': email, 'password': password});
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>;
        if (data['requiresTwoFactor'] == true) {
          _twoFactorToken = data['twoFactorToken'] as String?;
          _twoFactorEmail = data['email'] as String?;
          notifyListeners();
          return null;
        }
        await _saveSession(data);
        return null;
      }
      _error = extractApiErrorMessage(res.body, 'Error al iniciar sesión');
      notifyListeners();
      return _error;
    } catch (_) {
      _error = 'El servidor tardó en responder. Intenta de nuevo.';
      notifyListeners();
      return _error;
    }
  }

  /// Paso 2 del login: valida el código de 6 dígitos enviado por correo.
  /// Si es correcto, abre la sesión real. Devuelve el mensaje de error, o
  /// null si funcionó.
  Future<String?> verifyTwoFactor(String code) async {
    if (_twoFactorToken == null) {
      return 'La verificación expiró. Inicia sesión de nuevo.';
    }
    try {
      final res = await _post('/auth/login/verify-2fa', {
        'twoFactorToken': _twoFactorToken,
        'code': code,
      });
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        await _saveSession(body['data']);
        _twoFactorToken = null;
        _twoFactorEmail = null;
        return null;
      }
      return extractApiErrorMessage(res.body, 'Código incorrecto');
    } catch (_) {
      return 'El servidor tardó en responder. Intenta de nuevo.';
    }
  }

  /// Pide un código nuevo sin volver a pedir la contraseña.
  Future<String?> resendTwoFactorCode() async {
    if (_twoFactorToken == null) {
      return 'La verificación expiró. Inicia sesión de nuevo.';
    }
    try {
      final res = await _post('/auth/login/resend-2fa', {'twoFactorToken': _twoFactorToken});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] as Map<String, dynamic>;
        _twoFactorToken = data['twoFactorToken'] as String?;
        _twoFactorEmail = data['email'] as String?;
        notifyListeners();
        return null;
      }
      return extractApiErrorMessage(res.body, 'No se pudo reenviar el código');
    } catch (_) {
      return 'El servidor tardó en responder. Intenta de nuevo.';
    }
  }

  /// Cancela la verificación en curso (ej. el usuario le da "atrás").
  void cancelTwoFactor() {
    _twoFactorToken = null;
    _twoFactorEmail = null;
    notifyListeners();
  }

  /// Paso 1 del registro: valida los datos y manda un código de verificación
  /// al correo. La cuenta todavía NO existe — hace falta `verifyRegistration`
  /// para que se cree de verdad.
  Future<String?> register({required String nombre, required String email, required String password}) async {
    _error = null;
    _registrationToken = null;
    _registrationEmail = null;
    try {
      final res = await _post('/auth/register', {'nombre': nombre, 'email': email, 'password': password});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] as Map<String, dynamic>;
        if (data['requiresVerification'] == true) {
          _registrationToken = data['verificationToken'] as String?;
          _registrationEmail = data['email'] as String?;
          notifyListeners();
          return null;
        }
      }
      _error = extractApiErrorMessage(res.body, 'Error al registrarse');
      notifyListeners();
      return _error;
    } catch (_) {
      _error = 'El servidor tardó en responder. Intenta de nuevo.';
      notifyListeners();
      return _error;
    }
  }

  /// Paso 2 del registro: valida el código. Si es correcto, ahí sí se crea
  /// la cuenta en el backend y se abre la sesión automáticamente.
  Future<String?> verifyRegistration(String code) async {
    if (_registrationToken == null) {
      return 'La verificación expiró. Regístrate de nuevo.';
    }
    try {
      final res = await _post('/auth/register/verify', {
        'verificationToken': _registrationToken,
        'code': code,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        await _saveSession(body['data']);
        _registrationToken = null;
        _registrationEmail = null;
        return null;
      }
      return extractApiErrorMessage(res.body, 'Código incorrecto');
    } catch (_) {
      return 'El servidor tardó en responder. Intenta de nuevo.';
    }
  }

  /// Pide un código de verificación de registro nuevo.
  Future<String?> resendRegistrationCode() async {
    if (_registrationToken == null) {
      return 'La verificación expiró. Regístrate de nuevo.';
    }
    try {
      final res = await _post('/auth/register/resend', {'verificationToken': _registrationToken});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] as Map<String, dynamic>;
        _registrationToken = data['verificationToken'] as String?;
        _registrationEmail = data['email'] as String?;
        notifyListeners();
        return null;
      }
      return extractApiErrorMessage(res.body, 'No se pudo reenviar el código');
    } catch (_) {
      return 'El servidor tardó en responder. Intenta de nuevo.';
    }
  }

  /// Cancela el registro pendiente (ej. el usuario le da "atrás").
  void cancelRegistration() {
    _registrationToken = null;
    _registrationEmail = null;
    notifyListeners();
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode == 200) return null;
      return extractApiErrorMessage(res.body);
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
