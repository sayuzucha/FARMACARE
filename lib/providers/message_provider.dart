import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PatientMessage {
  final String id;
  final String patientId;
  final String userId;
  final String userName;
  final String? userFotoUrl;
  final String contenido;
  final DateTime createdAt;

  const PatientMessage({
    required this.id,
    required this.patientId,
    required this.userId,
    required this.userName,
    this.userFotoUrl,
    required this.contenido,
    required this.createdAt,
  });

  factory PatientMessage.fromJson(Map<String, dynamic> j) => PatientMessage(
        id: j['id'],
        patientId: j['patient_id'],
        userId: j['user_id'],
        userName: j['user_nombre'] ?? j['user']?['nombre'] ?? 'Usuario',
        userFotoUrl: j['user_foto_url'] ?? j['user']?['foto_url'],
        contenido: j['contenido'] ?? '',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

class MessageProvider extends ChangeNotifier {
  static const _baseUrl = 'http://10.0.2.2:3000/api/v1';

  List<PatientMessage> _messages = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;

  List<PatientMessage> get messages => _messages;
  bool get loading => _loading;
  bool get sending => _sending;
  String? get error => _error;

  Future<void> fetchMessages(Map<String, String> headers, String patientId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patients/$patientId/messages'), headers: headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List;
        _messages = list.map((e) => PatientMessage.fromJson(e)).toList();
      } else {
        _error = jsonDecode(res.body)['message'] ?? 'Error al cargar mensajes';
      }
    } catch (_) {
      _error = 'Error de conexión';
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> sendMessage(Map<String, String> headers, String patientId, String contenido) async {
    _sending = true;
    notifyListeners();
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients/$patientId/messages'),
        headers: headers,
        body: jsonEncode({'contenido': contenido}),
      );
      _sending = false;
      if (res.statusCode == 201) {
        await fetchMessages(headers, patientId);
        return null;
      }
      notifyListeners();
      return jsonDecode(res.body)['message'] ?? 'Error al enviar';
    } catch (_) {
      _sending = false;
      notifyListeners();
      return 'Error de conexión';
    }
  }

  Future<String?> deleteMessage(Map<String, String> headers, String patientId, String messageId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId/messages/$messageId'),
        headers: headers,
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _messages.removeWhere((m) => m.id == messageId);
        notifyListeners();
        return null;
      }
      return jsonDecode(res.body)['message'] ?? 'Error al eliminar';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  void clear() {
    _messages = [];
    notifyListeners();
  }
}
