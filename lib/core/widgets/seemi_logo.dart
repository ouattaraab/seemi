import 'package:flutter/material.dart';

/// Logo SeeMi — cercle bleu #1A6DCC avec icône œil blanc.
///
/// Utilisé dans SplashScreen, LoginScreen, RegisterScreen.
/// [size] est le diamètre du cercle (par défaut 68).
class SeeMiLogo extends StatelessWidget {
  final double size;

  const SeeMiLogo({super.key, this.size = 68});

  /// Bleu principal du cercle logo (#1A6DCC)
  static const Color _circleBlue = Color(0xFF1A6DCC);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _circleBlue,
      ),
      child: Icon(
        Icons.visibility_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}
