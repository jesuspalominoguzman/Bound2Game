// =============================================================================
// main.dart — Bound2Game Flutter (Android)
//
// Punto de entrada principal de la aplicación.
// Configura el tema oscuro, el título y el widget raíz.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/shake_selector_screen.dart';
import 'theme/app_theme.dart';

/// Key global para navegación sin contexto
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
class Bound2GameApp extends StatefulWidget {
  const Bound2GameApp({super.key});

  @override
  State<Bound2GameApp> createState() => _Bound2GameAppState();
}

class _Bound2GameAppState extends State<Bound2GameApp> {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _initShakeListener();
  }

  void _initShakeListener() {
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_isShaking) return;

      // Calcular fuerza total
      final double force = event.x.abs() + event.y.abs() + event.z.abs();
      
      if (force > 25) {
        _isShaking = true;
        
        // Ejecutar navegación
        if (navigatorKey.currentState != null) {
          // Bloqueo simple: verificamos que la ruta actual no sea ya ShakeSelectorScreen
          // (Esto se maneja empujando la ruta y esperando a que vuelva para desbloquear)
          navigatorKey.currentState!
              .push(MaterialPageRoute(builder: (_) => const ShakeSelectorScreen()))
              .then((_) {
            // Cuando el usuario cierra la pantalla de Shake to Play, rehabilitamos el sacudido
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) setState(() => _isShaking = false);
            });
          });
        } else {
          // Fallback por si navigatorKey no está listo
          Future.delayed(const Duration(seconds: 1), () => _isShaking = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      // ── Metadatos ────────────────────────────────────────────────────────
      title: 'Bound2Game',
      debugShowCheckedModeBanner: false,

      // ── Tema ─────────────────────────────────────────────────────────────
      // Se usa exclusivamente el tema oscuro; no se proporciona [theme]
      // (light) para evitar que el sistema operativo lo active.
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,

      // ── Pantalla inicial (AuthWrapper) ────────────────────────────────────
      home: const AuthWrapper(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH WRAPPER
// Controlador principal de navegación de la app.
// Decidirá si mostrar LoginScreen o MainLayout.
// ─────────────────────────────────────────────────────────────────────────────

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // TODO(backend): Leer estado real de autenticación de Firebase/SharedPreferences.
  // Por defecto, iniciamos con la pantalla de Login para probar el bypass.
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Simular carga de token
    await Future.delayed(const Duration(milliseconds: 500));
    // setState(() => _isLoggedIn = ...);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return const MainLayout();
    } else {
      return const LoginScreen();
    }
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
