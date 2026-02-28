import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';

/// Données pour un écran d'onboarding.
class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.camera_alt_outlined,
    title: 'Partagez vos photos',
    description:
        'Prenez ou sélectionnez vos plus belles photos depuis votre galerie',
  ),
  _OnboardingPage(
    icon: Icons.monetization_on_outlined,
    title: 'Fixez votre prix',
    description:
        'Définissez le montant que les acheteurs paieront pour voir votre contenu',
  ),
  _OnboardingPage(
    icon: Icons.account_balance_wallet_outlined,
    title: 'Gagnez de l\'argent',
    description:
        'Recevez vos gains directement sur votre Mobile Money ou compte bancaire',
  ),
];

/// Écran d'onboarding 3 pages — introduction à PPV.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(RouteNames.kRouteRegister);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _OnboardingPageView(page: page);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.kSpaceLg),
              _PageIndicator(
                count: _pages.length,
                currentPage: _currentPage,
              ),
              const SizedBox(height: AppSpacing.kSpace2xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(isLastPage ? 'Commencer' : 'Suivant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          page.icon,
          size: AppSpacing.kSpace2xl + AppSpacing.kSpaceXl,
          color: AppColors.kPrimary,
        ),
        const SizedBox(height: AppSpacing.kSpaceLg),
        Text(
          page.title,
          style: AppTextStyles.kHeadlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        Text(
          page.description,
          style: AppTextStyles.kBodyLarge.copyWith(
            color: AppColors.kTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int currentPage;

  const _PageIndicator({
    required this.count,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.kSpaceXs,
          ),
          height: AppSpacing.kSpaceSm,
          width: isActive
              ? AppSpacing.kSpaceLg
              : AppSpacing.kSpaceSm,
          decoration: BoxDecoration(
            color: isActive ? AppColors.kPrimary : AppColors.kOutline,
            borderRadius: BorderRadius.circular(AppSpacing.kSpaceXs),
          ),
        );
      }),
    );
  }
}
