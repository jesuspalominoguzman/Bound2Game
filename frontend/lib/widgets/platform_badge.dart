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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cfg.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        cfg.name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: cfg.color,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
  }
}
