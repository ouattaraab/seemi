import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
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

    final storage = widget.storageService ?? const SecureStorageService();
    final hasToken = await storage.hasTokens();

    if (!mounted) return;
    if (hasToken) {
      context.go(RouteNames.kRouteHome);
    } else {
      context.go(RouteNames.kRouteOnboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SeeMiLogo(size: 80),
            SizedBox(height: AppSpacing.kSpaceLg),
            Text(
              'SeeMi',
              style: AppTextStyles.kDisplayLarge,
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
