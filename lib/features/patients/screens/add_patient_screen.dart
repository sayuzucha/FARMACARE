import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/patient_provider.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  int _step = 0;
  bool _loading = false;
  String? _error;

  final _nombreCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _sangreCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  String _sexo = 'masculino';

  final List<String> _enfermedades = [];
  final _alergiasCtrl = TextEditingController();
  final _otrasAlergiasCtrl = TextEditingController();
  final _medicoCtrl = TextEditingController();
  final _especialidadCtrl = TextEditingController();
  final _medicoTelCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  final _inviteEmailCtrl = TextEditingController();
  String _inviteRol = 'cuidador';
  final List<Map<String, String>> _invitados = [];

  static const _enfermedadesOpciones = ['Diabetes tipo 2', 'Hipertensión', 'Artritis', 'Osteoporosis', 'Dislipidemia', 'Cardiopatía', 'Insuf. renal', 'Alzheimer'];

  @override
  void dispose() {
    _nombreCtrl.dispose(); _fechaCtrl.dispose(); _pesoCtrl.dispose();
    _sangreCtrl.dispose(); _telCtrl.dispose(); _alergiasCtrl.dispose();
    _otrasAlergiasCtrl.dispose(); _medicoCtrl.dispose(); _especialidadCtrl.dispose();
    _medicoTelCtrl.dispose(); _notasCtrl.dispose(); _inviteEmailCtrl.dispose();
    super.dispose();
  }

  void _nextStep() => setState(() => _step++);
  void _prevStep() => setState(() => _step--);

  void _addInvitado() {
    final email = _inviteEmailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _invitados.add({'email': email, 'rol': _inviteRol});
      _inviteEmailCtrl.clear();
    });
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthProvider>();
    final patientProv = context.read<PatientProvider>();

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'fecha_nacimiento': _fechaCtrl.text.trim(),
      'sexo': _sexo,
      if (_pesoCtrl.text.isNotEmpty) 'peso_kg': double.tryParse(_pesoCtrl.text) ?? 0,
      if (_sangreCtrl.text.isNotEmpty) 'tipo_sangre': _sangreCtrl.text.trim(),
      if (_telCtrl.text.isNotEmpty) 'telefono_emergencia': _telCtrl.text.trim(),
      'enfermedades': _enfermedades,
      if (_alergiasCtrl.text.isNotEmpty) 'alergias_medicamentos': _alergiasCtrl.text.split(',').map((e) => e.trim()).toList(),
      if (_otrasAlergiasCtrl.text.isNotEmpty) 'otras_alergias': _otrasAlergiasCtrl.text.trim(),
      if (_medicoCtrl.text.isNotEmpty) 'medico_nombre': _medicoCtrl.text.trim(),
      if (_especialidadCtrl.text.isNotEmpty) 'medico_especialidad': _especialidadCtrl.text.trim(),
      if (_medicoTelCtrl.text.isNotEmpty) 'medico_telefono': _medicoTelCtrl.text.trim(),
      if (_notasCtrl.text.isNotEmpty) 'notas': _notasCtrl.text.trim(),
    };

    final err = await patientProv.createPatient(auth.authHeaders(), data);
    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
      return;
    }

    final newPatient = patientProv.patients.isNotEmpty ? patientProv.patients.first : null;
    if (newPatient != null) {
      for (final inv in _invitados) {
        await patientProv.inviteCaregiver(auth.authHeaders(), newPatient.id, inv);
      }
    }

    if (mounted) context.go('/patients');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: _step == 0 ? () => context.pop() : _prevStep,
          icon: Icon(_step == 0 ? Icons.close_rounded : Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: Text(_step == 0 ? 'Datos personales' : _step == 1 ? 'Historial médico' : 'Invitar cuidadores', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        actions: [Text('${_step + 1} / 3', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)), const SizedBox(width: 16)],
      ),
      body: Column(
        children: [
          _StepDots(current: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _step == 0 ? _buildStep1() : _step == 1 ? _buildStep2() : _buildStep3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        AppTextField(label: 'Nombre completo', controller: _nombreCtrl, prefixIcon: Icons.person_outline_rounded),
        const SizedBox(height: 14),
        AppTextField(label: 'Fecha de nacimiento', hint: 'YYYY-MM-DD', controller: _fechaCtrl, prefixIcon: Icons.calendar_today_outlined, keyboardType: TextInputType.datetime),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sexo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(children: ['masculino', 'femenino', 'otro'].map((s) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: _SexoChip(value: s, selected: _sexo == s, onTap: () => setState(() => _sexo = s))))).toList()),
          ],
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: AppTextField(label: 'Peso (kg)', controller: _pesoCtrl, keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: AppTextField(label: 'Tipo de sangre', hint: 'O+', controller: _sangreCtrl)),
        ]),
        const SizedBox(height: 14),
        AppTextField(label: 'Teléfono de emergencia', controller: _telCtrl, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 28),
        AppButton(label: 'Continuar', onPressed: _nombreCtrl.text.isNotEmpty && _fechaCtrl.text.isNotEmpty ? _nextStep : null),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enfermedades crónicas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: _enfermedadesOpciones.map((e) => _EnfChip(label: e, selected: _enfermedades.contains(e), onTap: () => setState(() => _enfermedades.contains(e) ? _enfermedades.remove(e) : _enfermedades.add(e)))).toList()),
        const SizedBox(height: 20),
        AppTextField(label: 'Alergias a medicamentos', hint: 'Ej. Penicilina, Sulfonamidas', controller: _alergiasCtrl),
        const SizedBox(height: 14),
        AppTextField(label: 'Otras alergias', hint: 'Ej. Látex, alimentos...', controller: _otrasAlergiasCtrl),
        const SizedBox(height: 14),
        AppTextField(label: 'Nombre del médico', controller: _medicoCtrl, prefixIcon: Icons.medical_services_outlined),
        const SizedBox(height: 14),
        AppTextField(label: 'Especialidad', controller: _especialidadCtrl),
        const SizedBox(height: 14),
        AppTextField(label: 'Teléfono del médico', hint: '+52 123 456 7890', controller: _medicoTelCtrl, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        AppTextField(label: 'Notas adicionales', controller: _notasCtrl, maxLines: 3),
        const SizedBox(height: 28),
        AppButton(label: 'Continuar', onPressed: _nextStep),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Invita a familiares o cuidadores para que también puedan ver y registrar tomas. Puedes saltar este paso y hacerlo después.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 20),
        AppTextField(label: 'Correo electrónico', hint: 'nombre@correo.com', controller: _inviteEmailCtrl, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        Row(children: ['cuidador', 'admin'].map((r) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _RolCard(value: r, selected: _inviteRol == r, onTap: () => setState(() => _inviteRol = r))))).toList()),
        const SizedBox(height: 12),
        AppButton(label: 'Agregar persona', variant: AppButtonVariant.secondary, icon: Icons.person_add_outlined, onPressed: _addInvitado),
        if (_invitados.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Personas agregadas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ..._invitados.map((inv) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.backgroundSecondary, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderLight, width: 0.5)),
                child: Row(
                  children: [
                    Expanded(child: Text(inv['email']!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                    PillBadge.fromRol(inv['rol']!),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: () => setState(() => _invitados.remove(inv)), child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiary)),
                  ],
                ),
              )),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
        ],
        const SizedBox(height: 28),
        AppButton(label: 'Crear paciente', onPressed: _loading ? null : _submit, loading: _loading),
        const SizedBox(height: 12),
        AppButton(label: 'Saltar este paso', variant: AppButtonVariant.ghost, onPressed: _loading ? null : _submit),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  final int current;
  const _StepDots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(color: i == current ? AppColors.primary : AppColors.borderLight, borderRadius: BorderRadius.circular(4)),
        )),
      ),
    );
  }
}

class _SexoChip extends StatelessWidget {
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _SexoChip({required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 0.5),
        ),
        alignment: Alignment.center,
        child: Text(value[0].toUpperCase() + value.substring(1), style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w500 : FontWeight.w400, color: selected ? AppColors.primaryDark : AppColors.textSecondary)),
      ),
    );
  }
}

class _EnfChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _EnfChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoSurface : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.info : AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[const Icon(Icons.check_rounded, size: 12, color: AppColors.infoText), const SizedBox(width: 4)],
            Text(label, style: TextStyle(fontSize: 12, color: selected ? AppColors.infoText : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RolCard extends StatelessWidget {
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _RolCard({required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAdmin = value == 'admin';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 0.5),
        ),
        child: Column(
          children: [
            Icon(isAdmin ? Icons.shield_outlined : Icons.favorite_border_rounded, size: 20, color: selected ? AppColors.primary : AppColors.textTertiary),
            const SizedBox(height: 4),
            Text(isAdmin ? 'Admin' : 'Cuidador', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? AppColors.primaryDark : AppColors.textSecondary)),
            Text(isAdmin ? 'Gestiona todo' : 'Ve y registra tomas', style: TextStyle(fontSize: 10, color: selected ? AppColors.primary : AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class PillBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const PillBadge({super.key, required this.label, required this.bg, required this.fg});

  factory PillBadge.fromRol(String rol) => PillBadge(label: rol == 'admin' ? 'Admin' : 'Cuidador', bg: rol == 'admin' ? AppColors.infoSurface : AppColors.backgroundTertiary, fg: rol == 'admin' ? AppColors.infoText : AppColors.textSecondary);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
      );
}
