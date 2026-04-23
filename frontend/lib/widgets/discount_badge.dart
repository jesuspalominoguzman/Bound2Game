// =============================================================================
// discount_badge.dart — Bound2Game Flutter
// Widget reutilizable: Badge de porcentaje de descuento / "GRATIS"
// Usado en DealsScreen y en el Comparador de Precios de GameDetailScreen.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/deal_model.dart';

/// Badge que muestra el porcentaje de descuento o "GRATIS".
///
/// Escala: [small] para listas compactas, normal para tarjetas grandes.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({
    super.key,
    required this.deal,
    this.small = false,
  });

  final GameDeal deal;

  /// Si true, usa fuente más pequeña (para listas compactas).
  final bool small;

  @override
  Widget build(BuildContext context) {
    final isFree = deal.isFree;
    final pct    = deal.discountPercent;

    // Color según magnitud del descuento
    final Color color;
    if (isFree) {
      color = const Color(0xFF4AF626); // verde
    } else if (pct >= 50) {
      color = const Color(0xFFFFB800); // amarillo
    } else {
      color = const Color(0xFF00E5FF); // cyan
    }

    final label = isFree ? 'GRATIS' : '-$pct%';
    final fontSize = small ? 9.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 7,
        vertical:   small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
