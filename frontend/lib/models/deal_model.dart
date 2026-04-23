// =============================================================================
// deal_model.dart — Bound2Game Flutter
// Sistema de Ofertas Globales (Deals Engine)
//
// Diseñado para ser agnóstico de la fuente de datos:
//   TODO(backend): Sustituir sampleDeals por una llamada a la API de ofertas
//   (IsThereAnyDeal, CheapShark, o endpoint propio de Bound2Game).
// =============================================================================

import 'package:flutter/material.dart';

// =============================================================================
// ENUM: PlayerMode — Modo de juego
// =============================================================================

enum PlayerMode {
  solo,
  multi,
  both;

  String get label {
    switch (this) {
      case PlayerMode.solo:  return 'Single Player';
      case PlayerMode.multi: return 'Multijugador';
      case PlayerMode.both:  return 'Ambos';
    }
  }
}

// =============================================================================
// ENUM: DealStore — Tiendas soportadas
// =============================================================================

enum DealStore {
  steam,
  epic,
  psStore,
  xbox,
  nintendo,
  gog,
  instantGaming;

  DealStoreConfig get config => DealStoreConfig.of(this);
}

// =============================================================================
// CONFIG: DealStoreConfig
// =============================================================================

class DealStoreConfig {
  final String name;
  final Color color;
  final Color background;
  final IconData icon;
  final String shortName;

  const DealStoreConfig({
    required this.name,
    required this.color,
    required this.background,
    required this.icon,
    required this.shortName,
  });

  static DealStoreConfig of(DealStore store) {
    switch (store) {
      case DealStore.steam:
        return DealStoreConfig(
          name: 'Steam', shortName: 'ST',
          color: const Color(0xFF1B9ED9),
          background: const Color(0xFF1B9ED9).withValues(alpha: 0.12),
          icon: Icons.computer_rounded,
        );
      case DealStore.epic:
        return DealStoreConfig(
          name: 'Epic Games', shortName: 'EG',
          color: const Color(0xFFE8E8E8),
          background: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
          icon: Icons.sports_esports_rounded,
        );
      case DealStore.psStore:
        return DealStoreConfig(
          name: 'PlayStation', shortName: 'PS',
          color: const Color(0xFF0070CC),
          background: const Color(0xFF0070CC).withValues(alpha: 0.12),
          icon: Icons.gamepad_rounded,
        );
      case DealStore.xbox:
        return DealStoreConfig(
          name: 'Xbox', shortName: 'XB',
          color: const Color(0xFF107C10),
          background: const Color(0xFF107C10).withValues(alpha: 0.12),
          icon: Icons.gamepad_outlined,
        );
      case DealStore.nintendo:
        return DealStoreConfig(
          name: 'Nintendo', shortName: 'NS',
          color: const Color(0xFFE60012),
          background: const Color(0xFFE60012).withValues(alpha: 0.12),
          icon: Icons.videogame_asset_rounded,
        );
      case DealStore.gog:
        return DealStoreConfig(
          name: 'GOG', shortName: 'GOG',
          color: const Color(0xFFA855F7),
          background: const Color(0xFFA855F7).withValues(alpha: 0.12),
          icon: Icons.public_rounded,
        );
      case DealStore.instantGaming:
        return DealStoreConfig(
          name: 'Instant Gaming', shortName: 'IG',
          color: const Color(0xFFFF6B00),
          background: const Color(0xFFFF6B00).withValues(alpha: 0.12),
          icon: Icons.flash_on_rounded,
        );
    }
  }
}

// =============================================================================
// MODEL: GameDeal
// =============================================================================

class GameDeal {
  final String gameId;
  final String gameTitle;
  final String? gameCover;
  final DealStore store;
  final double originalPrice;
  final double salePrice;
  final int discountPercent;
  final bool isFree;
  final String? dealUrl;
  final DateTime? expiresAt;
  final String? genre;
  final PlayerMode? playerMode;

  const GameDeal({
    required this.gameId,
    required this.gameTitle,
    required this.store,
    required this.originalPrice,
    required this.salePrice,
    required this.discountPercent,
    required this.isFree,
    this.gameCover,
    this.dealUrl,
    this.expiresAt,
    this.genre,
    this.playerMode,
  });

  GameDeal copyWith({
    String? gameId, String? gameTitle, String? gameCover, DealStore? store,
    double? originalPrice, double? salePrice, int? discountPercent,
    bool? isFree, String? dealUrl, DateTime? expiresAt,
    String? genre, PlayerMode? playerMode,
  }) => GameDeal(
    gameId: gameId ?? this.gameId,
    gameTitle: gameTitle ?? this.gameTitle,
    gameCover: gameCover ?? this.gameCover,
    store: store ?? this.store,
    originalPrice: originalPrice ?? this.originalPrice,
    salePrice: salePrice ?? this.salePrice,
    discountPercent: discountPercent ?? this.discountPercent,
    isFree: isFree ?? this.isFree,
    dealUrl: dealUrl ?? this.dealUrl,
    expiresAt: expiresAt ?? this.expiresAt,
    genre: genre ?? this.genre,
    playerMode: playerMode ?? this.playerMode,
  );

  String get salePriceLabel =>
      isFree ? 'GRATIS' : '${salePrice.toStringAsFixed(2)} €';
  String get originalPriceLabel => '${originalPrice.toStringAsFixed(2)} €';
}

// =============================================================================
// MODEL: DealNotificationPrefs
// =============================================================================

class DealNotificationPrefs {
  final Map<DealStore, bool> freeGamesAlerts;
  const DealNotificationPrefs({required this.freeGamesAlerts});

  factory DealNotificationPrefs.defaults() => DealNotificationPrefs(
    freeGamesAlerts: {for (final s in DealStore.values) s: true},
  );

  DealNotificationPrefs withAlert(DealStore store, bool enabled) {
    final updated = Map<DealStore, bool>.from(freeGamesAlerts);
    updated[store] = enabled;
    return DealNotificationPrefs(freeGamesAlerts: updated);
  }

  bool isAlertEnabled(DealStore store) => freeGamesAlerts[store] ?? true;
}

// =============================================================================
// DATOS DE EJEMPLO — TODO(backend): Reemplazar por DealsService.fetchDeals()
// =============================================================================

final List<GameDeal> sampleDeals = [
  // Gratuitos
  GameDeal(gameId: '3', gameTitle: 'League of Legends',
    gameCover: 'https://images.unsplash.com/photo-1652318970273-acc95af4c6e1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic, originalPrice: 0, salePrice: 0,
    discountPercent: 100, isFree: true, genre: 'MOBA', playerMode: PlayerMode.multi),
  GameDeal(gameId: '4', gameTitle: 'Rocket League',
    gameCover: 'https://images.unsplash.com/photo-1600998837340-4887228e311f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic, originalPrice: 0, salePrice: 0,
    discountPercent: 100, isFree: true, genre: 'Deporte', playerMode: PlayerMode.both),
  GameDeal(gameId: '7', gameTitle: 'Fortnite',
    gameCover: 'https://images.unsplash.com/photo-1589241062272-c0a000072dfa?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic, originalPrice: 0, salePrice: 0,
    discountPercent: 100, isFree: true, expiresAt: DateTime(2026, 5, 1),
    genre: 'Battle Royale', playerMode: PlayerMode.multi),
  GameDeal(gameId: '8', gameTitle: 'Destiny 2',
    gameCover: 'https://images.unsplash.com/photo-1640955011254-39734e60b16f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam, originalPrice: 0, salePrice: 0,
    discountPercent: 100, isFree: true, genre: 'Shooter', playerMode: PlayerMode.both),

  // Steam
  GameDeal(gameId: '1', gameTitle: 'The Witcher 3: Wild Hunt',
    gameCover: 'https://images.unsplash.com/photo-1596387451385-d5f211f6e7ab?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam, originalPrice: 29.99, salePrice: 8.99,
    discountPercent: 70, isFree: false, expiresAt: DateTime(2026, 4, 30),
    genre: 'RPG', playerMode: PlayerMode.solo),
  GameDeal(gameId: '2', gameTitle: 'Cyberpunk 2077',
    gameCover: 'https://images.unsplash.com/photo-1642345843526-6279c8880a49?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam, originalPrice: 59.99, salePrice: 29.99,
    discountPercent: 50, isFree: false, genre: 'RPG', playerMode: PlayerMode.solo),
  GameDeal(gameId: '5', gameTitle: 'Starfield',
    gameCover: 'https://images.unsplash.com/photo-1633355194356-1a2b1995cc62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam, originalPrice: 69.99, salePrice: 34.99,
    discountPercent: 50, isFree: false, genre: 'RPG', playerMode: PlayerMode.solo),
  GameDeal(gameId: '9', gameTitle: 'Red Dead Redemption 2',
    gameCover: 'https://images.unsplash.com/photo-1607853202273-797f1c22a38e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam, originalPrice: 59.99, salePrice: 17.99,
    discountPercent: 70, isFree: false, genre: 'Acción', playerMode: PlayerMode.both),
  GameDeal(gameId: '10', gameTitle: 'Elden Ring',
    gameCover: 'https://images.unsplash.com/photo-1666888730264-8c7b85de6d40?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam, originalPrice: 59.99, salePrice: 35.99,
    discountPercent: 40, isFree: false, genre: 'RPG', playerMode: PlayerMode.solo),
  GameDeal(gameId: '11', gameTitle: 'Hades',
    gameCover: 'https://images.unsplash.com/photo-1628277613967-6abca504d0ac?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam, originalPrice: 24.99, salePrice: 12.49,
    discountPercent: 50, isFree: false, genre: 'Roguelike', playerMode: PlayerMode.solo),

  // Epic
  GameDeal(gameId: '12', gameTitle: 'Grand Theft Auto V',
    gameCover: 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic, originalPrice: 29.99, salePrice: 14.99,
    discountPercent: 50, isFree: false, genre: 'Acción', playerMode: PlayerMode.both),
  GameDeal(gameId: '13', gameTitle: 'Control',
    gameCover: 'https://images.unsplash.com/photo-1551103782-8ab07afd45c1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic, originalPrice: 39.99, salePrice: 9.99,
    discountPercent: 75, isFree: false, genre: 'Acción', playerMode: PlayerMode.solo),
  GameDeal(gameId: '14', gameTitle: 'Alan Wake 2',
    gameCover: 'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic, originalPrice: 49.99, salePrice: 24.99,
    discountPercent: 50, isFree: false, genre: 'Terror', playerMode: PlayerMode.solo),

  // PlayStation
  GameDeal(gameId: '6', gameTitle: 'Horizon Zero Dawn',
    gameCover: 'https://images.unsplash.com/photo-1654424931721-01f8487cf5f1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.psStore, originalPrice: 19.99, salePrice: 4.99,
    discountPercent: 75, isFree: false, genre: 'Acción', playerMode: PlayerMode.solo),
  GameDeal(gameId: '15', gameTitle: 'God of War Ragnarök',
    gameCover: 'https://images.unsplash.com/photo-1674901001180-f56e65f23997?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.psStore, originalPrice: 79.99, salePrice: 47.99,
    discountPercent: 40, isFree: false, genre: 'Acción', playerMode: PlayerMode.solo),
  GameDeal(gameId: '16', gameTitle: 'Spider-Man: Miles Morales',
    gameCover: 'https://images.unsplash.com/photo-1608889476518-738c9b1dcb40?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.psStore, originalPrice: 49.99, salePrice: 19.99,
    discountPercent: 60, isFree: false, genre: 'Acción', playerMode: PlayerMode.solo),

  // GOG
  GameDeal(gameId: '17', gameTitle: "Baldur's Gate 3",
    gameCover: 'https://images.unsplash.com/photo-1670888741735-f69bb3f7f4ed?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.gog, originalPrice: 59.99, salePrice: 35.99,
    discountPercent: 40, isFree: false, genre: 'RPG', playerMode: PlayerMode.both),
  GameDeal(gameId: '18', gameTitle: 'Disco Elysium',
    gameCover: 'https://images.unsplash.com/photo-1615679591400-93db7ead06d4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.gog, originalPrice: 39.99, salePrice: 9.99,
    discountPercent: 75, isFree: false, genre: 'RPG', playerMode: PlayerMode.solo),

  // Instant Gaming
  GameDeal(gameId: '19', gameTitle: 'Counter-Strike 2',
    gameCover: 'https://images.unsplash.com/photo-1580327344181-c1163234e5a0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.instantGaming, originalPrice: 14.99, salePrice: 5.99,
    discountPercent: 60, isFree: false, genre: 'Shooter', playerMode: PlayerMode.multi),
  GameDeal(gameId: '20', gameTitle: 'FIFA 24',
    gameCover: 'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.instantGaming, originalPrice: 69.99, salePrice: 24.99,
    discountPercent: 64, isFree: false, genre: 'Deporte', playerMode: PlayerMode.both),
];

// =============================================================================
// MODEL: UpcomingGame — Próximos lanzamientos
// =============================================================================

class UpcomingGame {
  final String id;
  final String title;
  final String? cover;
  final DateTime releaseDate;
  final String? genre;
  final DealStore? store;

  const UpcomingGame({
    required this.id,
    required this.title,
    required this.releaseDate,
    this.cover,
    this.genre,
    this.store,
  });

  String get releaseDateLabel {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return '${releaseDate.day} ${months[releaseDate.month - 1]} ${releaseDate.year}';
  }
}

/// TODO(backend): Reemplazar por UpcomingService.fetchUpcoming()
final List<UpcomingGame> sampleUpcoming = [
  UpcomingGame(
    id: 'u1', title: 'Grand Theft Auto VI',
    cover: 'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    releaseDate: DateTime(2026, 5, 26), genre: 'Acción', store: DealStore.psStore,
  ),
  UpcomingGame(
    id: 'u2', title: 'DOOM: The Dark Ages',
    cover: 'https://images.unsplash.com/photo-1640955011254-39734e60b16f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    releaseDate: DateTime(2026, 5, 15), genre: 'Shooter', store: DealStore.steam,
  ),
  UpcomingGame(
    id: 'u3', title: 'Ghost of Yōtei',
    cover: 'https://images.unsplash.com/photo-1607853202273-797f1c22a38e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    releaseDate: DateTime(2026, 10, 1), genre: 'Acción', store: DealStore.psStore,
  ),
  UpcomingGame(
    id: 'u4', title: 'Mafia: The Old Country',
    cover: 'https://images.unsplash.com/photo-1596387451385-d5f211f6e7ab?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    releaseDate: DateTime(2026, 8, 8), genre: 'Acción', store: DealStore.steam,
  ),
  UpcomingGame(
    id: 'u5', title: 'Monster Hunter Wilds DLC',
    cover: 'https://images.unsplash.com/photo-1666888730264-8c7b85de6d40?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    releaseDate: DateTime(2026, 6, 20), genre: 'RPG', store: DealStore.steam,
  ),
  UpcomingGame(
    id: 'u6', title: 'Marvel\'s Wolverine',
    cover: 'https://images.unsplash.com/photo-1608889476518-738c9b1dcb40?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    releaseDate: DateTime(2026, 12, 1), genre: 'Acción', store: DealStore.psStore,
  ),
];

