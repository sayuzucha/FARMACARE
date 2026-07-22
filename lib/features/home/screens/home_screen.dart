import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/pill_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/dose_provider.dart';

class HomeScreen extends StatefulWidget {
  final String patientId;
  const HomeScreen({super.key, required this.patientId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<DoseProvider>().fetchToday(auth.authHeaders(), widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final patientProv = context.watch<PatientProvider>();
    final doseProv = context.watch<DoseProvider>();
    final patient = patientProv.activePatient;
    final today = doseProv.today;

    return AppShell(
      currentIndex: 0,
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(onPressed: () => context.go('/patients'), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
        title: GestureDetector(
          onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => context.push('/patients/${widget.patientId}/caregivers')),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient?.nombre ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const Text('Tomas del día', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ),
        actions: [
          IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary)),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: doseProv.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (today != null) _SummaryCards(summary: today),
                  const SizedBox(height: 12),
                  _QuickActions(patientId: widget.patientId),
                  const SizedBox(height: 16),
                  if (today != null) ...[
                    _buildSection('Pendientes', today.schedule.where((s) => s.isPending).toList(), auth, doseProv),
                    _buildSection('Completadas', today.schedule.where((s) => !s.isPending).toList(), auth, doseProv),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSection(String title, List<DoseSlot> slots, AuthProvider auth, DoseProvider doseProv) {
    if (slots.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.3)),
        ),
        ...slots.map((slot) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DoseCard(
                slot: slot,
                onTomado: slot.isPending ? () => _showConfirmSheet(context, slot, auth, doseProv) : null,
                onOmitido: slot.isPending ? () => _showOmitSheet(context, slot, auth, doseProv) : null,
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showConfirmSheet(BuildContext context, DoseSlot slot, AuthProvider auth, DoseProvider doseProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmDoseSheet(slot: slot, onConfirm: (notas) async {
        final err = await doseProv.registerDose(
          auth.authHeaders(),
          widget.patientId,
          slot.medicationId,
          estado: 'tomado',
          horaProgramada: slot.horaProgramada,
          notas: notas,
        );
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
        }
      }),
    );
  }

  void _showOmitSheet(BuildContext context, DoseSlot slot, AuthProvider auth, DoseProvider doseProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OmitDoseSheet(slot: slot, onConfirm: (motivo, notas) async {
        final err = await doseProv.registerDose(
          auth.authHeaders(),
          widget.patientId,
          slot.medicationId,
          estado: 'omitido',
          horaProgramada: slot.horaProgramada,
          motivoOmision: motivo,
          notas: notas,
        );
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
        }
      }),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final String patientId;
  const _QuickActions({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickCard(icon: Icons.chat_bubble_outline_rounded, label: 'Mensajes', color: AppColors.infoSurface, iconColor: AppColors.info, onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => context.push('/patients/$patientId/messages')))),
        const SizedBox(width: 10),
        Expanded(child: _QuickCard(icon: Icons.calendar_month_outlined, label: 'Calendario', color: AppColors.primarySurface, iconColor: AppColors.primary, onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => context.push('/patients/$patientId/calendar')))),
        const SizedBox(width: 10),
        Expanded(child: _QuickCard(icon: Icons.people_outline_rounded, label: 'Cuidadores', color: AppColors.backgroundTertiary, iconColor: AppColors.textSecondary, onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => context.push('/patients/$patientId/caregivers')))),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  const _QuickCard({required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: iconColor)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final DoseSummary summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Tomas hoy', value: '${summary.tomadas}/${summary.total}', color: AppColors.primary, progress: summary.porcentaje)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Cumplimiento', value: '${(summary.porcentaje * 100).round()}%', color: AppColors.primary, progress: summary.porcentaje)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double progress;
  const _StatCard({required this.label, required this.value, required this.color, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.backgroundTertiary,
              color: color,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  final DoseSlot slot;
  final VoidCallback? onTomado;
  final VoidCallback? onOmitido;
  const _DoseCard({required this.slot, this.onTomado, this.onOmitido});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 0.5)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: slot.isPending ? AppColors.warningSurface : slot.isTomado ? AppColors.successSurface : AppColors.errorSurface, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.medication_outlined, size: 18, color: slot.isPending ? AppColors.warning : slot.isTomado ? AppColors.success : AppColors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${slot.medicationNombre} ${slot.dosis.toStringAsFixed(0)}${slot.unidad}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(slot.horaProgramada, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (slot.indicaciones != null) ...[const Text('  ·  ', style: TextStyle(color: AppColors.textTertiary)), Expanded(child: Text(slot.indicaciones!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis))],
                    ]),
                  ],
                ),
              ),
              PillBadge.fromDoseEstado(slot.estado),
            ],
          ),
          if (slot.isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _ActionBtn(label: 'Tomado', color: AppColors.successSurface, textColor: AppColors.successText, onTap: onTomado!)),
                const SizedBox(width: 8),
                Expanded(child: _ActionBtn(label: 'Omitir', color: AppColors.backgroundSecondary, textColor: AppColors.textSecondary, onTap: onOmitido!)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderLight, width: 0.5)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
      ),
    );
  }
}

class _ConfirmDoseSheet extends StatefulWidget {
  final DoseSlot slot;
  final Function(String? notas) onConfirm;
  const _ConfirmDoseSheet({required this.slot, required this.onConfirm});

  @override
  State<_ConfirmDoseSheet> createState() => _ConfirmDoseSheetState();
}

class _ConfirmDoseSheetState extends State<_ConfirmDoseSheet> {
  final _notasCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Confirmar toma', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('${widget.slot.medicationNombre} · ${widget.slot.horaProgramada}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(controller: _notasCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Notas opcionales...', hintStyle: TextStyle(color: AppColors.textHint))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                Navigator.pop(context);
                await widget.onConfirm(_notasCtrl.text.isEmpty ? null : _notasCtrl.text);
              },
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirmar'),
            )),
          ]),
        ],
      ),
    );
  }
}

class _OmitDoseSheet extends StatefulWidget {
  final DoseSlot slot;
  final Function(String motivo, String? notas) onConfirm;
  const _OmitDoseSheet({required this.slot, required this.onConfirm});

  @override
  State<_OmitDoseSheet> createState() => _OmitDoseSheetState();
}

class _OmitDoseSheetState extends State<_OmitDoseSheet> {
  String _motivo = 'Olvido';
  final _notasCtrl = TextEditingController();
  static const _motivos = ['Olvido', 'Efecto adverso', 'Sin medicamento', 'Otro'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Omitir toma', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('${widget.slot.medicationNombre} · ${widget.slot.horaProgramada}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const Text('Motivo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: _motivos.map((m) => GestureDetector(
            onTap: () => setState(() => _motivo = m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _motivo == m ? AppColors.errorSurface : AppColors.backgroundSecondary, borderRadius: BorderRadius.circular(20), border: Border.all(color: _motivo == m ? AppColors.errorBorder : AppColors.border, width: 0.5)),
              child: Text(m, style: TextStyle(fontSize: 12, color: _motivo == m ? AppColors.errorText : AppColors.textSecondary)),
            ),
          )).toList()),
          const SizedBox(height: 12),
          TextField(controller: _notasCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Notas adicionales...', hintStyle: TextStyle(color: AppColors.textHint))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () { Navigator.pop(context); widget.onConfirm(_motivo, _notasCtrl.text.isEmpty ? null : _notasCtrl.text); },
              child: const Text('Registrar omisión'),
            )),
          ]),
        ],
      ),
    );
  }
}
