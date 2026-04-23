// =============================================================================
// pc_req_dot.dart — Bound2Game Flutter
// Fuente: PcReqDot() en Dashboard.tsx
// =============================================================================

import 'package:flutter/material.dart';
import '../models/game_model.dart';

/// Punto de color con glow que indica la compatibilidad del PC con el juego.
/// Corresponde al componente `PcReqDot` de Dashboard.tsx.
class PcReqDot extends StatelessWidget {
  const PcReqDot({super.key, required this.pcReq});

  final PcReq pcReq;

  @override
  Widget build(BuildContext context) {
    final color = pcReq.config.color;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
      ),
    );
  }
}
