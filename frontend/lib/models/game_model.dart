// =============================================================================
// game_model.dart — Bound2Game Flutter (Android)
// Fuente: InterfazdeusuarioBound2game - CORRECTO
//   └── src/app/data/gameData.ts
//
// Mapeo TypeScript → Dart:
//   type Platform  → enum Platform
//   type Status    → enum GameStatus
//   type PcReq     → enum PcReq
//   interface PcSpec     → class PcSpec
//   interface Game       → class Game
//   interface User       → class User
//   const REPUTATION_CONFIG → ReputationConfig
//   const PC_REQ_CONFIG     → PcReqConfig
//   const PLATFORM_CONFIG   → PlatformConfig
//   const GAMES             → sampleGames  (datos de ejemplo del diseño)
//   const USERS             → sampleUsers
// =============================================================================

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

/// Plataformas de juego disponibles.
/// Corresponde a `type Platform = 'steam' | 'epic' | 'ig' | 'integrated'`
enum Platform {
  steam,
  epic,
  ig,
  integrated;

  /// Nombre completo de la plataforma.
  String get displayName => PlatformConfig.of(this).name;

  /// Abreviatura para badges.
  String get shortName => PlatformConfig.of(this).short;

  /// Color asociado a la plataforma.
  Color get color => PlatformConfig.of(this).color;
}

/// Estado de progreso del jugador en un juego.
/// Corresponde a `type Status = 'unplayed' | 'playing' | 'completed' | 'abandoned'`
enum GameStatus {
  unplayed,
  playing,
  completed,
  abandoned;

  /// Etiqueta en español para mostrar en la UI.
  String get label {
    switch (this) {
      case GameStatus.unplayed:   return 'Sin jugar';
      case GameStatus.playing:    return 'Jugando';
      case GameStatus.completed:  return 'Completado';
      case GameStatus.abandoned:  return 'Abandonado';
    }
  }

  /// Color del badge de estado.
  Color get color {
    switch (this) {
      case GameStatus.unplayed:   return const Color(0xFF8E8E8E);
      case GameStatus.playing:    return const Color(0xFF4A6CF7);
      case GameStatus.completed:  return const Color(0xFF4AF626);
      case GameStatus.abandoned:  return const Color(0xFFFF4040);
    }
  }
}

/// Compatibilidad del juego con el PC del usuario.
/// Corresponde a `type PcReq = 'green' | 'yellow' | 'red'`
enum PcReq {
  green,
  yellow,
  red;

  /// Datos de configuración visual.
  PcReqConfig get config => PcReqConfig.of(this);
}

/// Niveles de reputación de un usuario.
/// Corresponde a `reputation` en la interfaz `User`
enum Reputation {
  legendary,
  exemplar,
  positive,
  neutral,
  negative;

  /// Datos de configuración visual.
  ReputationConfig get config => ReputationConfig.of(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE DATOS PRINCIPALES
// ─────────────────────────────────────────────────────────────────────────────

/// Especificación de un componente de hardware del PC.
/// Corresponde a `interface PcSpec { value: number; label: string }`
class PcSpec {
  /// Porcentaje de cumplimiento (0-100).
  final int value;

  /// Descripción legible (ej. "i7-13700K — Supera ampliamente").
  final String label;

  const PcSpec({required this.value, required this.label});

  factory PcSpec.fromMap(Map<String, dynamic> map) => PcSpec(
    value: (map['value'] as num).toInt(),
    label: map['label'] as String,
  );

  Map<String, dynamic> toMap() => {'value': value, 'label': label};
}

/// Conjunto de especificaciones del PC del usuario para un juego.
/// Corresponde a `pcSpecs?: { cpu, gpu, ram, storage }` en `Game`
class PcSpecs {
  final PcSpec cpu;
  final PcSpec gpu;
  final PcSpec ram;
  final PcSpec storage;

  const PcSpecs({
    required this.cpu,
    required this.gpu,
    required this.ram,
    required this.storage,
  });

  factory PcSpecs.fromMap(Map<String, dynamic> map) => PcSpecs(
    cpu:     PcSpec.fromMap(map['cpu'] as Map<String, dynamic>),
    gpu:     PcSpec.fromMap(map['gpu'] as Map<String, dynamic>),
    ram:     PcSpec.fromMap(map['ram'] as Map<String, dynamic>),
    storage: PcSpec.fromMap(map['storage'] as Map<String, dynamic>),
  );
}

/// Información de cosméticos de un juego.
/// Corresponde a `cosmetics?: { skins, rareItems, value, featured? }` en `Game`
class Cosmetics {
  final int skins;
  final int rareItems;
  final double value;
  final String? featured;

  const Cosmetics({
    required this.skins,
    required this.rareItems,
    required this.value,
    this.featured,
  });
}

/// Tiempos estimados (HowLongToBeat).
/// Corresponde a `hltb?: { main, extra, completionist }` en `Game`
class HltbTimes {
  /// Horas para terminar la historia principal (null si es un juego sin fin).
  final int? main;
  /// Horas para extras.
  final int? extra;
  /// Horas para completar el 100%.
  final int? completionist;

  const HltbTimes({this.main, this.extra, this.completionist});
}

/// Modelo completo de un juego en la biblioteca del usuario.
/// Corresponde a `interface Game` en gameData.ts
class Game {
  final int id;
  final String title;
  final Platform platform;
  final String genre;

  /// Horas jugadas totales.
  final int playtime;
  final GameStatus status;

  /// URL de la imagen de portada.
  final String cover;
  final PcReq pcReq;
  final bool hasCosmetics;
  final Cosmetics? cosmetics;
  final HltbTimes? hltb;

  /// Precio en USD (0 = gratis).
  final double price;

  /// Año de lanzamiento.
  final int year;
  final PcSpecs? pcSpecs;

  /// Puntuación del juego (0.0–10.0).
  final double? rating;

  const Game({
    required this.id,
    required this.title,
    required this.platform,
    required this.genre,
    required this.playtime,
    required this.status,
    required this.cover,
    required this.pcReq,
    required this.hasCosmetics,
    required this.price,
    required this.year,
    this.cosmetics,
    this.hltb,
    this.pcSpecs,
    this.rating,
  });
}

/// Modelo de usuario de la comunidad Bound2Game.
/// Corresponde a `interface User` en gameData.ts
class User {
  final int id;
  final String name;

  /// URL del avatar (puede ser null; en ese caso se usa [initials]).
  final String? avatar;

  /// Iniciales para el avatar generado (ej. "VR").
  final String? initials;

  /// Color de fondo del avatar generado (ej. "#7B61FF").
  final Color? avatarColor;

  final Reputation reputation;
  final String reputationLabel;
  final List<String> tags;

  /// Juegos en común con el usuario actual.
  final int commonGames;

  /// Puntuación de reputación (0.0–5.0).
  final double score;

  /// Nivel del jugador.
  final int level;

  /// Juego favorito del usuario.
  final String? favoriteGame;

  const User({
    required this.id,
    required this.name,
    required this.reputation,
    required this.reputationLabel,
    required this.tags,
    required this.commonGames,
    required this.score,
    required this.level,
    this.avatar,
    this.initials,
    this.avatarColor,
    this.favoriteGame,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURACIONES VISUALES (Config objects)
// ─────────────────────────────────────────────────────────────────────────────

/// Configuración visual de un nivel de reputación.
/// Corresponde a `REPUTATION_CONFIG` en gameData.ts
class ReputationConfig {
  final Color color;
  final Color background;
  final String label;

  const ReputationConfig({
    required this.color,
    required this.background,
    required this.label,
  });

  /// Retorna la configuración para un nivel de [Reputation].
  static ReputationConfig of(Reputation rep) {
    switch (rep) {
      case Reputation.legendary:
        return ReputationConfig(
          color: const Color(0xFFFFD700),
          background: const Color(0xFFFFD700).withOpacity(0.15),
          label: 'Leyenda',
        );
      case Reputation.exemplar:
        return ReputationConfig(
          color: const Color(0xFF4AF626),
          background: const Color(0xFF4AF626).withOpacity(0.15),
          label: 'Ejemplar',
        );
      case Reputation.positive:
        return ReputationConfig(
          color: const Color(0xFF00E5FF),
          background: const Color(0xFF00E5FF).withOpacity(0.15),
          label: 'Positivo',
        );
      case Reputation.neutral:
        return ReputationConfig(
          color: const Color(0xFF888888),
          background: const Color(0xFF888888).withOpacity(0.15),
          label: 'Neutral',
        );
      case Reputation.negative:
        return ReputationConfig(
          color: const Color(0xFFFF4040),
          background: const Color(0xFFFF4040).withOpacity(0.15),
          label: 'Negativo',
        );
    }
  }
}

/// Configuración visual de un requisito de PC.
/// Corresponde a `PC_REQ_CONFIG` en gameData.ts
class PcReqConfig {
  final Color color;
  final Color background;
  final String label;
  final String icon;

  const PcReqConfig({
    required this.color,
    required this.background,
    required this.label,
    required this.icon,
  });

  static PcReqConfig of(PcReq req) {
    switch (req) {
      case PcReq.green:
        return PcReqConfig(
          color: const Color(0xFF4AF626),
          background: const Color(0xFF4AF626).withOpacity(0.15),
          label: '¡Listo para Jugar!',
          icon: '✓',
        );
      case PcReq.yellow:
        return PcReqConfig(
          color: const Color(0xFFFFB800),
          background: const Color(0xFFFFB800).withOpacity(0.15),
          label: 'Puede requerir ajustes',
          icon: '⚡',
        );
      case PcReq.red:
        return PcReqConfig(
          color: const Color(0xFFFF4040),
          background: const Color(0xFFFF4040).withOpacity(0.15),
          label: 'No compatible',
          icon: '✗',
        );
    }
  }
}

/// Configuración visual de una plataforma de juego.
/// Corresponde a `PLATFORM_CONFIG` en gameData.ts
class PlatformConfig {
  final String name;
  final Color color;
  final String short;

  const PlatformConfig({
    required this.name,
    required this.color,
    required this.short,
  });

  static PlatformConfig of(Platform platform) {
    switch (platform) {
      case Platform.steam:
        return const PlatformConfig(name: 'Steam', color: Color(0xFF1B9ED9), short: 'ST');
      case Platform.epic:
        return const PlatformConfig(name: 'Epic Games', color: Color(0xFFFFFFFF), short: 'EG');
      case Platform.ig:
        return const PlatformConfig(name: 'Instant Gaming', color: Color(0xFFFF6B00), short: 'IG');
      case Platform.integrated:
        return const PlatformConfig(name: 'Integrado', color: Color(0xFF9B59B6), short: 'B2G');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATOS DE EJEMPLO
// Corresponde a `const GAMES` y `const USERS` en gameData.ts
// ─────────────────────────────────────────────────────────────────────────────

/// Lista de juegos de muestra del diseño de referencia.
final List<Game> sampleGames = [
  const Game(
    id: 1,
    title: 'The Witcher 3: Wild Hunt',
    platform: Platform.steam,
    genre: 'RPG',
    playtime: 150,
    status: GameStatus.completed,
    cover: 'https://images.unsplash.com/photo-1596387451385-d5f211f6e7ab?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    pcReq: PcReq.green,
    hasCosmetics: false,
    hltb: HltbTimes(main: 52, extra: 103, completionist: 173),
    price: 30,
    year: 2015,
    rating: 9.8,
    pcSpecs: PcSpecs(
      cpu:     PcSpec(value: 92, label: 'i7-13700K — Supera ampliamente'),
      gpu:     PcSpec(value: 88, label: 'RTX 4070 — Supera ampliamente'),
      ram:     PcSpec(value: 85, label: '32 GB DDR5 — Supera ampliamente'),
      storage: PcSpec(value: 78, label: '1 TB NVMe — Cumple'),
    ),
  ),
  const Game(
    id: 2,
    title: 'Cyberpunk 2077',
    platform: Platform.steam,
    genre: 'Action RPG',
    playtime: 45,
    status: GameStatus.playing,
    cover: 'https://images.unsplash.com/photo-1642345843526-6279c8880a49?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    pcReq: PcReq.yellow,
    hasCosmetics: false,
    hltb: HltbTimes(main: 24, extra: 58, completionist: 102),
    price: 60,
    year: 2020,
    rating: 8.4,
    pcSpecs: PcSpecs(
      cpu:     PcSpec(value: 68, label: 'i7-13700K — Cumple justo'),
      gpu:     PcSpec(value: 55, label: 'RTX 4070 — Ajustes recomendados'),
      ram:     PcSpec(value: 82, label: '32 GB DDR5 — Supera'),
      storage: PcSpec(value: 72, label: '1 TB NVMe — Cumple'),
    ),
  ),
  const Game(
    id: 3,
    title: 'League of Legends',
    platform: Platform.epic,
    genre: 'MOBA',
    playtime: 320,
    status: GameStatus.playing,
    cover: 'https://images.unsplash.com/photo-1652318970273-acc95af4c6e1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    pcReq: PcReq.green,
    hasCosmetics: true,
    cosmetics: Cosmetics(skins: 47, rareItems: 12, value: 380, featured: 'K/DA Ahri Ultimate'),
    hltb: HltbTimes(),
    price: 0,
    year: 2009,
    rating: 8.1,
    pcSpecs: PcSpecs(
      cpu:     PcSpec(value: 96, label: 'i7-13700K — Supera ampliamente'),
      gpu:     PcSpec(value: 94, label: 'RTX 4070 — Supera ampliamente'),
      ram:     PcSpec(value: 98, label: '32 GB DDR5 — Supera ampliamente'),
      storage: PcSpec(value: 92, label: '1 TB NVMe — Supera ampliamente'),
    ),
  ),
  const Game(
    id: 4,
    title: 'Rocket League',
    platform: Platform.epic,
    genre: 'Sports',
    playtime: 85,
    status: GameStatus.playing,
    cover: 'https://images.unsplash.com/photo-1600998837340-4887228e311f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    pcReq: PcReq.green,
    hasCosmetics: true,
    cosmetics: Cosmetics(skins: 23, rareItems: 5, value: 145, featured: 'Fennec Black Market'),
    hltb: HltbTimes(),
    price: 0,
    year: 2015,
    rating: 9.0,
    pcSpecs: PcSpecs(
      cpu:     PcSpec(value: 94, label: 'i7-13700K — Supera ampliamente'),
      gpu:     PcSpec(value: 91, label: 'RTX 4070 — Supera ampliamente'),
      ram:     PcSpec(value: 96, label: '32 GB DDR5 — Supera ampliamente'),
      storage: PcSpec(value: 97, label: '1 TB NVMe — Supera ampliamente'),
    ),
  ),
  const Game(
    id: 5,
    title: 'Starfield',
    platform: Platform.steam,
    genre: 'Action RPG',
    playtime: 5,
    status: GameStatus.unplayed,
    cover: 'https://images.unsplash.com/photo-1633355194356-1a2b1995cc62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    pcReq: PcReq.red,
    hasCosmetics: false,
    hltb: HltbTimes(main: 17, extra: 57, completionist: 155),
    price: 60,
    year: 2023,
    rating: 6.9,
    pcSpecs: PcSpecs(
      cpu:     PcSpec(value: 28, label: 'i7-13700K — No compatible'),
      gpu:     PcSpec(value: 22, label: 'RTX 4070 — No compatible'),
      ram:     PcSpec(value: 38, label: '32 GB DDR5 — Por debajo del mínimo'),
      storage: PcSpec(value: 30, label: '1 TB NVMe — Insuficiente'),
    ),
  ),
  const Game(
    id: 6,
    title: 'Horizon Zero Dawn',
    platform: Platform.ig,
    genre: 'Action',
    playtime: 22,
    status: GameStatus.abandoned,
    cover: 'https://images.unsplash.com/photo-1654424931721-01f8487cf5f1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    pcReq: PcReq.yellow,
    hasCosmetics: false,
    hltb: HltbTimes(main: 22, extra: 43, completionist: 60),
    price: 15,
    year: 2020,
    rating: 8.7,
    pcSpecs: PcSpecs(
      cpu:     PcSpec(value: 65, label: 'i7-13700K — Cumple justo'),
      gpu:     PcSpec(value: 58, label: 'RTX 4070 — Ajustes recomendados'),
      ram:     PcSpec(value: 74, label: '32 GB DDR5 — Cumple'),
      storage: PcSpec(value: 68, label: '1 TB NVMe — Cumple'),
    ),
  ),
];

/// Lista de usuarios de muestra del diseño de referencia.
final List<User> sampleUsers = [
  const User(
    id: 1,
    name: 'NightSaber_X',
    avatar: 'https://images.unsplash.com/photo-1721571698375-db5c4c4b0e50?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=200',
    reputation: Reputation.legendary,
    reputationLabel: 'Leyenda de la Comunidad',
    tags: ['Líder Positivo', 'Buen Comunicador', 'Mentor'],
    commonGames: 8,
    score: 4.9,
    level: 87,
    favoriteGame: 'The Witcher 3: Wild Hunt',
  ),
  const User(
    id: 2,
    name: 'StarPixel_77',
    avatar: 'https://images.unsplash.com/photo-1725273454553-aec0c2905bbb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=200',
    reputation: Reputation.exemplar,
    reputationLabel: 'Jugador Ejemplar',
    tags: ['Buen Comunicador', 'Mentor', 'Fair Play'],
    commonGames: 5,
    score: 4.7,
    level: 63,
    favoriteGame: 'League of Legends',
  ),
  User(
    id: 3,
    name: 'VoidRunner_42',
    initials: 'VR',
    avatarColor: const Color(0xFF7B61FF),
    reputation: Reputation.exemplar,
    reputationLabel: 'Jugador Ejemplar',
    tags: const ['Fair Play', 'Estratega'],
    commonGames: 3,
    score: 4.5,
    level: 44,
    favoriteGame: 'Cyberpunk 2077',
  ),
  User(
    id: 4,
    name: 'CryptoKnight',
    initials: 'CK',
    avatarColor: const Color(0xFF00B4D8),
    reputation: Reputation.positive,
    reputationLabel: 'Compañero Positivo',
    tags: const ['Buen Comunicador'],
    commonGames: 2,
    score: 4.2,
    level: 29,
    favoriteGame: 'Rocket League',
  ),
  User(
    id: 5,
    name: 'GlitchQueen',
    initials: 'GQ',
    avatarColor: const Color(0xFFFF6B9D),
    reputation: Reputation.legendary,
    reputationLabel: 'Leyenda de la Comunidad',
    tags: const ['Speedrunner', 'Líder Positivo', 'Buen Comunicador'],
    commonGames: 6,
    score: 4.95,
    level: 112,
    favoriteGame: 'Rocket League',
  ),
  User(
    id: 6,
    name: 'IronWolf_Pro',
    initials: 'IW',
    avatarColor: const Color(0xFFFF7043),
    reputation: Reputation.positive,
    reputationLabel: 'Compañero Positivo',
    tags: const ['Fair Play', 'Paciente'],
    commonGames: 4,
    score: 4.3,
    level: 38,
    favoriteGame: 'League of Legends',
  ),
];
