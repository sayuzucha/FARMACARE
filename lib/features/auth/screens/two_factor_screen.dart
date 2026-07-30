import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/auth_provider.dart';

/// Paso 2 del login: el usuario ya metió email/contraseña correctos y le
/// mandamos un código de 6 dígitos por correo. Aquí lo captura para abrir
/// la sesión de verdad.
class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeCtrl = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  // Cooldown para el botón de reenviar (evita spam de correos).
  Timer? _cooldownTimer;
  int _cooldown = 0;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _verificar() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) return;
    setState(() { _verifying = true; _error = null; });
    final err = await context.read<AuthProvider>().verifyTwoFactor(code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      context.go('/patients');
    }
  }

  Future<void> _reenviar() async {
    if (_cooldown > 0 || _resending) return;
    setState(() { _resending = true; _error = null; });
    final err = await context.read<AuthProvider>().resendTwoFactorCode();
    if (!mounted) return;
    setState(() => _resending = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      _codeCtrl.clear();
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te mandamos un código nuevo.'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.twoFactorEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.read<AuthProvider>().cancelTwoFactor();
            context.go('/login');
          },
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: const Text(
          'Verificación en 2 pasos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Revisa tu correo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email != null
                        ? 'Te mandamos un código de 6 dígitos a $email. Expira en 10 minutos.'
                        : 'Te mandamos un código de 6 dígitos a tu correo. Expira en 10 minutos.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Código de verificación',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              autocorrect: false,
              enableSuggestions: false,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                  letterSpacing: 10,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (value) {
                if (_error != null) setState(() => _error = null);
                if (value.length == 6) _verificar();
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.errorBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.errorText)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: 'Verificar',
              onPressed: _verifying ? null : _verificar,
              loading: _verifying,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: (_cooldown > 0 || _resending) ? null : _reenviar,
                child: Text(
                  _resending
                      ? 'Enviando...'
                      : _cooldown > 0
                          ? 'Reenviar código (${_cooldown}s)'
                          : '¿No te llegó? Reenviar código',
                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
