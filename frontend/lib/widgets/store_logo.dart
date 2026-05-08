// =============================================================================
// store_logo.dart — Bound2Game Flutter
//
// Widget reutilizable para mostrar el logo de una tienda.
// Soporta tanto PNG como SVG automáticamente, detectando la extensión
// del asset. Si el archivo no existe o falla, muestra el icono de Material
// configurado en DealStoreConfig como fallback.
//
// Uso:
//   StoreLogoWidget(store: DealStore.steam, size: 24)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/deal_model.dart';

// ── Mapa central de logos ─────────────────────────────────────────────────────
// Fuente única de verdad para las rutas de los assets de logo.
// Admite .svg y .png indistintamente.
// Para añadir un logo nuevo: basta con poner el archivo en assets/images/
// y añadir aquí la entrada correspondiente.

const _kStoreLogos = <DealStore, String>{
  DealStore.steam:         'assets/images/steam_logo.png',
  DealStore.epic:          'assets/images/epic_logo.svg',
  DealStore.psStore:       'assets/images/ps_logo.png',
  DealStore.xbox:          'assets/images/xbox_logo.png',
  DealStore.nintendo:      'assets/images/nintendo_logo.svg',
  DealStore.instantGaming: 'assets/images/instant_logo.png',
};

// Tiendas con logos monocromáticos (negros) que necesitan invertirse a blanco
// para ser visibles y elegantes en el tema oscuro de la aplicación.
const _kMonochromeStores = {
  DealStore.psStore,
  DealStore.xbox,
  DealStore.nintendo,
  // Si en el futuro consigues un logo a color para estas tiendas,
  // simplemente elimínalas de este Set.
};

/// Devuelve la ruta del asset de logo para [store], o `null` si no existe.
String? storeLogoPath(DealStore store) => _kStoreLogos[store];

// =============================================================================
// StoreLogoWidget
// =============================================================================

class StoreLogoWidget extends StatelessWidget {
  const StoreLogoWidget({
    super.key,
    required this.store,
    this.size = 24,
    this.color,
  });

  /// Tienda cuyo logo se va a mostrar.
  final DealStore store;

  /// Tamaño (ancho y alto) del logo en píxeles lógicos.
  final double size;

  /// Color override manual. Si es null, el widget decidirá si debe
  /// tintar el logo automáticamente a blanco basado en `_kMonochromeStores`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final path = storeLogoPath(store);
    final cfg  = store.config;

    // Sin asset registrado → icono de Material como fallback
    if (path == null) {
      return Icon(cfg.icon, color: cfg.color, size: size);
    }

    // Determinamos el color final del logo de forma inteligente
    final bool needsWhiteTint = _kMonochromeStores.contains(store);
    final Color? finalColor = color ?? (needsWhiteTint ? Colors.white : null);

    final isSvg = path.toLowerCase().endsWith('.svg');

    if (isSvg) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: finalColor != null
            ? ColorFilter.mode(finalColor, BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) =>
            Icon(cfg.icon, color: cfg.color, size: size),
      );
    }

    // PNG / otros formatos raster
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: finalColor,
      colorBlendMode: finalColor != null ? BlendMode.srcIn : null,
      errorBuilder: (_, _, _) =>
          Icon(cfg.icon, color: cfg.color, size: size),
    );
  }
}
