// =============================================================================
// dynamic_appbar_title.dart — Bound2Game Flutter (Android)
//
// Título animado de la AppBar con splash de marca UNA SOLA VEZ en toda
// la sesión. Usa una bandera estática para que al navegar entre pestañas
// no se repita el splash.
//
// Fase 1 (0-3s, solo si _hasShownSplash es false):
//   Muestra "Bound2Game" con 'Bound' blanco, '2' amarillo, 'Game' blanco.
// Fase 2: Muestra el nombre de la página con la(s) letra(s) central(es)
//   en amarillo (#FFB800) y el resto en blanco.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Constantes de color ────────────────────────────────────────────────────────
const _kYellow = Color(0xFFFFB800);
const _kWhite  = Colors.white;

// ─────────────────────────────────────────────────────────────────────────────
// FUNCIÓN PURA: Algoritmo de color por letras
// ─────────────────────────────────────────────────────────────────────────────

/// Genera [TextSpan] para [text] con la(s) letra(s) central(es) en amarillo.
/// Si longitud es par → las 2 letras centrales son amarillas.
/// Si longitud es impar → la letra exactamente central es amarilla.
List<TextSpan> _buildColoredSpans(String text, TextStyle baseStyle) {
  if (text.isEmpty) return [];

  final len = text.length;
  final List<int> centralIndices = len % 2 == 0
      ? [len ~/ 2 - 1, len ~/ 2]
      : [len ~/ 2];

  return List.generate(len, (i) {
    return TextSpan(
      text: text[i],
      style: baseStyle.copyWith(
        color: centralIndices.contains(i) ? _kYellow : _kWhite,
      ),
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: DynamicAppBarTitle
// ─────────────────────────────────────────────────────────────────────────────

class DynamicAppBarTitle extends StatefulWidget {
  const DynamicAppBarTitle({
    super.key,
    required this.pageName,
    this.splashDuration = const Duration(seconds: 3),
    this.fadeDuration   = const Duration(milliseconds: 400),
  });

  final String pageName;
  final Duration splashDuration;
  final Duration fadeDuration;

  // ── Bandera estática de sesión ────────────────────────────────────────────
  // Persiste durante toda la vida de la app. El splash solo ocurre una vez.
  static bool _hasShownSplash = false;

  @override
  State<DynamicAppBarTitle> createState() => _DynamicAppBarTitleState();
}

class _DynamicAppBarTitleState extends State<DynamicAppBarTitle>
    with SingleTickerProviderStateMixin {

  // true → mostrando splash de marca; false → mostrando nombre de página
  late bool _showSplash;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this, duration: widget.fadeDuration);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    if (DynamicAppBarTitle._hasShownSplash) {
      // Splash ya mostrado en esta sesión → ir directamente al nombre de página
      _showSplash = false;
      _fadeCtrl.value = 1.0;
    } else {
      // Primera vez → mostrar splash y programar la transición
      _showSplash = true;
      _fadeCtrl.value = 1.0;
      _splashTimer = Timer(widget.splashDuration, _transitionToPageName);
    }
  }

  @override
  void didUpdateWidget(DynamicAppBarTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si ya estamos en fase 2 y el nombre de pestaña cambia,
    // hacemos un breve fade para actualizar el texto.
    if (!_showSplash && oldWidget.pageName != widget.pageName) {
      _fadeCtrl.reverse().then((_) {
        if (mounted) _fadeCtrl.forward();
      });
    }
  }

  void _transitionToPageName() {
    if (!mounted) return;
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      // Marca el splash como visto para toda la sesión
      DynamicAppBarTitle._hasShownSplash = true;
      setState(() => _showSplash = false);
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Estilos ────────────────────────────────────────────────────────────────

  TextStyle get _baseStyle => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.0,
  );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: _showSplash ? _buildBrandTitle() : _buildPageTitle(),
    );
  }

  /// "Bound" blanco + "2" amarillo + "Game" blanco
  Widget _buildBrandTitle() {
    return RichText(
      text: TextSpan(
        style: _baseStyle,
        children: const [
          TextSpan(text: 'Bound', style: TextStyle(color: _kWhite)),
          TextSpan(text: '2',    style: TextStyle(color: _kYellow)),
          TextSpan(text: 'Game', style: TextStyle(color: _kWhite)),
        ],
      ),
    );
  }

  /// Nombre de página con letra(s) central(es) en amarillo.
  Widget _buildPageTitle() {
    return RichText(
      text: TextSpan(
        style: _baseStyle,
        children: _buildColoredSpans(widget.pageName, _baseStyle),
      ),
    );
  }
}
