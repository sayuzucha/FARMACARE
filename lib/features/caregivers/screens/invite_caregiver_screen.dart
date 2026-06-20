import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/caregiver_provider.dart';
import '../../../providers/patient_provider.dart';

class InviteCaregiverScreen extends StatefulWidget {
  final String patientId;
  const InviteCaregiverScreen({super.key, required this.patientId});

  @override
  State<InviteCaregiverScreen> createState() => _InviteCaregiverScreenState();
}

class _InviteCaregiverScreenState extends State<InviteCaregiverScreen> {
  final _emailCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();
  String _rol = 'cuidador';
  String? _emailError;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailCtrl.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(() => _emailError = email.isEmpty ? 'Campo requerido' : !valid ? 'Email inválido' : null);
    return _emailError == null;
  }

  Future<void> _send() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final prov = context.read<CaregiverProvider>();
    final err = await prov.sendInvite(
      auth.authHeaders(),
      widget.patientId,
      _emailCtrl.text.trim(),
      _rol,
      _mensajeCtrl.text.trim().isEmpty ? null : _mensajeCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitación enviada'), backgroundColor: AppColors.success));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientProvider>().activePatient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
        title: const Text('Invitar persona', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (patient != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.backgroundSecondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 0.5)),
                child: Row(
                  children: [
                    AvatarWidget(name: patient.nombre, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          if (patient.enfermedades.isNotEmpty)
                            Text(patient.enfermedades.join(', '), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Email de la persona',
              hint: 'ejemplo@correo.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
            ),
            const SizedBox(height: 20),
            const Text('Rol', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _RolCard(
                  title: 'Cuidador',
                  description: 'Puede registrar tomas y ver información',
                  icon: Icons.person_outline_rounded,
                  selected: _rol == 'cuidador',
                  onTap: () => setState(() => _rol = 'cuidador'),
                )),
                const SizedBox(width: 10),
                Expanded(child: _RolCard(
                  title: 'Admin',
                  description: 'Acceso completo y gestión de cuidadores',
                  icon: Icons.admin_panel_settings_outlined,
                  selected: _rol == 'admin',
                  onTap: () => setState(() => _rol = 'admin'),
                )),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Mensaje (opcional)',
              hint: 'Escribe un mensaje personalizado...',
              controller: _mensajeCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text('¿Cómo funciona?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            const _Step(number: '1', text: 'Se envía un email con la invitación a la persona indicada'),
            const SizedBox(height: 8),
            const _Step(number: '2', text: 'La persona acepta la invitación desde la app o el email'),
            const SizedBox(height: 8),
            const _Step(number: '3', text: 'Una vez aceptada, podrá acceder al perfil del paciente'),
            const SizedBox(height: 28),
            AppButton(label: 'Enviar invitación', onPressed: _send, loading: _loading),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _RolCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RolCard({required this.title, required this.description, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.primaryDark : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      ],
    );
  }
}
