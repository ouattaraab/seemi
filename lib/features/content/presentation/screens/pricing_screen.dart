import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
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
  static const _suggested = [100, 200, 500, 1000];

  int? _selectedPriceFcfa;
  bool _tosAccepted = false;
  bool _published = false;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  bool _canPublish(ContentProvider p) =>
      _selectedPriceFcfa != null &&
      _selectedPriceFcfa! >= 100 &&
      _tosAccepted &&
      !p.isPublishing;

  // ── Actions ───────────────────────────────────────────────────────────────

  void _selectAmount(int amount) {
    setState(() {
      _selectedPriceFcfa = amount;
      _customController.clear();
    });
  }

  void _onCustomChanged(String val) {
    final n = int.tryParse(val);
    setState(() {
      _selectedPriceFcfa = (n != null && n >= 100) ? n : null;
    });
  }

  Future<void> _publish() async {
    if (_selectedPriceFcfa == null || !_tosAccepted) return;
    final provider = context.read<ContentProvider>();
    if (provider.isPublishing) return;

    final success =
        await provider.publishContent(widget.contentId, _selectedPriceFcfa!);
    if (!mounted) return;

    if (success) {
      final shareUrl = provider.lastPublishedContent?.shareUrl;
      if (shareUrl != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SharingScreen(shareUrl: shareUrl)),
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
            textColor: Colors.white,
            onPressed: _publish,
          ),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      body: Consumer<ContentProvider>(
        builder: (context, provider, child) {
          if (_published) return _buildSuccess();

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: _buildForm(provider),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kBgElevated,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.kTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Définir le prix',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Formulaire ────────────────────────────────────────────────────────────

  Widget _buildForm(ContentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Montants suggérés ──────────────────────────────────────────
        const _SectionLabel(label: 'MONTANT SUGGÉRÉ'),
        const SizedBox(height: 12),
        _buildAmountGrid(),
        const SizedBox(height: 24),

        // ── Divider centré ─────────────────────────────────────────────
        _buildDivider('Ou saisissez un montant'),
        const SizedBox(height: 16),

        // ── Champ personnalisé ─────────────────────────────────────────
        _buildCustomInput(),

        // ── Gains estimés (animé) ──────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _selectedPriceFcfa != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _buildEarningsCard(),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),

        // ── CGU ────────────────────────────────────────────────────────
        _buildTosRow(),
        const SizedBox(height: 28),

        // ── Barre de progression ───────────────────────────────────────
        if (provider.isPublishing) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              backgroundColor: AppColors.kBorder,
              color: AppColors.kAccent,
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Bouton publier ─────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: AppSpacing.kButtonHeight,
          child: FilledButton.icon(
            onPressed: _canPublish(provider) ? _publish : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              disabledBackgroundColor: AppColors.kBgElevated,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: provider.isPublishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.rocket_launch_rounded, size: 18),
            label: const Text('Publier maintenant'),
          ),
        ),
      ],
    );
  }

  // ── Grille de montants ────────────────────────────────────────────────────

  Widget _buildAmountGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3.0,
      children: _suggested.map((amount) {
        final isSelected =
            _selectedPriceFcfa == amount && _customController.text.isEmpty;
        return GestureDetector(
          onTap: () => _selectAmount(amount),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.kPrimary : AppColors.kBgSurface,
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
              border: Border.all(
                color:
                    isSelected ? AppColors.kPrimary : AppColors.kBorder,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.kPrimary.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$amount',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : AppColors.kTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'FCFA',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.kTextTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Divider avec texte ─────────────────────────────────────────────────────

  Widget _buildDivider(String text) {
    return Row(
      children: [
        const Expanded(
            child: Divider(color: AppColors.kBorder, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.kTextTertiary,
            ),
          ),
        ),
        const Expanded(
            child: Divider(color: AppColors.kBorder, height: 1)),
      ],
    );
  }

  // ── Champ prix libre ──────────────────────────────────────────────────────

  Widget _buildCustomInput() {
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
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: const Text(
              'FCFA',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.kAccentDark,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.kBorder),
          Expanded(
            child: TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Minimum 100',
                hintStyle: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.kTextTertiary,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onCustomChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte gains estimés ───────────────────────────────────────────────────

  Widget _buildEarningsCard() {
    final gains = (_selectedPriceFcfa! * 0.80).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.kSuccess.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(
          color: AppColors.kSuccess.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: AppColors.kSuccess,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vos gains estimés',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.kTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$gains FCFA par vente',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.kSuccess,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppSpacing.kRadiusPill),
            ),
            child: const Text(
              '80%',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.kSuccess,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ligne CGU ─────────────────────────────────────────────────────────────

  Widget _buildTosRow() {
    return GestureDetector(
      onTap: () => setState(() => _tosAccepted = !_tosAccepted),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(top: 2),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _tosAccepted ? AppColors.kPrimary : Colors.transparent,
              border: Border.all(
                color: _tosAccepted
                    ? AppColors.kPrimary
                    : AppColors.kBorder,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _tosAccepted
                ? const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.kTextSecondary,
                  height: 1.55,
                ),
                children: [
                  TextSpan(text: "J'accepte les "),
                  TextSpan(
                    text: 'CGU',
                    style: TextStyle(
                      color: AppColors.kPrimary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.kPrimary,
                    ),
                  ),
                  TextSpan(text: ' et la '),
                  TextSpan(
                    text: 'politique de confidentialité',
                    style: TextStyle(
                      color: AppColors.kPrimary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.kPrimary,
                    ),
                  ),
                  TextSpan(text: ' de Seemi.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vue succès (fallback sans shareUrl) ───────────────────────────────────

  Widget _buildSuccess() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.kSuccess.withValues(alpha: 0.08),
                ),
                child: Container(
                  margin: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.kSuccess.withValues(alpha: 0.14),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 36,
                    color: AppColors.kSuccess,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Contenu publié !',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.kTextPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Prix : $_selectedPriceFcfa FCFA',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  color: AppColors.kTextSecondary,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.kButtonHeight,
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kPrimary,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text("Retour à l'accueil"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _SectionLabel ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.kTextTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}
