import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/pill_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/report_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _desdeCtrl = TextEditingController();
  final _hastaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _desdeCtrl.dispose();
    _hastaCtrl.dispose();
    super.dispose();
  }

  String? get _patientId => context.read<PatientProvider>().activePatient?.id;

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final pid = _patientId;
    if (pid == null) return;
    final prov = context.read<ReportProvider>();
    await Future.wait([
      prov.fetchCompliance(auth.authHeaders(), pid),
      prov.fetchActivity(auth.authHeaders(), pid),
    ]);
  }

  Future<void> _applyFilter() async {
    final auth = context.read<AuthProvider>();
    final pid = _patientId;
    if (pid == null) return;
    await context.read<ReportProvider>().fetchCompliance(
          auth.authHeaders(),
          pid,
          desde: _desdeCtrl.text.trim().isEmpty ? null : _desdeCtrl.text.trim(),
          hasta: _hastaCtrl.text.trim().isEmpty ? null : _hastaCtrl.text.trim(),
        );
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      ctrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientProvider>().activePatient;
    final prov = context.watch<ReportProvider>();
    final report = prov.report;

    return AppShell(
      currentIndex: 2,
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reporte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (patient != null) Text(patient.nombre, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exportando...'))),
            icon: const Icon(Icons.download_outlined, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (report != null) ...[
                    _ComplianceCard(report: report),
                    const SizedBox(height: 16),
                    _StatsGrid(report: report),
                    const SizedBox(height: 20),
                    _FilterSection(
                      desdeCtrl: _desdeCtrl,
                      hastaCtrl: _hastaCtrl,
                      onPickDesde: () => _pickDate(_desdeCtrl),
                      onPickHasta: () => _pickDate(_hastaCtrl),
                      onApply: _applyFilter,
                    ),
                    const SizedBox(height: 20),
                    if (report.desglose.isNotEmpty) ...[
                      const Text('Por medicamento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      ...report.desglose.map((mc) => _MedComplianceRow(mc: mc)),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (prov.activity.isNotEmpty) ...[
                    const Text('Actividad reciente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 0.5)),
                      child: Column(
                        children: prov.activity.asMap().entries.map((e) {
                          final idx = e.key;
                          final item = e.value;
                          return Column(
                            children: [
                              _ActivityRow(item: item),
                              if (idx < prov.activity.length - 1) const Divider(height: 1, indent: 16, color: AppColors.borderLight),
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
}

class _ComplianceCard extends StatelessWidget {
  final ComplianceReport report;
  const _ComplianceCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 0.5)),
      child: Column(
        children: [
          Text('${report.porcentaje.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const Text('Cumplimiento', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.porcentaje / 100,
              backgroundColor: AppColors.backgroundTertiary,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final ComplianceReport report;
  const _StatsGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Tomadas', value: '${report.tomadas}', color: AppColors.success, bg: AppColors.successSurface)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Omitidas', value: '${report.omitidas}', color: AppColors.error, bg: AppColors.errorSurface)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _StatCard({required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final TextEditingController desdeCtrl;
  final TextEditingController hastaCtrl;
  final VoidCallback onPickDesde;
  final VoidCallback onPickHasta;
  final VoidCallback onApply;
  const _FilterSection({required this.desdeCtrl, required this.hastaCtrl, required this.onPickDesde, required this.onPickHasta, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filtrar por fecha', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onPickDesde,
                child: AbsorbPointer(child: AppTextField(label: 'Desde', hint: 'YYYY-MM-DD', controller: desdeCtrl, prefixIcon: Icons.calendar_today_outlined)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onPickHasta,
                child: AbsorbPointer(child: AppTextField(label: 'Hasta', hint: 'YYYY-MM-DD', controller: hastaCtrl, prefixIcon: Icons.calendar_today_outlined)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onApply,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
            child: const Text('Aplicar'),
          ),
        ),
      ],
    );
  }
}

class _MedComplianceRow extends StatelessWidget {
  final MedCompliance mc;
  const _MedComplianceRow({required this.mc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderLight, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(mc.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
              Text('${mc.porcentaje.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: mc.porcentaje / 100,
              backgroundColor: AppColors.backgroundTertiary,
              color: AppColors.primary,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityItem item;
  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          PillBadge.fromDoseEstado(item.estado),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.medicamentoNombre != null)
                  Text(item.medicamentoNombre!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                if (item.registradoPor != null)
                  Text('por ${item.registradoPor}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text(item.fecha, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
