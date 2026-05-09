// =============================================================================
// auth_service.dart — Bound2Game Flutter
//
// Gestiona la persistencia del token JWT y los datos del usuario autenticado
// usando SharedPreferences. Es la única fuente de verdad de sesión.
// =============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELO: AuthUser — Usuario autenticado (response del backend)
// Corresponde a la respuesta de POST /api/users/login y /api/users/register
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// MODELO: AuthSession — Token + usuario juntos
// ─────────────────────────────────────────────────────────────────────────────

class AuthSession {
  final String   token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE: AuthService
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  static const _kToken = 'b2g_auth_token';
  static const _kUser  = 'b2g_auth_user';

  // ── Guardar sesión tras login/register ──────────────────────────────────────
  static Future<void> saveSession(String token, AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  // ── Cargar sesión guardada (al arrancar la app) ────────────────────────────
  static Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final userJson = prefs.getString(_kUser);

    if (token == null || token.isEmpty || userJson == null) return null;

    try {
      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      return AuthSession(token: token, user: AuthUser.fromJson(decoded));
    } catch (_) {
      // JSON corrupto → limpiar
      await clearSession();
      return null;
    }
  }

  // ── Obtener solo el token (para las cabeceras HTTP) ────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  // ── Obtener el usuario actual ──────────────────────────────────────────────
  static Future<AuthUser?> getCurrentUser() async {
    final session = await loadSession();
    return session?.user;
  }

  // ── Logout: borra el token y los datos locales ────────────────────────────
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
  }

  // ── ¿Hay sesión activa? ───────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
