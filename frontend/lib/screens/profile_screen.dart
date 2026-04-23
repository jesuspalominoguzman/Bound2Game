// =============================================================================
// profile_screen.dart — Bound2Game Flutter
//
// Perfil Dual: 
//   - Propio: Permite editar redes sociales y navegar a ajustes.
//   - Amigo/Otro: Vista solo lectura, tocar copia el nickname.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import 'settings_screen.dart';

const _bg       = Color(0xFF0D0D0D);
const _bgCard   = Color(0xFF181818);
const _border   = Color(0xFF252525);
const _textMain = Color(0xFFD1D1D1);
const _textSub  = Color(0xFF888888);

// ── Colores de redes sociales adaptados a dark mode ──────────────────────────
const _colorDiscord  = Color(0xFF5865F2);
const _colorSteam    = Color(0xFF1B2838);
const _colorSteamTxt = Color(0xFF66C0F4);
const _colorEpic     = Color(0xFF2A2A2A);
const _colorNintendo = Color(0xFFE60012);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.isOwnProfile,
    this.user,
  });

  final bool isOwnProfile;
  final SocialUser? user;

  @override
  Widget build(BuildContext context) {
    // Si no se pasa usuario, asume el usuario actual (mockUsers[0])
    final targetUser = user ?? mockUsers[0];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        // Solo mostramos el título y ajustes si es el propio perfil
        // Si no es el propio perfil, la navegación de vuelta ya la pone Flutter (flecha atrás)
        title: Text(isOwnProfile ? 'Mi Perfil' : 'Perfil de Jugador',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: _textMain),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // ── Cabecera: Avatar y Reputación ──────────────────────────────
            _ProfileHeader(user: targetUser),
            const SizedBox(height: 32),

            // ── Redes Sociales ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Redes y Plataformas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SocialCard(
                    platform: 'Discord',
                    nickname: '${targetUser.username}#1234',
                    bgColor: _colorDiscord.withValues(alpha: 0.15),
                    borderColor: _colorDiscord.withValues(alpha: 0.3),
                    iconColor: _colorDiscord,
                    icon: Icons.discord,
                    isOwnProfile: isOwnProfile,
                  ),
                  const SizedBox(height: 10),
                  _SocialCard(
                    platform: 'Steam',
                    nickname: targetUser.username,
                    bgColor: _colorSteam,
                    borderColor: _border,
                    iconColor: _colorSteamTxt,
                    icon: Icons.videogame_asset,
                    isOwnProfile: isOwnProfile,
                  ),
                  const SizedBox(height: 10),
                  _SocialCard(
                    platform: 'Epic Games',
                    nickname: targetUser.username,
                    bgColor: _colorEpic,
                    borderColor: _border,
                    iconColor: Colors.white,
                    icon: Icons.games_rounded,
                    isOwnProfile: isOwnProfile,
                  ),
                  const SizedBox(height: 10),
                  _SocialCard(
                    platform: 'Nintendo',
                    nickname: 'SW-1234-5678-9012',
                    bgColor: _colorNintendo.withValues(alpha: 0.15),
                    borderColor: _colorNintendo.withValues(alpha: 0.3),
                    iconColor: _colorNintendo,
                    icon: Icons.gamepad_rounded,
                    isOwnProfile: isOwnProfile,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileHeader
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final SocialUser user;

  @override
  Widget build(BuildContext context) {
    final cfg = user.reputationConfig;

    return Column(
      children: [
        // Avatar grande
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: user.avatarBgColor ?? const Color(0xFF252525),
            border: Border.all(color: cfg.color, width: 3),
            boxShadow: [
              BoxShadow(
                color: cfg.color.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
            image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(user.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
              ? Center(
                  child: Text(
                    user.initials ?? user.username[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),

        // Nombre de usuario
        Text(
          user.username,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        // Etiqueta de reputación
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cfg.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cfg.color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 14, color: cfg.color),
              const SizedBox(width: 4),
              Text(
                user.reputationLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cfg.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SocialCard
// ─────────────────────────────────────────────────────────────────────────────

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.platform,
    required this.nickname,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.isOwnProfile,
  });

  final String platform;
  final String nickname;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final bool isOwnProfile;

  void _handleTap(BuildContext context) {
    if (isOwnProfile) {
      // Lógica de edición
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Editando $platform...'),
          backgroundColor: _bgCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // Lógica de solo lectura: copiar al portapapeles
      Clipboard.setData(ClipboardData(text: nickname));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Nickname copiado!'),
          backgroundColor: Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: iconColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isOwnProfile ? Icons.edit_rounded : Icons.copy_rounded,
              size: 18,
              color: isOwnProfile ? _textSub : iconColor.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
