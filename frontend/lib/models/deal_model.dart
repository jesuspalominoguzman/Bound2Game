// Este archivo es el cerebro de las ofertas. Aquí definimos qué datos nos interesan de un "chollo": el precio original, el rebajado y en qué tienda está.
// He intentado que sea muy automático para que la app sepa qué tienda es solo con leer el nombre.

import 'package:flutter/material.dart';
import 'game_model.dart';

// Un "chollo" individual. Me traigo la info del servidor y calculo cuánto nos ahorramos de verdad.
class Deal {
  final String id;
  final String title;
  final double normalPrice;
  final double salePrice;
  final String storeName;
  final String thumbUrl;
  final String category;
  final String? dealUrl;
  final String? releaseDate;

  const Deal({
    required this.id,
    required this.title,
    required this.normalPrice,
    required this.salePrice,
    required this.storeName,
    required this.thumbUrl,
    required this.category,
    this.dealUrl,
    this.releaseDate,
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
      dealUrl: json['dealUrl']?.toString(),
      releaseDate: json['releaseDate']?.toString(),
    );
  }

  // Intentamos adivinar la tienda basándonos en el nombre que nos manda la API para ponerle el logo que toca.
  DealStore get storeEnum {
    final s = storeName.toLowerCase();
    if (s.contains('steam')) return DealStore.steam;
    if (s.contains('epic')) return DealStore.epic;
    if (s.contains('playstation') || s.contains('psn') || s.contains('psstore')) return DealStore.psStore;
    if (s.contains('xbox') || s.contains('microsoft')) return DealStore.xbox;
    if (s.contains('nintendo')) return DealStore.nintendo;
    return DealStore.other;
  }

  // Sacamos el porcentaje de descuento para que el usuario sepa si es una ganga o no.
  int get calculatedDiscount {
    if (normalPrice <= 0 || salePrice <= 0) return 0;
    if (salePrice >= normalPrice) return 0;
    return ((1 - (salePrice / normalPrice)) * 100).round();
  }

  // Un pequeño truco para convertir una oferta en un objeto "Juego" por si queremos ver sus detalles en la otra pantalla.
  Game toGame() {
    Platform platform;
    switch (storeEnum) {
      case DealStore.steam: platform = Platform.steam; break;
      case DealStore.epic:  platform = Platform.epic; break;
      default:              platform = Platform.integrated; break;
    }

    return Game(
      id: int.tryParse(id) ?? 999,
      title: title,
      platform: platform,
      genre: 'Varios',
      playtime: 0,
      status: GameStatus.unplayed,
      cover: thumbUrl,
      pcReq: PcReq.green,
      hasCosmetics: false,
      price: normalPrice,
      year: DateTime.now().year,
    );
  }
}

// Para saber si el juego es para jugar solo o con amigos.
enum PlayerMode {
  solo,
  multi,
  both;

  String get label {
    switch (this) {
      case PlayerMode.solo:  return 'Un jugador';
      case PlayerMode.multi: return 'Multijugador';
      case PlayerMode.both:  return 'Ambos';
    }
  }
}

// Las tiendas que vigilamos para encontrar ofertas. He incluido las principales de PC y consolas.
enum DealStore {
  steam,
  epic,
  psStore,
  xbox,
  nintendo,
  other;

  DealStoreConfig get config => DealStoreConfig.of(this);
}

// Aquí asocio cada tienda con su color y su icono oficial.
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
      case DealStore.other:
        return DealStoreConfig(
          name: 'Tienda', shortName: 'ST',
          color: const Color(0xFF888888),
          background: const Color(0xFF888888).withValues(alpha: 0.12),
          icon: Icons.storefront_rounded,
        );
    }
  }
}

// Esta clase es para cuando los datos vienen un poco más detallados del servidor.
class GameDeal {
  final String gameId;
  final String gameTitle;
  final String? gameCover;
  final DealStore store;
  final String? storeName;
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
    this.storeName,
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
      storeName:       json['storeName']?.toString(),
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
      case 'steam':         return DealStore.steam;
      default:              return DealStore.other;
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String get salePriceLabel => isFree ? 'GRATIS' : '${salePrice.toStringAsFixed(2)} €';
  String get originalPriceLabel => '${originalPrice.toStringAsFixed(2)} €';
}

// Para guardar si queremos que el móvil nos avise cuando haya juegos gratis.
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
