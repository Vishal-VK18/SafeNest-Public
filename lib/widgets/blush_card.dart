// lib/widgets/blush_card.dart
// Reusable glassmorphism card widget for the Blush UI design system.

import 'package:flutter/material.dart';
import '../utils/blush_theme.dart';

class BlushCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  const BlushCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BlushDecorations.glassCard(
        borderRadius: borderRadius,
        color: color,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
