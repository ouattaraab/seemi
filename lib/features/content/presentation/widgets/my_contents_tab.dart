import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';
import 'package:ppv_app/features/content/presentation/widgets/blurred_content_card.dart';

/// Onglet Accueil — liste des contenus du créateur avec pagination infinie.
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
      if (mounted) {
        context.read<ContentProvider>().loadMyContents();
      }
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
      builder: (context, provider, _) {
        // Premier chargement
        if (provider.isFetchingContents && provider.myContents.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Erreur sans données
        if (provider.contentsError != null && provider.myContents.isEmpty) {
          return _buildErrorView(provider);
        }

        // Liste vide
        if (provider.myContents.isEmpty) {
          return _buildEmptyState();
        }

        // Liste avec contenus
        return RefreshIndicator(
          onRefresh: () =>
              context.read<ContentProvider>().loadMyContents(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
            itemCount: provider.myContents.length +
                (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < provider.myContents.length) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.kSpaceMd),
                  child: BlurredContentCard(content: provider.myContents[index]),
                );
              }
              // Indicateur de chargement en bas de liste
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.kSpaceLg),
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorView(ContentProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSpacing.kIconSizeHero,
              color: AppColors.kError,
            ),
            const SizedBox(height: AppSpacing.kSpaceLg),
            Text(
              provider.contentsError ?? 'Erreur de chargement',
              style: AppTextStyles.kBodyMedium
                  .copyWith(color: AppColors.kTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.kSpaceLg),
            FilledButton(
              onPressed: () => provider.loadMyContents(refresh: true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: AppSpacing.kIconSizeHero,
              color: AppColors.kTextTertiary,
            ),
            const SizedBox(height: AppSpacing.kSpaceLg),
            Text(
              'Aucun contenu pour l\'instant.',
              style: AppTextStyles.kTitleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.kSpaceSm),
            Text(
              'Tapez + pour publier votre premier contenu !',
              style: AppTextStyles.kBodyMedium
                  .copyWith(color: AppColors.kTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
