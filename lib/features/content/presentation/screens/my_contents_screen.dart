import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/content/domain/content.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';

/// Écran "Tous mes contenus" — liste paginée (cursor-based) des contenus
/// du créateur. Accessible depuis le bouton "Voir tout" du dashboard.
class MyContentsScreen extends StatefulWidget {
  const MyContentsScreen({super.key});

  @override
  State<MyContentsScreen> createState() => _MyContentsScreenState();
}

class _MyContentsScreenState extends State<MyContentsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContentProvider>().loadMyContents(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ContentProvider>();
      if (provider.hasMore && !provider.isFetchingContents) {
        provider.loadMyContents();
      }
    }
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
          'Mes contenus',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => context.push(RouteNames.kRouteMyBundles),
              icon: const Icon(Icons.collections_bookmark_rounded,
                  size: 16, color: AppColors.kPrimary),
              label: const Text(
                'Bundles',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kPrimary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.kBorder.withValues(alpha: 0.6)),
        ),
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, child) {
          if (provider.isFetchingContents && provider.myContents.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimary),
            );
          }

          if (provider.contentsError != null && provider.myContents.isEmpty) {
            return _ErrorState(
              message: provider.contentsError!,
              onRetry: () => provider.loadMyContents(refresh: true),
            );
          }

          if (provider.myContents.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            color: AppColors.kPrimary,
            onRefresh: () => provider.loadMyContents(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              itemCount: provider.myContents.length +
                  (provider.hasMore || provider.isFetchingContents ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.myContents.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.kPrimary),
                    ),
                  );
                }
                final content = provider.myContents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ContentListTile(content: content),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── _ContentListTile ─────────────────────────────────────────────────────────

class _ContentListTile extends StatelessWidget {
  final Content content;
  const _ContentListTile({required this.content});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Supprimer ce contenu ?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        content: const Text(
          'Cette action est irréversible. Le contenu ne sera plus accessible '
          'pour personne et les liens partagés afficheront '
          '« Ce contenu n\'est plus disponible ».',
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
                color: AppColors.kTextSecondary,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.kError),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text(
              'Supprimer',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<ContentProvider>();
    final success = await provider.deleteContent(content.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Contenu supprimé.'
              : provider.deleteContentError ?? 'Erreur lors de la suppression.',
        ),
        backgroundColor: success ? AppColors.kSuccess : AppColors.kError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        RouteNames.creatorContentDetail(content.id),
        extra: content,
      ),
      child: Container(
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
        child: Row(
          children: [
            // Miniature
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.kRadiusLg),
                bottomLeft: Radius.circular(AppSpacing.kRadiusLg),
              ),
              child: SizedBox(
                width: 88,
                height: 88,
                child: content.blurUrl != null
                    ? Image.network(
                        content.blurUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, st) =>
                            _placeholder(content.type),
                      )
                    : _placeholder(content.type),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeBadge(type: content.type),
                        const SizedBox(width: 6),
                        _StatusBadge(status: content.status),
                        if (content.isViewOnce) ...[
                          const SizedBox(width: 6),
                          _ViewOnceBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content.slug ?? 'Contenu #${content.id}',
                      style: AppTextStyles.kBodyMedium
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined,
                            size: 13, color: AppColors.kTextTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${content.viewCount} vues',
                          style: AppTextStyles.kCaption,
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.shopping_cart_outlined,
                            size: 13, color: AppColors.kTextTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${content.purchaseCount} ventes',
                          style: AppTextStyles.kCaption,
                        ),
                      ],
                    ),
                    if (content.price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_fmt(content.price! ~/ 100)} FCFA',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton supprimer
                IconButton(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.kError,
                    size: 20,
                  ),
                  tooltip: 'Supprimer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right_rounded,
                      color: AppColors.kTextTertiary, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String type) {
    return Container(
      color: AppColors.kBgElevated,
      child: Icon(
        type == 'video' ? Icons.videocam_outlined : Icons.image_outlined,
        size: 30,
        color: AppColors.kTextTertiary,
      ),
    );
  }

  static String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── Badges ───────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isVideo = type == 'video';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isVideo
            ? AppColors.kAccentViolet.withValues(alpha: 0.10)
            : AppColors.kPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.image_rounded,
            size: 10,
            color: isVideo ? AppColors.kAccentViolet : AppColors.kPrimary,
          ),
          const SizedBox(width: 3),
          Text(
            isVideo ? 'Vidéo' : 'Photo',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isVideo ? AppColors.kAccentViolet : AppColors.kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active'   => ('Actif', AppColors.kSuccess),
      'pending'  => ('En attente', AppColors.kWarning),
      'rejected' => ('Rejeté', AppColors.kError),
      'deleted'  => ('Supprimé', AppColors.kTextTertiary),
      _ => (status, AppColors.kTextSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ViewOnceBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.kAccentViolet.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off_outlined,
              size: 10, color: AppColors.kAccentViolet),
          SizedBox(width: 3),
          Text(
            'Vue unique',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.kAccentViolet,
            ),
          ),
        ],
      ),
    );
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
              child: const Icon(Icons.image_outlined,
                  size: 36, color: AppColors.kTextTertiary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun contenu publié',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Uploadez votre premier contenu pour commencer à gagner.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.kTextSecondary,
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
