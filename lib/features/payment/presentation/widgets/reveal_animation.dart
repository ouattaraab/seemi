import 'dart:ui';

import 'package:flutter/material.dart';

/// Widget d'animation de révélation de contenu : blur(20) → blur(0) en 600ms.
///
/// Joue automatiquement l'animation dès sa construction.
/// [onComplete] est appelé à la fin de l'animation.
class RevealAnimation extends StatefulWidget {
  final String originalUrl;
  final VoidCallback? onComplete;

  const RevealAnimation({
    super.key,
    required this.originalUrl,
    this.onComplete,
  });

  @override
  State<RevealAnimation> createState() => _RevealAnimationState();
}

class _RevealAnimationState extends State<RevealAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _blurAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    // Anime le blur de 20 → 0 avec easeOut pour un effet cinématique
    _blurAnim = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward().whenComplete(() {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blurAnim,
      builder: (context, child) {
        return ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: _blurAnim.value,
            sigmaY: _blurAnim.value,
          ),
          child: child,
        );
      },
      child: Image.network(
        widget.originalUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 64),
        ),
      ),
    );
  }
}
