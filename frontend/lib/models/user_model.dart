// Este archivo es el modelo de los usuarios de la app. He intentado que guarde todo lo importante: su karma, sus amigos, qué PC tienen y hasta sus cuentas vinculadas.
// Al final, es lo que usamos para pintar los perfiles y saber quién está conectado.

import 'package:flutter/material.dart';

// Esta es la clase principal para cualquier usuario (nosotros o nuestros amigos). Me traigo los datos directamente de MongoDB.
class User {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final int karma;
  final Map<String, dynamic> pcComponents;
  final List<User> friends;
  // Los últimos juegos a los que ha dado caña para enseñarlos en su perfil.
  final List<String> recentGames;
  final List<String> recentGameCovers;
  final bool isOnline;
  final String? steamId;
  final String? epicId;
  final String? xboxId;
  final String? discordId;
  final int friendsCount;
  final String? userRating; // Si nos cae bien (like), mal (dislike) o ni fu ni fa.
  final String? friendStatus; // 'none', 'pending', 'friends'

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
    this.steamId,
    this.epicId,
    this.xboxId,
    this.discordId,
    this.friendsCount = 0,
    this.userRating,
    this.friendStatus,
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
      steamId: json['steamId']?.toString(),
      epicId: json['epicId']?.toString(),
      xboxId: json['xboxId']?.toString(),
      discordId: json['discordId']?.toString(),
      friendsCount: (json['friendsCount'] as num?)?.toInt() ?? friendsList.length,
      userRating: json['userRating']?.toString(),
      friendStatus: json['friendStatus']?.toString(),
    );
  }

  // Si el usuario no tiene foto, sacamos las iniciales de su nombre para ponerlas en el círculo del avatar y que no quede vacío.
  String get initials {
    if (username.isEmpty) return '?';
    if (username.length == 1) return username.toUpperCase();
    return username.substring(0, 2).toUpperCase();
  }

  // Generamos un color aleatorio (pero siempre el mismo para el mismo usuario) para el fondo del avatar.
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

  // Esto nos sirve para actualizar solo un trocito del usuario (como si está online o no) sin tener que volver a crear todo el objeto.
  User copyWith({
    bool? isOnline,
    String? steamId,
    String? epicId,
    String? xboxId,
    String? discordId,
    int? friendsCount,
    Map<String, dynamic>? pcComponents,
    String? userRating,
    int? karma,
    String? friendStatus,
  }) {
    return User(
      id: id,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      bio: bio,
      karma: karma ?? this.karma,
      pcComponents: pcComponents ?? Map<String, dynamic>.from(this.pcComponents),
      friends: friends,
      recentGames: recentGames,
      recentGameCovers: recentGameCovers,
      isOnline: isOnline ?? this.isOnline,
      steamId: steamId ?? this.steamId,
      epicId: epicId ?? this.epicId,
      xboxId: xboxId ?? this.xboxId,
      discordId: discordId ?? this.discordId,
      friendsCount: friendsCount ?? this.friendsCount,
      userRating: userRating ?? this.userRating,
      friendStatus: friendStatus ?? this.friendStatus,
    );
  }
}
