import 'dart:convert';
import 'package:flutter/material.dart';
import 'safe_change_notifier.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/api_error.dart';

class CaregiverUser {
  final String id;
  final String nombre;
  final String email;

  const CaregiverUser({required this.id, required this.nombre, required this.email});

  factory CaregiverUser.fromJson(Map<String, dynamic> j) => CaregiverUser(
        id: j['id']?.toString() ?? '',
        nombre: j['nombre'] ?? '',
        email: j['email'] ?? '',
      );
}

class Caregiver {
  final String id;       // caregiver record id (usado en PATCH/DELETE)
  final String patientId;
  final String userId;
  final String rol;
  final CaregiverUser user;

  const Caregiver({required this.id, required this.patientId, required this.userId, required this.rol, required this.user});

  // API devuelve estructura plana: { id, rol, user_id, nombre, email }
  factory Caregiver.fromJson(Map<String, dynamic> j) {
    final id = j['id']?.toString() ?? '';
    final userId = j['user_id']?.toString() ?? '';
    final user = j['user'] != null
        ? CaregiverUser.fromJson(j['user'])
        : CaregiverUser(id: userId, nombre: j['nombre'] ?? '', email: j['email'] ?? '');
    return Caregiver(
      id: id,
      patientId: j['patient_id']?.toString() ?? '',
      userId: userId,
      rol: j['rol'] ?? 'cuidador',
      user: user,
    );
  }
}

class Invite {
  final String id;
  final String email;
  final String rol;
  final String estado;
  final String? expiresAt;

  const Invite({required this.id, required this.email, required this.rol, required this.estado, this.expiresAt});

  factory Invite.fromJson(Map<String, dynamic> j) => Invite(
        id: j['id']?.toString() ?? '',
        email: j['email'] ?? '',
        rol: j['rol'] ?? 'cuidador',
        estado: j['estado'] ?? 'pendiente',
        expiresAt: j['expires_at'],
      );
}

class ReceivedInvite {
  final String id;
  final String rol;
  final String estado;
  final String patientNombre;
  final String invitedByNombre;

  const ReceivedInvite({
    required this.id,
    required this.rol,
    required this.estado,
    required this.patientNombre,
    required this.invitedByNombre,
  });

  factory ReceivedInvite.fromJson(Map<String, dynamic> j) => ReceivedInvite(
        id: j['id']?.toString() ?? '',
        rol: j['rol'] ?? 'cuidador',
        estado: j['estado'] ?? 'pendiente',
        patientNombre: j['patient']?['nombre'] ?? j['patient_nombre'] ?? 'Paciente',
        invitedByNombre: j['invited_by']?['nombre'] ?? j['invited_by_nombre'] ?? 'Un usuario',
      );
}

class CaregiverProvider extends SafeChangeNotifier {
  static String get _baseUrl => ApiConstants.baseUrl;

  List<Caregiver> _caregivers = [];
  List<Invite> _invites = [];
  List<ReceivedInvite> _myInvites = [];
  Map<String, dynamic>? _foundUser;
  bool _loading = false;
  bool _searchingUser = false;
  String? _error;

  List<Caregiver> get caregivers => _caregivers;
  List<Invite> get invites => _invites;
  List<ReceivedInvite> get myInvites => _myInvites;
  Map<String, dynamic>? get foundUser => _foundUser;
  bool get loading => _loading;
  bool get searchingUser => _searchingUser;
  String? get error => _error;

  static List _parseList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final d = body['data'] ?? body['caregivers'] ?? body['invites'];
      if (d is List) return d;
    }
    return [];
  }

  // GET /users/search?email=
  Future<String?> searchUserByEmail(Map<String, String> headers, String email) async {
    _searchingUser = true;
    _foundUser = null;
    notifyListeners();
    try {
      final uri = Uri.parse('$_baseUrl/users/search').replace(queryParameters: {'email': email});
      final res = await http.get(uri, headers: headers);
      _searchingUser = false;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        _foundUser = body['data'] ?? body;
        notifyListeners();
        return null;
      }
      notifyListeners();
      return extractApiErrorMessage(res.body, 'Esta persona no se ha registrado en la aplicación');
    } catch (_) {
      _searchingUser = false;
      notifyListeners();
      return 'Error de conexión';
    }
  }

  void clearFoundUser() {
    _foundUser = null;
    _searchingUser = false;
    notifyListeners();
  }

  // GET /users/me/invites
  Future<void> fetchMyInvites(Map<String, String> headers) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/users/me/invites'), headers: headers);
      if (res.statusCode == 200) {
        _myInvites = _parseList(jsonDecode(res.body)).map((e) => ReceivedInvite.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // POST /invites/accept  { "invite_id": id }
  Future<String?> acceptInvite(Map<String, String> headers, String inviteId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/invites/accept'),
        headers: headers,
        body: jsonEncode({'invite_id': inviteId}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _myInvites.removeWhere((i) => i.id == inviteId);
        notifyListeners();
        return null;
      }
      return extractApiErrorMessage(res.body, 'Error al aceptar');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  // DELETE /users/me/invites/:id
  Future<String?> rejectInvite(Map<String, String> headers, String inviteId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/users/me/invites/$inviteId'),
        headers: headers,
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _myInvites.removeWhere((i) => i.id == inviteId);
        notifyListeners();
        return null;
      }
      return extractApiErrorMessage(res.body, 'Error al rechazar');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<void> fetchAll(Map<String, String> headers, String patientId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/patients/$patientId/caregivers'), headers: headers),
        http.get(Uri.parse('$_baseUrl/patients/$patientId/invites'), headers: headers),
      ]);
      if (results[0].statusCode == 200) {
        _caregivers = _parseList(jsonDecode(results[0].body)).map((e) => Caregiver.fromJson(e)).toList();
      }
      if (results[1].statusCode == 200) {
        _invites = _parseList(jsonDecode(results[1].body)).map((e) => Invite.fromJson(e)).toList();
      }
    } catch (_) {
      _error = 'Error de conexión';
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> sendInvite(Map<String, String> headers, String patientId, String email, String rol, String? mensaje) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients/$patientId/invites'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'rol': rol,
          if (mensaje != null && mensaje.isNotEmpty) 'mensaje': mensaje,
        }),
      );
      if (res.statusCode == 201) return null;
      return extractApiErrorMessage(res.body, 'Error al enviar invitación');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<String?> cancelInvite(Map<String, String> headers, String patientId, String inviteId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId/invites/$inviteId'),
        headers: headers,
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _invites.removeWhere((i) => i.id == inviteId);
        notifyListeners();
        return null;
      }
      return extractApiErrorMessage(res.body, 'Error al cancelar');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  // PATCH /patients/:id/caregivers/:caregiverId
  Future<String?> changeRole(Map<String, String> headers, String patientId, String caregiverId, String rol) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/patients/$patientId/caregivers/$caregiverId'),
        headers: headers,
        body: jsonEncode({'rol': rol}),
      );
      if (res.statusCode == 200) {
        await fetchAll(headers, patientId);
        return null;
      }
      return extractApiErrorMessage(res.body, 'Error al cambiar rol');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  // DELETE /patients/:id/caregivers/:caregiverId
  Future<String?> removeCaregiver(Map<String, String> headers, String patientId, String caregiverId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId/caregivers/$caregiverId'),
        headers: headers,
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _caregivers.removeWhere((c) => c.id == caregiverId);
        notifyListeners();
        return null;
      }
      return extractApiErrorMessage(res.body, 'Error al remover');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  void clear() {
    _caregivers = [];
    _invites = [];
    _myInvites = [];
    notifyListeners();
  }
}
