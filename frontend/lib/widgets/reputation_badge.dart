// =============================================================================
// reputation_badge.dart — Bound2Game Flutter
// Fuente: ReputationBadge() en Dashboard.tsx
// =============================================================================

import 'package:flutter/material.dart';
import '../models/game_model.dart';

/// Badge de reputación con fondo coloreado, borde y texto.
/// Corresponde al componente `ReputationBadge` de Dashboard.tsx.
class ReputationBadge extends StatelessWidget {
  const ReputationBadge({
    super.key,
    required this.reputation,
    required this.label,
  });

  final Reputation reputation;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cfg = reputation.config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: cfg.color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: cfg.color,
        ),
      ),
    );
  }
}
