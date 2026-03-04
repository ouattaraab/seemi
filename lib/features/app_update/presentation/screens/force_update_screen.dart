import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/core/widgets/seemi_logo.dart';

/// Écran de mise à jour obligatoire (force = true) ou dialog optionnel (force = false).
///
/// Quand `force = true` : écran plein bloquant (PopScope canPop: false).
/// Quand `force = false` : affiché comme dialog dismissible depuis SplashScreen.
class ForceUpdateScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ForceUpdateScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isForce = data['force'] == true;
    final latestVersion = data['latest_version'] as String? ?? '';
    final notes = data['notes'] as String? ?? '';
    final storeUrl = data['store_url'] as String? ?? '';

    return PopScope(
      canPop: !isForce,
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
                    Icons.system_update_outlined,
                    size: 72,
                    color: Color(0xFF1A9EFF),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isForce
                        ? 'Mise à jour requise'
                        : 'Nouvelle version disponible',
                    style: AppTextStyles.kHeadlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version $latestVersion',
                    style: AppTextStyles.kCaption.copyWith(
                      color: const Color(0xFF1A9EFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha(26),
                        ),
                      ),
                      child: Text(
                        notes,
                        style: AppTextStyles.kCaption.copyWith(
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: storeUrl.isNotEmpty
                          ? () => _openStore(storeUrl)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A9EFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Mettre à jour',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (!isForce) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Plus tard',
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: Colors.white54,
                        ),
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

  Future<void> _openStore(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
