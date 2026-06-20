import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AuthProvider>().forgotPassword(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (err == null) _sent = true;
      else _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(onPressed: () => context.go('/login'), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Recuperar contraseña', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Te enviaremos un enlace a tu correo para restablecer tu contraseña.', style: TextStyle(fontSize: 13, color: AppColors.textTertiary, height: 1.5)),
              const SizedBox(height: 32),
              if (_sent) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('Revisa tu correo. Si existe una cuenta con ese email recibirás el enlace.', style: TextStyle(fontSize: 13, color: AppColors.primaryDark, height: 1.5))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(label: 'Volver al inicio de sesión', variant: AppButtonVariant.secondary, onPressed: () => context.go('/login')),
              ] else ...[
                AppTextField(
                  label: 'Correo electrónico',
                  hint: 'nombre@correo.com',
                  controller: _emailCtrl,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _submit,
                  errorText: _error,
                ),
                const SizedBox(height: 24),
                AppButton(label: 'Enviar enlace', onPressed: _loading ? null : _submit, loading: _loading),
                const SizedBox(height: 16),
                AppButton(label: 'Volver al inicio de sesión', variant: AppButtonVariant.ghost, onPressed: () => context.go('/login')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
