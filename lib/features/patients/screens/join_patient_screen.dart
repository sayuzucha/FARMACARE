import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/patient_provider.dart';

class JoinPatientScreen extends StatefulWidget {
  const JoinPatientScreen({super.key});

  @override
  State<JoinPatientScreen> createState() => _JoinPatientScreenState();
}

class _JoinPatientScreenState extends State<JoinPatientScreen> {
  final _codeCtrl = TextEditingController();

  // null = no buscado aún, PatientPreview = encontrado, String = error
  PatientPreview? _preview;
  String? _previewError;
  bool _searching = false;
  bool _joining = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 4) return;
    setState(() {
      _searching = true;
      _preview = null;
      _previewError = null;
    });
    final auth = context.read<AuthProvider>();
    final (preview, err) = await context.read<PatientProvider>().fetchPatientByCode(
      auth.authHeaders(),
      code,
    );
    if (!mounted) return;
    setState(() {
      _searching = false;
      _preview = preview;
      _previewError = err;
    });
  }

  Future<void> _unirse() async {
    final code = _codeCtrl.text.trim();
    setState(() => _joining = true);
    final auth = context.read<AuthProvider>();
    final err = await context.read<PatientProvider>().joinPatient(auth.authHeaders(), code);
    if (!mounted) return;
    setState(() => _joining = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Te has unido como cuidador!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/patients');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: const Text(
          'Unirse a paciente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Ilustración / intro ──────────────────────────────────────
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
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ingresa el código del paciente',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'El administrador del paciente te puede compartir su código de 6 caracteres.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Input de código ──────────────────────────────────────────
            const Text(
              'Código del paciente',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(8),
                    ],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 6,
                    ),
                    decoration: InputDecoration(
                      hintText: 'A3F7B2',
                      hintStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        letterSpacing: 6,
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
                    onChanged: (_) {
                      // Limpiar preview si cambia el código
                      if (_preview != null || _previewError != null) {
                        setState(() { _preview = null; _previewError = null; });
                      }
                    },
                    onSubmitted: (_) => _buscar(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _searching ? null : _buscar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      elevation: 0,
                    ),
                    child: _searching
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Buscar', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Error de búsqueda ────────────────────────────────────────
            if (_previewError != null)
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
                      child: Text(
                        _previewError!,
                        style: const TextStyle(fontSize: 13, color: AppColors.errorText),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Preview del paciente ─────────────────────────────────────
            if (_preview != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AvatarWidget(name: _preview!.nombre, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _preview!.nombre,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_preview!.cuidadoresNombres.length} cuidador${_preview!.cuidadoresNombres.length != 1 ? 'es' : ''}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _codeCtrl.text.trim().toUpperCase(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                    if (_preview!.cuidadoresNombres.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 12),
                      const Text(
                        'Equipo actual',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _preview!.cuidadoresNombres.map((nombre) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvatarWidget(name: nombre, size: 24),
                            const SizedBox(width: 5),
                            Text(nombre, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _joining ? null : _unirse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        child: _joining
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.group_add_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Unirme como cuidador'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Formateador que convierte texto a mayúsculas automáticamente
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue new_) =>
      new_.copyWith(text: new_.text.toUpperCase(), selection: new_.selection);
}
