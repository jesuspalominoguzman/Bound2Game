// =============================================================================
// profile_screen.dart — Bound2Game Flutter
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import 'settings_screen.dart';

// ── Constantes de color ───────────────────────────────────────────────────────
const _bg        = Color(0xFF292929);
const _bgCard    = Color(0xFF1A1A1A);
const _border    = Color(0xFF252525);
const _textMain  = Colors.white;
const _textSub   = Color(0xFF888888);
const _yellow    = Color(0xFFFFB800);
const _green     = Color(0xFF4AF626);

// Colores de plataformas
const _colorDiscord  = Color(0xFF5865F2);
const _colorSteam    = Color(0xFF1B2838);
const _colorSteamTxt = Color(0xFF66C0F4);
const _colorEpic     = Color(0xFF2A2A2A);
const _colorXbox     = Color(0xFF107C10);

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
      appBar: isOwnProfile
          ? null
          : AppBar(
              backgroundColor: _bg,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: const BackButton(color: _textMain),
            ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // ── Cabecera: Avatar, Nombre y Estado ──────────────────────────
            _ProfileHeader(user: targetUser),
            const SizedBox(height: 32),

            // ── Estadísticas Clave ─────────────────────────────────────────
            const _SectionTitle(title: 'Estadísticas Clave'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _KeyStatsGrid(user: targetUser),
            ),
            const SizedBox(height: 32),

            // ── Juegos Top ─────────────────────────────────────────────────
            const _SectionTitle(title: 'Juegos más jugados'),
            const SizedBox(height: 12),
            _TopGamesList(user: targetUser),
            const SizedBox(height: 32),

            // ── Plataformas Vinculadas ─────────────────────────────────────
            const _SectionTitle(title: 'Plataformas Vinculadas'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _PlatformCard(
                    platform: 'Steam',
                    nickname: targetUser.username,
                    bgColor: _colorSteam,
                    iconColor: _colorSteamTxt,
                    icon: Icons.videogame_asset,
                    isOwnProfile: isOwnProfile,
                  ),
                  const SizedBox(height: 10),
                  _PlatformCard(
                    platform: 'Epic Games',
                    nickname: targetUser.username,
                    bgColor: _colorEpic,
                    iconColor: Colors.white,
                    icon: Icons.games_rounded,
                    isOwnProfile: isOwnProfile,
                  ),
                  const SizedBox(height: 10),
                  _PlatformCard(
                    platform: 'Xbox Live',
                    nickname: '${targetUser.username}#77',
                    bgColor: _colorXbox.withOpacity(0.15),
                    iconColor: _colorXbox,
                    icon: Icons.gamepad_rounded,
                    isOwnProfile: isOwnProfile,
                  ),
                  const SizedBox(height: 10),
                  _PlatformCard(
                    platform: 'Discord',
                    nickname: '${targetUser.username}#1234',
                    bgColor: _colorDiscord.withOpacity(0.15),
                    iconColor: _colorDiscord,
                    icon: Icons.discord,
                    isOwnProfile: isOwnProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textMain,
          ),
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
    return Column(
      children: [
        // Avatar grande
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: user.avatarBgColor ?? _border,
          ),
          child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    user.avatarUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    user.initials ?? user.username[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Nombre de usuario
        Text(
          user.username,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        // Estado de conexión
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: user.isOnline ? _green : _textSub,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              user.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: user.isOnline ? _green : _textSub,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _KeyStatsGrid
// ─────────────────────────────────────────────────────────────────────────────

class _KeyStatsGrid extends StatelessWidget {
  const _KeyStatsGrid({required this.user});
  final SocialUser user;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Un grid limpio 2x1 para Horas y Juegos
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2, // Tarjetas más anchas que altas
          children: [
            _StatCard(
              icon: Icons.timer_rounded,
              title: 'Horas Totales',
              value: '${(user.level * 15) + 120}h',
            ),
            _StatCard(
              icon: Icons.sports_esports_rounded,
              title: 'Juegos',
              value: '${user.commonGames + 15}',
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _yellow),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: _textSub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textMain,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopGamesList
// ─────────────────────────────────────────────────────────────────────────────

class _TopGamesList extends StatelessWidget {
  const _TopGamesList({required this.user});
  final SocialUser user;

  @override
  Widget build(BuildContext context) {
    // Tomamos hasta 10 juegos
    final topGames = sampleGames.take(10).toList();
    
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: topGames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final game = topGames[index];
          return Container(
            width: 85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _bgCard,
              image: DecorationImage(
                image: NetworkImage(game.cover),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: _border),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlatformCard
// ─────────────────────────────────────────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.nickname,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    required this.isOwnProfile,
  });

  final String platform;
  final String nickname;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final bool isOwnProfile;

  void _handleTap(BuildContext context) {
    if (isOwnProfile) {
      // Editar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Editando $platform...'),
          backgroundColor: _bgCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Copiar ID al portapapeles
      Clipboard.setData(ClipboardData(text: nickname));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID copiado al portapapeles'),
          backgroundColor: _bgCard,
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
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
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
                      color: iconColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOwnProfile ? nickname : nickname, // Mostrar siempre el ID
                    style: const TextStyle(
                      fontSize: 14,
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
              color: isOwnProfile ? _textSub : iconColor.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }
}
