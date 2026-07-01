import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: ListView(
        children: [
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AvatarWidget(name: user?.nombre ?? '', size: 64),
                const SizedBox(height: 12),
                Text(user?.nombre ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                if (user?.telefono != null) ...[
                  const SizedBox(height: 2),
                  Text(user!.telefono!, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            color: AppColors.background,
            child: Column(
              children: [
                _OptionTile(icon: Icons.edit_outlined, label: 'Editar perfil', onTap: () => _showEditSheet(context, auth)),
                const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                _OptionTile(icon: Icons.lock_outline_rounded, label: 'Cambiar contraseña', onTap: () => _showChangePasswordSheet(context, auth)),
                const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                _OptionTile(icon: Icons.notifications_outlined, label: 'Notificaciones', onTap: () => context.push('/notifications')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            color: AppColors.background,
            child: _OptionTile(icon: Icons.logout_rounded, label: 'Cerrar sesión', labelColor: AppColors.error, iconColor: AppColors.error, onTap: () => _showLogoutModal(context, auth)),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  void _showEditSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _EditProfileSheet(auth: auth));
  }

  void _showChangePasswordSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _ChangePasswordSheet(auth: auth));
  }

  void _showLogoutModal(BuildContext context, AuthProvider auth) {
    showDialog(context: context, builder: (_) => _LogoutModal(auth: auth));
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;
  const _OptionTile({required this.icon, required this.label, required this.onTap, this.labelColor, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor ?? AppColors.textSecondary),
      title: Text(label, style: TextStyle(fontSize: 14, color: labelColor ?? AppColors.textPrimary)),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: labelColor ?? AppColors.textTertiary),
      onTap: onTap,
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final AuthProvider auth;
  const _EditProfileSheet({required this.auth});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.auth.user?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: widget.auth.user?.telefono ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/users/me'),
        headers: widget.auth.authHeaders(),
        body: jsonEncode({
          'nombre': _nombreCtrl.text.trim(),
          if (_telefonoCtrl.text.trim().isNotEmpty) 'telefono': _telefonoCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado'), backgroundColor: AppColors.success));
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Error al guardar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión'), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Editar perfil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          AvatarWidget(name: widget.auth.user?.nombre ?? '', size: 60),
          const SizedBox(height: 16),
          AppTextField(label: 'Nombre', hint: 'Tu nombre', controller: _nombreCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Teléfono', hint: '+52 123 456 7890', controller: _telefonoCtrl, keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: AppButton(label: 'Cancelar', onPressed: () => Navigator.pop(context), variant: AppButtonVariant.secondary)),
            const SizedBox(width: 10),
            Expanded(child: AppButton(label: 'Guardar', onPressed: _save, loading: _loading)),
          ]),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final AuthProvider auth;
  const _ChangePasswordSheet({required this.auth});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  String? _confirmarError;
  bool _loading = false;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nuevaCtrl.text.length < 6) { setState(() => _confirmarError = 'Mínimo 6 caracteres'); return; }
    if (_nuevaCtrl.text != _confirmarCtrl.text) { setState(() => _confirmarError = 'Las contraseñas no coinciden'); return; }
    setState(() { _confirmarError = null; _loading = true; });
    try {
      final res = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/users/me/password'),
        headers: widget.auth.authHeaders(),
        body: jsonEncode({'password_actual': _actualCtrl.text, 'password_nueva': _nuevaCtrl.text}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada'), backgroundColor: AppColors.success));
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Error al cambiar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión'), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Cambiar contraseña', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          AppTextField(label: 'Contraseña actual', hint: '••••••••', controller: _actualCtrl, obscure: true),
          const SizedBox(height: 12),
          AppTextField(label: 'Contraseña nueva', hint: '••••••••', controller: _nuevaCtrl, obscure: true),
          const SizedBox(height: 12),
          AppTextField(label: 'Confirmar contraseña', hint: '••••••••', controller: _confirmarCtrl, obscure: true, errorText: _confirmarError),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: AppButton(label: 'Cancelar', onPressed: () => Navigator.pop(context), variant: AppButtonVariant.secondary)),
            const SizedBox(width: 10),
            Expanded(child: AppButton(label: 'Guardar', onPressed: _save, loading: _loading)),
          ]),
        ],
      ),
    );
  }
}

class _LogoutModal extends StatelessWidget {
  final AuthProvider auth;
  const _LogoutModal({required this.auth});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cerrar sesión', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      content: const Text('¿Estás seguro? Tendrás que volver a iniciar sesión.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      actions: [
        AppButton(label: 'Cancelar', onPressed: () => Navigator.pop(context), variant: AppButtonVariant.secondary),
        const SizedBox(width: 8),
        AppButton(
          label: 'Cerrar sesión',
          onPressed: () async {
            Navigator.pop(context);
            await auth.logout();
            if (context.mounted) context.go('/login');
          },
          variant: AppButtonVariant.danger,
        ),
      ],
    );
  }
}
