import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CaregiverUser {
  final String id;
  final String nombre;
  final String email;
  final String? fotoUrl;

  const CaregiverUser({required this.id, required this.nombre, required this.email, this.fotoUrl});

  factory CaregiverUser.fromJson(Map<String, dynamic> j) => CaregiverUser(
        id: j['id'],
        nombre: j['nombre'],
        email: j['email'],
        fotoUrl: j['foto_url'],
      );
}

class Caregiver {
  final String id;
  final String patientId;
  final String userId;
  final String rol;
  final CaregiverUser user;

  const Caregiver({required this.id, required this.patientId, required this.userId, required this.rol, required this.user});

  factory Caregiver.fromJson(Map<String, dynamic> j) => Caregiver(
        id: j['id'],
        patientId: j['patient_id'],
        userId: j['user_id'],
        rol: j['rol'] ?? 'cuidador',
        user: CaregiverUser.fromJson(j['user']),
      );
}

class Invite {
  final String id;
  final String email;
  final String rol;
  final String estado;
  final String? expiresAt;

  const Invite({required this.id, required this.email, required this.rol, required this.estado, this.expiresAt});

  factory Invite.fromJson(Map<String, dynamic> j) => Invite(
        id: j['id'],
        email: j['email'],
        rol: j['rol'] ?? 'cuidador',
        estado: j['estado'] ?? 'pendiente',
        expiresAt: j['expires_at'],
      );
}

class CaregiverProvider extends ChangeNotifier {
  static const _baseUrl = 'http://10.0.2.2:3000/api/v1';

  List<Caregiver> _caregivers = [];
  List<Invite> _invites = [];
  bool _loading = false;
  String? _error;

  List<Caregiver> get caregivers => _caregivers;
  List<Invite> get invites => _invites;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchAll(Map<String, String> headers, String patientId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/patients/$patientId/caregivers'), headers: headers),
        http.get(Uri.parse('$_baseUrl/patients/$patientId/invites'), headers: headers),
      ]);
      final caregiversRes = results[0];
      final invitesRes = results[1];
      if (caregiversRes.statusCode == 200) {
        final list = jsonDecode(caregiversRes.body)['data'] as List;
        _caregivers = list.map((e) => Caregiver.fromJson(e)).toList();
      }
      if (invitesRes.statusCode == 200) {
        final list = jsonDecode(invitesRes.body)['data'] as List;
        _invites = list.map((e) => Invite.fromJson(e)).toList();
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
      return jsonDecode(res.body)['message'] ?? 'Error al enviar invitación';
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
      return jsonDecode(res.body)['message'] ?? 'Error al cancelar';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<String?> removeCaregiver(Map<String, String> headers, String patientId, String userId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId/caregivers/$userId'),
        headers: headers,
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _caregivers.removeWhere((c) => c.userId == userId);
        notifyListeners();
        return null;
      }
      return jsonDecode(res.body)['message'] ?? 'Error al remover';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<String?> changeRole(Map<String, String> headers, String patientId, String userId, String rol) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/patients/$patientId/caregivers/$userId'),
        headers: headers,
        body: jsonEncode({'rol': rol}),
      );
      if (res.statusCode == 200) {
        await fetchAll(headers, patientId);
        return null;
      }
      return jsonDecode(res.body)['message'] ?? 'Error al cambiar rol';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  void clear() {
    _caregivers = [];
    _invites = [];
    notifyListeners();
  }
}
