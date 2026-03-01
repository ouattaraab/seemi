import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';

/// Écran temporaire pour visualiser le design system PPV.
/// Sera remplacé par la navigation réelle en Story 1.4.
class DesignShowcaseScreen extends StatelessWidget {
  const DesignShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SeeMi Design System')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
        children: [
          _buildSectionTitle(context, 'Palette de Couleurs'),
          _buildColorSection(),
          const SizedBox(height: AppSpacing.kSpaceLg),
          _buildSectionTitle(context, 'Typographie'),
          _buildTypographySection(),
          const SizedBox(height: AppSpacing.kSpaceLg),
          _buildSectionTitle(context, 'Boutons'),
          _buildButtonSection(),
          const SizedBox(height: AppSpacing.kSpaceLg),
          _buildSectionTitle(context, 'Cards'),
          _buildCardSection(context),
          const SizedBox(height: AppSpacing.kSpaceLg),
          _buildSectionTitle(context, 'Inputs'),
          _buildInputSection(),
          const SizedBox(height: AppSpacing.kSpaceLg),
          _buildSectionTitle(context, 'Spacing'),
          _buildSpacingSection(),
          const SizedBox(height: AppSpacing.kSpace2xl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.kSpaceMd),
      child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
    );
  }

  // ─── Palette Section ───
  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Backgrounds', style: AppTextStyles.kLabelLarge),
        const SizedBox(height: AppSpacing.kSpaceSm),
        _buildColorRow([
          const _ColorItem('Base', AppColors.kBgBase),
          const _ColorItem('Surface', AppColors.kBgSurface),
          const _ColorItem('Elevated', AppColors.kBgElevated),
          const _ColorItem('Overlay', AppColors.kBgOverlay),
        ]),
        const SizedBox(height: AppSpacing.kSpaceMd),
        const Text('Primary Teal', style: AppTextStyles.kLabelLarge),
        const SizedBox(height: AppSpacing.kSpaceSm),
        _buildColorRow([
          const _ColorItem('Primary', AppColors.kPrimary),
          const _ColorItem('Light', AppColors.kPrimaryLight),
          const _ColorItem('Dark', AppColors.kPrimaryDark),
        ]),
        const SizedBox(height: AppSpacing.kSpaceMd),
        const Text('Accent Orange', style: AppTextStyles.kLabelLarge),
        const SizedBox(height: AppSpacing.kSpaceSm),
        _buildColorRow([
          const _ColorItem('Orange', AppColors.kAccentOrange),
          const _ColorItem('Light', AppColors.kAccentOrangeLight),
          const _ColorItem('Dark', AppColors.kAccentOrangeDark),
        ]),
        const SizedBox(height: AppSpacing.kSpaceMd),
        const Text('Accent Violet', style: AppTextStyles.kLabelLarge),
        const SizedBox(height: AppSpacing.kSpaceSm),
        _buildColorRow([
          const _ColorItem('Violet', AppColors.kAccentViolet),
          const _ColorItem('Light', AppColors.kAccentVioletLight),
          const _ColorItem('Dark', AppColors.kAccentVioletDark),
        ]),
        const SizedBox(height: AppSpacing.kSpaceMd),
        const Text('Sémantiques', style: AppTextStyles.kLabelLarge),
        const SizedBox(height: AppSpacing.kSpaceSm),
        _buildColorRow([
          const _ColorItem('Success', AppColors.kSuccess),
          const _ColorItem('Warning', AppColors.kWarning),
          const _ColorItem('Error', AppColors.kError),
          const _ColorItem('Info', AppColors.kInfo),
        ]),
        const SizedBox(height: AppSpacing.kSpaceMd),
        const Text('Textes', style: AppTextStyles.kLabelLarge),
        const SizedBox(height: AppSpacing.kSpaceSm),
        _buildColorRow([
          const _ColorItem('Primary', AppColors.kTextPrimary),
          const _ColorItem('Secondary', AppColors.kTextSecondary),
          const _ColorItem('Tertiary', AppColors.kTextTertiary),
          const _ColorItem('Disabled', AppColors.kTextDisabled),
        ]),
      ],
    );
  }

  Widget _buildColorRow(List<_ColorItem> items) {
    return Wrap(
      spacing: AppSpacing.kSpaceSm,
      runSpacing: AppSpacing.kSpaceSm,
      children: items
          .map((item) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.kRadiusSm),
                      border: Border.all(color: AppColors.kDivider),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.kSpaceXs),
                  Text(
                    item.name,
                    style: AppTextStyles.kCaption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ))
          .toList(),
    );
  }

  // ─── Typography Section ───
  Widget _buildTypographySection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large 32px', style: AppTextStyles.kDisplayLarge),
        SizedBox(height: AppSpacing.kSpaceSm),
        Text('Headline Large 24px', style: AppTextStyles.kHeadlineLarge),
        SizedBox(height: AppSpacing.kSpaceSm),
        Text('Headline Medium 20px', style: AppTextStyles.kHeadlineMedium),
        SizedBox(height: AppSpacing.kSpaceSm),
        Text('Title Large 17px', style: AppTextStyles.kTitleLarge),
        SizedBox(height: AppSpacing.kSpaceSm),
        Text('Body Large 15px', style: AppTextStyles.kBodyLarge),
        SizedBox(height: AppSpacing.kSpaceSm),
        Text('Body Medium 14px', style: AppTextStyles.kBodyMedium),
        SizedBox(height: AppSpacing.kSpaceSm),
        Text('Label Large 13px', style: AppTextStyles.kLabelLarge),
        SizedBox(height: AppSpacing.kSpaceSm),
        Text('Caption 12px', style: AppTextStyles.kCaption),
      ],
    );
  }

  // ─── Buttons Section ───
  Widget _buildButtonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CTA Orange
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.kAccentOrange,
            foregroundColor: AppColors.kBgBase,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusCta),
            ),
          ),
          child: const Text('Payer 500 FCFA (CTA)'),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        // Primary Teal
        FilledButton(
          onPressed: () {},
          child: const Text('Publier (Primary)'),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        // Secondary Violet
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.kAccentVioletSurface,
            foregroundColor: AppColors.kAccentViolet,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusButton),
            ),
            side: const BorderSide(color: AppColors.kAccentViolet),
          ),
          child: const Text('Historique (Secondary)'),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        // Outline
        OutlinedButton(
          onPressed: () {},
          child: const Text('Annuler (Outline)'),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        // Ghost
        TextButton(
          onPressed: () {},
          child: const Text('Voir tout (Ghost)'),
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        // Destructive
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.kError,
            foregroundColor: AppColors.kTextPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
            ),
          ),
          child: const Text('Supprimer (Destructive)'),
        ),
      ],
    );
  }

  // ─── Cards Section ───
  Widget _buildCardSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.kSpaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card Title',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.kSpaceSm),
            Text(
              'Contenu exemple sur fond surface #1A1A1A avec radius 16dp.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Inputs Section ───
  Widget _buildInputSection() {
    return const TextField(
      decoration: InputDecoration(
        hintText: 'Entrez votre texte...',
        labelText: 'Input Field',
      ),
    );
  }

  // ─── Spacing Section ───
  Widget _buildSpacingSection() {
    const spacings = [
      ('Xs (4px)', AppSpacing.kSpaceXs),
      ('Sm (8px)', AppSpacing.kSpaceSm),
      ('Md (16px)', AppSpacing.kSpaceMd),
      ('Lg (24px)', AppSpacing.kSpaceLg),
      ('Xl (32px)', AppSpacing.kSpaceXl),
      ('2xl (48px)', AppSpacing.kSpace2xl),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spacings
          .map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.kSpaceSm),
                child: Row(
                  children: [
                    Container(
                      width: entry.$2,
                      height: 24,
                      color: AppColors.kPrimary,
                    ),
                    const SizedBox(width: AppSpacing.kSpaceSm),
                    Text(entry.$1, style: AppTextStyles.kCaption),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ColorItem {
  final String name;
  final Color color;
  const _ColorItem(this.name, this.color);
}
