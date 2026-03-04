import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';
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

  Future<void> _pickAndUploadAvatar(ProfileProvider provider) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    // Éviction du cache avant l'upload pour forcer le rechargement de l'URL.
    final oldAvatarUrl = provider.user?.avatarUrl;
    if (oldAvatarUrl != null) {
      await NetworkImage(oldAvatarUrl).evict();
    }

    final success = await provider.updateProfile(avatar: File(image.path));

    // Éviction également de la nouvelle URL si elle est identique (serveur qui écrase le fichier).
    final newAvatarUrl = provider.user?.avatarUrl;
    if (newAvatarUrl != null && newAvatarUrl != oldAvatarUrl) {
      await NetworkImage(newAvatarUrl).evict();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Photo de profil mise à jour.'
            : provider.error ?? 'Erreur lors de la mise à jour.'),
        backgroundColor:
            success ? AppColors.kSuccess : AppColors.kError,
      ),
    );
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
                            onTap: () => context.push(RouteNames.kRouteChangePassword),
                          ),
                          _MenuItemData(
                            icon: Icons.notifications_outlined,
                            iconColor: AppColors.kAccentDark,
                            iconBg: AppColors.kAccent.withValues(alpha: 0.10),
                            label: 'Notifications',
                            onTap: () => context.push(RouteNames.kRouteNotificationPreferences),
                          ),
                        ]),

                        const SizedBox(height: 32),

                        // ── Créateur ──────────────────────────────────
                        const _SectionLabel(label: 'CRÉATEUR'),
                        const SizedBox(height: 12),
                        _MenuCard(items: [
                          if (user?.kycStatus == 'none' || user?.kycStatus == 'rejected')
                            _MenuItemData(
                              icon: user?.kycStatus == 'rejected'
                                  ? Icons.refresh_rounded
                                  : Icons.verified_user_outlined,
                              iconColor: user?.kycStatus == 'rejected'
                                  ? AppColors.kError
                                  : AppColors.kPrimary,
                              iconBg: user?.kycStatus == 'rejected'
                                  ? AppColors.kError.withValues(alpha: 0.08)
                                  : AppColors.kPrimary.withValues(alpha: 0.08),
                              label: user?.kycStatus == 'rejected'
                                  ? 'Resoumettre ma vérification'
                                  : 'Vérifier mon compte',
                              onTap: () => context.push(RouteNames.kRouteKyc),
                            ),
                          _MenuItemData(
                            icon: Icons.card_giftcard_rounded,
                            iconColor: AppColors.kAccentDark,
                            iconBg: AppColors.kAccent.withValues(alpha: 0.10),
                            label: 'Parrainage',
                            onTap: () => context.push(RouteNames.kRouteReferral),
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
                            label: 'Contactez-nous',
                            onTap: () => _showContactSheet(context),
                          ),
                          _MenuItemData(
                            icon: Icons.description_outlined,
                            iconColor: AppColors.kTextSecondary,
                            iconBg: AppColors.kBgElevated,
                            label: 'Conditions générales',
                            onTap: () => _openWebPage(
                              context,
                              '${AppConfig.webBaseUrl}/cgu',
                            ),
                          ),
                          _MenuItemData(
                            icon: Icons.shield_outlined,
                            iconColor: AppColors.kTextSecondary,
                            iconBg: AppColors.kBgElevated,
                            label: 'Politique de confidentialité',
                            onTap: () => _openWebPage(
                              context,
                              '${AppConfig.webBaseUrl}/confidentialite',
                            ),
                          ),
                        ]),

                        const SizedBox(height: 32),

                        // ── Zone Danger ───────────────────────────────
                        const _SectionLabel(label: 'ZONE DANGER'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: AppSpacing.kButtonHeight,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDeleteAccount(context),
                            icon: const Icon(Icons.delete_forever_rounded, size: 20),
                            label: const Text('Supprimer mon compte'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.kError,
                              backgroundColor: AppColors.kError.withValues(alpha: 0.04),
                              side: BorderSide(color: AppColors.kError.withValues(alpha: 0.22)),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

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
                              // Cache-buster : force un rechargement si l'URL change
                              // même si le serveur écrase le même fichier.
                              '${user!.avatarUrl}?v=${user.avatarUrl.hashCode}',
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
                child: GestureDetector(
                  onTap: () => _pickAndUploadAvatar(provider),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.kAccent,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.kBgSurface, width: 3),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
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
      color: AppColors.kPrimaryDark,
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

  Future<void> _openWebPage(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir la page.'),
          backgroundColor: AppColors.kError,
        ),
      );
    }
  }

  void _showContactSheet(BuildContext context) {
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        bool isSending = false;
        bool sent = false;
        return StatefulBuilder(
          builder: (innerCtx, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.kBgSurface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.kRadiusXl),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
              ),
              child: sent
                  ? _buildContactSentState()
                  : Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Handle
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.kBorder,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Contactez-nous',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.kTextPrimary,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Laissez-nous un message, nous vous répondrons dès que possible.',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: AppColors.kTextSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: messageController,
                            maxLines: 5,
                            minLines: 4,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Veuillez saisir un message.';
                              }
                              if (v.trim().length < 10) {
                                return 'Le message est trop court.';
                              }
                              return null;
                            },
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: AppColors.kTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Décrivez votre problème ou question…',
                              hintStyle: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                color: AppColors.kTextTertiary,
                              ),
                              filled: true,
                              fillColor: AppColors.kBgElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.kRadiusLg),
                                borderSide:
                                    const BorderSide(color: AppColors.kBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.kRadiusLg),
                                borderSide:
                                    const BorderSide(color: AppColors.kBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.kRadiusLg),
                                borderSide: const BorderSide(
                                    color: AppColors.kPrimary, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.kRadiusLg),
                                borderSide: const BorderSide(
                                    color: AppColors.kError, width: 1.5),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.kRadiusLg),
                                borderSide: const BorderSide(
                                    color: AppColors.kError, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: AppSpacing.kButtonHeight,
                            child: ElevatedButton.icon(
                              onPressed: isSending
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setState(() => isSending = true);
                                      // Envoie via mailto — remplacer par un appel API
                                      // POST /support si un endpoint est disponible.
                                      final body = Uri.encodeComponent(
                                        messageController.text.trim(),
                                      );
                                      final uri = Uri.parse(
                                        'mailto:support@seemi.click'
                                        '?subject=Message%20support%20SeeMi'
                                        '&body=$body',
                                      );
                                      await launchUrl(uri);
                                      setState(() {
                                        isSending = false;
                                        sent = true;
                                      });
                                    },
                              icon: isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                isSending ? 'Envoi…' : 'Envoyer le message',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    ).whenComplete(() => messageController.dispose());
  }

  Widget _buildContactSentState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.kSuccess.withValues(alpha: 0.10),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.kSuccess,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Message envoyé !',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Notre équipe vous répondra dans les plus brefs délais.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: AppColors.kTextSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _logout(BuildContext context, ProfileProvider provider) async {
    await provider.logout();
    if (context.mounted) context.go(RouteNames.kRouteLogin);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildDeleteAccountDialog(ctx),
    );
    if (confirmed != true || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.deleteAccount();

    if (!context.mounted) return;
    if (success) {
      context.go(RouteNames.kRouteLogin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Impossible de supprimer le compte.'),
          backgroundColor: AppColors.kError,
        ),
      );
    }
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

// ─── _DeleteAccountDialog ─────────────────────────────────────────────────────

Widget _buildDeleteAccountDialog(BuildContext parentCtx) {
  final confirmCtrl = TextEditingController();
  return StatefulBuilder(
    builder: (ctx, setState) {
      final ready = confirmCtrl.text == 'SUPPRIMER';
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Supprimer mon compte',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800, color: AppColors.kTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette action est irréversible. Vos données seront anonymisées et votre compte désactivé.',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.kTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tapez SUPPRIMER pour confirmer :',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.kTextPrimary, fontFamily: 'Plus Jakarta Sans', letterSpacing: 1.5),
              decoration: InputDecoration(
                hintText: 'SUPPRIMER',
                hintStyle: const TextStyle(color: AppColors.kTextTertiary),
                filled: true,
                fillColor: AppColors.kBgElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: AppColors.kTextSecondary)),
          ),
          FilledButton(
            onPressed: ready ? () => Navigator.pop(ctx, true) : null,
            style: FilledButton.styleFrom(backgroundColor: AppColors.kError),
            child: const Text('Supprimer', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700)),
          ),
        ],
      );
    },
  );
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
