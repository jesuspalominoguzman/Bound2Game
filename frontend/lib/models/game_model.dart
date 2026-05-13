// Aquí es donde defino qué es un "juego" para la app. He intentado que cubra todo: plataformas, géneros, estados de juego...
// Es lo que uso para pintar las tarjetas en la biblioteca y en los detalles.

import 'package:flutter/material.dart';

// Las plataformas que soportamos. He incluido las típicas (Steam, Epic) y también consolas por si alguien quiere meter sus juegos de ahí.
enum Platform {
  steam,
  epic,
  ig,
  integrated,
  nintendo,
  playstation,
  xbox;

  String get displayName => PlatformConfig.of(this).name;
  String get shortName => PlatformConfig.of(this).short;
  Color get color => PlatformConfig.of(this).color;

  // Una ayuda para saber si el juego es de PC y así mirar si nuestro hardware puede con él.
  bool get isPc => this == Platform.steam || this == Platform.epic || this == Platform.ig;
}

// ¿Cómo va la partida? He puesto los estados clásicos de cualquier biblioteca de juegos.
enum GameStatus {
  unplayed,
  playing,
  completed,
  abandoned;

  String get label {
    switch (this) {
      case GameStatus.unplayed:   return 'Sin jugar';
      case GameStatus.playing:    return 'Jugando';
      case GameStatus.completed:  return 'Completado';
      case GameStatus.abandoned:  return 'Abandonado';
    }
  }

  Color get color {
    switch (this) {
      case GameStatus.unplayed:   return const Color(0xFF8E8E8E);
      case GameStatus.playing:    return const Color(0xFF4A6CF7);
      case GameStatus.completed:  return const Color(0xFF4AF626);
      case GameStatus.abandoned:  return const Color(0xFFFF4040);
    }
  }
}

// El semáforo de compatibilidad. Verde si va perfecto, rojo si mejor ni intentarlo.
enum PcReq {
  green,
  yellow,
  red;

  PcReqConfig get config => PcReqConfig.of(this);

  // Un apaño para leer lo que nos manda el backend sin que rompa.
  static PcReq fromString(String? status) {
    if (status == null) return PcReq.yellow;
    switch (status.toUpperCase()) {
      case 'VERDE': return PcReq.green;
      case 'ROJO': return PcReq.red;
      case 'AMARILLO':
      default: return PcReq.yellow;
    }
  }
}

// El sistema de karma de los usuarios. Para saber si alguien es un jugador de fiar o un "troll".
enum Reputation {
  legendary,
  exemplar,
  positive,
  neutral,
  negative;

  ReputationConfig get config => ReputationConfig.of(this);
}

// Un componente de hardware del PC. Nos dice cuánto cumple (0-100) y una descripción.
class PcSpec {
  final int value;
  final String label;

  const PcSpec({required this.value, required this.label});

  factory PcSpec.fromMap(Map<String, dynamic> map) => PcSpec(
    value: (map['value'] as num).toInt(),
    label: map['label'] as String,
  );

  Map<String, dynamic> toMap() => {'value': value, 'label': label};
}

// El conjunto de piezas del PC: CPU, Gráfica, RAM y Disco.
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

// Los cosméticos del juego: skins, objetos raros y el valor total de la cuenta.
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

// Tiempos de HowLongToBeat. Para saber si nos va a dar para años o si lo terminamos en una tarde.
class HltbTimes {
  final int? main;
  final int? extra;
  final int? completionist;

  const HltbTimes({this.main, this.extra, this.completionist});
}

// Esta es la clase principal para los juegos. Tiene un montón de campos para que no falte ni un detalle.
class Game {
  final int id;
  final String? entryId;
  final String title;
  final Platform platform;
  final String genre;
  final int playtime;
  final GameStatus status;
  final String cover;
  final PcReq pcReq;
  final bool hasCosmetics;
  final Cosmetics? cosmetics;
  final HltbTimes? hltb;
  final double price;
  final int year;
  final PcSpecs? pcSpecs;
  final double? rentability;
  final double? rating;
  final String? pcRequirements;
  final int? metacritic;
  final String? esrbRating;
  final List<String> genres;

  const Game({
    required this.id,
    this.entryId,
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
    this.rentability,
    this.rating,
    this.pcRequirements,
    this.metacritic,
    this.esrbRating,
    this.genres = const [],
  });

  Game copyWith({
    int? id,
    String? entryId,
    String? title,
    Platform? platform,
    String? genre,
    int? playtime,
    GameStatus? status,
    String? cover,
    PcReq? pcReq,
    bool? hasCosmetics,
    Cosmetics? cosmetics,
    HltbTimes? hltb,
    double? price,
    int? year,
    PcSpecs? pcSpecs,
    double? rentability,
    double? rating,
    String? pcRequirements,
    int? metacritic,
    String? esrbRating,
    List<String>? genres,
  }) {
    return Game(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      genre: genre ?? this.genre,
      playtime: playtime ?? this.playtime,
      status: status ?? this.status,
      cover: cover ?? this.cover,
      pcReq: pcReq ?? this.pcReq,
      hasCosmetics: hasCosmetics ?? this.hasCosmetics,
      cosmetics: cosmetics ?? this.cosmetics,
      hltb: hltb ?? this.hltb,
      price: price ?? this.price,
      year: year ?? this.year,
      pcSpecs: pcSpecs ?? this.pcSpecs,
      rentability: rentability ?? this.rentability,
      rating: rating ?? this.rating,
      pcRequirements: pcRequirements ?? this.pcRequirements,
      metacritic: metacritic ?? this.metacritic,
      esrbRating: esrbRating ?? this.esrbRating,
      genres: genres ?? this.genres,
    );
  }
}

// Configuración visual de la reputación (colores y etiquetas).
class ReputationConfig {
  final Color color;
  final Color background;
  final String label;

  const ReputationConfig({
    required this.color,
    required this.background,
    required this.label,
  });

  static ReputationConfig of(Reputation rep) {
    switch (rep) {
      case Reputation.legendary:
        return ReputationConfig(
          color: const Color(0xFFFFD700),
          background: const Color(0xFFFFD700).withValues(alpha: 0.15),
          label: 'Leyenda',
        );
      case Reputation.exemplar:
        return ReputationConfig(
          color: const Color(0xFF4AF626),
          background: const Color(0xFF4AF626).withValues(alpha: 0.15),
          label: 'Ejemplar',
        );
      case Reputation.positive:
        return ReputationConfig(
          color: const Color(0xFF00E5FF),
          background: const Color(0xFF00E5FF).withValues(alpha: 0.15),
          label: 'Positivo',
        );
      case Reputation.neutral:
        return ReputationConfig(
          color: const Color(0xFF888888),
          background: const Color(0xFF888888).withValues(alpha: 0.15),
          label: 'Neutral',
        );
      case Reputation.negative:
        return ReputationConfig(
          color: const Color(0xFFFF4040),
          background: const Color(0xFFFF4040).withValues(alpha: 0.15),
          label: 'Negativo',
        );
    }
  }
}

// Configuración visual de los requisitos de PC (semáforo).
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
          background: const Color(0xFF4AF626).withValues(alpha: 0.15),
          label: '¡Listo para Jugar!',
          icon: '✓',
        );
      case PcReq.yellow:
        return PcReqConfig(
          color: const Color(0xFFFFB800),
          background: const Color(0xFFFFB800).withValues(alpha: 0.15),
          label: 'Revisar requisitos',
          icon: '⚡',
        );
      case PcReq.red:
        return PcReqConfig(
          color: const Color(0xFFFF4040),
          background: const Color(0xFFFF4040).withValues(alpha: 0.15),
          label: 'No compatible',
          icon: '✗',
        );
    }
  }
}

// Colores y nombres de cada plataforma para que se vean bien en los badges.
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
      case Platform.nintendo:
        return const PlatformConfig(name: 'Nintendo', color: Color(0xFFE4000F), short: 'NIN');
      case Platform.playstation:
        return const PlatformConfig(name: 'PlayStation', color: Color(0xFF003087), short: 'PS');
      case Platform.xbox:
        return const PlatformConfig(name: 'Xbox', color: Color(0xFF107C10), short: 'XBX');
    }
  }
}

// Unos cuantos juegos de ejemplo que uso para probar la función de agitar el móvil y que no se vea vacío al principio.
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
];
