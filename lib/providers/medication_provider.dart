import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Medication {
  final String id;
  final String nombre;
  final double dosis;
  final String unidad;
  final String viaAdministracion;
  final List<String> horarios;
  final int cantidad;
  final int? frecuenciaHoras;
  final int? duracionDias;
  final List<int> diasSemana;
  final String fechaInicio;
  final String? fechaFin;
  final String? indicaciones;
  final bool activo;
  final String? motivoSuspension;

  const Medication({
    required this.id,
    required this.nombre,
    required this.dosis,
    required this.unidad,
    required this.viaAdministracion,
    required this.horarios,
    this.cantidad = 1,
    this.frecuenciaHoras,
    this.duracionDias,
    this.diasSemana = const [],
    required this.fechaInicio,
    this.fechaFin,
    this.indicaciones,
    required this.activo,
    this.motivoSuspension,
  });

  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
        id: j['id'],
        nombre: j['nombre'],
        dosis: (j['dosis'] ?? 0).toDouble(),
        unidad: j['unidad'] ?? '',
        viaAdministracion: j['via_administracion'] ?? '',
        horarios: List<String>.from(j['horarios'] ?? []),
        cantidad: j['cantidad'] ?? 1,
        frecuenciaHoras: j['frecuencia_horas'],
        duracionDias: j['duracion_dias'],
        diasSemana: List<int>.from(j['dias_semana'] ?? []),
        fechaInicio: j['fecha_inicio'] ?? '',
        fechaFin: j['fecha_fin'],
        indicaciones: j['indicaciones'],
        activo: j['activo'] ?? true,
        motivoSuspension: j['motivo_suspension'],
      );

  bool activoEnDia(DateTime fecha) {
    if (!activo) return false;
    final inicio = DateTime.tryParse(fechaInicio);
    if (inicio != null && fecha.isBefore(DateTime(inicio.year, inicio.month, inicio.day))) return false;
    if (fechaFin != null) {
      final fin = DateTime.tryParse(fechaFin!);
      if (fin != null && fecha.isAfter(DateTime(fin.year, fin.month, fin.day))) return false;
    } else if (duracionDias != null && inicio != null) {
      final fin = inicio.add(Duration(days: duracionDias!));
      if (fecha.isAfter(fin)) return false;
    }
    if (diasSemana.isNotEmpty && !diasSemana.contains(fecha.weekday)) return false;
    return true;
  }
}

class MedicationProvider extends ChangeNotifier {
  static const _baseUrl = 'http://10.0.2.2:3000/api/v1';

  List<Medication> _medications = [];
  bool _loading = false;
  String? _error;

  List<Medication> get medications => _medications;
  List<Medication> get active => _medications.where((m) => m.activo).toList();
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchMedications(Map<String, String> headers, String patientId, {bool soloActivos = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final uri = Uri.parse('$_baseUrl/patients/$patientId/medications').replace(
        queryParameters: soloActivos ? {'activos': 'true'} : null,
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List;
        _medications = list.map((e) => Medication.fromJson(e)).toList();
      } else {
        _error = jsonDecode(res.body)['message'] ?? 'Error al cargar medicamentos';
      }
    } catch (_) {
      _error = 'Error de conexión';
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> createMedication(Map<String, String> headers, String patientId, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients/$patientId/medications'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) {
        await fetchMedications(headers, patientId);
        return null;
      }
      return jsonDecode(res.body)['message'] ?? 'Error al crear medicamento';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<String?> updateMedication(Map<String, String> headers, String patientId, String medId, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/patients/$patientId/medications/$medId'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        await fetchMedications(headers, patientId);
        return null;
      }
      return jsonDecode(res.body)['message'] ?? 'Error al actualizar';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<String?> toggleActive(Map<String, String> headers, String patientId, String medId, bool activo, {String? motivo}) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/patients/$patientId/medications/$medId'),
        headers: headers,
        body: jsonEncode({
          'activo': activo,
          if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
        }),
      );
      if (res.statusCode == 200) {
        await fetchMedications(headers, patientId);
        return null;
      }
      return jsonDecode(res.body)['message'] ?? 'Error';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  void clear() {
    _medications = [];
    notifyListeners();
  }
}
