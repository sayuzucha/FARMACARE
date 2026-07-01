import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/caregiver_provider.dart';
import '../../../providers/dose_provider.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<PatientProvider>().fetchPatients(auth.authHeaders());
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _showActions(Patient p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientActionsSheet(patient: p, onReload: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientProv = context.watch<PatientProvider>();
    final auth = context.watch<AuthProvider>();
    final nombre = auth.user?.nombre.split(' ').first ?? '';

    final filtered = _query.isEmpty
        ? patientProv.patients
        : patientProv.patients.where((p) => p.nombre.toLowerCase().contains(_query)).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.background,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 20,
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
                              Text('$_greeting, $nombre',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.4)),
                              const SizedBox(height: 2),
                              Text(
                                patientProv.patients.isEmpty
                                    ? 'Agrega tu primer paciente'
                                    : '${patientProv.patients.length} ${patientProv.patients.length == 1 ? 'paciente' : 'pacientes'} a tu cargo',
                                style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/patients/add'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                    if (patientProv.patients.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(children: [
                        _StatChip(icon: Icons.people_outline_rounded, label: '${patientProv.patients.length}', sub: 'Pacientes', color: AppColors.primary),
                        const SizedBox(width: 10),
                        _StatChip(
                          icon: Icons.medication_outlined,
                          label: '${patientProv.patients.fold(0, (s, p) => s + p.totalMedicamentos)}',
                          sub: 'Medicamentos',
                          color: AppColors.info,
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight, width: 0.5),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Buscar paciente...',
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                            prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (patientProv.loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (patientProv.error != null)
              SliverFillRemaining(child: _buildError(patientProv.error!))
            else if (patientProv.patients.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else if (filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text('Sin resultados para "$_query"', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == filtered.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _AddPatientCard(onTap: () => context.push('/patients/add')),
                        );
                      }
                      final p = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PatientCard(
                          patient: p,
                          onTap: () {
                            context.read<PatientProvider>().setActivePatient(p);
                            context.read<DoseProvider>().clear();
                            context.push('/patients/${p.id}/home');
                          },
                          onMenu: () => _showActions(p),
                          onAddCaregiver: () => context.push('/patients/${p.id}/caregivers/invite'),
                          onViewCaregivers: () => context.push('/patients/${p.id}/caregivers'),
                        ),
                      );
                    },
                    childCount: filtered.length + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Error al cargar pacientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.elderly_outlined, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Sin pacientes aún', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Agrega a la persona cuyo tratamiento quieres gestionar y lleva el control de sus medicamentos.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 28),
            _FeatureRow(icon: Icons.medication_outlined, text: 'Registra medicamentos y horarios'),
            const SizedBox(height: 10),
            _FeatureRow(icon: Icons.calendar_today_outlined, text: 'Lleva un calendario de tomas'),
            const SizedBox(height: 10),
            _FeatureRow(icon: Icons.group_outlined, text: 'Invita a otros cuidadores'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/patients/add'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar primer paciente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PATIENT CARD ───────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;
  final VoidCallback onMenu;
  final VoidCallback onAddCaregiver;
  final VoidCallback onViewCaregivers;

  const _PatientCard({
    required this.patient,
    required this.onTap,
    required this.onMenu,
    required this.onAddCaregiver,
    required this.onViewCaregivers,
  });

  @override
  Widget build(BuildContext context) {
    final edad = patient.edad;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // TOP — tap para ir al home
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvatarWidget(name: patient.nombre, size: 50),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.nombre,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 3),
                            Row(children: [
                              if (edad != null) ...[
                                const Icon(Icons.cake_outlined, size: 12, color: AppColors.textTertiary),
                                const SizedBox(width: 3),
                                Text('$edad años', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                const SizedBox(width: 8),
                              ],
                              if (patient.tipoSangre != null) ...[
                                const Icon(Icons.water_drop_outlined, size: 12, color: AppColors.textTertiary),
                                const SizedBox(width: 3),
                                Text(patient.tipoSangre!, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                              ],
                            ]),
                            const SizedBox(height: 4),
                            PillBadge.fromRol(patient.rol ?? 'cuidador'),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onMenu,
                        icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textTertiary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (patient.enfermedades.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: patient.enfermedades.take(3).map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight, width: 0.5),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.medication_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text('${patient.totalMedicamentos} medicamento${patient.totalMedicamentos != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const Spacer(),
                    const Text('Ver detalle', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                  ]),
                ],
              ),
            ),
          ),

          // BOTTOM — acciones de cuidadores
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight, width: 0.5)),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onViewCaregivers,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.group_outlined, size: 15, color: AppColors.textSecondary),
                          SizedBox(width: 6),
                          Text('Ver cuidadores', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 0.5, height: 36, color: AppColors.borderLight),
                Expanded(
                  child: InkWell(
                    onTap: onAddCaregiver,
                    borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_add_outlined, size: 15, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Agregar cuidador', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ACTIONS SHEET ──────────────────────────────────────────────────────────

class _PatientActionsSheet extends StatefulWidget {
  final Patient patient;
  final VoidCallback onReload;
  const _PatientActionsSheet({required this.patient, required this.onReload});

  @override
  State<_PatientActionsSheet> createState() => _PatientActionsSheetState();
}

class _PatientActionsSheetState extends State<_PatientActionsSheet> {
  bool _loadingCaregivers = false;
  List<Caregiver> _caregivers = [];
  bool _caregiversFetched = false;

  @override
  void initState() {
    super.initState();
    _fetchCaregivers();
  }

  Future<void> _fetchCaregivers() async {
    setState(() => _loadingCaregivers = true);
    final auth = context.read<AuthProvider>();
    final prov = context.read<CaregiverProvider>();
    await prov.fetchAll(auth.authHeaders(), widget.patient.id);
    if (mounted) {
      setState(() {
        _caregivers = prov.caregivers;
        _caregiversFetched = true;
        _loadingCaregivers = false;
      });
    }
  }

  void _confirmDelete() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar paciente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('¿Seguro que deseas eliminar a ${widget.patient.nombre}? Esta acción no se puede deshacer.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              final err = await context.read<PatientProvider>().deletePatient(auth.authHeaders(), widget.patient.id);
              if (mounted && err != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEdit() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPatientSheet(patient: widget.patient, onSaved: widget.onReload),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Header paciente
          Row(children: [
            AvatarWidget(name: widget.patient.nombre, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.patient.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (widget.patient.edad != null)
                  Text('${widget.patient.edad} años', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ]),
            ),
            PillBadge.fromRol(widget.patient.rol ?? 'cuidador'),
          ]),

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          // Cuidadores asociados
          const Text('Cuidadores', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          if (_loadingCaregivers)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
          else if (_caregivers.isEmpty && _caregiversFetched)
            const Text('Sin cuidadores registrados', style: TextStyle(fontSize: 13, color: AppColors.textTertiary))
          else
            ...(_caregivers.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                AvatarWidget(name: c.user.nombre, size: 36),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.user.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Text(c.user.email, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ])),
                PillBadge.fromRol(c.rol),
              ]),
            ))),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),

          // Acciones
          _ActionTile(icon: Icons.edit_outlined, label: 'Editar paciente', onTap: _showEdit),
          _ActionTile(
            icon: Icons.person_add_outlined,
            label: 'Agregar cuidador',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              context.push('/patients/${widget.patient.id}/caregivers/invite');
            },
          ),
          _ActionTile(
            icon: Icons.group_outlined,
            label: 'Ver todos los cuidadores',
            onTap: () {
              Navigator.pop(context);
              context.push('/patients/${widget.patient.id}/caregivers');
            },
          ),
          _ActionTile(icon: Icons.delete_outline_rounded, label: 'Eliminar paciente', color: AppColors.error, onTap: _confirmDelete),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      minLeadingWidth: 36,
      dense: true,
    );
  }
}

// ─── EDIT SHEET ─────────────────────────────────────────────────────────────

class _EditPatientSheet extends StatefulWidget {
  final Patient patient;
  final VoidCallback onSaved;
  const _EditPatientSheet({required this.patient, required this.onSaved});

  @override
  State<_EditPatientSheet> createState() => _EditPatientSheetState();
}

class _EditPatientSheetState extends State<_EditPatientSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _pesoCtrl;
  late final TextEditingController _telCtrl;
  late String _sexo;
  String? _tipoSangre;
  DateTime? _fechaNac;
  bool _loading = false;

  static const _tiposSangre = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nombreCtrl = TextEditingController(text: p.nombre);
    _pesoCtrl = TextEditingController(text: p.pesoKg?.toString() ?? '');
    _telCtrl = TextEditingController(text: p.telefonoEmergencia ?? '');
    _sexo = p.sexo;
    _tipoSangre = _tiposSangre.contains(p.tipoSangre) ? p.tipoSangre : null;
    _fechaNac = p.fechaNacimiento != null ? DateTime.tryParse(p.fechaNacimiento!) : null;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _pesoCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNac ?? DateTime(1960),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.textPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaNac = picked);
  }

  Future<void> _save() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final iso = _fechaNac != null
        ? '${_fechaNac!.year}-${_fechaNac!.month.toString().padLeft(2, '0')}-${_fechaNac!.day.toString().padLeft(2, '0')}'
        : widget.patient.fechaNacimiento ?? '';
    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'fecha_nacimiento': iso,
      'sexo': _sexo,
      if (_pesoCtrl.text.isNotEmpty) 'peso_kg': double.tryParse(_pesoCtrl.text) ?? 0,
      if (_tipoSangre != null) 'tipo_sangre': _tipoSangre,
      if (_telCtrl.text.isNotEmpty) 'telefono_emergencia': _telCtrl.text.trim(),
    };
    final err = await context.read<PatientProvider>().updatePatient(auth.authHeaders(), widget.patient.id, data);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else {
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaDisplay = _fechaNac != null
        ? '${_fechaNac!.day.toString().padLeft(2, '0')}/${_fechaNac!.month.toString().padLeft(2, '0')}/${_fechaNac!.year}'
        : 'Seleccionar fecha';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Editar paciente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),

            AppTextField(label: 'Nombre completo', controller: _nombreCtrl, prefixIcon: Icons.person_outline_rounded),
            const SizedBox(height: 14),

            // Fecha
            const Text('Fecha de nacimiento', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _fechaNac != null ? AppColors.primary : AppColors.border, width: _fechaNac != null ? 1.5 : 0.5),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: _fechaNac != null ? AppColors.primary : AppColors.textTertiary),
                  const SizedBox(width: 10),
                  Text(fechaDisplay, style: TextStyle(fontSize: 14, color: _fechaNac != null ? AppColors.textPrimary : AppColors.textTertiary)),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // Sexo
            const Text('Sexo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: ['masculino', 'femenino', 'otro'].map((s) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _sexo = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _sexo == s ? AppColors.primarySurface : AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _sexo == s ? AppColors.primary : AppColors.border, width: _sexo == s ? 1.5 : 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(s[0].toUpperCase() + s.substring(1),
                          style: TextStyle(fontSize: 13, fontWeight: _sexo == s ? FontWeight.w500 : FontWeight.w400, color: _sexo == s ? AppColors.primaryDark : AppColors.textSecondary)),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 14),

            Row(children: [
              Expanded(child: AppTextField(label: 'Peso (kg)', controller: _pesoCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tipo de sangre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _tipoSangre != null ? AppColors.primary : AppColors.border, width: _tipoSangre != null ? 1.5 : 0.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _tipoSangre,
                        hint: const Text('—', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textTertiary),
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        dropdownColor: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        items: _tiposSangre.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _tipoSangre = v),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            AppTextField(label: 'Teléfono de emergencia', controller: _telCtrl, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            AppButton(label: 'Guardar cambios', onPressed: _loading ? null : _save, loading: _loading),
          ],
        ),
      ),
    );
  }
}

// ─── HELPERS ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15), width: 0.5),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ]),
        ]),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]);
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.textTertiary, size: 18),
            SizedBox(width: 6),
            Text('Agregar nuevo paciente', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
