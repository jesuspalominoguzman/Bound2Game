// =============================================================================
// user_model.dart — Bound2Game Flutter
// =============================================================================

import 'package:flutter/material.dart';

// =============================================================================
// MODELO PRINCIPAL (Real de MongoDB)
// =============================================================================

class User {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final int karma;
  final Map<String, dynamic> pcComponents;
  final List<User> friends;
  /// Títulos recientes de la biblioteca del amigo (max 5).
  final List<String> recentGames;
  /// URLs de portada de los juegos recientes (misma longitud que recentGames).
  final List<String> recentGameCovers;
  final bool isOnline;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    this.karma = 0,
    this.pcComponents = const {},
    this.friends = const [],
    this.recentGames = const [],
    this.recentGameCovers = const [],
    this.isOnline = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var friendsList = <User>[];
    if (json['friends'] != null && json['friends'] is List) {
      friendsList = (json['friends'] as List).map((f) {
        if (f is String) {
          return User(id: f, username: 'Unknown');
        } else if (f is Map<String, dynamic>) {
          return User.fromJson(f);
        }
        return User(id: '', username: 'Unknown');
      }).toList();
    }

    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      bio: json['bio']?.toString(),
      karma: (json['karma'] as num?)?.toInt() ?? 0,
      pcComponents: json['pcComponents'] as Map<String, dynamic>? ?? {},
      friends: friendsList,
      recentGames: (json['recentGames'] as List<dynamic>? ?? [])
          .map((g) => g.toString())
          .toList(),
      recentGameCovers: (json['recentGameCovers'] as List<dynamic>? ?? [])
          .map((g) => g.toString())
          .toList(),
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }

  // ── Computed ────────────────────────────────────────────────────────────────

  /// Iniciales para avatar generado. Ej: 'VR'
  String get initials {
    if (username.isEmpty) return '?';
    if (username.length == 1) return username.toUpperCase();
    return username.substring(0, 2).toUpperCase();
  }

  /// Color de fondo del avatar generado basado en el ID
  Color get avatarBgColor {
    if (id.isEmpty) return const Color(0xFF1A1A1A);
    final colors = [
      const Color(0xFF7B61FF),
      const Color(0xFF00B4D8),
      const Color(0xFFFF6B9D),
      const Color(0xFFFF7043),
      const Color(0xFF4AF626),
      const Color(0xFFFFB800),
    ];
    final hash = id.hashCode.abs();
    return colors[hash % colors.length];
  }
}
