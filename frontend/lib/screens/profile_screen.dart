// =============================================================================
// profile_screen.dart — Bound2Game Flutter
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/game_model.dart' hide User;
import '../services/api_service.dart';

// ── Constantes de color ───────────────────────────────────────────────────────
const _bg        = Color(0xFF292929);
const _bgCard    = Color(0xFF1A1A1A);
const _border    = Color(0xFF252525);
const _textMain  = Colors.white;
const _textSub   = Color(0xFF888888);
const _yellow    = Color(0xFFFFB800);
const _green     = Color(0xFF4AF626);
const _cyan      = Color(0xFF00E5FF);

// Colores de plataformas
const _colorDiscord  = Color(0xFF5865F2);
const _colorSteam    = Color(0xFF1B2838);
const _colorSteamTxt = Color(0xFF66C0F4);
const _colorEpic     = Color(0xFF2A2A2A);
const _colorXbox     = Color(0xFF107C10);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.isOwnProfile,
    this.user,
  });

  final bool isOwnProfile;
  final User? user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    if (widget.isOwnProfile) {
      _profileFuture = ApiService.fetchMyProfile();
    } else {
      _profileFuture = Future.value(widget.user!);
    }
  }

  // Permite refrescar desde el pull-to-refresh
  Future<void> _refresh() async {
    setState(() {
      _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: widget.isOwnProfile
          ? null
          : AppBar(
              backgroundColor: _bg,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: const BackButton(color: _textMain),
            ),
      body: FutureBuilder<User>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _cyan, strokeWidth: 2),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: _textSub, size: 48),
                  const SizedBox(height: 16),
                  Text('Error al cargar perfil', style: TextStyle(color: _textSub)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Reintentar', style: TextStyle(color: _cyan)),
                  )
                ],
              ),
            );
          }

          final user = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: _refresh,
            color: _cyan,
            backgroundColor: _bgCard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // ── Cabecera: Avatar, Nombre y Estado ──────────────────────────
                  _ProfileHeader(user: user),
                  const SizedBox(height: 32),

                  // ── Bio ────────────────────────────────────────────────────────
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const _SectionTitle(title: 'Sobre mí'),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        user.bio!,
                        style: const TextStyle(fontSize: 14, color: _textSub, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Componentes PC (Real de MongoDB) ───────────────────────────
                  if (user.pcComponents.isNotEmpty) ...[
                    const _SectionTitle(title: 'Mi Equipo (PC)'),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PcSpecsGrid(specs: user.pcComponents),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Estadísticas Clave ─────────────────────────────────────────
                  const _SectionTitle(title: 'Estadísticas Clave'),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _KeyStatsGrid(user: user),
                  ),
                  const SizedBox(height: 32),

                  // ── Juegos Top (Mock por ahora, a la espera de la librería) ────
                  const _SectionTitle(title: 'Juegos más jugados'),
                  const SizedBox(height: 12),
                  _TopGamesList(),
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
                          nickname: user.username,
                          bgColor: _colorSteam,
                          iconColor: _colorSteamTxt,
                          icon: Icons.videogame_asset,
                          isOwnProfile: widget.isOwnProfile,
                        ),
                        const SizedBox(height: 10),
                        _PlatformCard(
                          platform: 'Epic Games',
                          nickname: user.username,
                          bgColor: _colorEpic,
                          iconColor: Colors.white,
                          icon: Icons.games_rounded,
                          isOwnProfile: widget.isOwnProfile,
                        ),
                        const SizedBox(height: 10),
                        _PlatformCard(
                          platform: 'Xbox Live',
                          nickname: '${user.username}#77',
                          bgColor: _colorXbox.withValues(alpha: 0.15),
                          iconColor: _colorXbox,
                          icon: Icons.gamepad_rounded,
                          isOwnProfile: widget.isOwnProfile,
                        ),
                        const SizedBox(height: 10),
                        _PlatformCard(
                          platform: 'Discord',
                          nickname: '${user.username}#1234',
                          bgColor: _colorDiscord.withValues(alpha: 0.15),
                          iconColor: _colorDiscord,
                          icon: Icons.discord,
                          isOwnProfile: widget.isOwnProfile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
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
  final User user;

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
            color: user.avatarBgColor,
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
                    user.initials,
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
// _PcSpecsGrid
// ─────────────────────────────────────────────────────────────────────────────

class _PcSpecsGrid extends StatelessWidget {
  const _PcSpecsGrid({required this.specs});
  final Map<String, dynamic> specs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _PcSpecRow(icon: Icons.memory_rounded, label: 'CPU', value: specs['cpu']?.toString() ?? '-'),
          const Divider(color: _border, height: 24),
          _PcSpecRow(icon: Icons.developer_board_rounded, label: 'GPU', value: specs['gpu']?.toString() ?? '-'),
          const Divider(color: _border, height: 24),
          _PcSpecRow(icon: Icons.sd_storage_rounded, label: 'RAM', value: '${specs['ram'] ?? '-'} GB'),
          const Divider(color: _border, height: 24),
          _PcSpecRow(icon: Icons.storage_rounded, label: 'Storage', value: specs['storage']?.toString() ?? '-'),
        ],
      ),
    );
  }
}

class _PcSpecRow extends StatelessWidget {
  const _PcSpecRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _cyan),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textSub, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'No especificado' : value,
            style: const TextStyle(fontSize: 13, color: _textMain, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
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
  final User user;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          children: [
            _StatCard(
              icon: Icons.group_rounded,
              title: 'Amigos',
              value: '${user.friends.length}',
            ),
            _StatCard(
              icon: Icons.stars_rounded,
              title: 'Karma',
              value: '${user.karma}',
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
  @override
  Widget build(BuildContext context) {
    final topGames = sampleGames.take(10).toList();
    
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: topGames.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Editando $platform...'),
          backgroundColor: _bgCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
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
                      color: iconColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nickname,
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
              color: isOwnProfile ? _textSub : iconColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
