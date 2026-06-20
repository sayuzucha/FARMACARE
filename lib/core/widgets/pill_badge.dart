import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PillType { success, error, warning, info, neutral }

class PillBadge extends StatelessWidget {
  final String label;
  final PillType type;

  const PillBadge({super.key, required this.label, this.type = PillType.neutral});

  factory PillBadge.fromDoseEstado(String estado) {
    switch (estado) {
      case 'tomado':
        return PillBadge(label: 'Tomado', type: PillType.success);
      case 'omitido':
        return PillBadge(label: 'Omitido', type: PillType.error);
      default:
        return PillBadge(label: 'Pendiente', type: PillType.warning);
    }
  }

  factory PillBadge.fromRol(String rol) {
    return PillBadge(
      label: rol == 'admin' ? 'Admin' : 'Cuidador',
      type: rol == 'admin' ? PillType.info : PillType.neutral,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case PillType.success:
        bg = AppColors.successSurface;
        fg = AppColors.successText;
        break;
      case PillType.error:
        bg = AppColors.errorSurface;
        fg = AppColors.errorText;
        break;
      case PillType.warning:
        bg = AppColors.warningSurface;
        fg = AppColors.warningText;
        break;
      case PillType.info:
        bg = AppColors.infoSurface;
        fg = AppColors.infoText;
        break;
      case PillType.neutral:
        bg = AppColors.backgroundTertiary;
        fg = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}
