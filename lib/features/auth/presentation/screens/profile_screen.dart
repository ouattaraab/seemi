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

/// Écran profil — onglet 4 de la bottom navigation.
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
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.user == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
          return const Center(child: CircularProgressIndicator());
        }

        final fullName = [user.firstName, user.lastName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.kSpaceXl),
              // Avatar
              _buildAvatar(user.avatarUrl),
              const SizedBox(height: AppSpacing.kSpaceMd),
              // Name
              Text(
                fullName.isEmpty ? 'Utilisateur' : fullName,
                style: AppTextStyles.kHeadlineMedium,
              ),
              const SizedBox(height: AppSpacing.kSpaceXs),
              // Phone (read-only)
              Text(
                user.phone,
                style: AppTextStyles.kBodyMedium
                    .copyWith(color: AppColors.kTextSecondary),
              ),
              const SizedBox(height: AppSpacing.kSpaceSm),
              // KYC badge
              _buildKycBadge(user.kycStatus),
              const SizedBox(height: AppSpacing.kSpaceLg),
              // Edit form or edit button
              if (_isEditing)
                _buildEditForm(provider)
              else
                _buildEditButton(),
              const SizedBox(height: AppSpacing.kSpace2xl),
              // Logout
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _logout,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kError,
                    foregroundColor: AppColors.kTextPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.kRadiusMd),
                    ),
                  ),
                  child: const Text('Déconnexion'),
                ),
              ),
              const SizedBox(height: AppSpacing.kSpaceMd),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    return GestureDetector(
      onTap: _isEditing ? _pickAvatar : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.kBgElevated,
            backgroundImage: _selectedAvatar != null
                ? FileImage(_selectedAvatar!)
                : (avatarUrl != null ? NetworkImage(avatarUrl) : null),
            onBackgroundImageError: avatarUrl != null
                ? (_, __) {} // Suppress broken image error
                : null,
            child: (_selectedAvatar == null && avatarUrl == null)
                ? const Icon(Icons.person,
                    size: 48, color: AppColors.kTextTertiary)
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    size: 16, color: AppColors.kTextPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKycBadge(String kycStatus) {
    Color color;
    String label;
    switch (kycStatus) {
      case 'approved':
        color = AppColors.kSuccess;
        label = 'KYC vérifié';
      case 'pending':
        color = AppColors.kWarning;
        label = 'KYC en attente';
      case 'rejected':
        color = AppColors.kError;
        label = 'KYC rejeté';
      default:
        color = AppColors.kTextTertiary;
        label = 'KYC non soumis';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.kSpaceSm,
        vertical: AppSpacing.kSpaceXs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.kCaption.copyWith(color: color),
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: () {
          final user = context.read<ProfileProvider>().user;
          _firstNameController.text = user?.firstName ?? '';
          _lastNameController.text = user?.lastName ?? '';
          _selectedAvatar = null;
          setState(() => _isEditing = true);
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.kPrimary,
          foregroundColor: AppColors.kTextPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
          ),
        ),
        child: const Text('Modifier le profil'),
      ),
    );
  }

  Widget _buildEditForm(ProfileProvider provider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // First name
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'Prénom',
              labelStyle: AppTextStyles.kCaption
                  .copyWith(color: AppColors.kTextTertiary),
              filled: true,
              fillColor: AppColors.kBgElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            style: AppTextStyles.kBodyLarge,
            maxLength: 100,
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
          // Last name
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Nom',
              labelStyle: AppTextStyles.kCaption
                  .copyWith(color: AppColors.kTextTertiary),
              filled: true,
              fillColor: AppColors.kBgElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            style: AppTextStyles.kBodyLarge,
            maxLength: 100,
          ),
          const SizedBox(height: AppSpacing.kSpaceMd),
          // Phone (read-only)
          TextFormField(
            initialValue: provider.user?.phone ?? '',
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              labelStyle: AppTextStyles.kCaption
                  .copyWith(color: AppColors.kTextTertiary),
              filled: true,
              fillColor: AppColors.kBgElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            style: AppTextStyles.kBodyLarge
                .copyWith(color: AppColors.kTextTertiary),
          ),
          const SizedBox(height: AppSpacing.kSpaceLg),
          // Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      _selectedAvatar = null;
                      setState(() => _isEditing = false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.kRadiusMd),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.kSpaceMd),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: provider.isLoading ? null : _submitProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kPrimary,
                      foregroundColor: AppColors.kTextPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.kRadiusMd),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.kTextPrimary,
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

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    final success = await provider.updateProfile(
      firstName: firstName.isNotEmpty ? firstName : null,
      lastName: lastName.isNotEmpty ? lastName : null,
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
