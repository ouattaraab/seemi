import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/auth/presentation/kyc_provider.dart';
import 'package:ppv_app/features/auth/presentation/widgets/kyc_step_indicator.dart';

/// Écran KYC multi-étapes — 3 étapes de vérification d'identité.
class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _dateController      = TextEditingController();
  final _imagePicker         = ImagePicker();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      context.read<KycProvider>().setDocument(File(picked.path));
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: eighteenYearsAgo,
      firstDate: DateTime(1920),
      lastDate: eighteenYearsAgo,
      helpText: 'Date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.kPrimary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      context.read<KycProvider>().setDateOfBirth(picked);
      _dateController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  void _onContinueStep1() {
    final provider = context.read<KycProvider>();
    provider.setFirstName(_firstNameController.text);
    provider.setLastName(_lastNameController.text);
    if (provider.validateStep1()) {
      provider.nextStep();
    }
  }

  void _onContinueStep2() {
    final provider = context.read<KycProvider>();
    if (provider.documentFile == null) return;
    provider.nextStep();
  }

  Future<void> _onSubmit() async {
    final provider = context.read<KycProvider>();
    final success = await provider.submitKyc();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre vérification KYC est en cours de traitement.'),
          duration: Duration(seconds: 4),
        ),
      );
      context.go(RouteNames.kRoutePayoutMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KycProvider>(
      builder: (context, kycProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.kBgBase,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                _buildHeader(context, kycProvider),

                // ── Indicateur étapes ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: KycStepIndicator(currentStep: kycProvider.currentStep),
                ),

                // ── Contenu scrollable ─────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCurrentStep(kycProvider),
                  ),
                ),

                // ── Erreur API ─────────────────────────────────────────────
                if (kycProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: _ErrorBanner(message: kycProvider.error!),
                  ),

                // ── Bouton action ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: _buildActionButton(kycProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, KycProvider provider) {
    const titles = ['Informations', "Pièce d'identité", 'Récapitulatif'];
    final title = titles[(provider.currentStep - 1).clamp(0, 2)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: provider.currentStep > 1
                ? provider.previousStep
                : () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.kBgElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.kTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextPrimary,
            ),
          ),
          const Spacer(),
          // Badge étape courante
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
            ),
            child: Text(
              'Étape ${provider.currentStep}/3',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dispatch ──────────────────────────────────────────────────────────────

  Widget _buildCurrentStep(KycProvider provider) {
    return switch (provider.currentStep) {
      1 => _buildStep1(provider),
      2 => _buildStep2(provider),
      3 => _buildStep3(provider),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Étape 1 — Informations personnelles ───────────────────────────────────

  Widget _buildStep1(KycProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations personnelles',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.kTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ces informations sont nécessaires pour vérifier votre identité.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: AppColors.kTextSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        const _FieldLabel('Prénom'),
        const SizedBox(height: 8),
        _KycPillField(
          controller: _firstNameController,
          hintText: 'Votre prénom',
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        const _FieldLabel('Nom'),
        const SizedBox(height: 8),
        _KycPillField(
          controller: _lastNameController,
          hintText: 'Votre nom de famille',
          prefixIcon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),

        const _FieldLabel('Date de naissance'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: _KycPillField(
              controller: _dateController,
              hintText: 'Sélectionnez votre date',
              prefixIcon: Icons.calendar_today_outlined,
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.kTextSecondary,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Étape 2 — Pièce d'identité ────────────────────────────────────────────

  Widget _buildStep2(KycProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pièce d'identité",
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.kTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Prenez une photo ou importez votre pièce d'identité depuis la galerie.",
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: AppColors.kTextSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        if (provider.documentFile != null) ...[
          // Document sélectionné
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            child: Image.file(
              provider.documentFile!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kTextSecondary,
                side: const BorderSide(color: AppColors.kBorder),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Changer de document'),
            ),
          ),
        ] else ...[
          // Placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.kBgSurface,
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
              border: Border.all(color: AppColors.kBorder),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    size: 28,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aucun document sélectionné',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'CNI, passeport ou permis de conduire',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.kTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sources
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kPrimary,
                    side: BorderSide(
                        color: AppColors.kPrimary.withValues(alpha: 0.40)),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Caméra'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kTextSecondary,
                    side: const BorderSide(color: AppColors.kBorder),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galerie'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Étape 3 — Récapitulatif ───────────────────────────────────────────────

  Widget _buildStep3(KycProvider provider) {
    final dob = provider.dateOfBirth;
    final dobStr = dob != null
        ? '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Récapitulatif',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.kTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Vérifiez vos informations avant de soumettre.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: AppColors.kTextSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Carte récap
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          child: Column(
            children: [
              _buildSummaryRow('Prénom', provider.firstName),
              const Divider(height: 20, color: AppColors.kBorder),
              _buildSummaryRow('Nom', provider.lastName),
              const Divider(height: 20, color: AppColors.kBorder),
              _buildSummaryRow('Date de naissance', dobStr),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (provider.documentFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
            child: Image.file(
              provider.documentFile!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        if (provider.isLoading) ...[
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
            child: const LinearProgressIndicator(
              minHeight: 4,
              color: AppColors.kPrimary,
              backgroundColor: AppColors.kBgElevated,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envoi en cours…',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: AppColors.kTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: AppColors.kTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.kTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Bouton action ─────────────────────────────────────────────────────────

  Widget _buildActionButton(KycProvider provider) {
    final isEnabled = switch (provider.currentStep) {
      1 => true,
      2 => provider.documentFile != null,
      3 => !provider.isLoading,
      _ => false,
    };

    final label = switch (provider.currentStep) {
      1 => 'Continuer',
      2 => 'Continuer',
      3 => 'Soumettre ma vérification',
      _ => '',
    };

    final onPressed = switch (provider.currentStep) {
      1 => _onContinueStep1,
      2 => _onContinueStep2,
      3 => _onSubmit,
      _ => () {},
    };

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.kButtonHeight,
      child: FilledButton(
        onPressed: isEnabled ? onPressed : null,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          backgroundColor: AppColors.kPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: provider.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

// ── _FieldLabel ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.kTextTertiary,
      ),
    );
  }
}

// ── _KycPillField ─────────────────────────────────────────────────────────────

class _KycPillField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;

  const _KycPillField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.kTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 15,
          color: AppColors.kTextTertiary,
        ),
        filled: true,
        fillColor: AppColors.kBgSurface,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(prefixIcon, color: AppColors.kTextSecondary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

// ── _ErrorBanner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.kError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kError.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.kError, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: AppColors.kError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
