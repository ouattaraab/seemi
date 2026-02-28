import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/content/domain/content.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';

/// Carte affichant un contenu flouté avec ses statistiques (vues, ventes, gains).
class BlurredContentCard extends StatelessWidget {
  final Content content;

  const BlurredContentCard({super.key, required this.content});

  String get _priceFcfa {
    if (content.price == null) return 'Prix non défini';
    return '${content.price! ~/ 100} FCFA';
  }

  int get _totalGained =>
      content.price != null ? (content.price! ~/ 100) * content.purchaseCount : 0;

  Future<void> _share(BuildContext context) async {
    final repo = context.read<ShareRepository>();
    await repo.shareContent(content.shareUrl!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien partagé !')),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: content.shareUrl!));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copié !')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
        side: BorderSide(color: AppColors.kOutline),
      ),
      color: AppColors.kBgSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.kSpaceSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            const SizedBox(width: AppSpacing.kSpaceMd),
            Expanded(child: _buildStats()),
            if (content.shareUrl != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _copyLink(context),
                    icon: const Icon(Icons.link_outlined),
                    iconSize: 20,
                    color: AppColors.kTextSecondary,
                  ),
                  IconButton(
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.share_outlined),
                    iconSize: 20,
                    color: AppColors.kTextSecondary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusSm),
      child: SizedBox(
        width: 80,
        height: 80,
        child: content.blurUrl != null
            ? Image.network(
                content.blurUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.kBgElevated,
      child: Icon(
        Icons.image_outlined,
        color: AppColors.kTextTertiary,
        size: 32,
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_priceFcfa, style: AppTextStyles.kTitleLarge),
        const SizedBox(height: AppSpacing.kSpaceXs),
        _statRow(
          icon: Icons.visibility_outlined,
          label: '${content.viewCount} vue${content.viewCount != 1 ? 's' : ''}',
          color: AppColors.kTextSecondary,
        ),
        _statRow(
          icon: Icons.shopping_cart_outlined,
          label:
              '${content.purchaseCount} vente${content.purchaseCount != 1 ? 's' : ''}',
          color: AppColors.kTextSecondary,
        ),
        _statRow(
          icon: Icons.account_balance_wallet_outlined,
          label: '$_totalGained FCFA gagné',
          color: AppColors.kSuccess,
        ),
      ],
    );
  }

  Widget _statRow({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.kCaption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
