// lib/widgets/connection_status_badge.dart
import 'package:flutter/material.dart';
import '../models/device_status_model.dart';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectionStatusBadge extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, dotColor, textColor;
    switch (status) {
      case ConnectionStatus.connected:
        bg        = const Color(0xFFF0FDF4);
        dotColor  = const Color(0xFF22C55E);
        textColor = const Color(0xFF16A34A);
        break;
      case ConnectionStatus.connecting:
      case ConnectionStatus.scanning:
        bg        = const Color(0xFFFFFBEB);
        dotColor  = AppColors.alertOrange;
        textColor = const Color(0xFFD97706);
        break;
      case ConnectionStatus.disconnected:
        bg        = const Color(0xFFFFF1F2);
        dotColor  = AppColors.dangerRed;
        textColor = AppColors.dangerRed;
        break;
    }

    final label = {
      ConnectionStatus.connected:    'Connected',
      ConnectionStatus.connecting:   'Connecting',
      ConnectionStatus.scanning:     'Scanning',
      ConnectionStatus.disconnected: 'Disconnected',
    }[status]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: dotColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
