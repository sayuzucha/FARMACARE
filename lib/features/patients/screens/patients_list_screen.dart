import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/pill_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/dose_provider.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<PatientProvider>().fetchPatients(auth.authHeaders());
  }

  @override
  Widget build(BuildContext context) {
    final patientProv = context.watch<PatientProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${auth.user?.nombre.split(' ').first ?? ''}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            const Text('Mis pacientes', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/patients/add'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: patientProv.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : patientProv.patients.isEmpty
                ? _buildEmpty()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...patientProv.patients.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PatientCard(
                              patient: p,
                              onTap: () {
                                context.read<PatientProvider>().setActivePatient(p);
                                context.read<DoseProvider>().clear();
                                context.push('/patients/${p.id}/home');
                              },
                            ),
                          )),
                      _AddPatientCard(onTap: () => context.push('/patients/add')),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.person_add_outlined, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Sin pacientes aún', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Agrega a la persona cuyo tratamiento quieres gestionar', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/patients/add'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar paciente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final dynamic patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarWidget(name: patient.nombre, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(patient.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                const Text('Activo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.primaryDark)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (patient.enfermedades.isNotEmpty)
                        Text(patient.enfermedades.take(2).join(', '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                PillBadge.fromRol(patient.rol ?? 'cuidador'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.medication_outlined, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('${patient.totalMedicamentos} medicamentos activos', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPatientCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPatientCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_rounded, color: AppColors.textTertiary, size: 18),
            SizedBox(width: 6),
            Text('Agregar nuevo paciente', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
