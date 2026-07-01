import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medication_provider.dart';
import '../../../providers/patient_provider.dart';

class PatientCalendarScreen extends StatefulWidget {
  final String patientId;
  const PatientCalendarScreen({super.key, required this.patientId});

  @override
  State<PatientCalendarScreen> createState() => _PatientCalendarScreenState();
}

class _PatientCalendarScreenState extends State<PatientCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      context.read<MedicationProvider>().fetchMedications(auth.authHeaders(), widget.patientId),
      context.read<AppointmentProvider>().fetchAppointments(auth.authHeaders(), widget.patientId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientProvider>().activePatient;
    final medProv = context.watch<MedicationProvider>();
    final apptProv = context.watch<AppointmentProvider>();

    final medsHoy = _selectedDay != null
        ? medProv.medications.where((m) => m.activoEnDia(_selectedDay!)).toList()
        : <Medication>[];

    final citasHoy = _selectedDay != null
        ? apptProv.appointments.where((a) {
            final d = a.fechaDate;
            return d != null && d.year == _selectedDay!.year && d.month == _selectedDay!.month && d.day == _selectedDay!.day;
          }).toList()
        : <DoctorAppointment>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calendario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (patient != null) Text(patient.nombre, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddAppointmentSheet(context),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          children: [
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(16),
              child: _CalendarWidget(
                focusedMonth: _focusedMonth,
                selectedDay: _selectedDay,
                medications: medProv.medications,
                appointmentDates: apptProv.fechasConCita,
                onDaySelected: (d) => setState(() => _selectedDay = d),
                onMonthChanged: (m) => setState(() => _focusedMonth = m),
              ),
            ),
            _Legend(),
            if (_selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              if (medsHoy.isEmpty && citasHoy.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin medicamentos ni citas este día', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                ),
              if (medsHoy.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Medicamentos', style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      ...medsHoy.map((m) => _MedDayCard(med: m, patientId: widget.patientId)),
                    ],
                  ),
                ),
              if (citasHoy.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Citas médicas', style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      ...citasHoy.map((a) => _AppointmentCard(
                            appointment: a,
                            onDelete: () => _deleteAppointment(a),
                          )),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 24),
            if (apptProv.appointments.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Próximas citas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
              ...apptProv.appointments.map((a) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _AppointmentCard(appointment: a, onDelete: () => _deleteAppointment(a)),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAppointment(DoctorAppointment a) async {
    final auth = context.read<AuthProvider>();
    final err = await context.read<AppointmentProvider>().deleteAppointment(auth.authHeaders(), widget.patientId, a.id);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  void _showAddAppointmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAppointmentSheet(
        patientId: widget.patientId,
        initialDate: _selectedDay,
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final List<Medication> medications;
  final Set<String> appointmentDates;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;
  const _CalendarWidget({required this.focusedMonth, required this.selectedDay, required this.medications, required this.appointmentDates, required this.onDaySelected, required this.onMonthChanged});

  static const _weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

  bool _hasMed(DateTime day) => medications.any((m) => m.activoEnDia(day));
  bool _hasAppt(DateTime day) {
    final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return appointmentDates.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    int startOffset = first.weekday - 1;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month - 1)),
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
            ),
            Expanded(
              child: Text('${_meses[focusedMonth.month - 1]} ${focusedMonth.year}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            IconButton(
              onPressed: () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + 1)),
              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: _weekDays.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary))))).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 2),
          itemCount: startOffset + lastDay,
          itemBuilder: (_, i) {
            if (i < startOffset) return const SizedBox.shrink();
            final day = DateTime(focusedMonth.year, focusedMonth.month, i - startOffset + 1);
            final isSel = selectedDay != null && selectedDay!.year == day.year && selectedDay!.month == day.month && selectedDay!.day == day.day;
            final isToday = DateTime.now().year == day.year && DateTime.now().month == day.month && DateTime.now().day == day.day;
            final hasMed = _hasMed(day);
            final hasAppt = _hasAppt(day);
            return GestureDetector(
              onTap: () => onDaySelected(day),
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : isToday ? AppColors.primarySurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.day}', style: TextStyle(fontSize: 13, fontWeight: isToday || isSel ? FontWeight.w700 : FontWeight.w400, color: isSel ? Colors.white : isToday ? AppColors.primary : AppColors.textPrimary)),
                    if (hasMed || hasAppt)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasMed) Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 2, right: 1), decoration: BoxDecoration(color: isSel ? Colors.white : AppColors.primary, shape: BoxShape.circle)),
                          if (hasAppt) Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 2), decoration: BoxDecoration(color: isSel ? Colors.white : AppColors.info, shape: BoxShape.circle)),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text('Medicamento', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.info, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text('Cita médica', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MedDayCard extends StatelessWidget {
  final Medication med;
  final String patientId;
  const _MedDayCard({required this.med, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/patients/$patientId/medications/${med.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderLight, width: 0.5)),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Text('${med.dosis.toStringAsFixed(0)} ${med.unidad} · ${med.cantidad} pastilla(s)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (med.horarios.isNotEmpty)
              Text(med.horarios.join(', '), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onDelete;
  const _AppointmentCard({required this.appointment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.infoSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.info, width: 0.5)),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.infoText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.fecha, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.infoText)),
                if (appointment.hora != null) Text(appointment.hora!, style: const TextStyle(fontSize: 11, color: AppColors.infoText)),
                if (appointment.medicoNombre != null) Text('Dr. ${appointment.medicoNombre}', style: const TextStyle(fontSize: 12, color: AppColors.infoText)),
                if (appointment.especialidad != null) Text(appointment.especialidad!, style: const TextStyle(fontSize: 11, color: AppColors.infoText)),
                if (appointment.lugar != null) Text(appointment.lugar!, style: const TextStyle(fontSize: 11, color: AppColors.infoText)),
                if (appointment.notas != null) Text(appointment.notas!, style: const TextStyle(fontSize: 11, color: AppColors.infoText)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.infoText), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _AddAppointmentSheet extends StatefulWidget {
  final String patientId;
  final DateTime? initialDate;
  const _AddAppointmentSheet({required this.patientId, this.initialDate});

  @override
  State<_AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends State<_AddAppointmentSheet> {
  final _fechaCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();
  final _medicoNombreCtrl = TextEditingController();
  final _especialidadCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      final d = widget.initialDate!;
      _fechaCtrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _fechaCtrl.dispose(); _horaCtrl.dispose(); _medicoNombreCtrl.dispose();
    _especialidadCtrl.dispose(); _lugarCtrl.dispose(); _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d != null) _fechaCtrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) _horaCtrl.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (_fechaCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final err = await context.read<AppointmentProvider>().createAppointment(
          auth.authHeaders(),
          widget.patientId,
          {
            'fecha': _fechaCtrl.text.trim(),
            if (_horaCtrl.text.isNotEmpty) 'hora': _horaCtrl.text.trim(),
            if (_medicoNombreCtrl.text.isNotEmpty) 'medico_nombre': _medicoNombreCtrl.text.trim(),
            if (_especialidadCtrl.text.isNotEmpty) 'especialidad': _especialidadCtrl.text.trim(),
            if (_lugarCtrl.text.isNotEmpty) 'lugar': _lugarCtrl.text.trim(),
            if (_notasCtrl.text.isNotEmpty) 'notas': _notasCtrl.text.trim(),
          },
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Nueva cita médica', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            GestureDetector(onTap: _pickDate, child: AbsorbPointer(child: AppTextField(label: 'Fecha *', hint: 'YYYY-MM-DD', controller: _fechaCtrl, prefixIcon: Icons.calendar_today_outlined))),
            const SizedBox(height: 12),
            GestureDetector(onTap: _pickTime, child: AbsorbPointer(child: AppTextField(label: 'Hora (opcional)', hint: 'HH:MM', controller: _horaCtrl, prefixIcon: Icons.access_time_rounded))),
            const SizedBox(height: 12),
            AppTextField(label: 'Médico (opcional)', hint: 'Ej. Dr. García', controller: _medicoNombreCtrl, prefixIcon: Icons.medical_services_outlined),
            const SizedBox(height: 12),
            AppTextField(label: 'Especialidad (opcional)', hint: 'Ej. Cardiología', controller: _especialidadCtrl),
            const SizedBox(height: 12),
            AppTextField(label: 'Lugar (opcional)', hint: 'Ej. IMSS, Hospital General', controller: _lugarCtrl, prefixIcon: Icons.location_on_outlined),
            const SizedBox(height: 12),
            AppTextField(label: 'Notas (opcional)', hint: 'Ej. Llevar estudios previos', controller: _notasCtrl, maxLines: 2),
            const SizedBox(height: 20),
            AppButton(label: 'Guardar cita', onPressed: _save, loading: _loading),
          ],
        ),
      ),
    );
  }
}
