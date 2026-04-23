// =============================================================================
// main.dart — Bound2Game Flutter (Android)
//
// Punto de entrada principal de la aplicación.
// Configura el tema oscuro, el título y el widget raíz.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/main_layout.dart';
import 'theme/app_theme.dart';

void main() {
  // Garantiza que los bindings de Flutter estén inicializados antes de
  // configurar la orientación y la barra de estado del sistema.
  WidgetsFlutterBinding.ensureInitialized();

  // Forza orientación vertical (portrait) — app 100% móvil.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Barra de estado transparente con íconos claros (modo oscuro).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF303030), // AppColors.sidebar
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const Bound2GameApp());
}

/// Widget raíz de la aplicación Bound2Game.
///
/// Responsabilidades:
/// - Inyectar el [ThemeData] oscuro generado por [buildAppTheme].
/// - Deshabilitar el banner de depuración.
/// - Establecer el título de la app y la pantalla inicial.
class Bound2GameApp extends StatelessWidget {
  const Bound2GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── Metadatos ────────────────────────────────────────────────────────
      title: 'Bound2Game',
      debugShowCheckedModeBanner: false,

      // ── Tema ─────────────────────────────────────────────────────────────
      // Se usa exclusivamente el tema oscuro; no se proporciona [theme]
      // (light) para evitar que el sistema operativo lo active.
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,

      // ── Pantalla inicial ──────────────────────────────────────────────────
      // TODO: Reemplazar por el router/navigator definitivo cuando se
      // implementen las pantallas (screens/).
      home: const MainLayout(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEHOLDER TEMPORAL
// Se eliminará cuando se implemente la pantalla de inicio real.
// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla provisional que verifica que el tema se aplica correctamente.
/// Muestra el logotipo/nombre y los colores base de Bound2Game.
class _SplashPlaceholder extends StatelessWidget {
  const _SplashPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icono / Logo ──────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),

              // ── Nombre de la app ──────────────────────────────────────────
              Text(
                'Bound2Game',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // ── Subtítulo ─────────────────────────────────────────────────
              Text(
                'Tu biblioteca gaming, en tu bolsillo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // ── Indicador de carga ────────────────────────────────────────
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
