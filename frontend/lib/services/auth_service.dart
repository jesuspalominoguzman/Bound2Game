// Este archivo se encarga de que la sesión del usuario no se pierda al cerrar la app.
// Guardamos el token de seguridad (JWT) y los datos básicos del usuario en la memoria del móvil para que no tenga que loguearse cada vez que la abra.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Estos son los datos del usuario que nos llegan del servidor cuando entramos.
// He incluido el karma, los componentes del PC y el avatar para que todo se vea bien desde el principio.
class AuthUser {
  final String id;
  final String username;
  final String email;
  final String avatarUrl;
  final Map<String, dynamic> reputation;
  final Map<String, dynamic> pcComponents;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl = '',
    this.reputation = const {},
    this.pcComponents = const {},
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id:            json['id']?.toString()       ?? json['_id']?.toString() ?? '',
      username:      json['username']?.toString()  ?? '',
      email:         json['email']?.toString()     ?? '',
      avatarUrl:     json['avatarUrl']?.toString() ?? '',
      reputation:    (json['reputation']   as Map<String, dynamic>?) ?? {},
      pcComponents:  (json['pcComponents'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id':            id,
    'username':      username,
    'email':         email,
    'avatarUrl':     avatarUrl,
    'reputation':    reputation,
    'pcComponents':  pcComponents,
  };
}

// Un pequeño modelo para tener el token y el usuario juntos.
class AuthSession {
  final String   token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});
}

// Aquí es donde ocurre la magia de la persistencia.
class AuthService {
  static const _kToken = 'b2g_auth_token';
  static const _kUser  = 'b2g_auth_user';

  // Cuando el usuario hace login o se registra, guardamos su token y sus datos.
  static Future<void> saveSession(String token, AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  // Al abrir la app, miramos si ya teníamos una sesión guardada.
  static Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final userJson = prefs.getString(_kUser);

    if (token == null || token.isEmpty || userJson == null) return null;

    try {
      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      return AuthSession(token: token, user: AuthUser.fromJson(decoded));
    } catch (_) {
      // Si el JSON está mal por lo que sea, limpiamos todo por si acaso.
      await clearSession();
      return null;
    }
  }

  // Sacamos solo el token, que es lo que necesitamos para las cabeceras de las peticiones HTTP.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  // Pillamos los datos del usuario que tenemos guardados.
  static Future<AuthUser?> getCurrentUser() async {
    final session = await loadSession();
    return session?.user;
  }

  // Para cuando el usuario quiere cerrar sesión. Borramos el token y sus datos del móvil.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
  }

  // Una comprobación rápida para saber si el usuario ya ha entrado o no.
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
