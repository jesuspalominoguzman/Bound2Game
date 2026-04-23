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
// ENUM: DealStore — Tiendas soportadas
// =============================================================================

/// Tiendas donde se pueden encontrar ofertas de juegos.
/// Extensible: añadir un valor aquí + su config en [DealStoreConfig.of].
enum DealStore {
  steam,
  epic,
  psStore,
  xbox,
  nintendo,
  gog,
  instantGaming;

  /// Configuración visual de esta tienda.
  DealStoreConfig get config => DealStoreConfig.of(this);
}

// =============================================================================
// CONFIG: DealStoreConfig — Datos visuales de cada tienda
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
          name: 'Steam',
          color: const Color(0xFF1B9ED9),
          background: const Color(0xFF1B9ED9).withValues(alpha: 0.12),
          icon: Icons.computer_rounded,
          shortName: 'ST',
        );
      case DealStore.epic:
        return DealStoreConfig(
          name: 'Epic Games',
          color: const Color(0xFFFFFFFF),
          background: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
          icon: Icons.sports_esports_rounded,
          shortName: 'EG',
        );
      case DealStore.psStore:
        return DealStoreConfig(
          name: 'PlayStation Store',
          color: const Color(0xFF0070CC),
          background: const Color(0xFF0070CC).withValues(alpha: 0.12),
          icon: Icons.gamepad_rounded,
          shortName: 'PS',
        );
      case DealStore.xbox:
        return DealStoreConfig(
          name: 'Xbox / PC Game Pass',
          color: const Color(0xFF107C10),
          background: const Color(0xFF107C10).withValues(alpha: 0.12),
          icon: Icons.gamepad_outlined,
          shortName: 'XB',
        );
      case DealStore.nintendo:
        return DealStoreConfig(
          name: 'Nintendo eShop',
          color: const Color(0xFFE60012),
          background: const Color(0xFFE60012).withValues(alpha: 0.12),
          icon: Icons.videogame_asset_rounded,
          shortName: 'NS',
        );
      case DealStore.gog:
        return DealStoreConfig(
          name: 'GOG',
          color: const Color(0xFFA855F7),
          background: const Color(0xFFA855F7).withValues(alpha: 0.12),
          icon: Icons.public_rounded,
          shortName: 'GOG',
        );
      case DealStore.instantGaming:
        return DealStoreConfig(
          name: 'Instant Gaming',
          color: const Color(0xFFFF6B00),
          background: const Color(0xFFFF6B00).withValues(alpha: 0.12),
          icon: Icons.flash_on_rounded,
          shortName: 'IG',
        );
    }
  }
}

// =============================================================================
// MODEL: GameDeal — Una oferta concreta de un juego en una tienda
// =============================================================================

/// Representa la oferta de un juego en una tienda específica.
///
/// Todos los precios y porcentajes vienen del servicio de datos,
/// NUNCA se hardcodean en la capa de presentación.
class GameDeal {
  /// ID que corresponde a [Game.id] en game_model.dart (para cruzar datos).
  final String gameId;

  final String gameTitle;

  /// URL de portada (puede ser null si aún no se ha cargado).
  final String? gameCover;

  final DealStore store;

  /// Precio sin descuento en EUR.
  /// TODO(backend): Recibir divisa del servidor y convertir localmente.
  final double originalPrice;

  /// Precio con descuento en EUR (0.0 si es gratuito).
  final double salePrice;

  /// Porcentaje de descuento (0–100).
  /// Calculado en el backend/servicio, no en la UI.
  final int discountPercent;

  /// true si [salePrice] == 0 (juego gratuito durante la oferta).
  final bool isFree;

  /// URL directa a la página del juego en la tienda.
  /// TODO(backend): Generar desde el servicio de deals.
  final String? dealUrl;

  /// Fecha de expiración de la oferta (null = sin fecha conocida).
  final DateTime? expiresAt;

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
  });

  /// Copia con campos actualizados (útil para actualizar desde API).
  GameDeal copyWith({
    String? gameId,
    String? gameTitle,
    String? gameCover,
    DealStore? store,
    double? originalPrice,
    double? salePrice,
    int? discountPercent,
    bool? isFree,
    String? dealUrl,
    DateTime? expiresAt,
  }) {
    return GameDeal(
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
    );
  }

  /// Formatea el precio de oferta como cadena localizada.
  String get salePriceLabel =>
      isFree ? 'GRATIS' : '${salePrice.toStringAsFixed(2)} €';

  /// Formatea el precio original como cadena localizada.
  String get originalPriceLabel => '${originalPrice.toStringAsFixed(2)} €';
}

// =============================================================================
// MODEL: DealNotificationPrefs — Preferencias push por tienda
// =============================================================================

/// Preferencias de notificaciones push del usuario para cada tienda.
///
/// TODO(backend): Sincronizar con el servidor de notificaciones de Bound2Game.
class DealNotificationPrefs {
  /// Mapa de tienda → si el usuario quiere alertas de juegos gratuitos.
  final Map<DealStore, bool> freeGamesAlerts;

  const DealNotificationPrefs({required this.freeGamesAlerts});

  /// Estado por defecto: todas las tiendas activas.
  factory DealNotificationPrefs.defaults() => DealNotificationPrefs(
        freeGamesAlerts: {for (final s in DealStore.values) s: true},
      );

  /// Devuelve una copia con la preferencia de [store] actualizada.
  DealNotificationPrefs withAlert(DealStore store, bool enabled) {
    final updated = Map<DealStore, bool>.from(freeGamesAlerts);
    updated[store] = enabled;
    return DealNotificationPrefs(freeGamesAlerts: updated);
  }

  bool isAlertEnabled(DealStore store) => freeGamesAlerts[store] ?? true;
}

// =============================================================================
// DATOS DE EJEMPLO
// Fuente: cruzados con sampleGames de game_model.dart
// TODO(backend): Reemplazar por llamada a DealsService.fetchDeals()
// =============================================================================

/// Datos de muestra del motor de ofertas.
/// Cruzados con los IDs de [sampleGames] para que el Comparador de Precios
/// de [GameDetailScreen] funcione de forma coherente.
final List<GameDeal> sampleDeals = [
  // ── Juegos GRATUITOS (destacados arriba en DealsScreen) ──────────────────

  GameDeal(
    gameId: '3',
    gameTitle: 'League of Legends',
    gameCover:
        'https://images.unsplash.com/photo-1652318970273-acc95af4c6e1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic,
    originalPrice: 0,
    salePrice: 0,
    discountPercent: 100,
    isFree: true,
    dealUrl: 'https://store.epicgames.com',
  ),
  GameDeal(
    gameId: '4',
    gameTitle: 'Rocket League',
    gameCover:
        'https://images.unsplash.com/photo-1600998837340-4887228e311f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic,
    originalPrice: 0,
    salePrice: 0,
    discountPercent: 100,
    isFree: true,
    dealUrl: 'https://store.epicgames.com',
  ),
  GameDeal(
    gameId: '7',
    gameTitle: 'Fortnite',
    gameCover:
        'https://images.unsplash.com/photo-1589241062272-c0a000072dfa?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic,
    originalPrice: 0,
    salePrice: 0,
    discountPercent: 100,
    isFree: true,
    dealUrl: 'https://store.epicgames.com',
    expiresAt: DateTime(2026, 5, 1),
  ),
  GameDeal(
    gameId: '8',
    gameTitle: 'Destiny 2',
    gameCover:
        'https://images.unsplash.com/photo-1640955011254-39734e60b16f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam,
    originalPrice: 0,
    salePrice: 0,
    discountPercent: 100,
    isFree: true,
    dealUrl: 'https://store.steampowered.com',
  ),

  // ── Ofertas de Steam ──────────────────────────────────────────────────────

  GameDeal(
    gameId: '1',
    gameTitle: 'The Witcher 3: Wild Hunt',
    gameCover:
        'https://images.unsplash.com/photo-1596387451385-d5f211f6e7ab?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam,
    originalPrice: 29.99,
    salePrice: 8.99,
    discountPercent: 70,
    isFree: false,
    dealUrl: 'https://store.steampowered.com',
    expiresAt: DateTime(2026, 4, 30),
  ),
  GameDeal(
    gameId: '2',
    gameTitle: 'Cyberpunk 2077',
    gameCover:
        'https://images.unsplash.com/photo-1642345843526-6279c8880a49?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam,
    originalPrice: 59.99,
    salePrice: 29.99,
    discountPercent: 50,
    isFree: false,
    dealUrl: 'https://store.steampowered.com',
  ),
  GameDeal(
    gameId: '5',
    gameTitle: 'Starfield',
    gameCover:
        'https://images.unsplash.com/photo-1633355194356-1a2b1995cc62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam,
    originalPrice: 69.99,
    salePrice: 34.99,
    discountPercent: 50,
    isFree: false,
    dealUrl: 'https://store.steampowered.com',
  ),
  GameDeal(
    gameId: '9',
    gameTitle: 'Red Dead Redemption 2',
    gameCover:
        'https://images.unsplash.com/photo-1607853202273-797f1c22a38e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam,
    originalPrice: 59.99,
    salePrice: 17.99,
    discountPercent: 70,
    isFree: false,
    dealUrl: 'https://store.steampowered.com',
  ),
  GameDeal(
    gameId: '10',
    gameTitle: 'Elden Ring',
    gameCover:
        'https://images.unsplash.com/photo-1666888730264-8c7b85de6d40?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam,
    originalPrice: 59.99,
    salePrice: 35.99,
    discountPercent: 40,
    isFree: false,
    dealUrl: 'https://store.steampowered.com',
  ),
  GameDeal(
    gameId: '11',
    gameTitle: 'Hades',
    gameCover:
        'https://images.unsplash.com/photo-1628277613967-6abca504d0ac?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.steam,
    originalPrice: 24.99,
    salePrice: 12.49,
    discountPercent: 50,
    isFree: false,
    dealUrl: 'https://store.steampowered.com',
  ),

  // ── Ofertas de Epic Games ─────────────────────────────────────────────────

  GameDeal(
    gameId: '12',
    gameTitle: 'Grand Theft Auto V',
    gameCover:
        'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic,
    originalPrice: 29.99,
    salePrice: 14.99,
    discountPercent: 50,
    isFree: false,
    dealUrl: 'https://store.epicgames.com',
  ),
  GameDeal(
    gameId: '13',
    gameTitle: 'Control',
    gameCover:
        'https://images.unsplash.com/photo-1551103782-8ab07afd45c1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic,
    originalPrice: 39.99,
    salePrice: 9.99,
    discountPercent: 75,
    isFree: false,
    dealUrl: 'https://store.epicgames.com',
  ),
  GameDeal(
    gameId: '14',
    gameTitle: 'Alan Wake 2',
    gameCover:
        'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.epic,
    originalPrice: 49.99,
    salePrice: 24.99,
    discountPercent: 50,
    isFree: false,
    dealUrl: 'https://store.epicgames.com',
  ),

  // ── Ofertas de PlayStation Store ──────────────────────────────────────────

  GameDeal(
    gameId: '6',
    gameTitle: 'Horizon Zero Dawn',
    gameCover:
        'https://images.unsplash.com/photo-1654424931721-01f8487cf5f1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.psStore,
    originalPrice: 19.99,
    salePrice: 4.99,
    discountPercent: 75,
    isFree: false,
    dealUrl: 'https://store.playstation.com',
  ),
  GameDeal(
    gameId: '15',
    gameTitle: 'God of War Ragnarök',
    gameCover:
        'https://images.unsplash.com/photo-1674901001180-f56e65f23997?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.psStore,
    originalPrice: 79.99,
    salePrice: 47.99,
    discountPercent: 40,
    isFree: false,
    dealUrl: 'https://store.playstation.com',
  ),
  GameDeal(
    gameId: '16',
    gameTitle: 'Spider-Man: Miles Morales',
    gameCover:
        'https://images.unsplash.com/photo-1608889476518-738c9b1dcb40?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.psStore,
    originalPrice: 49.99,
    salePrice: 19.99,
    discountPercent: 60,
    isFree: false,
    dealUrl: 'https://store.playstation.com',
  ),

  // ── Ofertas de GOG ────────────────────────────────────────────────────────

  GameDeal(
    gameId: '17',
    gameTitle: 'Baldur\'s Gate 3',
    gameCover:
        'https://images.unsplash.com/photo-1670888741735-f69bb3f7f4ed?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.gog,
    originalPrice: 59.99,
    salePrice: 35.99,
    discountPercent: 40,
    isFree: false,
    dealUrl: 'https://www.gog.com',
  ),
  GameDeal(
    gameId: '18',
    gameTitle: 'Disco Elysium',
    gameCover:
        'https://images.unsplash.com/photo-1615679591400-93db7ead06d4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.gog,
    originalPrice: 39.99,
    salePrice: 9.99,
    discountPercent: 75,
    isFree: false,
    dealUrl: 'https://www.gog.com',
  ),

  // ── Ofertas de Instant Gaming ─────────────────────────────────────────────

  GameDeal(
    gameId: '19',
    gameTitle: 'Counter-Strike 2',
    gameCover:
        'https://images.unsplash.com/photo-1580327344181-c1163234e5a0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.instantGaming,
    originalPrice: 14.99,
    salePrice: 5.99,
    discountPercent: 60,
    isFree: false,
    dealUrl: 'https://www.instant-gaming.com',
  ),
  GameDeal(
    gameId: '20',
    gameTitle: 'FIFA 24',
    gameCover:
        'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
    store: DealStore.instantGaming,
    originalPrice: 69.99,
    salePrice: 24.99,
    discountPercent: 64,
    isFree: false,
    dealUrl: 'https://www.instant-gaming.com',
  ),
];
