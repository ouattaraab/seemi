import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/services/app_install_service.dart';
import 'package:ppv_app/core/services/app_status_service.dart';
import 'package:ppv_app/core/services/feature_flag_service.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/core/widgets/seemi_logo.dart';

/// Écran splash PPV — logo centré, redirige après 2 secondes.
///
/// Si token existe → home, sinon → onboarding.
/// Pour faciliter le dev, redirige vers home par défaut.
class SplashScreen extends StatefulWidget {
  final SecureStorageService? storageService;

  const SplashScreen({super.key, this.storageService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _navigationTimer;
  late final AnimationController _ctrl;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 2), _onTimerComplete);

    // Durée totale de l'animation : 700ms
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    ));
    _textFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.80, curve: Curves.easeOut),
    );
    _taglineFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onTimerComplete() {
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    if (!mounted) return;

    // Si un deep link a déjà redirigé GoRouter vers une autre route que le splash,
    // ne pas écraser cette navigation (ex: seemi:///reset-password?token=...).
    final currentLocation = GoRouterState.of(context).matchedLocation;
    if (currentLocation != RouteNames.kRouteSplash) return;

    // 1. Suivi premier lancement (fire-and-forget, silencieux)
    unawaited(AppInstallService().trackIfFirstLaunch());

    // 2. Vérifier le statut de l'app (maintenance / mise à jour)
    try {
      final status = await AppStatusService().check();
      if (!mounted) return;

      final maintenance = status['maintenance'] as Map<String, dynamic>;
      final update = status['update'] as Map<String, dynamic>;
      final features = status['features'] as Map<String, dynamic>? ?? {};
      FeatureFlagService.instance.init(features);

      if (maintenance['enabled'] == true) {
        context.go(RouteNames.kRouteMaintenance, extra: maintenance);
        return;
      }

      if (update['needs_update'] == true && update['force'] == true) {
        context.go(RouteNames.kRouteForceUpdate, extra: update);
        return;
      }

      if (update['needs_update'] == true && update['force'] != true) {
        await _showOptionalUpdateDialog(update);
        if (!mounted) return;
      }
    } catch (_) {
      // Pas de réseau ou erreur → continuer normalement
    }

    // 3. Vérification du token d'authentification
    final storage = widget.storageService ?? const SecureStorageService();
    final hasToken = await storage.hasTokens();

    if (!mounted) return;
    if (hasToken) {
      // Enregistre / rafraîchit le token FCM en arrière-plan (fire-and-forget).
      // Garantit que les créateurs déjà connectés reçoivent les push notifications
      // sans avoir à se reconnecter explicitement.
      context.read<AuthProvider>().refreshFcmToken().ignore();
      context.go(RouteNames.kRouteHome);
    } else {
      context.go(RouteNames.kRouteOnboarding);
    }
  }

  Future<void> _showOptionalUpdateDialog(Map<String, dynamic> update) async {
    final latestVersion = update['latest_version'] as String? ?? '';
    final notes = update['notes'] as String? ?? '';
    final storeUrl = update['store_url'] as String? ?? '';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nouvelle version disponible',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version $latestVersion',
              style: const TextStyle(
                color: AppColors.kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Plus tard',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.54)),
            ),
          ),
          if (storeUrl.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                // HIGH-03 — Valider le schème et l'hôte avant de lancer l'URL
                // pour éviter l'exploitation via un store_url malveillant.
                final uri = Uri.tryParse(storeUrl);
                // HIGH-03 — Exact match (pas endsWith) pour éviter evil-play.google.com
                const _allowedHosts = {
                  'play.google.com',
                  'www.play.google.com',
                  'apps.apple.com',
                  'www.apps.apple.com',
                };
                if (uri != null &&
                    uri.scheme == 'https' &&
                    _allowedHosts.contains(uri.host) &&
                    await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                'Mettre à jour',
                style: TextStyle(
                  color: AppColors.kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo pill SeeMi
            SlideTransition(
              position: _logoSlide,
              child: FadeTransition(
                opacity: _logoFade,
                child: SeeMiLogo(size: 220),
              ),
            ),
            SizedBox(height: AppSpacing.kSpaceMd),
            // Tagline : fade en dernier
            FadeTransition(
              opacity: _taglineFade,
              child: Text(
                'Monétisez vos contenus',
                style: AppTextStyles.kBodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
