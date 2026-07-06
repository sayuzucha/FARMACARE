import 'dart:convert';
import 'package:flutter/material.dart';
import 'safe_change_notifier.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class AppNotification {
  final String id;
  final String titulo;
  final String cuerpo;
  final String tipo;
  final bool leida;
  final String? patientId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.tipo,
    required this.leida,
    this.patientId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        titulo: j['titulo'] ?? '',
        cuerpo: j['cuerpo'] ?? '',
        tipo: j['tipo'] ?? 'sistema',
        leida: j['leida'] ?? false,
        patientId: j['patient_id'],
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );

  AppNotification copyWith({bool? leida}) => AppNotification(
        id: id,
        titulo: titulo,
        cuerpo: cuerpo,
        tipo: tipo,
        leida: leida ?? this.leida,
        patientId: patientId,
        createdAt: createdAt,
      );
}

class NotificationProvider extends SafeChangeNotifier {
  static String get _baseUrl => ApiConstants.baseUrl;

  List<AppNotification> _notifications = [];
  bool _loading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.leida).length;
  bool get loading => _loading;

  Future<void> fetchNotifications(Map<String, String> headers, {bool soloNoLeidas = false}) async {
    _loading = true;
    notifyListeners();
    try {
      final uri = Uri.parse('$_baseUrl/users/me/notifications').replace(
        queryParameters: soloNoLeidas ? {'leidas': 'false'} : null,
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body is List ? body : (body['data'] ?? body['notifications'] ?? [])) as List;
        _notifications = list.map((e) => AppNotification.fromJson(e)).toList();
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(Map<String, String> headers, String notifId) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/users/me/notifications/$notifId/read'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final idx = _notifications.indexWhere((n) => n.id == notifId);
        if (idx != -1) {
          _notifications[idx] = _notifications[idx].copyWith(leida: true);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void clear() {
    _notifications = [];
    notifyListeners();
  }
}
