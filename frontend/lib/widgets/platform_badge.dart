// =============================================================================
// platform_badge.dart — Bound2Game Flutter
// Fuente: PlatformBadge() en Dashboard.tsx
// =============================================================================

import 'package:flutter/material.dart';
import '../models/game_model.dart';

/// Badge de plataforma con el color y nombre de la misma.
/// Corresponde al componente `PlatformBadge` de Dashboard.tsx.
class PlatformBadge extends StatelessWidget {
  const PlatformBadge({super.key, required this.platform});

  final Platform platform;

  @override
  Widget build(BuildContext context) {
    final cfg = PlatformConfig.of(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        cfg.name,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: cfg.color,
        ),
      ),
    );
  }
}
