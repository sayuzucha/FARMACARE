import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/pill_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/caregiver_provider.dart';
import '../../../providers/patient_provider.dart';

class CaregiversScreen extends StatefulWidget {
  final String patientId;
  const CaregiversScreen({super.key, required this.patientId});

  @override
  State<CaregiversScreen> createState() => _CaregiversScreenState();
}

class _CaregiversScreenState extends State<CaregiversScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<CaregiverProvider>().fetchAll(auth.authHeaders(), widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final patient = context.watch<PatientProvider>().activePatient;
    final caregiverProv = context.watch<CaregiverProvider>();
    final isAdmin = patient?.rol == 'admin';

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cuidadores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (patient != null) Text(patient.nombre, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () => context.push('/patients/${widget.patientId}/caregivers/invite'),
              icon: const Icon(Icons.person_add_outlined, color: AppColors.primary),
            ),
        ],
      ),
      body: caregiverProv.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader(title: 'Miembros del grupo', count: caregiverProv.caregivers.length),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 0.5)),
                    child: Column(
                      children: caregiverProv.caregivers.asMap().entries.map((e) {
                        final idx = e.key;
                        final c = e.value;
                        final isMe = c.userId == auth.user?.id;
                        return Column(
                          children: [
                            ListTile(
                              leading: AvatarWidget(name: c.user.nombre, size: 40, photoUrl: c.user.fotoUrl),
                              title: Row(
                                children: [
                                  Expanded(child: Text(c.user.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                                  if (isMe)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.backgroundTertiary, borderRadius: BorderRadius.circular(10)),
                                      child: const Text('Tú', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ),
                                  PillBadge.fromRol(c.rol),
                                ],
                              ),
                              subtitle: Text(c.user.email, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                              onTap: () => _showCaregiverSheet(context, c, auth, isAdmin),
                            ),
                            if (idx < caregiverProv.caregivers.length - 1)
                              const Divider(height: 1, indent: 70, color: AppColors.borderLight),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  if (caregiverProv.invites.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Invitaciones pendientes', count: caregiverProv.invites.length),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 0.5)),
                      child: Column(
                        children: caregiverProv.invites.asMap().entries.map((e) {
                          final idx = e.key;
                          final inv = e.value;
                          return Column(
                            children: [
                              ListTile(
                                leading: const CircleAvatar(backgroundColor: AppColors.backgroundSecondary, child: Icon(Icons.mail_outline_rounded, color: AppColors.textTertiary, size: 20)),
                                title: Text(inv.email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                subtitle: const Text('Pendiente de aceptar', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                trailing: isAdmin
                                    ? IconButton(
                                        onPressed: () => _showCancelInviteModal(context, inv),
                                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
                                      )
                                    : null,
                              ),
                              if (idx < caregiverProv.invites.length - 1)
                                const Divider(height: 1, indent: 70, color: AppColors.borderLight),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _showCaregiverSheet(BuildContext context, Caregiver c, AuthProvider auth, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CaregiverDetailSheet(
        caregiver: c,
        isAdmin: isAdmin,
        isMe: c.userId == auth.user?.id,
        onChangeRole: (rol) => _changeRole(c, rol),
        onRemove: () => _removeCaregiver(c),
      ),
    );
  }

  Future<void> _changeRole(Caregiver c, String rol) async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<CaregiverProvider>();
    final err = await prov.changeRole(auth.authHeaders(), widget.patientId, c.userId, rol);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol actualizado'), backgroundColor: AppColors.success));
    }
  }

  Future<void> _removeCaregiver(Caregiver c) async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<CaregiverProvider>();
    final err = await prov.removeCaregiver(auth.authHeaders(), widget.patientId, c.userId);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuidador removido'), backgroundColor: AppColors.success));
    }
  }

  void _showCancelInviteModal(BuildContext context, Invite inv) {
    showDialog(
      context: context,
      builder: (_) => _CancelInviteModal(
        invite: inv,
        onConfirm: () async {
          final auth = context.read<AuthProvider>();
          final prov = context.read<CaregiverProvider>();
          final err = await prov.cancelInvite(auth.authHeaders(), widget.patientId, inv.id);
          if (!mounted) return;
          if (err != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitación cancelada'), backgroundColor: AppColors.success));
          }
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Text('$title · $count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.3));
  }
}

class _CaregiverDetailSheet extends StatelessWidget {
  final Caregiver caregiver;
  final bool isAdmin;
  final bool isMe;
  final Function(String rol) onChangeRole;
  final VoidCallback onRemove;
  const _CaregiverDetailSheet({required this.caregiver, required this.isAdmin, required this.isMe, required this.onChangeRole, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final canManage = isAdmin && !isMe;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          AvatarWidget(name: caregiver.user.nombre, size: 56, photoUrl: caregiver.user.fotoUrl),
          const SizedBox(height: 12),
          Text(caregiver.user.nombre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(caregiver.user.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          PillBadge.fromRol(caregiver.rol),
          if (canManage) ...[
            const SizedBox(height: 20),
            AppButton(
              label: caregiver.rol == 'admin' ? 'Cambiar a Cuidador' : 'Cambiar a Admin',
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => _ChangeRoleModal(
                    caregiver: caregiver,
                    newRol: caregiver.rol == 'admin' ? 'cuidador' : 'admin',
                    onConfirm: () => onChangeRole(caregiver.rol == 'admin' ? 'cuidador' : 'admin'),
                  ),
                );
              },
              variant: AppButtonVariant.secondary,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Remover del grupo',
              onPressed: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => _RemoveCaregiverModal(caregiver: caregiver, onConfirm: onRemove));
              },
              variant: AppButtonVariant.danger,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CancelInviteModal extends StatelessWidget {
  final Invite invite;
  final VoidCallback onConfirm;
  const _CancelInviteModal({required this.invite, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cancelar invitación', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      content: Text('¿Deseas cancelar la invitación enviada a ${invite.email}?', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      actions: [
        AppButton(label: 'Cancelar', onPressed: () => Navigator.pop(context), variant: AppButtonVariant.secondary),
        const SizedBox(width: 8),
        AppButton(
          label: 'Confirmar',
          onPressed: () { Navigator.pop(context); onConfirm(); },
          variant: AppButtonVariant.danger,
        ),
      ],
    );
  }
}

class _ChangeRoleModal extends StatelessWidget {
  final Caregiver caregiver;
  final String newRol;
  final VoidCallback onConfirm;
  const _ChangeRoleModal({required this.caregiver, required this.newRol, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cambiar rol', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      content: Text('¿Cambiar el rol de ${caregiver.user.nombre} a ${newRol == 'admin' ? 'Admin' : 'Cuidador'}?', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      actions: [
        AppButton(label: 'Cancelar', onPressed: () => Navigator.pop(context), variant: AppButtonVariant.secondary),
        const SizedBox(width: 8),
        AppButton(
          label: 'Confirmar',
          onPressed: () { Navigator.pop(context); onConfirm(); },
          variant: AppButtonVariant.danger,
        ),
      ],
    );
  }
}

class _RemoveCaregiverModal extends StatelessWidget {
  final Caregiver caregiver;
  final VoidCallback onConfirm;
  const _RemoveCaregiverModal({required this.caregiver, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Remover del grupo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      content: Text('¿Remover a ${caregiver.user.nombre} del grupo de cuidadores? Esta acción no se puede deshacer.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      actions: [
        AppButton(label: 'Cancelar', onPressed: () => Navigator.pop(context), variant: AppButtonVariant.secondary),
        const SizedBox(width: 8),
        AppButton(
          label: 'Remover',
          onPressed: () { Navigator.pop(context); onConfirm(); },
          variant: AppButtonVariant.danger,
        ),
      ],
    );
  }
}
