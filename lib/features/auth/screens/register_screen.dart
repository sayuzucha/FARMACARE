import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final err = await context.read<AuthProvider>().register(
      nombre: _nombreCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (err != null) setState(() { _loading = false; _error = err; });
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Crear cuenta', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Ingresa tus datos para registrarte', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Nombre completo',
                  hint: 'Tu nombre',
                  controller: _nombreCtrl,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Correo electrónico',
                  hint: 'nombre@correo.com',
                  controller: _emailCtrl,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Contraseña',
                  hint: 'Mínimo 6 caracteres',
                  controller: _passCtrl,
                  obscure: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _submit,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
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
                const SizedBox(height: 24),
                AppButton(label: 'Crear cuenta', onPressed: _loading ? null : _submit, loading: _loading),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta? ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text('Inicia sesión', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
