import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/services/app_status_service.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/core/widgets/seemi_logo.dart';

/// Écran plein écran affiché pendant la maintenance.
///
/// Bloque la navigation arrière (WillPopScope).
/// Affiche un compte à rebours si `end_at` est fourni.
/// Quand le countdown atteint 0, re-vérifie le statut automatiquement.
class MaintenanceScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const MaintenanceScreen({super.key, required this.data});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  Timer? _countdownTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final endAtStr = widget.data['end_at'] as String?;
    if (endAtStr == null || endAtStr.isEmpty) return;

    final endAt = DateTime.tryParse(endAtStr);
    if (endAt == null) return;

    final now = DateTime.now().toUtc();
    final diff = endAt.toUtc().difference(now);
    if (diff.isNegative) {
      _checkStatus();
      return;
    }

    setState(() => _remaining = diff);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemaining = _remaining! - const Duration(seconds: 1);
      if (newRemaining.isNegative || newRemaining == Duration.zero) {
        timer.cancel();
        _checkStatus();
      } else {
        setState(() => _remaining = newRemaining);
      }
    });
  }

  Future<void> _checkStatus() async {
    try {
      final status = await AppStatusService().check();
      final maintenance = status['maintenance'] as Map<String, dynamic>;
      if (!mounted) return;

      if (maintenance['enabled'] == true) {
        // Toujours en maintenance — rester sur l'écran avec les nouvelles données
        setState(() {
          _countdownTimer?.cancel();
          _countdownTimer = null;
          _remaining = null;
        });
        // Naviguer vers maintenance avec les nouvelles données
        context.go(RouteNames.kRouteMaintenance, extra: maintenance);
      } else {
        // Maintenance terminée — reprendre le flux normal
        final storage = const SecureStorageService();
        final hasToken = await storage.hasTokens();
        if (!mounted) return;
        context.go(
          hasToken ? RouteNames.kRouteHome : RouteNames.kRouteOnboarding,
        );
      }
    } catch (_) {
      // Réseau indisponible → réessayer dans 30 secondes
      if (mounted) {
        setState(() {
          _remaining = const Duration(seconds: 30);
        });
        _startCountdown();
      }
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.data['message'] as String? ??
        'La plateforme est en maintenance. Nous serons bientôt de retour !';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SeeMiLogo(size: 64),
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 72,
                    color: Color(0xFFFF9F0A),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Maintenance en cours',
                    style: AppTextStyles.kHeadlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: AppTextStyles.kBodyMedium.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_remaining != null) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Reprise estimée dans',
                      style: AppTextStyles.kCaption.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_remaining!),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF9F0A),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
