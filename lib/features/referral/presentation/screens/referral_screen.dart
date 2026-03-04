import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/auth/presentation/profile_provider.dart';
import 'package:ppv_app/features/referral/domain/referral_stats.dart';
import 'package:ppv_app/features/referral/presentation/referral_provider.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReferralProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        elevation: 0,
        title: const Text(
          'Parrainage',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.kTextPrimary),
      ),
      body: Consumer2<ProfileProvider, ReferralProvider>(
        builder: (context, profileProvider, referralProvider, _) {
          final user = profileProvider.user;
          final kycApproved = user?.kycStatus == 'approved';

          if (!kycApproved) {
            return _buildKycRequired();
          }

          if (referralProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimary),
            );
          }

          if (referralProvider.error != null) {
            return _buildError(referralProvider);
          }

          final stats = referralProvider.stats;
          if (stats == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            color: AppColors.kPrimary,
            onRefresh: () => referralProvider.loadStats(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Section Mon code ──────────────────────────────
                  _buildCodeSection(stats.code),
                  const SizedBox(height: 28),

                  // ── Section Statistiques ──────────────────────────
                  _buildStatsSection(stats),
                  const SizedBox(height: 28),

                  // ── Section Comment ça marche ─────────────────────
                  _buildHowItWorks(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKycRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kWarning.withValues(alpha: 0.10),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: AppColors.kWarning,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'KYC requis',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Complétez votre vérification d\'identité (KYC) pour accéder au programme de parrainage et gagner des commissions.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.kTextSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ReferralProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.kError, size: 48),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'Une erreur est survenue.',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.kTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => provider.loadStats(),
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSection(String code) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.kPrimary.withValues(alpha: 0.15),
            AppColors.kAccent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kPrimary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: AppColors.kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mon code de parrainage',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.kBgSurface,
              borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.kPrimary,
                letterSpacing: 2.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copié dans le presse-papier !'),
                        backgroundColor: AppColors.kSuccess,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kPrimary,
                    side: BorderSide(color: AppColors.kPrimary.withValues(alpha: 0.40)),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Share.share(
                      'Rejoins SeeMi avec mon code de parrainage $code et monétise tes contenus ! 🚀\nhttps://seemi.click',
                      subject: 'Rejoins SeeMi !',
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Partager'),
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ReferralStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STATISTIQUES',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.kTextTertiary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline_rounded,
                iconColor: AppColors.kPrimary,
                label: 'Filleuls actifs',
                value: '${stats.activeCount}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.kAccentDark,
                label: 'Gains totaux',
                value: '${(stats.totalEarned / 100).toStringAsFixed(0)} FCFA',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.group_add_outlined,
          iconColor: AppColors.kSuccess,
          label: 'Total filleuls inscrits',
          value: '${stats.referralsCount}',
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMMENT ÇA MARCHE',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.kTextTertiary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.kBgSurface,
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: const Column(
            children: [
              _HowItWorksStep(
                step: '1',
                title: 'Partagez votre code',
                description: 'Envoyez votre code unique à vos amis créateurs.',
                icon: Icons.share_outlined,
              ),
              SizedBox(height: 20),
              _HowItWorksStep(
                step: '2',
                title: 'Ils s\'inscrivent',
                description: 'Votre filleul utilise votre code lors de son inscription sur SeeMi.',
                icon: Icons.person_add_outlined,
              ),
              SizedBox(height: 20),
              _HowItWorksStep(
                step: '3',
                title: 'Vous gagnez une commission',
                description: 'À chaque vente de votre filleul, vous recevez automatiquement une commission sur la part plateforme.',
                icon: Icons.monetization_on_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool fullWidth;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.kTextPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final IconData icon;

  const _HowItWorksStep({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.kPrimary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.kPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: AppColors.kTextSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
