import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../../providers/patient_provider.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final patientId = context.watch<PatientProvider>().activePatient?.id;

    final items = [
      _NavItem(icon: Icons.people_outline, label: 'Pacientes', route: '/patients'),
      _NavItem(icon: Icons.medication_outlined, label: 'Medicamentos', route: patientId != null ? '/patients/$patientId/medications' : '/patients'),
      _NavItem(icon: Icons.bar_chart_outlined, label: 'Reportes', route: '/reports'),
      _NavItem(icon: Icons.person_outline, label: 'Perfil', route: '/profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.route),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 22, color: selected ? AppColors.primary : AppColors.textTertiary),
                      const SizedBox(height: 2),
                      Text(item.label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w500 : FontWeight.w400, color: selected ? AppColors.primary : AppColors.textTertiary)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}
