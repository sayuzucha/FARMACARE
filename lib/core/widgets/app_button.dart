import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool fullWidth;
  final IconData? icon;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.fullWidth = true,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = isDisabled ? AppColors.primaryLight : AppColors.primary;
        fg = isDisabled ? AppColors.primaryDark : Colors.white;
        border = Colors.transparent;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.backgroundSecondary;
        fg = AppColors.textPrimary;
        border = AppColors.border;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.errorSurface;
        fg = AppColors.errorText;
        border = AppColors.errorBorder;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = Colors.transparent;
        break;
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 0.5),
              ),
              alignment: Alignment.center,
              child: loading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                  : Row(
                      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
                        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
