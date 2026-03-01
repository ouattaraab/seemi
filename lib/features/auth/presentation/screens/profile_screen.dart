import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          final user = provider.user;
          final fullName = [user?.firstName, user?.lastName]
              .where((s) => s != null && s.isNotEmpty)
              .join(' ');
          final displayName = fullName.isNotEmpty ? fullName.toUpperCase() : 'Utilisateur';

          return RefreshIndicator(
            color: AppColors.kPrimary,
            onRefresh: () => provider.loadProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Header profil ─────────────────────────────────────
                  _buildProfileHeader(context, provider, displayName, user?.phone ?? ''),

                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ── Paramètres du compte ──────────────────────
                        const Text('Paramètres du compte', style: AppTextStyles.kTitleLarge),
                        const SizedBox(height: 12),
                        _buildMenuSection([
                          _MenuItem(
                            icon: Icons.lock_outline_rounded,
                            label: 'Mot de passe & Sécurité',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ── Support & Légal ───────────────────────────
                        const Text('Support & Légal', style: AppTextStyles.kTitleLarge),
                        const SizedBox(height: 12),
                        _buildMenuSection([
                          _MenuItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Contacter le support',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.description_outlined,
                            label: 'Conditions générales',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.shield_outlined,
                            label: 'Politique de confidentialité',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 32),

                        // ── Déconnexion ───────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: AppSpacing.kButtonHeight,
                          child: OutlinedButton.icon(
                            onPressed: () => _logout(context, provider),
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text('Se déconnecter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.kError,
                              side: BorderSide(
                                color: AppColors.kError.withValues(alpha: 0.3),
                              ),
                              backgroundColor: AppColors.kError.withValues(alpha: 0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Version
                        Center(
                          child: Text(
                            'VERSION SEEMI APP 1.0.0',
                            style: AppTextStyles.kCaption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    ProfileProvider provider,
    String displayName,
    String phone,
  ) {
    final user = provider.user;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.kPrimary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)),
        border: Border(
          bottom: BorderSide(color: AppColors.kPrimary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.kAccent,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: user?.avatarUrl != null
                      ? Image.network(
                          user!.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, st) => _defaultAvatar(displayName),
                        )
                      : _defaultAvatar(displayName),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.kAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.kBgBase, width: 3),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: AppTextStyles.kHeadlineMedium.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            phone.isNotEmpty ? phone : 'Téléphone non renseigné',
            style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
          ),
          const SizedBox(height: 12),
          // Badge KYC / Pro
          _buildKycBadge(user?.kycStatus ?? 'none'),
        ],
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      color: AppColors.kPrimary,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : 'U',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 36),
        ),
      ),
    );
  }

  Widget _buildKycBadge(String kycStatus) {
    final (color, label) = switch (kycStatus) {
      'approved' => (AppColors.kAccent, 'Créateur Vérifié'),
      'pending'  => (AppColors.kWarning, 'KYC en attente'),
      'rejected' => (AppColors.kError, 'KYC rejeté'),
      _          => (AppColors.kTextSecondary, 'KYC non soumis'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.kDivider),
              items[i].buildRow(context),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, ProfileProvider provider) async {
    await provider.logout();
    if (context.mounted) context.go(RouteNames.kRouteLogin);
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap});

  Widget buildRow(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.kBgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.kPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.kBodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.kTextTertiary),
          ],
        ),
      ),
    );
  }
}
