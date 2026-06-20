import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medication_provider.dart';

class AddMedicationScreen extends StatefulWidget {
  final String patientId;
  const AddMedicationScreen({super.key, required this.patientId});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nombreCtrl = TextEditingController();
  final _dosisCtrl = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  final _indicacionesCtrl = TextEditingController();

  String _unidad = 'mg';
  String _via = 'oral';
  List<String> _horarios = [];
  int _cantidad = 1;
  int? _frecuenciaHoras;
  final _duracionCtrl = TextEditingController();
  List<int> _diasSemana = [];

  String? _nombreError;
  String? _dosisError;
  String? _horariosError;
  String? _fechaInicioError;

  static const _unidades = ['mg', 'ml', 'g', 'UI', 'gotas'];
  static const _vias = ['oral', 'inyectable', 'tópico', 'inhalado'];
  static const _frecuencias = [4, 6, 8, 12, 24];
  static const _diasNombres = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dosisCtrl.dispose();
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    _indicacionesCtrl.dispose();
    _duracionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      final hora = '$h:$m';
      if (!_horarios.contains(hora)) {
        setState(() => _horarios = [..._horarios, hora]..sort());
      }
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      ctrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nombreError = _nombreCtrl.text.trim().isEmpty ? 'Campo requerido' : null;
      final dosis = double.tryParse(_dosisCtrl.text.trim());
      _dosisError = (dosis == null || dosis <= 0) ? 'Ingresa una dosis válida' : null;
      _horariosError = _horarios.isEmpty ? 'Agrega al menos un horario' : null;
      _fechaInicioError = _fechaInicioCtrl.text.trim().isEmpty ? 'Campo requerido' : null;
      if (_nombreError != null || _dosisError != null || _horariosError != null || _fechaInicioError != null) ok = false;
    });
    return ok;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final auth = context.read<AuthProvider>();
    final medProv = context.read<MedicationProvider>();
    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'dosis': double.parse(_dosisCtrl.text.trim()),
      'unidad': _unidad,
      'via_administracion': _via,
      'horarios': _horarios,
      'cantidad': _cantidad,
      if (_frecuenciaHoras != null) 'frecuencia_horas': _frecuenciaHoras,
      if (_duracionCtrl.text.trim().isNotEmpty) 'duracion_dias': int.tryParse(_duracionCtrl.text.trim()),
      if (_diasSemana.isNotEmpty) 'dias_semana': _diasSemana,
      'fecha_inicio': _fechaInicioCtrl.text.trim(),
      if (_fechaFinCtrl.text.trim().isNotEmpty) 'fecha_fin': _fechaFinCtrl.text.trim(),
      if (_indicacionesCtrl.text.trim().isNotEmpty) 'indicaciones': _indicacionesCtrl.text.trim(),
    };
    final err = await medProv.createMedication(auth.authHeaders(), widget.patientId, data);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<MedicationProvider>().loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        ),
        title: const Text('Nuevo medicamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Nombre del medicamento',
              hint: 'Ej. Metformina',
              controller: _nombreCtrl,
              errorText: _nombreError,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Dosis',
              hint: 'Ej. 500',
              controller: _dosisCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              errorText: _dosisError,
            ),
            const SizedBox(height: 16),
            _DropdownField(
              label: 'Unidad',
              value: _unidad,
              items: _unidades,
              onChanged: (v) => setState(() => _unidad = v!),
            ),
            const SizedBox(height: 16),
            _DropdownField(
              label: 'Vía de administración',
              value: _via,
              items: _vias,
              onChanged: (v) => setState(() => _via = v!),
            ),
            const SizedBox(height: 16),
            _CantidadSelector(
              value: _cantidad,
              onChanged: (v) => setState(() => _cantidad = v),
            ),
            const SizedBox(height: 16),
            _FrecuenciaSelector(
              value: _frecuenciaHoras,
              opciones: _frecuencias,
              onChanged: (v) => setState(() => _frecuenciaHoras = v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Duración (días)',
              hint: 'Ej. 30 (dejar vacío si es indefinido)',
              controller: _duracionCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _DiasSemanaSelector(
              selected: _diasSemana,
              nombres: _diasNombres,
              onChanged: (d) => setState(() => _diasSemana = d),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Horarios', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const Spacer(),
                GestureDetector(
                  onTap: _pickTime,
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 2),
                      Text('Agregar horario', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            if (_horariosError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_horariosError!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
              ),
            const SizedBox(height: 8),
            if (_horarios.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _horarios.map((h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(h, style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _horarios = _horarios.where((x) => x != h).toList()),
                        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _pickDate(_fechaInicioCtrl),
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Fecha de inicio',
                  hint: 'YYYY-MM-DD',
                  controller: _fechaInicioCtrl,
                  errorText: _fechaInicioError,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _pickDate(_fechaFinCtrl),
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Fecha de fin (opcional)',
                  hint: 'YYYY-MM-DD',
                  controller: _fechaFinCtrl,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Indicaciones (opcional)',
              hint: 'Tomar con alimentos...',
              controller: _indicacionesCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Guardar medicamento',
              onPressed: _save,
              loading: loading,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CantidadSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _CantidadSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cantidad por toma', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            _CountBtn(icon: Icons.remove_rounded, onTap: value > 1 ? () => onChanged(value - 1) : null),
            const SizedBox(width: 16),
            Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(width: 16),
            _CountBtn(icon: Icons.add_rounded, onTap: () => onChanged(value + 1)),
            const SizedBox(width: 10),
            const Text('pastilla(s) / dosis', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      ],
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primarySurface : AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: onTap != null ? AppColors.primary : AppColors.border, width: 0.5),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? AppColors.primary : AppColors.textHint),
      ),
    );
  }
}

class _FrecuenciaSelector extends StatelessWidget {
  final int? value;
  final List<int> opciones;
  final ValueChanged<int?> onChanged;
  const _FrecuenciaSelector({required this.value, required this.opciones, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frecuencia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        const Text('Opcional si ya pusiste horarios específicos', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            GestureDetector(
              onTap: () => onChanged(null),
              child: _FreqChip(label: 'Ninguna', selected: value == null),
            ),
            ...opciones.map((h) => GestureDetector(
              onTap: () => onChanged(h),
              child: _FreqChip(label: 'Cada ${h}h', selected: value == h),
            )),
          ],
        ),
      ],
    );
  }
}

class _FreqChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _FreqChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySurface : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 0.8),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? AppColors.primaryDark : AppColors.textSecondary)),
    );
  }
}

class _DiasSemanaSelector extends StatelessWidget {
  final List<int> selected;
  final List<String> nombres;
  final ValueChanged<List<int>> onChanged;
  const _DiasSemanaSelector({required this.selected, required this.nombres, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Días de la semana', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        const Text('Dejar vacío = todos los días', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final dia = i + 1;
            final sel = selected.contains(dia);
            return GestureDetector(
              onTap: () {
                final next = List<int>.from(selected);
                sel ? next.remove(dia) : next.add(dia);
                next.sort();
                onChanged(next);
              },
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.backgroundSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: 0.8),
                ),
                alignment: Alignment.center,
                child: Text(nombres[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textSecondary)),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 0.8)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
      ],
    );
  }
}
