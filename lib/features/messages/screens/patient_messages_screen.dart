import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/patient_provider.dart';

class PatientMessagesScreen extends StatefulWidget {
  final String patientId;
  const PatientMessagesScreen({super.key, required this.patientId});

  @override
  State<PatientMessagesScreen> createState() => _PatientMessagesScreenState();
}

class _PatientMessagesScreenState extends State<PatientMessagesScreen> {
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
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    _ctrl.clear();
    final auth = context.read<AuthProvider>();
    final err = await context.read<MessageProvider>().sendMessage(auth.authHeaders(), widget.patientId, texto);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else {
      _scrollToBottom();
    }
  }

  void _confirmDelete(BuildContext context, PatientMessage msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar mensaje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: const Text('¿Deseas eliminar este mensaje?', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = context.read<AuthProvider>();
              final err = await context.read<MessageProvider>().deleteMessage(auth.authHeaders(), widget.patientId, msg.id);
              if (err != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final patient = context.watch<PatientProvider>().activePatient;
    final prov = context.watch<MessageProvider>();
    final myId = auth.user?.id;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mensajes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (patient != null) Text(patient.nombre, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : prov.messages.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: prov.messages.length,
                        itemBuilder: (_, i) {
                          final msg = prov.messages[i];
                          final isMe = msg.userId == myId;
                          final showDate = i == 0 || !_sameDay(prov.messages[i - 1].createdAt, msg.createdAt);
                          return Column(
                            children: [
                              if (showDate) _DateDivider(date: msg.createdAt),
                              _MessageBubble(
                                msg: msg,
                                isMe: isMe,
                                onLongPress: isMe ? () => _confirmDelete(context, msg) : null,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _InputBar(ctrl: _ctrl, sending: prov.sending, onSend: _send),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MessageBubble extends StatelessWidget {
  final PatientMessage msg;
  final bool isMe;
  final VoidCallback? onLongPress;
  const _MessageBubble({required this.msg, required this.isMe, this.onLongPress});

  String _time() {
    final h = msg.createdAt.hour.toString().padLeft(2, '0');
    final m = msg.createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            AvatarWidget(name: msg.userName, size: 28, photoUrl: msg.userFotoUrl),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(msg.userName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                    Text(msg.contenido, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(_time(), style: TextStyle(fontSize: 10, color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textHint)),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String _label() {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.borderLight)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(_label(), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ),
          const Expanded(child: Divider(color: AppColors.borderLight)),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSend;
  const _InputBar({required this.ctrl, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: sending ? AppColors.primaryLight : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: sending
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('Sin mensajes aún', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Deja recordatorios para el equipo', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
