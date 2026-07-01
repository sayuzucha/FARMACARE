import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/pill_badge.dart';
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
  String? _searchError;
  bool _loading = false;
  bool _emailVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<CaregiverProvider>().fetchMyInvites(auth.authHeaders());
    });
    _emailCtrl.addListener(() {
      if (_emailVerified || _searchError != null) {
        setState(() { _emailVerified = false; _searchError = null; });
        context.read<CaregiverProvider>().clearFoundUser();
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  bool _validateFormat() {
    final email = _emailCtrl.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(() => _emailError = email.isEmpty ? 'Campo requerido' : !valid ? 'Email inválido' : null);
    return _emailError == null;
  }

  Future<void> _searchUser() async {
    if (!_validateFormat()) return;
    final auth = context.read<AuthProvider>();
    final prov = context.read<CaregiverProvider>();
    final err = await prov.searchUserByEmail(auth.authHeaders(), _emailCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _searchError = err;
      _emailVerified = err == null;
    });
  }

  Future<void> _send() async {
    if (!_emailVerified) { await _searchUser(); return; }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final err = await context.read<CaregiverProvider>().sendInvite(
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

  Future<void> _acceptInvite(ReceivedInvite inv) async {
    final auth = context.read<AuthProvider>();
    final err = await context.read<CaregiverProvider>().acceptInvite(auth.authHeaders(), inv.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Invitación aceptada'),
      backgroundColor: err != null ? AppColors.error : AppColors.success,
    ));
    if (err == null) context.go('/patients');
  }

  Future<void> _rejectInvite(ReceivedInvite inv) async {
    final auth = context.read<AuthProvider>();
    final err = await context.read<CaregiverProvider>().rejectInvite(auth.authHeaders(), inv.id);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientProvider>().activePatient;
    final prov = context.watch<CaregiverProvider>();
    final myInvites = prov.myInvites;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
        title: const Text('Invitar cuidador', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── INVITACIONES RECIBIDAS ──────────────────────────────────
            if (myInvites.isNotEmpty) ...[
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.warningSurface, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.notifications_outlined, size: 16, color: AppColors.warning),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tienes ${myInvites.length} invitación${myInvites.length > 1 ? 'es' : ''} pendiente${myInvites.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ]),
              const SizedBox(height: 10),
              ...myInvites.map((inv) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.person_add_alt_1_outlined, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: inv.invitedByNombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                          const TextSpan(text: ' te invitó a ser cuidador de ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          TextSpan(text: inv.patientNombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        ])),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    PillBadge.fromRol(inv.rol),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectInvite(inv),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Rechazar', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptInvite(inv),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Aceptar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 16),
            ],

            // ── PACIENTE ────────────────────────────────────────────────
            if (patient != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.backgroundSecondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 0.5)),
                child: Row(children: [
                  AvatarWidget(name: patient.nombre, size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(patient.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    if (patient.enfermedades.isNotEmpty)
                      Text(patient.enfermedades.join(', '), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary), overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // ── BUSCAR USUARIO ──────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: AppTextField(
                  label: 'Email de la persona',
                  hint: 'ejemplo@correo.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: prov.searchingUser ? null : _searchUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: prov.searchingUser
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ]),

            // Resultado búsqueda
            if (_searchError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.errorBorder, width: 0.5)),
                child: Row(children: [
                  const Icon(Icons.person_off_outlined, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_searchError!, style: const TextStyle(fontSize: 13, color: AppColors.errorText))),
                ]),
              ),
            ],
            if (_emailVerified && prov.foundUser != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5)),
                child: Row(children: [
                  AvatarWidget(name: prov.foundUser!['nombre'] ?? '?', size: 36),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(prov.foundUser!['nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                    Text(prov.foundUser!['email'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                  ])),
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                ]),
              ),
            ],
            const SizedBox(height: 20),

            // ── ROL ─────────────────────────────────────────────────────
            const Text('Rol', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _RolCard(title: 'Cuidador', description: 'Puede registrar tomas y ver información', icon: Icons.person_outline_rounded, selected: _rol == 'cuidador', onTap: () => setState(() => _rol = 'cuidador'))),
              const SizedBox(width: 10),
              Expanded(child: _RolCard(title: 'Admin', description: 'Acceso completo y gestión de cuidadores', icon: Icons.admin_panel_settings_outlined, selected: _rol == 'admin', onTap: () => setState(() => _rol = 'admin'))),
            ]),
            const SizedBox(height: 20),

            AppTextField(label: 'Mensaje (opcional)', hint: 'Escribe un mensaje personalizado...', controller: _mensajeCtrl, maxLines: 3),
            const SizedBox(height: 24),

            const Text('¿Cómo funciona?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            const _Step(number: '1', text: 'Busca a la persona por su correo registrado en Farmacare'),
            const SizedBox(height: 8),
            const _Step(number: '2', text: 'Le llegará una notificación para aceptar o rechazar'),
            const SizedBox(height: 8),
            const _Step(number: '3', text: 'Una vez aceptada, podrá acceder al perfil del paciente'),
            const SizedBox(height: 28),

            AppButton(
              label: _emailVerified ? 'Enviar invitación' : 'Verificar usuario',
              onPressed: _loading ? null : _send,
              loading: _loading,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _RolCard extends StatelessWidget {
  final String title, description;
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.primaryDark : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ]),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number, text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 22, height: 22,
        decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]);
  }
}
