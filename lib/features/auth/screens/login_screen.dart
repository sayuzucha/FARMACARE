import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  /// Datos opcionales pasados desde register o join:
  /// { 'email': '...', 'success': true }
  final Map<String, dynamic>? extra;
  const LoginScreen({super.key, this.extra});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  bool _registroExitoso = false;

  @override
  void initState() {
    super.initState();
    final extra = widget.extra;
    if (extra != null) {
      if (extra['email'] != null) _emailCtrl.text = extra['email'] as String;
      if (extra['success'] == true) _registroExitoso = true;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthProvider>();
    final err = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else if (auth.needsTwoFactor) {
      setState(() => _loading = false);
      context.go('/two-factor');
    } else {
      context.go('/patients');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = isWideLayout(context);

    final formContent = Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 40),
          if (_registroExitoso) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6EE7B7), width: 0.8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Cuenta creada! Ya puedes iniciar sesión.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF065F46), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Farmacare', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          const Text('Gestor de medicamentos', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
          const SizedBox(height: 36),
          AppTextField(
            label: 'Correo electrónico',
            hint: 'nombre@correo.com',
            controller: _emailCtrl,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            errorText: _error != null ? '' : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Contraseña',
            hint: '••••••••',
            controller: _passCtrl,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            onEditingComplete: _submit,
            errorText: _error != null ? '' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.errorText))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 12, color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Iniciar sesión', onPressed: _loading ? null : _submit, loading: _loading),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta? ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => context.go('/register'),
                child: const Text('Regístrate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: isWide ? AppColors.backgroundSecondary : AppColors.background,
      body: SafeArea(
        child: isWide
            ? Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight, width: 0.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: formContent,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: formContent,
              ),
      ),
    );
  }
}
