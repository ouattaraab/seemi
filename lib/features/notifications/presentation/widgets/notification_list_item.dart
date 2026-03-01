import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/notifications/domain/app_notification.dart';

class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final (iconData, iconColor) = _iconForType(notification.type);

    return Material(
      color: isUnread
          ? AppColors.kPrimary.withValues(alpha: 0.04)
          : AppColors.kBgSurface,
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            border: Border.all(
              color: isUnread
                  ? AppColors.kPrimary.withValues(alpha: 0.15)
                  : AppColors.kBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icône ────────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              // ── Contenu ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + point non lu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.kBodyMedium.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.kTextPrimary,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.kPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Corps
                    Text(
                      notification.body,
                      style: AppTextStyles.kCaption.copyWith(
                        color: AppColors.kTextSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Date
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: AppColors.kTextTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(notification.createdAt),
                          style: AppTextStyles.kCaption.copyWith(
                            fontSize: 11,
                            color: AppColors.kTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static (IconData, Color) _iconForType(String type) {
    return switch (type) {
      'payment_confirmed' => (
          Icons.check_circle_outline_rounded,
          AppColors.kSuccess,
        ),
      'payment_failed' => (
          Icons.cancel_outlined,
          AppColors.kError,
        ),
      'withdrawal_processed' => (
          Icons.account_balance_rounded,
          AppColors.kPrimary,
        ),
      'withdrawal_rejected' => (
          Icons.account_balance_outlined,
          AppColors.kError,
        ),
      'withdrawal_requested' => (
          Icons.account_balance_wallet_outlined,
          AppColors.kPrimary,
        ),
      'content_moderated' => (
          Icons.image_outlined,
          AppColors.kAccent,
        ),
      _ => (
          Icons.notifications_outlined,
          AppColors.kTextSecondary,
        ),
    };
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}
