import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/profile_provider.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/withdrawal_bottom_sheet.dart';

/// Onglet Profil — affiche le portefeuille (Gains) puis le profil utilisateur.
///
/// Remplace les deux anciens onglets "Gains" et "Profil".
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  File? _selectedAvatar;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().loadProfile();
      // Portefeuille
      final wallet = context.read<WalletProvider>();
      wallet.loadBalance();
      wallet.loadWithdrawals();
      context.read<PayoutMethodProvider>().loadExistingPayoutMethod();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.user == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimary));
        }

        if (provider.error != null && provider.user == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.kError, size: 48),
                const SizedBox(height: AppSpacing.kSpaceMd),
                Text(
                  provider.error!,
                  style: AppTextStyles.kBodyMedium
                      .copyWith(color: AppColors.kError),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.kSpaceMd),
                FilledButton(
                  onPressed: () => provider.loadProfile(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final user = provider.user;
        if (user == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimary));
        }

        final fullName = [user.firstName, user.lastName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');

        return RefreshIndicator(
          color: AppColors.kPrimary,
          onRefresh: () async {
            await Future.wait([
              provider.loadProfile(),
              context.read<WalletProvider>().loadBalance(),
              context.read<WalletProvider>().loadWithdrawals(),
              context.read<PayoutMethodProvider>().loadExistingPayoutMethod(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.kSpaceMd),

                // ─── Section Gains ────────────────────────────────────────
                _buildWalletSection(),

                const SizedBox(height: AppSpacing.kSpaceLg),
                _buildDividerWithLabel('Mon Profil'),
                const SizedBox(height: AppSpacing.kSpaceLg),

                // ─── Avatar ───────────────────────────────────────────────
                _buildAvatar(user.avatarUrl),
                const SizedBox(height: AppSpacing.kSpaceMd),

                // Nom
                Text(
                  fullName.isEmpty ? 'Utilisateur' : fullName,
                  style: AppTextStyles.kHeadlineMedium,
                ),
                const SizedBox(height: AppSpacing.kSpaceXs),

                // Téléphone
                Text(
                  user.phone,
                  style: AppTextStyles.kBodyMedium
                      .copyWith(color: AppColors.kTextSecondary),
                ),
                const SizedBox(height: AppSpacing.kSpaceSm),

                // Badge KYC
                _buildKycBadge(user.kycStatus),
                const SizedBox(height: AppSpacing.kSpaceLg),

                // Formulaire ou bouton édition
                if (_isEditing) _buildEditForm(provider) else _buildEditButton(),

                const SizedBox(height: AppSpacing.kSpaceLg),

                // Bouton déconnexion
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.kButtonHeight,
                  child: FilledButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 22),
                    label: const Text('Déconnexion'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kError,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.kSpaceLg),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Section portefeuille ─────────────────────────────────────────────────

  Widget _buildWalletSection() {
    return Consumer2<WalletProvider, PayoutMethodProvider>(
      builder: (context, walletProvider, payoutProvider, _) {
        final hasPayoutMethod =
            payoutProvider.existingPayoutMethod?.isActive ?? false;
        final canWithdraw = walletProvider.balance > 0 &&
            hasPayoutMethod &&
            !walletProvider.isWithdrawing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte solde
            WalletCard(
              balanceCentimes: walletProvider.balance,
              isLoading: walletProvider.isLoading,
            ),

            if (walletProvider.error != null) ...[
              const SizedBox(height: 8),
              Text(
                walletProvider.error!,
                style: const TextStyle(
                    color: AppColors.kError, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 12),

            // Total gains
            Center(
              child: Text(
                '${WalletCard.formatAmount(walletProvider.totalCredits ~/ 100)} gagnés au total',
                key: const Key('total-credits-text'),
                style: AppTextStyles.kBodyMedium
                    .copyWith(color: AppColors.kTextSecondary),
              ),
            ),

            const SizedBox(height: AppSpacing.kSpaceMd),

            // Bouton Retirer
            SizedBox(
              width: double.infinity,
              height: AppSpacing.kButtonHeight,
              child: ElevatedButton.icon(
                key: const Key('btn-withdraw'),
                onPressed: canWithdraw
                    ? () {
                        walletProvider.clearWithdrawalError();
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.kBgElevated,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppSpacing.kRadiusXl),
                            ),
                          ),
                          builder: (_) => const WithdrawalBottomSheet(),
                        );
                      }
                    : null,
                icon: const Icon(Icons.account_balance_wallet_rounded,
                    size: 22),
                label: const Text('Retirer mes gains'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.kBgElevated,
                  disabledForegroundColor: AppColors.kTextTertiary,
                ),
              ),
            ),

            if (!hasPayoutMethod && !walletProvider.isLoading) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Configurez un moyen de reversement pour retirer',
                  style: AppTextStyles.kCaption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ─── Divider avec label ───────────────────────────────────────────────────

  Widget _buildDividerWithLabel(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.kDivider)),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.kSpaceMd),
          child: Text(
            label,
            style: AppTextStyles.kCaption.copyWith(
              color: AppColors.kTextTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.kDivider)),
      ],
    );
  }

  // ─── Avatar ───────────────────────────────────────────────────────────────

  Widget _buildAvatar(String? avatarUrl) {
    return GestureDetector(
      onTap: _isEditing ? _pickAvatar : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.kBgElevated,
            backgroundImage: _selectedAvatar != null
                ? FileImage(_selectedAvatar!)
                : (avatarUrl != null
                    ? NetworkImage(avatarUrl) as ImageProvider
                    : null),
            onBackgroundImageError:
                avatarUrl != null ? (_, __) {} : null,
            child: (_selectedAvatar == null && avatarUrl == null)
                ? const Icon(Icons.person_rounded,
                    size: 52, color: AppColors.kTextTertiary)
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Badge KYC ────────────────────────────────────────────────────────────

  Widget _buildKycBadge(String kycStatus) {
    final (color, label) = switch (kycStatus) {
      'approved' => (AppColors.kSuccess, 'KYC vérifié'),
      'pending' => (AppColors.kWarning, 'KYC en attente'),
      'rejected' => (AppColors.kError, 'KYC rejeté'),
      _ => (AppColors.kTextTertiary, 'KYC non soumis'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.kSpaceMd,
        vertical: AppSpacing.kSpaceXs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusButton),
      ),
      child: Text(
        label,
        style: AppTextStyles.kLabelLarge.copyWith(color: color),
      ),
    );
  }

  // ─── Bouton éditer ────────────────────────────────────────────────────────

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.kButtonHeight,
      child: OutlinedButton.icon(
        onPressed: () {
          final user = context.read<ProfileProvider>().user;
          _firstNameController.text = user?.firstName ?? '';
          _lastNameController.text = user?.lastName ?? '';
          _selectedAvatar = null;
          setState(() => _isEditing = true);
        },
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text('Modifier le profil'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kTextPrimary,
          side: const BorderSide(color: AppColors.kOutline, width: 1.5),
        ),
      ),
    );
  }

  // ─── Formulaire d'édition ─────────────────────────────────────────────────

  Widget _buildEditForm(ProfileProvider provider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Prénom',
              prefixIcon: Icon(Icons.person_outline, size: 22),
            ),
            style: AppTextStyles.kBodyLarge,
            maxLength: 100,
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(Icons.person_outline, size: 22),
            ),
            style: AppTextStyles.kBodyLarge,
            maxLength: 100,
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
          TextFormField(
            initialValue: provider.user?.phone ?? '',
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone_outlined, size: 22),
            ),
            style: AppTextStyles.kBodyLarge
                .copyWith(color: AppColors.kTextTertiary),
          ),
          const SizedBox(height: AppSpacing.kSpaceLg),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSpacing.kButtonHeight,
                  child: OutlinedButton(
                    onPressed: () {
                      _selectedAvatar = null;
                      setState(() => _isEditing = false);
                    },
                    child: const Text('Annuler'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.kSpaceMd),
              Expanded(
                child: SizedBox(
                  height: AppSpacing.kButtonHeight,
                  child: FilledButton(
                    onPressed:
                        provider.isLoading ? null : _submitProfile,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedAvatar = File(picked.path));
    }
  }

  Future<void> _submitProfile() async {
    final provider = context.read<ProfileProvider>();
    final success = await provider.updateProfile(
      firstName: _firstNameController.text.trim().isNotEmpty
          ? _firstNameController.text.trim()
          : null,
      lastName: _lastNameController.text.trim().isNotEmpty
          ? _lastNameController.text.trim()
          : null,
      avatar: _selectedAvatar,
    );
    if (!mounted) return;
    if (success) {
      setState(() {
        _isEditing = false;
        _selectedAvatar = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: AppColors.kSuccess,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors de la mise à jour'),
          backgroundColor: AppColors.kError,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await context.read<ProfileProvider>().logout();
    if (mounted) context.go(RouteNames.kRouteLogin);
  }
}
