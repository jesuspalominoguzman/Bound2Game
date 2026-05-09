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
// MODEL: Deal (Nueva integración API backend)
// =============================================================================

class Deal {
  final String id;
  final String title;
  final double normalPrice;
  final double salePrice;
  final String storeName;
  final String thumbUrl;
  final String category;

  const Deal({
    required this.id,
    required this.title,
    required this.normalPrice,
    required this.salePrice,
    required this.storeName,
    required this.thumbUrl,
    required this.category,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['gameId']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown',
      normalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      storeName: json['storeName']?.toString() ?? json['storeID']?.toString() ?? 'Steam',
      thumbUrl: json['thumb']?.toString() ?? '',
      category: json['category']?.toString() ?? 'DEAL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': id,
      'title': title,
      'originalPrice': normalPrice,
      'salePrice': salePrice,
      'storeName': storeName,
      'thumb': thumbUrl,
      'category': category,
    };
  }

  DealStore get storeEnum {
    final s = storeName.toLowerCase();
    if (s.contains('epic')) return DealStore.epic;
    if (s.contains('playstation') || s.contains('psn') || s.contains('psstore')) return DealStore.psStore;
    if (s.contains('xbox') || s.contains('microsoft')) return DealStore.xbox;
    if (s.contains('nintendo')) return DealStore.nintendo;
    if (s.contains('instant')) return DealStore.instantGaming;
    return DealStore.steam;
  }

  int get calculatedDiscount {
    if (normalPrice <= 0 || salePrice <= 0) return 0;
    if (salePrice >= normalPrice) return 0;
    return ((1 - (salePrice / normalPrice)) * 100).round();
  }
}


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

  // ── Factory: construir desde la respuesta del backend (ApiDeal normalizado) ──
  /// Mapea la clave `store` del backend (ej. "steam", "epic") al enum [DealStore].
  factory GameDeal.fromApiJson(Map<String, dynamic> json) {
    final storeStr = json['store']?.toString() ?? 'steam';
    final store = _storeFromString(storeStr);
    final double origPrice = _toDouble(json['originalPrice']);
    final double salePrice = _toDouble(json['salePrice']);

    return GameDeal(
      gameId:          json['gameId']?.toString()    ?? '',
      gameTitle:       json['gameTitle']?.toString()  ?? 'Unknown',
      gameCover:       json['gameCover']?.toString(),
      store:           store,
      originalPrice:   origPrice,
      salePrice:       salePrice,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      isFree:          json['isFree'] == true,
      dealUrl:         json['dealUrl']?.toString(),
    );
  }

  static DealStore _storeFromString(String s) {
    switch (s.toLowerCase()) {
      case 'epic':          return DealStore.epic;
      case 'psstore':       return DealStore.psStore;
      case 'xbox':          return DealStore.xbox;
      case 'nintendo':      return DealStore.nintendo;
      case 'instantgaming': return DealStore.instantGaming;
      default:              return DealStore.steam;
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }


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
// DATOS ELIMINADOS (Ahora se usa la API real en DealsScreen)
// =============================================================================

