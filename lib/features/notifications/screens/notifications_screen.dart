import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _soloNoLeidas = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await context.read<NotificationProvider>().fetchNotifications(auth.authHeaders(), soloNoLeidas: _soloNoLeidas);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Notificaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _ToggleChip(label: 'Todas', selected: !_soloNoLeidas, onTap: () { setState(() => _soloNoLeidas = false); _load(); }),
                const SizedBox(width: 8),
                _ToggleChip(label: 'No leídas', selected: _soloNoLeidas, onTap: () { setState(() => _soloNoLeidas = true); _load(); }),
              ],
            ),
          ),
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : prov.notifications.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.separated(
                          itemCount: prov.notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                          itemBuilder: (_, i) => _NotifTile(
                            notif: prov.notifications[i],
                            onTap: () {
                              final auth = context.read<AuthProvider>();
                              context.read<NotificationProvider>().markRead(auth.authHeaders(), prov.notifications[i].id);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
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

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  IconData get _icon {
    switch (notif.tipo) {
      case 'recordatorio': return Icons.alarm_outlined;
      case 'toma_registrada': return Icons.check_circle_outline;
      case 'invitacion': return Icons.person_add_outlined;
      default: return Icons.info_outline;
    }
  }

  String _relativeTime() {
    final diff = DateTime.now().difference(notif.createdAt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.leida ? AppColors.background : AppColors.backgroundSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
              child: Icon(_icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.titulo, style: TextStyle(fontSize: 14, fontWeight: notif.leida ? FontWeight.w400 : FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(notif.cuerpo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(_relativeTime(), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            if (!notif.leida)
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ],
        ),
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
          Icon(Icons.notifications_none_outlined, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('Sin notificaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Aquí aparecerán tus notificaciones', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
