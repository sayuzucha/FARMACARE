import 'dart:convert';
import 'package:flutter/material.dart';
import 'safe_change_notifier.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/api_error.dart';

class Patient {
  final String id;
  final String nombre;
  final String? fechaNacimiento;
  final String sexo;
  final double? pesoKg;
  final String? tipoSangre;
  final String? telefonoEmergencia;
  final List<String> enfermedades;
  final List<String> alergiasMedicamentos;
  final String? otrasAlergias;
  final String? medicoNombre;
  final String? medicoEspecialidad;
  final String? medicoTelefono;
  final String? notas;
  final String? rol;
  final int totalMedicamentos;
  final String? codigo;

  const Patient({
    required this.id,
    required this.nombre,
    this.fechaNacimiento,
    required this.sexo,
    this.pesoKg,
    this.tipoSangre,
    this.telefonoEmergencia,
    this.enfermedades = const [],
    this.alergiasMedicamentos = const [],
    this.otrasAlergias,
    this.medicoNombre,
    this.medicoEspecialidad,
    this.medicoTelefono,
    this.notas,
    this.rol,
    this.totalMedicamentos = 0,
    this.codigo,
  });

  int? get edad {
    if (fechaNacimiento == null) return null;
    final dob = DateTime.tryParse(fechaNacimiento!);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  factory Patient.fromJson(Map<String, dynamic> j) => Patient(
        id: j['id'],
        nombre: j['nombre'],
        fechaNacimiento: j['fecha_nacimiento'],
        sexo: j['sexo'] ?? 'masculino',
        pesoKg: j['peso_kg']?.toDouble(),
        tipoSangre: j['tipo_sangre'],
        telefonoEmergencia: j['telefono_emergencia'],
        enfermedades: _parseStringList(j['enfermedades']),
        alergiasMedicamentos: _parseStringList(j['alergias_medicamentos']),
        otrasAlergias: j['otras_alergias'],
        medicoNombre: j['medico_nombre'],
        medicoEspecialidad: j['medico_especialidad'],
        medicoTelefono: j['medico_telefono'],
        notas: j['notas'],
        rol: j['rol'],
        totalMedicamentos: j['total_medicamentos'] ?? 0,
        codigo: j['codigo'],
      );

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '[]') return [];
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) return List<String>.from(decoded);
      } catch (_) {}
      return [trimmed];
    }
    return [];
  }
}

/// Preview de paciente devuelto por GET /patients/code/:codigo
class PatientPreview {
  final String nombre;
  final List<String> cuidadoresNombres;

  const PatientPreview({required this.nombre, required this.cuidadoresNombres});

  factory PatientPreview.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] ?? j) as Map<String, dynamic>;
    final rawList = data['cuidadores'];
    final List cuidadores = rawList is List ? rawList : [];
    return PatientPreview(
      nombre: data['nombre']?.toString() ?? '',
      cuidadoresNombres: cuidadores
          .map<String>((c) => (c is Map ? c['nombre']?.toString() : c?.toString()) ?? '')
          .where((n) => n.isNotEmpty)
          .toList(),
    );
  }
}

class PatientProvider extends SafeChangeNotifier {
  static String get _baseUrl => ApiConstants.baseUrl;

  List<Patient> _patients = [];
  Patient? _activePatient;
  bool _loading = false;
  String? _error;

  List<Patient> get patients => _patients;
  Patient? get activePatient => _activePatient;
  bool get loading => _loading;
  String? get error => _error;

  void setActivePatient(Patient p) {
    _activePatient = p;
    notifyListeners();
  }

  Future<void> fetchPatients(Map<String, String> headers) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patients'), headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final raw = body['data'] ?? body['patients'] ?? body;
        final list = raw is List ? raw : [];
        _patients = list.map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _error = 'Error ${res.statusCode}: ${extractApiErrorMessage(res.body, res.body)}';
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> createPatient(Map<String, String> headers, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 201) {
        await fetchPatients(headers);
        return null;
      }
      return body['message'] ?? 'Error al crear paciente';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<String?> updatePatient(Map<String, String> headers, String patientId, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await fetchPatients(headers);
        return null;
      }
      return body['message'] ?? 'Error al actualizar';
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<String?> deletePatient(Map<String, String> headers, String patientId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: headers,
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _patients.removeWhere((p) => p.id == patientId);
        if (_activePatient?.id == patientId) _activePatient = null;
        notifyListeners();
        return null;
      }
      return extractApiErrorMessage(res.body, 'Error al eliminar');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  /// GET /patients/code/:codigo — preview antes de unirse
  /// Devuelve PatientPreview o null si el código no existe.
  /// [error] se rellena con el mensaje del API si falla.
  Future<(PatientPreview?, String?)> fetchPatientByCode(Map<String, String> headers, String codigo) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/patients/code/${codigo.trim().toUpperCase()}'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return (PatientPreview.fromJson(jsonDecode(res.body)), null);
      }
      final msg = extractApiErrorMessage(res.body, 'Código no encontrado');
      return (null, msg as String?);
    } catch (_) {
      return (null, 'Error de conexión');
    }
  }

  /// POST /patients/join — unirse como cuidador con un código
  /// Devuelve null si ok, o el mensaje de error (incluyendo 409 si ya eres cuidador).
  Future<String?> joinPatient(Map<String, String> headers, String codigo) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients/join'),
        headers: headers,
        body: jsonEncode({'codigo': codigo.trim().toUpperCase()}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchPatients(headers);
        return null;
      }
      return extractApiErrorMessage(res.body, 'Error al unirse al paciente');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  Future<String?> inviteCaregiver(Map<String, String> headers, String patientId, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients/$patientId/invites'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) return null;
      return extractApiErrorMessage(res.body, 'Error al invitar');
    } catch (_) {
      return 'Error de conexión';
    }
  }

  void clear() {
    _patients = [];
    _activePatient = null;
    notifyListeners();
  }
}
