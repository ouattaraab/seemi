import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/bundle/domain/bundle.dart';
import 'package:ppv_app/features/bundle/presentation/my_bundles_provider.dart';

/// Écran "Mes bundles" — liste des bundles créés par le créateur connecté.
class MyBundlesScreen extends StatefulWidget {
  const MyBundlesScreen({super.key});

  @override
  State<MyBundlesScreen> createState() => _MyBundlesScreenState();
}

class _MyBundlesScreenState extends State<MyBundlesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MyBundlesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.kTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Mes bundles',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: AppColors.kBorder.withValues(alpha: 0.6)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push(RouteNames.kRouteBundleCreate);
          if (result == true && mounted) {
            context.read<MyBundlesProvider>().load();
          }
        },
        backgroundColor: AppColors.kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Créer',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<MyBundlesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimary),
            );
          }

          if (provider.error != null && provider.bundles.isEmpty) {
            return _ErrorState(
              message: provider.error!,
              onRetry: provider.load,
            );
          }

          if (provider.bundles.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            color: AppColors.kPrimary,
            onRefresh: provider.load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              itemCount: provider.bundles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _BundleCard(
                    bundle: provider.bundles[index],
                    onDelete: () =>
                        _confirmDelete(context, provider, provider.bundles[index].id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, MyBundlesProvider provider, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Supprimer ce bundle ?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        content: const Text(
          'Le bundle sera définitivement supprimé. Les contenus individuels '
          'ne seront pas affectés.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: AppColors.kTextSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.kTextSecondary),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.kError),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text(
              'Supprimer',
              style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await provider.deleteBundle(id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Bundle supprimé.'
            : 'Erreur lors de la suppression.'),
        backgroundColor: success ? AppColors.kSuccess : AppColors.kError,
      ),
    );
  }
}

// ─── _BundleCard ──────────────────────────────────────────────────────────────

class _BundleCard extends StatelessWidget {
  final Bundle bundle;
  final VoidCallback onDelete;

  const _BundleCard({required this.bundle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = bundle.discountPercent > 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kTextPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône bundle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                color: AppColors.kPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bundle.title,
                          style: AppTextStyles.kBodyMedium
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.kSuccess.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.kRadiusPill),
                          ),
                          child: Text(
                            '-${bundle.discountPercent}%',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kSuccess,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bundle.itemsCount} contenu${bundle.itemsCount > 1 ? 's' : ''}',
                    style: AppTextStyles.kCaption,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          '${_fmt(bundle.totalPriceFcfa)} FCFA',
                          style: AppTextStyles.kCaption.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.kTextTertiary,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${_fmt(bundle.discountedPriceFcfa)} FCFA',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Supprimer
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.kError, size: 20),
              tooltip: 'Supprimer',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── _EmptyState ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kBgElevated,
              ),
              child: const Icon(Icons.collections_bookmark_outlined,
                  size: 36, color: AppColors.kTextTertiary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Créez votre premier bundle',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Regroupez plusieurs contenus dans un bundle avec une remise\n'
              'pour augmenter vos ventes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.kTextSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _ErrorState ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.kTextTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.kBodyMedium
                  .copyWith(color: AppColors.kTextSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
