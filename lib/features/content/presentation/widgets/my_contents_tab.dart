import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';
import 'package:ppv_app/features/content/presentation/widgets/blurred_content_card.dart';

/// Onglet liste des contenus du créateur avec pagination infinie.
class MyContentsTab extends StatefulWidget {
  const MyContentsTab({super.key});

  @override
  State<MyContentsTab> createState() => _MyContentsTabState();
}

class _MyContentsTabState extends State<MyContentsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContentProvider>().loadMyContents();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ContentProvider>().loadMyContents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, provider, child) {
        // Premier chargement
        if (provider.isFetchingContents && provider.myContents.isEmpty) {
          return const _SkeletonLoader();
        }

        // Erreur sans données
        if (provider.contentsError != null && provider.myContents.isEmpty) {
          return _buildError(provider);
        }

        // Liste vide
        if (provider.myContents.isEmpty) {
          return const _EmptyState();
        }

        // Liste
        return RefreshIndicator(
          color: AppColors.kPrimary,
          onRefresh: () =>
              context.read<ContentProvider>().loadMyContents(refresh: true),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount:
                provider.myContents.length + (provider.hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == provider.myContents.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.kPrimary,
                      ),
                    ),
                  ),
                );
              }
              return BlurredContentCard(
                content: provider.myContents[index],
              );
            },
          ),
        );
      },
    );
  }

  // ── Erreur ────────────────────────────────────────────────────────────────

  Widget _buildError(ContentProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kError.withValues(alpha: 0.08),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 28,
                color: AppColors.kError,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vérifiez votre connexion et réessayez.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => provider.loadMyContents(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kPrimary,
                side: const BorderSide(color: AppColors.kPrimary),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
              child: const Icon(
                Icons.photo_library_outlined,
                size: 36,
                color: AppColors.kTextTertiary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun contenu pour l\'instant',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Appuyez sur + pour publier\nvotre premier contenu.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.kTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _SkeletonLoader ──────────────────────────────────────────────────────────

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.kBgElevated,
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
            ),
          ),
          const SizedBox(width: 14),
          // Text placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.kBgElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 16,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppColors.kBgOverlay,
                        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _bar(AppColors.kBgElevated, 130, 12),
                const SizedBox(height: 6),
                _bar(AppColors.kBgOverlay, 110, 11),
                const SizedBox(height: 6),
                _bar(AppColors.kBgOverlay, 90, 11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color, double width, double height) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
