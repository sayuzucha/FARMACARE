import 'dart:convert';
import 'package:flutter/material.dart';
import 'safe_change_notifier.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/api_error.dart';

class DoctorAppointment {
  final String id;
  final String patientId;
  final String fecha;       // YYYY-MM-DD
  final String? hora;       // HH:MM
  final String? medicoNombre;
  final String? especialidad;
  final String? lugar;
  final String? notas;

  const DoctorAppointment({
    required this.id,
    required this.patientId,
    required this.fecha,
    this.hora,
    this.medicoNombre,
    this.especialidad,
    this.lugar,
    this.notas,
  });

  factory DoctorAppointment.fromJson(Map<String, dynamic> j) => DoctorAppointment(
        id: j['id']?.toString() ?? '',
        patientId: j['patient_id']?.toString() ?? '',
        fecha: (j['fecha'] ?? '').toString().split('T').first,
        hora: j['hora'],
        medicoNombre: j['medico_nombre'],
        especialidad: j['especialidad'],
        lugar: j['lugar'],
        notas: j['notas'],
      );

  DateTime? get fechaDate => DateTime.tryParse(fecha);
}

class AppointmentProvider extends SafeChangeNotifier {
  static String get _baseUrl => ApiConstants.baseUrl;

  List<DoctorAppointment> _appointments = [];
  bool _loading = false;
  String? _error;

  List<DoctorAppointment> get appointments => _appointments;
  bool get loading => _loading;
  String? get error => _error;

  static List _parseList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final d = body['data'] ?? body['appointments'];
      if (d is List) return d;
    }
    return [];
  }

  Future<void> fetchAppointments(Map<String, String> headers, String patientId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patients/$patientId/appointments'), headers: headers);
      if (res.statusCode == 200) {
        _appointments = _parseList(jsonDecode(res.body)).map((e) => DoctorAppointment.fromJson(e)).toList();
      } else {
        _error = extractApiErrorMessage(res.body, 'Error al cargar citas');
      }
    } catch (_) {
      _error = 'Error de conexión';
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> createAppointment(Map<String, String> headers, String patientId, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients/$patientId/appointments'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) {
        await fetchAppointments(headers, patientId);
        return null;
      }
      return extractApiErrorMessage(res.body, 'Error al crear cita');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<String?> deleteAppointment(Map<String, String> headers, String patientId, String appointmentId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId/appointments/$appointmentId'),
        headers: headers,
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _appointments.removeWhere((a) => a.id == appointmentId);
        notifyListeners();
        return null;
      }
      return extractApiErrorMessage(res.body, 'Error al eliminar');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Set<String> get fechasConCita => _appointments.map((a) => a.fecha.split('T').first).toSet();

  void clear() {
    _appointments = [];
    notifyListeners();
  }
}
