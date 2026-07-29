import 'dart:convert';
import 'package:flutter/material.dart';
import 'safe_change_notifier.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/api_error.dart';

class DoseSlot {
  final String medicationId;
  final String medicationNombre;
  final double dosis;
  final String unidad;
  final String? indicaciones;
  final String horaProgramada;
  final String fecha;
  final String estado;
  final Map<String, dynamic>? dose;

  const DoseSlot({
    required this.medicationId,
    required this.medicationNombre,
    required this.dosis,
    required this.unidad,
    this.indicaciones,
    required this.horaProgramada,
    required this.fecha,
    required this.estado,
    this.dose,
  });

  factory DoseSlot.fromJson(Map<String, dynamic> j) => DoseSlot(
        medicationId: j['medication_id'],
        medicationNombre: j['medication_nombre'],
        dosis: (j['dosis'] ?? 0).toDouble(),
        unidad: j['unidad'] ?? '',
        indicaciones: j['indicaciones'],
        horaProgramada: j['hora_programada'],
        fecha: j['fecha'],
        estado: j['estado'] ?? 'pendiente',
        dose: j['dose'],
      );

  bool get isPending => estado == 'pendiente';
  bool get isTomado => estado == 'tomado';
  bool get isOmitido => estado == 'omitido';
}

class DoseSummary {
  final String fecha;
  final int total;
  final int tomadas;
  final int pendientes;
  final List<DoseSlot> schedule;

  const DoseSummary({
    required this.fecha,
    required this.total,
    required this.tomadas,
    required this.pendientes,
    required this.schedule,
  });

  factory DoseSummary.fromJson(Map<String, dynamic> j) => DoseSummary(
        fecha: j['fecha'],
        total: j['total'] ?? 0,
        tomadas: j['tomadas'] ?? 0,
        pendientes: j['pendientes'] ?? 0,
        schedule: (j['schedule'] as List? ?? []).map((e) => DoseSlot.fromJson(e)).toList(),
      );

  double get porcentaje => total == 0 ? 0 : tomadas / total;
}

class DoseProvider extends SafeChangeNotifier {
  static String get _baseUrl => ApiConstants.baseUrl;

  DoseSummary? _today;
  bool _loading = false;
  bool _registering = false;
  String? _error;

  DoseSummary? get today => _today;
  bool get loading => _loading;
  bool get registering => _registering;
  String? get error => _error;

  Future<void> fetchToday(Map<String, String> headers, String patientId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patients/$patientId/doses/today'), headers: headers);
      if (res.statusCode == 200) {
        _today = DoseSummary.fromJson(jsonDecode(res.body)['data']);
      } else {
        _error = extractApiErrorMessage(res.body);
      }
    } catch (_) {
      _error = 'Error de conexión';
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> registerDose(
    Map<String, String> headers,
    String patientId,
    String medicationId, {
    required String estado,
    required String horaProgramada,
    String? horaReal,
    String? notas,
    String? motivoOmision,
  }) async {
    _registering = true;
    notifyListeners();
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients/$patientId/medications/$medicationId/doses'),
        headers: headers,
        body: jsonEncode({
          'estado': estado,
          'hora_programada': horaProgramada,
          if (horaReal != null) 'hora_real': horaReal,
          if (notas != null) 'notas': notas,
          if (motivoOmision != null) 'motivo_omision': motivoOmision,
        }),
      );
      _registering = false;
      if (res.statusCode == 201) {
        await fetchToday(headers, patientId);
        return null;
      }
      notifyListeners();
      return extractApiErrorMessage(res.body, 'Error al registrar');
    } catch (_) {
      _registering = false;
      notifyListeners();
      return 'Error de conexión';
    }
  }

  void clear() {
    _today = null;
    notifyListeners();
  }
}
