import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import 'avatar_widget.dart';
import 'bottom_nav.dart';

/// Breakpoint: >= 800px → web sidebar layout
bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 800;

class AppShell extends StatelessWidget {
  final int currentIndex;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color backgroundColor;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.currentIndex,
    required this.body,
    this.appBar,
    this.backgroundColor = AppColors.backgroundSecondary,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWideLayout(context)) {
      // ── MOBILE ──────────────────────────────────────────────────────
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: AppBottomNav(currentIndex: currentIndex),
      );
    }

    // ── WEB ─────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          _WebSidebar(currentIndex: currentIndex),
          const VerticalDivider(width: 1, thickness: 0.5, color: AppColors.borderLight),
          Expanded(
            child: Scaffold(
              backgroundColor: backgroundColor,
              appBar: appBar,
              floatingActionButton: floatingActionButton,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WebSidebar extends StatelessWidget {
  final int currentIndex;
  const _WebSidebar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final patient = context.watch<PatientProvider>().activePatient;
    final patientId = patient?.id;

    final items = [
      _SideItem(icon: Icons.people_outline_rounded,      label: 'Pacientes',     route: '/patients'),
      _SideItem(icon: Icons.medication_outlined,          label: 'Medicamentos',  route: patientId != null ? '/patients/$patientId/medications' : '/patients'),
      _SideItem(icon: Icons.bar_chart_outlined,           label: 'Reportes',      route: '/reports'),
      _SideItem(icon: Icons.person_outline_rounded,       label: 'Perfil',        route: '/profile'),
    ];

    return Container(
      width: 220,
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo / Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.local_pharmacy_outlined, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text('Farmacare', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
            ),

            // Paciente activo (si hay)
            if (patient != null) ...[
              const SizedBox(height: 4),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  AvatarWidget(name: patient.nombre, size: 30),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(patient.nombre,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                        overflow: TextOverflow.ellipsis),
                    const Text('Paciente activo', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                  ])),
                ]),
              ),
            ],

            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('NAVEGACIÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
            ),
            const SizedBox(height: 8),

            // Nav items
            ...List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return _SideNavTile(item: item, selected: selected);
            }),

            const Spacer(),
            const Divider(color: AppColors.borderLight, height: 1),

            // User info
            if (auth.user != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  AvatarWidget(name: auth.user!.nombre, size: 34),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(auth.user!.nombre,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    Text(auth.user!.email,
                        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                        overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _SideNavTile extends StatelessWidget {
  final _SideItem item;
  final bool selected;
  const _SideNavTile({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(item.icon, size: 20, color: selected ? AppColors.primary : AppColors.textSecondary),
        title: Text(item.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            )),
        onTap: () => context.go(item.route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _SideItem {
  final IconData icon;
  final String label;
  final String route;
  const _SideItem({required this.icon, required this.label, required this.route});
}
