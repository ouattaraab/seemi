import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';
import 'package:ppv_app/features/content/presentation/screens/sharing_screen.dart';

/// Écran de définition du prix et acceptation des CGU avant publication.
class PricingScreen extends StatefulWidget {
  final int contentId;
  final String contentType;

  const PricingScreen({
    super.key,
    required this.contentId,
    required this.contentType,
  });

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  static const List<int> _suggestedAmounts = [100, 200, 500, 1000];

  int? _selectedPriceFcfa;
  bool _tosAccepted = false;
  bool _published = false;
  final TextEditingController _customPriceController = TextEditingController();

  @override
  void dispose() {
    _customPriceController.dispose();
    super.dispose();
  }

  bool _canPublish(ContentProvider provider) =>
      _selectedPriceFcfa != null &&
      _selectedPriceFcfa! >= 100 &&
      _tosAccepted &&
      !provider.isPublishing;

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _selectSuggestedAmount(int amount) {
    setState(() {
      _selectedPriceFcfa = amount;
      _customPriceController.clear();
    });
  }

  void _onCustomPriceChanged(String value) {
    final parsed = int.tryParse(value);
    setState(() {
      _selectedPriceFcfa = (parsed != null && parsed >= 100) ? parsed : null;
    });
  }

  Future<void> _publish() async {
    if (_selectedPriceFcfa == null || !_tosAccepted) return;

    final provider = context.read<ContentProvider>();
    if (provider.isPublishing) return;

    final success = await provider.publishContent(
      widget.contentId,
      _selectedPriceFcfa!,
    );

    if (!mounted) return;

    if (success) {
      final shareUrl = provider.lastPublishedContent?.shareUrl;
      if (shareUrl != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharingScreen(shareUrl: shareUrl),
          ),
        );
      } else {
        setState(() => _published = true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors de la publication.'),
          backgroundColor: AppColors.kError,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: AppColors.kTextPrimary,
            onPressed: _publish,
          ),
        ),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        title: Text('Définir le prix', style: AppTextStyles.kHeadlineMedium),
        backgroundColor: AppColors.kBgBase,
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          if (_published) return _buildSuccessView();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
              child: _buildForm(provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(ContentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choisissez un montant', style: AppTextStyles.kTitleLarge),
        const SizedBox(height: AppSpacing.kSpaceMd),
        _buildSuggestedAmounts(),
        const SizedBox(height: AppSpacing.kSpaceLg),
        const Divider(),
        const SizedBox(height: AppSpacing.kSpaceLg),
        Text('Ou saisissez un montant', style: AppTextStyles.kTitleLarge),
        const SizedBox(height: AppSpacing.kSpaceSm),
        TextFormField(
          controller: _customPriceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Minimum 100 FCFA',
            suffixText: 'FCFA',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
            ),
          ),
          onChanged: _onCustomPriceChanged,
        ),
        const SizedBox(height: AppSpacing.kSpaceLg),
        const Divider(),
        CheckboxListTile(
          value: _tosAccepted,
          onChanged: (v) => setState(() => _tosAccepted = v ?? false),
          activeColor: AppColors.kPrimary,
          contentPadding: EdgeInsets.zero,
          title: RichText(
            text: TextSpan(
              style: AppTextStyles.kBodyMedium,
              children: [
                const TextSpan(text: "J'accepte les "),
                TextSpan(
                  text: 'CGU',
                  style: AppTextStyles.kBodyMedium.copyWith(
                    color: AppColors.kPrimary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' et la '),
                TextSpan(
                  text: 'politique de confidentialité',
                  style: AppTextStyles.kBodyMedium.copyWith(
                    color: AppColors.kPrimary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.kSpaceLg),
        if (provider.isPublishing) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.kSpaceMd),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _canPublish(provider) ? _publish : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              disabledBackgroundColor: AppColors.kOutline,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
              ),
            ),
            child: provider.isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publier'),
          ),
        ),
        if (_selectedPriceFcfa != null) ...[
          const SizedBox(height: AppSpacing.kSpaceSm),
          Center(
            child: Text(
              'Prix sélectionné : $_selectedPriceFcfa FCFA',
              style: AppTextStyles.kCaption.copyWith(
                color: AppColors.kTextSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestedAmounts() {
    return Wrap(
      spacing: AppSpacing.kSpaceSm,
      runSpacing: AppSpacing.kSpaceSm,
      children: _suggestedAmounts.map((amount) {
        final isSelected = _selectedPriceFcfa == amount &&
            _customPriceController.text.isEmpty;
        return isSelected
            ? FilledButton(
                onPressed: () => _selectSuggestedAmount(amount),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                  ),
                ),
                child: Text('$amount FCFA'),
              )
            : OutlinedButton(
                onPressed: () => _selectSuggestedAmount(amount),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTextSecondary,
                  side: BorderSide(color: AppColors.kTextSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                  ),
                ),
                child: Text('$amount FCFA'),
              );
      }).toList(),
    );
  }

  Widget _buildSuccessView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: AppSpacing.kIconSizeHero,
                color: AppColors.kSuccess,
              ),
              const SizedBox(height: AppSpacing.kSpaceLg),
              Text(
                'Contenu publié avec succès !',
                style: AppTextStyles.kTitleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.kSpaceSm),
              Text(
                'Prix : $_selectedPriceFcfa FCFA',
                style: AppTextStyles.kBodyMedium.copyWith(
                  color: AppColors.kTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.kSpaceXl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                    ),
                  ),
                  child: const Text("Retour à l'accueil"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
