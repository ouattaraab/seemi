import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
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
  final _lastNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _imagePicker = ImagePicker();

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
    if (provider.documentFile == null) {
      return;
    }
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
          appBar: AppBar(
            leading: kycProvider.currentStep > 1
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: kycProvider.previousStep,
                  )
                : null,
            title: const Text('Vérification KYC'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KycStepIndicator(currentStep: kycProvider.currentStep),
                  const SizedBox(height: AppSpacing.kSpaceXl),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildCurrentStep(kycProvider),
                    ),
                  ),
                  if (kycProvider.error != null) ...[
                    const SizedBox(height: AppSpacing.kSpaceSm),
                    Text(
                      kycProvider.error!,
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: AppColors.kError,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.kSpaceMd),
                  _buildActionButton(kycProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep(KycProvider provider) {
    switch (provider.currentStep) {
      case 1:
        return _buildStep1(provider);
      case 2:
        return _buildStep2(provider);
      case 3:
        return _buildStep3(provider);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(KycProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations personnelles',
            style: AppTextStyles.kHeadlineMedium),
        const SizedBox(height: AppSpacing.kSpaceSm),
        Text(
          'Ces informations sont nécessaires pour vérifier votre identité.',
          style: AppTextStyles.kBodyMedium
              .copyWith(color: AppColors.kTextSecondary),
        ),
        const SizedBox(height: AppSpacing.kSpaceLg),
        TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(labelText: 'Prénom'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        TextField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Nom'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        GestureDetector(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date de naissance',
                hintText: 'Sélectionnez votre date de naissance',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(KycProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pièce d'identité",
            style: AppTextStyles.kHeadlineMedium),
        const SizedBox(height: AppSpacing.kSpaceSm),
        Text(
          'Prenez une photo ou sélectionnez votre pièce d\'identité depuis la galerie.',
          style: AppTextStyles.kBodyMedium
              .copyWith(color: AppColors.kTextSecondary),
        ),
        const SizedBox(height: AppSpacing.kSpaceLg),
        if (provider.documentFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
            child: Image.file(
              provider.documentFile!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
        ] else ...[
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.kBgElevated,
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
              border: Border.all(color: AppColors.kOutline),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera_outlined,
                    size: 48, color: AppColors.kTextDisabled),
                const SizedBox(height: AppSpacing.kSpaceSm),
                Text(
                  'Aucune image sélectionnée',
                  style: AppTextStyles.kBodyMedium
                      .copyWith(color: AppColors.kTextDisabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Photo'),
              ),
            ),
            const SizedBox(width: AppSpacing.kSpaceMd),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3(KycProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Récapitulatif', style: AppTextStyles.kHeadlineMedium),
        const SizedBox(height: AppSpacing.kSpaceSm),
        Text(
          'Vérifiez vos informations avant de soumettre.',
          style: AppTextStyles.kBodyMedium
              .copyWith(color: AppColors.kTextSecondary),
        ),
        const SizedBox(height: AppSpacing.kSpaceLg),
        _buildSummaryRow('Prénom', provider.firstName),
        _buildSummaryRow('Nom', provider.lastName),
        _buildSummaryRow(
          'Date de naissance',
          provider.dateOfBirth != null
              ? '${provider.dateOfBirth!.day.toString().padLeft(2, '0')}/${provider.dateOfBirth!.month.toString().padLeft(2, '0')}/${provider.dateOfBirth!.year}'
              : '',
        ),
        const SizedBox(height: AppSpacing.kSpaceMd),
        if (provider.documentFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
            child: Image.file(
              provider.documentFile!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        if (provider.isLoading) ...[
          const SizedBox(height: AppSpacing.kSpaceMd),
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.kSpaceSm),
          Text(
            'Envoi en cours...',
            style: AppTextStyles.kBodyMedium
                .copyWith(color: AppColors.kTextSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.kSpaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.kBodyMedium
                  .copyWith(color: AppColors.kTextSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.kBodyMedium),
          ),
        ],
      ),
    );
  }

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
      height: AppSpacing.kSpace2xl,
      child: FilledButton(
        onPressed: isEnabled ? onPressed : null,
        child: provider.isLoading
            ? const SizedBox(
                width: AppSpacing.kSpaceLg,
                height: AppSpacing.kSpaceLg,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.kTextPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
