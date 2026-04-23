// =============================================================================
// user_model.dart — Bound2Game Flutter (Android)
// Fuente: InterfazdeusuarioBound2game - CORRECTO
//   └── src/app/pages/Social.tsx  (lista de jugadores, afinidad, reputación)
//
// Mapeo:
//   interface User (Social.tsx)  → class SocialUser
//   REPUTATION_CONFIG            → reutiliza Reputation + ReputationConfig
//                                  definidos en game_model.dart
//
// Nota de arquitectura:
//   Este archivo NO duplica el enum Reputation ni ReputationConfig.
//   Los importa directamente de game_model.dart para mantener una única
//   fuente de verdad para el sistema de reputación/karma del TFG.
// =============================================================================

import 'package:flutter/material.dart';
import 'game_model.dart';

// =============================================================================
// MODELO PRINCIPAL
// =============================================================================

/// Usuario social de la comunidad Bound2Game.
///
/// Extiende la información del `User` en gameData.ts con campos propios
/// de la pantalla Social: [isOnline], [lastSeen], [mutualFriends].
///
/// Corresponde a los objetos de `USERS` filtrados/enriquecidos en Social.tsx.
class SocialUser {
  final int id;

  /// Nombre de usuario (handle). Ej: 'NightSaber_X'
  final String username;

  /// URL del avatar. Puede ser null; en ese caso se usan [initials].
  final String? avatarUrl;

  /// Iniciales para avatar generado. Ej: 'VR'
  final String? initials;

  /// Color de fondo del avatar generado.
  final Color? avatarBgColor;

  // ── Reputación ──────────────────────────────────────────────────────────────

  /// Nivel de reputación (enum compartido con game_model.dart).
  final Reputation reputation;

  /// Etiqueta corta de reputación. Ej: 'Leyenda de la Comunidad'
  final String reputationLabel;

  /// Puntuación numérica de reputación (0.0 – 5.0).
  final double reputationScore;

  // ── Matchmaking / Afinidad ─────────────────────────────────────────────────

  /// Juegos en común con el usuario actual (base del índice de afinidad).
  final int commonGames;

  /// Lista de juegos en común (títulos). Para mostrar tooltips de afinidad.
  final List<String> commonGameTitles;

  /// Tags de personalidad del jugador. Ej: ['Fair Play', 'Mentor']
  final List<String> tags;

  /// Juego favorito declarado.
  final String? favoriteGame;

  // ── Presencia ───────────────────────────────────────────────────────────────

  /// Si el jugador está conectado ahora mismo.
  final bool isOnline;

  /// Texto de última conexión. Solo se usa si [isOnline] es false.
  /// Ej: 'Hace 2h', 'Ayer'
  final String? lastSeen;

  // ── Perfil ──────────────────────────────────────────────────────────────────

  /// Nivel del jugador.
  final int level;

  /// Número de amigos en común (con el usuario actual).
  final int mutualFriends;

  const SocialUser({
    required this.id,
    required this.username,
    required this.reputation,
    required this.reputationLabel,
    required this.reputationScore,
    required this.commonGames,
    required this.commonGameTitles,
    required this.tags,
    required this.level,
    required this.mutualFriends,
    required this.isOnline,
    this.avatarUrl,
    this.initials,
    this.avatarBgColor,
    this.favoriteGame,
    this.lastSeen,
  });

  // ── Computed ────────────────────────────────────────────────────────────────

  /// Índice de afinidad (0–100). Fórmula provisional; el backend calculará
  /// esto con un algoritmo más sofisticado basado en horas jugadas, géneros
  /// preferidos y estilos de juego.
  ///
  /// TODO(backend): GET /api/social/affinity?targetUserId=[id]
  int get affinityScore => (commonGames * 12).clamp(0, 100);

  /// Configuración visual de la reputación (color, background, label).
  ReputationConfig get reputationConfig => reputation.config;
}

// =============================================================================
// CAPA DE DATOS MOCK
//
// TODO(backend): Reemplazar mockUsers por una llamada al servicio real:
//
//   Future<List<SocialUser>> fetchSocialFeed() async {
//     final response = await apiClient.get('/api/social/feed');
//     return (response['users'] as List)
//         .map((u) => SocialUser.fromJson(u))
//         .toList();
//   }
//
// Y envolver la lista en un FutureBuilder<List<SocialUser>>.
// =============================================================================

/// Lista de usuarios de la comunidad para la pantalla Social.
/// Datos de ejemplo derivados de gameData.ts / Social.tsx.
final List<SocialUser> mockUsers = [
  const SocialUser(
    id: 1,
    username: 'NightSaber_X',
    avatarUrl:
        'https://images.unsplash.com/photo-1721571698375-db5c4c4b0e50?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=200',
    reputation: Reputation.legendary,
    reputationLabel: 'Leyenda de la Comunidad',
    reputationScore: 4.9,
    commonGames: 8,
    commonGameTitles: [
      'The Witcher 3',
      'Cyberpunk 2077',
      'Rocket League',
      'League of Legends',
    ],
    tags: ['Líder Positivo', 'Buen Comunicador', 'Mentor'],
    favoriteGame: 'The Witcher 3: Wild Hunt',
    level: 87,
    mutualFriends: 12,
    isOnline: true,
  ),
  const SocialUser(
    id: 2,
    username: 'StarPixel_77',
    avatarUrl:
        'https://images.unsplash.com/photo-1725273454553-aec0c2905bbb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=200',
    reputation: Reputation.exemplar,
    reputationLabel: 'Jugador Ejemplar',
    reputationScore: 4.7,
    commonGames: 5,
    commonGameTitles: [
      'League of Legends',
      'Rocket League',
      'Starfield',
    ],
    tags: ['Buen Comunicador', 'Mentor', 'Fair Play'],
    favoriteGame: 'League of Legends',
    level: 63,
    mutualFriends: 7,
    isOnline: true,
  ),
  SocialUser(
    id: 3,
    username: 'VoidRunner_42',
    initials: 'VR',
    avatarBgColor: const Color(0xFF7B61FF),
    reputation: Reputation.exemplar,
    reputationLabel: 'Jugador Ejemplar',
    reputationScore: 4.5,
    commonGames: 3,
    commonGameTitles: ['Cyberpunk 2077', 'Horizon Zero Dawn'],
    tags: const ['Fair Play', 'Estratega'],
    favoriteGame: 'Cyberpunk 2077',
    level: 44,
    mutualFriends: 3,
    isOnline: false,
    lastSeen: 'Hace 2h',
  ),
  SocialUser(
    id: 4,
    username: 'CryptoKnight',
    initials: 'CK',
    avatarBgColor: const Color(0xFF00B4D8),
    reputation: Reputation.positive,
    reputationLabel: 'Compañero Positivo',
    reputationScore: 4.2,
    commonGames: 2,
    commonGameTitles: ['Rocket League', 'League of Legends'],
    tags: const ['Buen Comunicador'],
    favoriteGame: 'Rocket League',
    level: 29,
    mutualFriends: 2,
    isOnline: false,
    lastSeen: 'Ayer',
  ),
  SocialUser(
    id: 5,
    username: 'GlitchQueen',
    initials: 'GQ',
    avatarBgColor: const Color(0xFFFF6B9D),
    reputation: Reputation.legendary,
    reputationLabel: 'Leyenda de la Comunidad',
    reputationScore: 4.95,
    commonGames: 6,
    commonGameTitles: [
      'Rocket League',
      'League of Legends',
      'The Witcher 3',
      'Cyberpunk 2077',
    ],
    tags: const ['Speedrunner', 'Líder Positivo', 'Buen Comunicador'],
    favoriteGame: 'Rocket League',
    level: 112,
    mutualFriends: 9,
    isOnline: true,
  ),
  SocialUser(
    id: 6,
    username: 'IronWolf_Pro',
    initials: 'IW',
    avatarBgColor: const Color(0xFFFF7043),
    reputation: Reputation.positive,
    reputationLabel: 'Compañero Positivo',
    reputationScore: 4.3,
    commonGames: 4,
    commonGameTitles: [
      'League of Legends',
      'Horizon Zero Dawn',
      'Starfield',
    ],
    tags: const ['Fair Play', 'Paciente'],
    favoriteGame: 'League of Legends',
    level: 38,
    mutualFriends: 5,
    isOnline: false,
    lastSeen: 'Hace 3h',
  ),
  SocialUser(
    id: 7,
    username: 'NeonFox_Ry',
    initials: 'NF',
    avatarBgColor: const Color(0xFF4AF626),
    reputation: Reputation.neutral,
    reputationLabel: 'Jugador Neutral',
    reputationScore: 3.5,
    commonGames: 1,
    commonGameTitles: ['The Witcher 3'],
    tags: const ['Casual', 'Singleplayer'],
    favoriteGame: 'The Witcher 3: Wild Hunt',
    level: 15,
    mutualFriends: 1,
    isOnline: true,
    lastSeen: null,
  ),
];
