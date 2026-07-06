import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/pill_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/caregiver_provider.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/patient_provider.dart';

class CaregiversScreen extends StatefulWidget {
  final String patientId;
  const CaregiversScreen({super.key, required this.patientId});

  @override
  State<CaregiversScreen> createState() => _CaregiversScreenState();
}

class _CaregiversScreenState extends State<CaregiversScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<CaregiverProvider>().fetchAll(auth.authHeaders(), widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final patient = context.watch<PatientProvider>().activePatient;
    final caregiverProv = context.watch<CaregiverProvider>();
    final isAdmin = patient?.rol == 'admin';

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cuidadores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (patient != null) Text(patient.nombre, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () => WidgetsBinding.instance.addPostFrameCallback(
                  (_) => context.push('/patients/${widget.patientId}/caregivers/invite')),
              icon: const Icon(Icons.key_rounded, color: AppColors.primary),
              tooltip: 'Código de acceso',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Miembros'), Tab(text: 'Chat')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: MIEMBROS ──────────────────────────────────────────
          caregiverProv.loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [

                      // Botón código de acceso (solo admin)
                      if (isAdmin) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => WidgetsBinding.instance.addPostFrameCallback(
                                (_) => context.push('/patients/${widget.patientId}/caregivers/invite')),
                            icon: const Icon(Icons.key_rounded, size: 18),
                            label: const Text('Ver código de acceso', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Lista de miembros
                      if (caregiverProv.caregivers.isEmpty)
                        _EmptyState(isAdmin: isAdmin,
                            onCode: () => WidgetsBinding.instance.addPostFrameCallback(
                                (_) => context.push('/patients/${widget.patientId}/caregivers/invite')))
                      else ...[
                        Text('Miembros · ${caregiverProv.caregivers.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight, width: 0.5),
                          ),
                          child: Column(
                            children: caregiverProv.caregivers.asMap().entries.map((e) {
                              final idx = e.key;
                              final c = e.value;
                              final isMe = c.userId == auth.user?.id;
                              return Column(
                                children: [
                                  ListTile(
                                    leading: AvatarWidget(name: c.user.nombre, size: 40),
                                    title: Row(children: [
                                      Expanded(child: Text(c.user.nombre,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                                      if (isMe)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: AppColors.backgroundTertiary, borderRadius: BorderRadius.circular(10)),
                                          child: const Text('Tú', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                        ),
                                      PillBadge.fromRol(c.rol),
                                    ]),
                                    subtitle: Text(c.user.email,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                    trailing: isAdmin && !isMe
                                        ? const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary)
                                        : null,
                                    onTap: isAdmin && !isMe
                                        ? () => _showCaregiverSheet(context, c, isAdmin)
                                        : null,
                                  ),
                                  if (idx < caregiverProv.caregivers.length - 1)
                                    const Divider(height: 1, indent: 70, color: AppColors.borderLight),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

          // ── TAB 2: CHAT ──────────────────────────────────────────────
          _ChatTab(patientId: widget.patientId),
        ],
      ),
    );
  }

  void _showCaregiverSheet(BuildContext context, Caregiver c, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CaregiverSheet(
        caregiver: c,
        onChangeRole: (rol) async {
          final auth = context.read<AuthProvider>();
          final err = await context.read<CaregiverProvider>()
              .changeRole(auth.authHeaders(), widget.patientId, c.id, rol);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(err ?? 'Rol actualizado'),
            backgroundColor: err != null ? AppColors.error : AppColors.success,
          ));
        },
        onRemove: () async {
          final auth = context.read<AuthProvider>();
          final err = await context.read<CaregiverProvider>()
              .removeCaregiver(auth.authHeaders(), widget.patientId, c.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(err ?? 'Cuidador removido'),
            backgroundColor: err != null ? AppColors.error : AppColors.success,
          ));
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onCode;
  const _EmptyState({required this.isAdmin, required this.onCode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.group_outlined, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Sin cuidadores aún', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(
          isAdmin
              ? 'Comparte el código de acceso para que otros se unan.'
              : 'El administrador del paciente puede agregar cuidadores.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCode,
            icon: const Icon(Icons.key_rounded, size: 18),
            label: const Text('Ver código de acceso'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ]),
    );
  }
}

class _CaregiverSheet extends StatelessWidget {
  final Caregiver caregiver;
  final Function(String rol) onChangeRole;
  final VoidCallback onRemove;
  const _CaregiverSheet({required this.caregiver, required this.onChangeRole, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final newRol = caregiver.rol == 'admin' ? 'cuidador' : 'admin';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        AvatarWidget(name: caregiver.user.nombre, size: 56),
        const SizedBox(height: 12),
        Text(caregiver.user.nombre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(caregiver.user.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        PillBadge.fromRol(caregiver.rol),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Cambiar rol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  content: Text('¿Cambiar a ${caregiver.user.nombre} a ${newRol == 'admin' ? 'Admin' : 'Cuidador'}?',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
                    TextButton(
                      onPressed: () { Navigator.pop(context); onChangeRole(newRol); },
                      child: Text('Confirmar', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(caregiver.rol == 'admin' ? 'Cambiar a Cuidador' : 'Cambiar a Admin'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(0, 46),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Remover del grupo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  content: Text('¿Remover a ${caregiver.user.nombre}? No podrá acceder al paciente.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
                    TextButton(
                      onPressed: () { Navigator.pop(context); onRemove(); },
                      child: const Text('Remover', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.person_remove_outlined, size: 18),
            label: const Text('Remover del grupo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              minimumSize: const Size(0, 46),
              side: const BorderSide(color: AppColors.errorBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CHAT TAB
// ──────────────────────────────────────────────────────────────────────────────

class _ChatTab extends StatefulWidget {
  final String patientId;
  const _ChatTab({required this.patientId});

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<MessageProvider>().fetchMessages(auth.authHeaders(), widget.patientId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final auth = context.read<AuthProvider>();
    final err = await context.read<MessageProvider>().sendMessage(auth.authHeaders(), widget.patientId, text);
    if (!mounted) return;
    if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    else _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final msgProv = context.watch<MessageProvider>();

    return Column(children: [
      Container(
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          const Icon(Icons.group_outlined, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          const Expanded(child: Text('Chat del grupo de cuidadores', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textTertiary), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
      ),
      const Divider(height: 1, color: AppColors.borderLight),
      Expanded(
        child: msgProv.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : msgProv.messages.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline_rounded, size: 32, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    const Text('Aún no hay mensajes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('¡Sé el primero en escribir!', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ]))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: msgProv.messages.length,
                    itemBuilder: (_, i) {
                      final msg = msgProv.messages[i];
                      final isMe = msg.userId == auth.user?.id;
                      final showDate = i == 0 || !_sameDay(msgProv.messages[i - 1].createdAt, msg.createdAt);
                      return Column(children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        _Bubble(msg: msg, isMe: isMe),
                      ]);
                    },
                  ),
      ),
      Container(
        color: AppColors.background,
        padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          msgProv.sending
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
              : IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(backgroundColor: AppColors.primarySurface, padding: const EdgeInsets.all(10)),
                ),
        ]),
      ),
    ]);
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Hoy';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      label = 'Ayer';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        const Expanded(child: Divider(color: AppColors.borderLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
        ),
        const Expanded(child: Divider(color: AppColors.borderLight)),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final PatientMessage msg;
  final bool isMe;
  const _Bubble({required this.msg, required this.isMe});

  String _time() {
    final h = msg.createdAt.hour.toString().padLeft(2, '0');
    final m = msg.createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6, left: isMe ? 48 : 0, right: isMe ? 0 : 48),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[AvatarWidget(name: msg.userName, size: 26), const SizedBox(width: 6)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(msg.userName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  Text(msg.contenido, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.textPrimary, height: 1.4)),
                  const SizedBox(height: 3),
                  Text(_time(), style: TextStyle(fontSize: 10, color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textHint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
