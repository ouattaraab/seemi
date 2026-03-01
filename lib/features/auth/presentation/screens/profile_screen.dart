import 'dart:math' as math;

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
          final displayName =
              fullName.isNotEmpty ? fullName.toUpperCase() : 'UTILISATEUR';

          return RefreshIndicator(
            color: AppColors.kPrimary,
            onRefresh: () => provider.loadProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Header ──────────────────────────────────────────────
                  _buildHeader(context, provider, displayName),

                  // ── Body ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Settings
                        const _SectionTitle(label: 'Paramètres du compte'),
                        const SizedBox(height: 16),
                        _MenuCard(items: [
                          _MenuItemData(
                            icon: Icons.lock_outline_rounded,
                            label: 'Mot de passe & Sécurité',
                            onTap: () {},
                          ),
                          _MenuItemData(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 40),

                        // Support & Légal
                        const _SectionTitle(label: 'Support & Légal'),
                        const SizedBox(height: 16),
                        _MenuCard(items: [
                          _MenuItemData(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Contacter le support',
                            onTap: () {},
                          ),
                          _MenuItemData(
                            icon: Icons.description_outlined,
                            label: 'Conditions générales',
                            onTap: () {},
                          ),
                          _MenuItemData(
                            icon: Icons.shield_outlined,
                            label: 'Politique de confidentialité',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 40),

                        // Logout
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: OutlinedButton.icon(
                            onPressed: () => _logout(context, provider),
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text('Se déconnecter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.kError,
                              backgroundColor:
                                  AppColors.kError.withValues(alpha: 0.05),
                              side: BorderSide(
                                color: AppColors.kError.withValues(alpha: 0.20),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.kRadiusPill),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Version
                        Center(
                          child: Text(
                            'SEEMI APP VERSION 1.0.4',
                            style: AppTextStyles.kCaption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
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

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    ProfileProvider provider,
    String displayName,
  ) {
    final user = provider.user;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.kPrimary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(48),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.kPrimary.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Column(
        children: [
          // Avatar with dashed border + edit button
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Dashed amber ring
              SizedBox(
                width: 112,
                height: 112,
                child: CustomPaint(
                  painter: const _DashedCirclePainter(
                    color: AppColors.kAccent,
                    strokeWidth: 2,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: user?.avatarUrl != null
                          ? Image.network(
                              user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, e, st) =>
                                  _avatarFallback(displayName),
                            )
                          : _avatarFallback(displayName),
                    ),
                  ),
                ),
              ),
              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.kAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.kBgBase, width: 3),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            displayName,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Email ou téléphone
          Text(
            user?.email?.isNotEmpty == true
                ? user!.email!
                : (user?.phone.isNotEmpty == true
                    ? user!.phone
                    : 'Contact non renseigné'),
            style: AppTextStyles.kBodyMedium.copyWith(
              color: AppColors.kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // KYC / Pro badge
          _buildKycBadge(user?.kycStatus ?? 'none'),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: AppColors.kPrimary,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0] : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 36,
        ),
      ),
    );
  }

  Widget _buildKycBadge(String kycStatus) {
    final (color, label) = switch (kycStatus) {
      'approved' => (AppColors.kAccent, 'Pro Créateur'),
      'pending'  => (AppColors.kWarning, 'KYC en attente'),
      'rejected' => (AppColors.kError, 'KYC rejeté'),
      _          => (AppColors.kTextSecondary, 'KYC non soumis'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, ProfileProvider provider) async {
    await provider.logout();
    if (context.mounted) context.go(RouteNames.kRouteLogin);
  }
}

// ─── _SectionTitle ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── _MenuCard ────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final List<_MenuItemData> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.kBgSurface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: AppColors.kBorder.withValues(alpha: 0.5),
                  indent: 0,
                  endIndent: 0,
                ),
              _MenuRow(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── _MenuItemData ────────────────────────────────────────────────────────────

class _MenuItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

// ─── _MenuRow ─────────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final _MenuItemData item;
  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.kBgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: AppColors.kPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: AppTextStyles.kBodyLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.kTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _DashedCirclePainter ─────────────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const dashCount = 22;
    const totalAngle = 2 * math.pi;
    const dashAngle = totalAngle / dashCount;
    const gapFraction = 0.40;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle - math.pi / 2;
      const sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
