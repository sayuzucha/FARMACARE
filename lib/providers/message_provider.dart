import 'dart:convert';
import 'package:flutter/material.dart';
import 'safe_change_notifier.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/api_error.dart';

class PatientMessage {
  final String id;
  final String patientId;
  final String userId;
  final String userName;
  final String contenido;
  final DateTime createdAt;

  const PatientMessage({
    required this.id,
    required this.patientId,
    required this.userId,
    required this.userName,
    required this.contenido,
    required this.createdAt,
  });

  factory PatientMessage.fromJson(Map<String, dynamic> j) => PatientMessage(
        id: j['id']?.toString() ?? '',
        patientId: j['patient_id']?.toString() ?? '',
        userId: j['user_id']?.toString() ?? '',
        userName: j['user_nombre'] ?? j['user']?['nombre'] ?? 'Usuario',
        contenido: j['contenido'] ?? '',
        createdAt: _parseDate(j['created_at'] ?? j['createdAt'] ?? j['timestamp'] ?? j['fecha']),
      );

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is int) {
      // Unix timestamp: si es muy grande es milisegundos, si no es segundos
      return v > 1e10
          ? DateTime.fromMillisecondsSinceEpoch(v)
          : DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    if (v is String) {
      final dt = DateTime.tryParse(v);
      if (dt != null) return dt.toLocal();
    }
    return DateTime.now();
  }
}

class MessageProvider extends SafeChangeNotifier {
  static String get _baseUrl => ApiConstants.baseUrl;

  List<PatientMessage> _messages = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;

  List<PatientMessage> get messages => _messages;
  bool get loading => _loading;
  bool get sending => _sending;
  String? get error => _error;

  static List _parseList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final d = body['data'] ?? body['messages'];
      if (d is List) return d;
    }
    return [];
  }

  Future<void> fetchMessages(Map<String, String> headers, String patientId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patients/$patientId/messages'), headers: headers);
      if (res.statusCode == 200) {
        _messages = _parseList(jsonDecode(res.body)).map((e) => PatientMessage.fromJson(e)).toList();
      } else {
        _error = extractApiErrorMessage(res.body, 'Error al cargar mensajes');
      }
    } catch (e) {
      _error = 'Error: $e';
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
      return extractApiErrorMessage(res.body, 'Error al enviar');
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
      return extractApiErrorMessage(res.body, 'Error al eliminar');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  void clear() {
    _messages = [];
    notifyListeners();
  }
}
