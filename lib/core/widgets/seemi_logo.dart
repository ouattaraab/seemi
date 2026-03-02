import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';

/// Logo SeeMi — cercle dégradé indigo avec icône œil blanc.
///
/// Utilisé dans SplashScreen, LoginScreen, RegisterScreen.
/// [size] est le diamètre du cercle (par défaut 68).
class SeeMiLogo extends StatelessWidget {
  final double size;

  const SeeMiLogo({super.key, this.size = 68});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.kPrimaryLight, // centre plus clair
            AppColors.kPrimaryDark,  // bord plus foncé
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: Icon(
        Icons.visibility_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}
