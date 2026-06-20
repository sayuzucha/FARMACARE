import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DoctorAppointment {
  final String id;
  final String patientId;
  final String fecha;
  final String? hora;
  final String? motivo;
  final String? medico;

  const DoctorAppointment({
    required this.id,
    required this.patientId,
    required this.fecha,
    this.hora,
    this.motivo,
    this.medico,
  });

  factory DoctorAppointment.fromJson(Map<String, dynamic> j) => DoctorAppointment(
        id: j['id'],
        patientId: j['patient_id'],
        fecha: j['fecha'] ?? '',
        hora: j['hora'],
        motivo: j['motivo'],
        medico: j['medico'],
      );

  DateTime? get fechaDate => DateTime.tryParse(fecha);
}

class AppointmentProvider extends ChangeNotifier {
  static const _baseUrl = 'http://10.0.2.2:3000/api/v1';

  List<DoctorAppointment> _appointments = [];
  bool _loading = false;
  String? _error;

  List<DoctorAppointment> get appointments => _appointments;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchAppointments(Map<String, String> headers, String patientId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patients/$patientId/appointments'), headers: headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List;
        _appointments = list.map((e) => DoctorAppointment.fromJson(e)).toList();
      } else {
        _error = jsonDecode(res.body)['message'] ?? 'Error al cargar citas';
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
      return jsonDecode(res.body)['message'] ?? 'Error al crear cita';
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
      return jsonDecode(res.body)['message'] ?? 'Error al eliminar';
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
