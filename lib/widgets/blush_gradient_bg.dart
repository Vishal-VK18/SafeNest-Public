// lib/widgets/blush_gradient_bg.dart
// Full-screen peach→blush gradient background wrapper for the Blush UI.

import 'package:flutter/material.dart';
import '../utils/blush_theme.dart';

/// Wraps [child] in the canonical SafeNest Blush background:
/// a peach→blush linear gradient with a soft cream/white overlay on top.
class BlushGradientBg extends StatelessWidget {
  final Widget child;
  final bool withSafeArea;

  const BlushGradientBg({
    super.key,
    required this.child,
    this.withSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Stack(
      children: [
        // Base gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: BlushGradients.background,
            ),
          ),
        ),
        // Cream overlay
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: BlushGradients.fogOverlay,
            ),
          ),
        ),
        // Content
        child,
      ],
    );

    if (withSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}
