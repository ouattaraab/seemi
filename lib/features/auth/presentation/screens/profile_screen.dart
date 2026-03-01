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
        builder: (context, provider, child) {
          final user = provider.user;
          final fullName = [user?.firstName, user?.lastName]
              .where((s) => s != null && s.isNotEmpty)
              .join(' ');
          final displayName =
              fullName.isNotEmpty ? _toTitleCase(fullName) : 'Utilisateur';

          return RefreshIndicator(
            color: AppColors.kPrimary,
            onRefresh: () => provider.loadProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────────
                  _buildHeader(provider, displayName),

                  // ── Body ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Paramètres du compte ──────────────────────
                        const _SectionLabel(label: 'PARAMÈTRES DU COMPTE'),
                        const SizedBox(height: 12),
                        _MenuCard(items: [
                          _MenuItemData(
                            icon: Icons.lock_outline_rounded,
                            iconColor: AppColors.kPrimary,
                            iconBg: AppColors.kPrimary.withValues(alpha: 0.08),
                            label: 'Mot de passe & Sécurité',
                            onTap: () {},
                          ),
                          _MenuItemData(
                            icon: Icons.notifications_outlined,
                            iconColor: AppColors.kAccentDark,
                            iconBg: AppColors.kAccent.withValues(alpha: 0.10),
                            label: 'Notifications',
                            onTap: () {},
                          ),
                        ]),

                        const SizedBox(height: 32),

                        // ── Support & Légal ───────────────────────────
                        const _SectionLabel(label: 'SUPPORT & LÉGAL'),
                        const SizedBox(height: 12),
                        _MenuCard(items: [
                          _MenuItemData(
                            icon: Icons.chat_bubble_outline_rounded,
                            iconColor: AppColors.kSuccess,
                            iconBg:
                                AppColors.kSuccess.withValues(alpha: 0.08),
                            label: 'Contacter le support',
                            onTap: () {},
                          ),
                          _MenuItemData(
                            icon: Icons.description_outlined,
                            iconColor: AppColors.kTextSecondary,
                            iconBg: AppColors.kBgElevated,
                            label: 'Conditions générales',
                            onTap: () {},
                          ),
                          _MenuItemData(
                            icon: Icons.shield_outlined,
                            iconColor: AppColors.kTextSecondary,
                            iconBg: AppColors.kBgElevated,
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
                              backgroundColor:
                                  AppColors.kError.withValues(alpha: 0.04),
                              side: BorderSide(
                                color: AppColors.kError.withValues(alpha: 0.22),
                              ),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Version ───────────────────────────────────
                        Center(
                          child: Text(
                            'SEEMI APP · VERSION 1.0.4',
                            style: AppTextStyles.kCaption.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.5,
                              fontSize: 10,
                              color: AppColors.kTextTertiary,
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

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ProfileProvider provider, String displayName) {
    final user = provider.user;
    final contact = user?.email?.isNotEmpty == true
        ? user!.email!
        : (user?.phone.isNotEmpty == true
            ? user!.phone
            : 'Contact non renseigné');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(40),
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.kBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.kTextPrimary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Avatar ──────────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Anneau en tirets amber
              SizedBox(
                width: 108,
                height: 108,
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
              // Bouton éditer
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.kAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.kBgSurface, width: 3),
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

          // ── Nom ─────────────────────────────────────────────────────
          Text(
            displayName,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.kTextPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // ── Contact ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                contact.contains('@')
                    ? Icons.alternate_email_rounded
                    : Icons.phone_outlined,
                size: 13,
                color: AppColors.kTextSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                contact,
                style: AppTextStyles.kBodyMedium.copyWith(
                  color: AppColors.kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Badge KYC ───────────────────────────────────────────────
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
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 36,
        ),
      ),
    );
  }

  Widget _buildKycBadge(String kycStatus) {
    final (color, label, icon) = switch (kycStatus) {
      'approved' => (AppColors.kAccent, 'Pro Créateur', Icons.verified_rounded),
      'pending'  => (AppColors.kWarning, 'KYC en attente', Icons.schedule_rounded),
      'rejected' => (AppColors.kError, 'KYC rejeté', Icons.cancel_rounded),
      _          => (AppColors.kTextSecondary, 'KYC non soumis', Icons.info_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
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

  static String _toTitleCase(String s) {
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
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

// ─── _MenuItemData ────────────────────────────────────────────────────────────

class _MenuItemData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });
}

// ─── _MenuCard ────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final List<_MenuItemData> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kTextPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: AppColors.kBorder.withValues(alpha: 0.6),
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

// ─── _MenuRow ─────────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final _MenuItemData item;
  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.kBodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.kTextTertiary,
              ),
            ],
          ),
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
