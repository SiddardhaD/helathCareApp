import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

enum AppBadgeStatus { success, warning, critical, info, neutral }

/// A small colored status pill, e.g. "Taken", "Missed", "Expiring soon",
/// "3 days left". Reused across medications, reminders, and documents so
/// status communication is visually consistent throughout the app.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppBadgeStatus status;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  });

  (Color bg, Color fg) get _colors => switch (status) {
        AppBadgeStatus.success => (AppColors.successLight, AppColors.success),
        AppBadgeStatus.warning => (AppColors.warningLight, AppColors.warning),
        AppBadgeStatus.critical => (AppColors.criticalLight, AppColors.critical),
        AppBadgeStatus.info => (AppColors.infoLight, AppColors.info),
        AppBadgeStatus.neutral => (AppColors.surfaceMuted, AppColors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTextStyles.labelMedium.copyWith(color: fg)),
        ],
      ),
    );
  }
}
