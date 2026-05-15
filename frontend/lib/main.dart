// Este es el punto de entrada principal de la aplicación.
// Aquí es donde arranca todo: cargamos las configuraciones, el tema y decidimos si el usuario tiene que loguearse o puede entrar directo.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/shake_selector_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'package:app_links/app_links.dart';
import 'models/user_model.dart';
import 'screens/user_profile_screen.dart';

// Esta llave nos sirve para navegar por la app sin tener que pasar el "contexto" por todas partes.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Aseguramos que Flutter esté listo antes de tocar cosas del sistema como la orientación.
  WidgetsFlutterBinding.ensureInitialized();

  // Cargamos el archivo .env donde guardamos la URL de nuestra API.
  await dotenv.load(fileName: ".env");

  // Forzamos que la app solo se vea en vertical, porque en horizontal se nos descuadra todo.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Ponemos la barra de arriba transparente para que quede más moderno y los iconos en blanco.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF303030), 
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const Bound2GameApp());
}

// El widget raíz. Aquí es donde meto el detector de movimiento (acelerómetro).
class Bound2GameApp extends StatefulWidget {
  const Bound2GameApp({super.key});

  @override
  State<Bound2GameApp> createState() => _Bound2GameAppState();
}

class _Bound2GameAppState extends State<Bound2GameApp> {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _isShaking = false;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    // Empezamos a escuchar por si el usuario agita el móvil.
    _initShakeListener();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Manejar enlaces recibidos mientras la app está abierta
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Manejar el enlace que abrió la app inicialmente
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('🔗 Deep Link recibido: $uri');
    // Formato esperado: https://bound2game.onrender.com/user/{userId}
    final isHttps = uri.scheme == 'https' && uri.host == 'bound2game.onrender.com';
    final isCustom = uri.scheme == 'bound2game' && uri.host == 'user';

    if ((isHttps || isCustom) && uri.pathSegments.isNotEmpty) {
      // Si es HTTPS, el ID está en el segundo segmento (/user/{id})
      // Si es custom, el ID está en el primero (/id)
      final userId = isHttps 
        ? (uri.pathSegments.length >= 2 ? uri.pathSegments[1] : null)
        : uri.pathSegments.first;

      if (userId != null && navigatorKey.currentState != null) {
        final loggedIn = await AuthService.isLoggedIn();
        if (loggedIn) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(user: User.minimal(userId)),
            ),
          );
        }
      }
    }
  }

  // Si el usuario agita el móvil con fuerza, le abrimos la pantalla mágica que elige un juego por él.
  void _initShakeListener() {
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_isShaking) return;

      // Calculamos cuánta caña le está dando al móvil.
      final double force = event.x.abs() + event.y.abs() + event.z.abs();
      
      if (force > 25) {
        _isShaking = true;
        
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!
              .push(MaterialPageRoute(builder: (_) => const ShakeSelectorScreen()))
              .then((_) {
            // Cuando cierra la pantalla, esperamos un segundo para que pueda volver a agitarlo.
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) setState(() => _isShaking = false);
            });
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () => _isShaking = false);
        }
      }
    });
  }

  @override
  void dispose() {
    // Muy importante: cancelamos el acelerómetro al cerrar la app para no gastar batería.
    _accelSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Bound2Game',
      debugShowCheckedModeBanner: false,

      // Solo usamos el tema oscuro porque mola mucho más y cansa menos la vista.
      darkTheme: buildAppTheme(),
      themeMode: ThemeMode.dark,

      // El AuthWrapper decide si mandamos al usuario al login o al dashboard.
      home: const AuthWrapper(),
    );
  }
}

// Este componente es el que mira si ya teníamos la sesión guardada del usuario.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // null mientras mira el disco, true si está logueado, false si no.
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (mounted) setState(() => _isLoggedIn = loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    // Si todavía estamos mirando el estado, ponemos una pantalla de carga para que no se vea el fondo vacío.
    if (_isLoggedIn == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF292929),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFB800),
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    // Si está logueado, a la app. Si no, al login de cabeza.
    return _isLoggedIn! ? const MainLayout() : const LoginScreen();
  }
}
