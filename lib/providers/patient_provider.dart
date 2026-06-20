import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
        enfermedades: List<String>.from(j['enfermedades'] ?? []),
        alergiasMedicamentos: List<String>.from(j['alergias_medicamentos'] ?? []),
        otrasAlergias: j['otras_alergias'],
        medicoNombre: j['medico_nombre'],
        medicoEspecialidad: j['medico_especialidad'],
        medicoTelefono: j['medico_telefono'],
        notas: j['notas'],
        rol: j['rol'],
        totalMedicamentos: j['total_medicamentos'] ?? 0,
      );
}

class PatientProvider extends ChangeNotifier {
  static const _baseUrl = 'http://10.0.2.2:3000/api/v1';

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
        final list = jsonDecode(res.body)['data'] as List;
        _patients = list.map((e) => Patient.fromJson(e)).toList();
      } else {
        _error = jsonDecode(res.body)['message'];
      }
    } catch (_) {
      _error = 'Error de conexión';
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

  Future<String?> inviteCaregiver(Map<String, String> headers, String patientId, Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients/$patientId/invites'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (res.statusCode == 201) return null;
      return jsonDecode(res.body)['message'] ?? 'Error al invitar';
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
