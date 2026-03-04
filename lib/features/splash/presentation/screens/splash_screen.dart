import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/services/app_status_service.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 2), _onTimerComplete);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _onTimerComplete() {
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    if (!mounted) return;

    // 1. Vérifier le statut de l'app (maintenance / mise à jour)
    try {
      final status = await AppStatusService().check();
      if (!mounted) return;

      final maintenance = status['maintenance'] as Map<String, dynamic>;
      final update = status['update'] as Map<String, dynamic>;

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

    // 2. Vérification du token d'authentification
    final storage = widget.storageService ?? const SecureStorageService();
    final hasToken = await storage.hasTokens();

    if (!mounted) return;
    if (hasToken) {
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
        backgroundColor: const Color(0xFF1A1A2E),
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
                color: Color(0xFF1A9EFF),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                notes,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Plus tard',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          if (storeUrl.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final uri = Uri.tryParse(storeUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                'Mettre à jour',
                style: TextStyle(
                  color: Color(0xFF1A9EFF),
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
            SeeMiLogo(size: 85),
            SizedBox(height: AppSpacing.kSpaceLg),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'ADLaM Display',
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: 'See',
                    style: TextStyle(color: Color(0xFF0B1120)),
                  ),
                  TextSpan(
                    text: 'Mi',
                    style: TextStyle(color: Color(0xFF1A9EFF)),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.kSpaceSm),
            Text(
              'Monétisez vos contenus',
              style: AppTextStyles.kBodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
