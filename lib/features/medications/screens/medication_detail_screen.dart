import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medication_provider.dart';

class MedicationDetailScreen extends StatefulWidget {
  final String patientId;
  final String medId;
  const MedicationDetailScreen({super.key, required this.patientId, required this.medId});

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<MedicationProvider>().fetchMedications(auth.authHeaders(), widget.patientId);
  }

  Medication? get _med {
    final meds = context.read<MedicationProvider>().medications;
    try {
      return meds.firstWhere((m) => m.id == widget.medId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleActive(bool activo, {String? motivo}) async {
    final auth = context.read<AuthProvider>();
    final medProv = context.read<MedicationProvider>();
    final err = await medProv.toggleActive(auth.authHeaders(), widget.patientId, widget.medId, activo, motivo: motivo);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(activo ? 'Medicamento reactivado' : 'Medicamento suspendido'), backgroundColor: AppColors.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    final medProv = context.watch<MedicationProvider>();
    Medication? med;
    try {
      med = medProv.medications.firstWhere((m) => m.id == widget.medId);
    } catch (_) {}

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
        title: Text(med?.nombre ?? 'Medicamento', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          if (med != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              onSelected: (val) {
                if (val == 'suspend') _showSuspendModal(context, med!);
                if (val == 'reactivate') _toggleActive(true);
              },
              itemBuilder: (_) => [
                if (med!.activo)
                  const PopupMenuItem(value: 'suspend', child: Text('Suspender'))
                else
                  const PopupMenuItem(value: 'reactivate', child: Text('Reactivar')),
              ],
            ),
        ],
      ),
      body: medProv.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : med == null
              ? const Center(child: Text('Medicamento no encontrado'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!med.activo)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.warningSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Medicamento suspendido', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warningText)),
                              if (med.motivoSuspension != null && med.motivoSuspension!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Motivo: ${med.motivoSuspension}', style: const TextStyle(fontSize: 13, color: AppColors.warningText)),
                                ),
                              const SizedBox(height: 10),
                              AppButton(label: 'Reactivar', onPressed: () => _toggleActive(true), variant: AppButtonVariant.secondary),
                            ],
                          ),
                        ),
                      _InfoCard(med: med),
                      const SizedBox(height: 16),
                      if (med.activo)
                        AppButton(
                          label: 'Suspender medicamento',
                          onPressed: () => _showSuspendModal(context, med!),
                          variant: AppButtonVariant.danger,
                        ),
                    ],
                  ),
                ),
    );
  }

  void _showSuspendModal(BuildContext context, Medication med) {
    showDialog(context: context, builder: (_) => _SuspendModal(med: med, onConfirm: (motivo) => _toggleActive(false, motivo: motivo)));
  }
}

class _InfoCard extends StatelessWidget {
  final Medication med;
  const _InfoCard({required this.med});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(med.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
              med.activo ? const PillBadge(label: 'Activo', type: PillType.success) : const PillBadge(label: 'Suspendido', type: PillType.neutral),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Dosis', value: '${med.dosis.toStringAsFixed(med.dosis == med.dosis.truncateToDouble() ? 0 : 1)} ${med.unidad}'),
          _InfoRow(label: 'Vía', value: med.viaAdministracion),
          _InfoRow(label: 'Fecha de inicio', value: med.fechaInicio),
          if (med.fechaFin != null) _InfoRow(label: 'Fecha de fin', value: med.fechaFin!),
          if (med.indicaciones != null && med.indicaciones!.isNotEmpty)
            _InfoRow(label: 'Indicaciones', value: med.indicaciones!),
          if (med.horarios.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Horarios', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: med.horarios.map((h) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                    Text(h, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
                  ],
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class _SuspendModal extends StatefulWidget {
  final Medication med;
  final Function(String? motivo) onConfirm;
  const _SuspendModal({required this.med, required this.onConfirm});

  @override
  State<_SuspendModal> createState() => _SuspendModalState();
}

class _SuspendModalState extends State<_SuspendModal> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Suspender medicamento', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.med.nombre, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Motivo (opcional)',
            hint: 'Ej. Efectos adversos',
            controller: _motivoCtrl,
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'Cancelar',
          onPressed: () => Navigator.pop(context),
          variant: AppButtonVariant.secondary,
        ),
        const SizedBox(width: 8),
        AppButton(
          label: 'Confirmar',
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(_motivoCtrl.text.trim().isEmpty ? null : _motivoCtrl.text.trim());
          },
          variant: AppButtonVariant.danger,
        ),
      ],
    );
  }
}
