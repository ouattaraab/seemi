import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/content/domain/content.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';

/// Carte d'un contenu créateur : thumbnail flouté + stats + actions.
class BlurredContentCard extends StatelessWidget {
  final Content content;

  const BlurredContentCard({super.key, required this.content});

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _priceFcfa {
    if (content.price == null) return 'Prix non défini';
    return _fcfa(content.price! ~/ 100);
  }

  int get _totalGained =>
      content.price != null
          ? (content.price! ~/ 100) * content.purchaseCount
          : 0;

  static String _fcfa(int amount) {
    if (amount >= 1000) {
      final k = amount ~/ 1000;
      final r = amount % 1000;
      return r == 0
          ? '$k\u202f000 FCFA'
          : '$k\u202f${r.toString().padLeft(3, '0')} FCFA';
    }
    return '$amount FCFA';
  }

  Future<void> _copyLink(BuildContext context) async {
    if (content.shareUrl == null) return;
    await Clipboard.setData(ClipboardData(text: content.shareUrl!));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copié !')),
    );
  }

  Future<void> _share(BuildContext context) async {
    if (content.shareUrl == null) return;
    await context.read<ShareRepository>().shareContent(content.shareUrl!);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kTextPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            const SizedBox(width: 14),
            Expanded(child: _buildInfo(context)),
          ],
        ),
      ),
    );
  }

  // ── Thumbnail ─────────────────────────────────────────────────────────────

  Widget _buildThumbnail() {
    final isVideo = content.type == 'video';
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image floutée
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
            child: content.blurUrl != null
                ? Image.network(
                    content.blurUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, st) => _placeholder(),
                  )
                : _placeholder(),
          ),
          // Cadenas central
          Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.40),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
          // Badge type (bas-gauche)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isVideo
                    ? AppColors.kPrimary.withValues(alpha: 0.88)
                    : AppColors.kAccent.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVideo
                        ? Icons.videocam_rounded
                        : Icons.image_rounded,
                    color: Colors.white,
                    size: 9,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isVideo ? 'VIDÉO' : 'PHOTO',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.kBgElevated,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.kTextTertiary,
        size: 28,
      ),
    );
  }

  // ── Info ──────────────────────────────────────────────────────────────────

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prix + statut + actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _priceFcfa,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.kTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(status: content.status),
            const Spacer(),
            if (content.shareUrl != null) ...[
              _ActionIcon(
                icon: Icons.link_rounded,
                onTap: () => _copyLink(context),
              ),
              const SizedBox(width: 6),
              _ActionIcon(
                icon: Icons.share_rounded,
                onTap: () => _share(context),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        // Stats
        _StatRow(
          icon: Icons.visibility_outlined,
          label:
              '${content.viewCount} vue${content.viewCount != 1 ? "s" : ""}',
          color: AppColors.kTextSecondary,
          iconBg: AppColors.kBgElevated,
        ),
        const SizedBox(height: 5),
        _StatRow(
          icon: Icons.shopping_bag_outlined,
          label:
              '${content.purchaseCount} vente${content.purchaseCount != 1 ? "s" : ""}',
          color: AppColors.kTextSecondary,
          iconBg: AppColors.kBgElevated,
        ),
        const SizedBox(height: 5),
        _StatRow(
          icon: Icons.account_balance_wallet_outlined,
          label: '${_fcfa(_totalGained)} gagné',
          color: AppColors.kSuccess,
          iconBg: AppColors.kSuccess.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}

// ─── _StatusBadge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'published'                => (AppColors.kSuccess, 'Publié'),
      'pending'                  => (AppColors.kWarning, 'En attente'),
      'rejected' || 'moderated' => (AppColors.kError, 'Rejeté'),
      _                          => (AppColors.kTextTertiary, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── _ActionIcon ──────────────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.kBgElevated,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: AppColors.kTextSecondary),
        ),
      ),
    );
  }
}

// ─── _StatRow ─────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconBg;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
