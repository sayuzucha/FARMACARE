import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/pill_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medication_provider.dart';
import '../../../providers/patient_provider.dart';

class MedicationsListScreen extends StatefulWidget {
  final String patientId;
  const MedicationsListScreen({super.key, required this.patientId});

  @override
  State<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends State<MedicationsListScreen> {
  bool _soloActivos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<MedicationProvider>().fetchMedications(auth.authHeaders(), widget.patientId, soloActivos: _soloActivos);
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientProvider>().activePatient;
    final medProv = context.watch<MedicationProvider>();
    final meds = medProv.medications;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medicamentos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (patient != null)
              Text(patient.nombre, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/patients/${widget.patientId}/medications/add'),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _ToggleChip(label: 'Todos', selected: !_soloActivos, onTap: () { setState(() => _soloActivos = false); _load(); }),
                const SizedBox(width: 8),
                _ToggleChip(label: 'Solo activos', selected: _soloActivos, onTap: () { setState(() => _soloActivos = true); _load(); }),
              ],
            ),
          ),
          Expanded(
            child: medProv.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : meds.isEmpty
                    ? _EmptyState(onAdd: () => context.push('/patients/${widget.patientId}/medications/add'))
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: meds.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _MedCard(
                            med: meds[i],
                            onTap: () => context.push('/patients/${widget.patientId}/medications/${meds[i].id}'),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 0.8),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? AppColors.primaryDark : AppColors.textSecondary)),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onTap;
  const _MedCard({required this.med, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('${med.dosis.toStringAsFixed(med.dosis == med.dosis.truncateToDouble() ? 0 : 1)} ${med.unidad}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                med.activo ? const PillBadge(label: 'Activo', type: PillType.success) : const PillBadge(label: 'Suspendido', type: PillType.neutral),
              ],
            ),
            if (med.horarios.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: med.horarios.map((h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.backgroundSecondary, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(h, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.medication_outlined, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text('Sin medicamentos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Agrega el primer medicamento', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
          const SizedBox(height: 20),
          AppButton(label: 'Agregar medicamento', onPressed: onAdd),
        ],
      ),
    );
  }
}
