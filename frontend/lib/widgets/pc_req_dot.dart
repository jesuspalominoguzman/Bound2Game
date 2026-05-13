// Este pequeño componente es el "semáforo" de compatibilidad. 
// Es un puntito con brillo (glow) que nos dice rápido si el PC puede con el juego.

import 'package:flutter/material.dart';
import '../models/game_model.dart';

class PcReqDot extends StatelessWidget {
  const PcReqDot({super.key, required this.pcReq});

  final PcReq pcReq;

  @override
  Widget build(BuildContext context) {
    // Sacamos el color de la configuración del modelo (verde, amarillo o rojo).
    final color = pcReq.config.color;
    
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // Le metemos un poquito de sombra con color para que parezca un LED encendido.
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}
