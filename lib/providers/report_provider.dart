import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class MedCompliance {
  final String nombre;
  final int total;
  final int tomadas;
  final int omitidas;
  final double porcentaje;

  const MedCompliance({required this.nombre, required this.total, required this.tomadas, required this.omitidas, required this.porcentaje});

  factory MedCompliance.fromJson(Map<String, dynamic> j) => MedCompliance(
        nombre: j['nombre'] ?? '',
        total: j['total'] ?? 0,
        tomadas: j['tomadas'] ?? 0,
        omitidas: j['omitidas'] ?? 0,
        porcentaje: (j['porcentaje'] ?? 0).toDouble(),
      );
}

class ComplianceReport {
  final double porcentaje;
  final int total;
  final int tomadas;
  final int omitidas;
  final String desde;
  final String hasta;
  final List<MedCompliance> desglose;

  const ComplianceReport({
    required this.porcentaje,
    required this.total,
    required this.tomadas,
    required this.omitidas,
    required this.desde,
    required this.hasta,
    required this.desglose,
  });

  factory ComplianceReport.fromJson(Map<String, dynamic> j) => ComplianceReport(
        porcentaje: (j['porcentaje'] ?? 0).toDouble(),
        total: j['total'] ?? 0,
        tomadas: j['tomadas'] ?? 0,
        omitidas: j['omitidas'] ?? 0,
        desde: j['desde'] ?? '',
        hasta: j['hasta'] ?? '',
        desglose: (j['desglose'] as List? ?? []).map((e) => MedCompliance.fromJson(e)).toList(),
      );
}

class ActivityItem {
  final String estado;
  final String fecha;
  final String horaProgramada;
  final String? registradoPor;
  final String? medicamentoNombre;

  const ActivityItem({required this.estado, required this.fecha, required this.horaProgramada, this.registradoPor, this.medicamentoNombre});

  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
        estado: j['estado'] ?? 'pendiente',
        fecha: j['fecha'] ?? '',
        horaProgramada: j['hora_programada'] ?? '',
        registradoPor: j['registrado_por'],
        medicamentoNombre: j['medicamento_nombre'],
      );
}

class ReportProvider extends ChangeNotifier {
  static String get _baseUrl => ApiConstants.baseUrl;

  ComplianceReport? _report;
  List<ActivityItem> _activity = [];
  bool _loading = false;
  String? _error;

  ComplianceReport? get report => _report;
  List<ActivityItem> get activity => _activity;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchCompliance(Map<String, String> headers, String patientId, {String? desde, String? hasta, String? medId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (desde != null) params['desde'] = desde;
      if (hasta != null) params['hasta'] = hasta;
      if (medId != null) params['med_id'] = medId;
      final uri = Uri.parse('$_baseUrl/patients/$patientId/reports/compliance').replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        _report = ComplianceReport.fromJson(jsonDecode(res.body)['data']);
      } else {
        _error = jsonDecode(res.body)['message'] ?? 'Error al cargar reporte';
      }
    } catch (_) {
      _error = 'Error de conexión';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchActivity(Map<String, String> headers, String patientId, {int page = 1}) async {
    try {
      final uri = Uri.parse('$_baseUrl/patients/$patientId/activity').replace(queryParameters: {'limit': '20', 'page': '$page'});
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body is List ? body : (body['data'] ?? body['activity'] ?? [])) as List;
        _activity = list.map((e) => ActivityItem.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  void clear() {
    _report = null;
    _activity = [];
    notifyListeners();
  }
}
