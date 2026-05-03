// =============================================================================
// dashboard_screen.dart — Bound2Game Flutter (Android)
//
// HomeScreen refactorizado. Principio "Menos es Más":
//   - Eliminados: WelcomeBanner, SystemStatusCard, QuickActionsCard.
//   - Protagonismo absoluto de los 4 StatCards (parrilla grande).
//   - Paleta: fondo #292929, tarjetas #1A1A1A, acento #FFB800.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';
import '../widgets/platform_badge.dart';
import '../widgets/pc_req_dot.dart';
import 'game_detail_screen.dart';
import 'chat_screen.dart';

// ── Paleta local (identidad visual definitiva) ────────────────────────────────
const _kBgCard   = Color(0xFF1A1A1A);
const _kBorder   = Color(0xFF2A2A2A);
const _kYellow   = Color(0xFFFFB800);
const _kWhite    = Color(0xFFFFFFFF);
const _kMuted    = Color(0xFFAAAAAA);
const _kSub      = Color(0xFF666666);

// ── Modelo de dato para las estadísticas (simplificado: sin icono) ───────────
class _StatData {
  const _StatData({required this.value, required this.description});
  final String value;
  final String description;
}

// ── Datos de estadísticas — textos exactos del brief ─────────────────────────
const _stats = [
  _StatData(value: '142',   description: 'Juegos en local'),
  _StatData(value: '1.847', description: 'Horas jugadas'),
  _StatData(value: '38',    description: 'Juegos completados'),
  _StatData(value: '47',    description: 'Juegos pendientes'),
];

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final recentGames  = sampleGames.take(4).toList();
    // Solo amigos online para la sección "Usuarios activos"
    final onlineUsers  = mockUsers.where((u) => u.isOnline).take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── Encabezado de sección ──────────────────────────────────────────
        const _SectionLabel(text: 'MIS ESTADÍSTICAS'),
        const SizedBox(height: 12),

        // ── PROTAGONISTAS: Grid de estadísticas grande ─────────────────────
        const _StatsGrid(),
        const SizedBox(height: 32),

        // ── Juegos Recientes ───────────────────────────────────────────────
        _SectionHeader(
          title: 'Juegos Recientes',
          actionLabel: 'Ver biblioteca',
          onTap: () => onNavigate?.call(1),
        ),
        const SizedBox(height: 14),
        _RecentGamesGrid(games: recentGames),
        const SizedBox(height: 32),

        // ── Usuarios activos (solo online) ─────────────────────────────────
        _SectionHeader(
          title: 'Usuarios activos',
          actionLabel: 'Ver comunidad',
          onTap: () => onNavigate?.call(3),
        ),
        const SizedBox(height: 14),
        _ActiveUsersList(users: onlineUsers),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL — Etiqueta de categoría en mayúsculas
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: _kSub,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER — Título + acción "Ver más"
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onTap,
  });
  final String title;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kWhite,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                actionLabel,
                style: GoogleFonts.inter(fontSize: 12, color: _kYellow),
              ),
              const Icon(Icons.chevron_right_rounded, size: 14, color: _kYellow),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS GRID — 4 tarjetas protagonistas en 2 columnas
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4, // Más ancho que alto → sin overflow
      ),
      itemCount: _stats.length,
      itemBuilder: (_, i) => _StatCard(stat: _stats[i]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _StatData stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Valor numérico grande ────────────────────────────────────
              Text(
                stat.value,
                style: GoogleFonts.inter(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: _kWhite,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              // ── Descripción ──────────────────────────────────────────────
              Text(
                stat.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _kMuted,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT GAMES GRID — 2 columnas, aspecto 3:4
// ─────────────────────────────────────────────────────────────────────────────

class _RecentGamesGrid extends StatelessWidget {
  const _RecentGamesGrid({required this.games});
  final List<Game> games;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3 / 4,
      ),
      itemCount: games.length,
      itemBuilder: (context, i) => _GameCard(game: games[i]),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _kBgCard,
            border: Border.all(color: _kBorder),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Portada del juego
              Image.network(
                game.cover,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _kBgCard,
                  child: const Icon(Icons.sports_esports_rounded,
                      color: _kBorder, size: 40),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: _kBgCard,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kYellow,
                      ),
                    ),
                  );
                },
              ),

              // PC Req dot — esquina superior derecha
              Positioned(
                top: 8,
                right: 8,
                child: PcReqDot(pcReq: game.pcReq),
              ),

              // Overlay gradiente inferior con info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xE6000000), Color(0x4D000000), Colors.transparent],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.title,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _kWhite,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PlatformBadge(platform: game.platform),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 9, color: _kMuted),
                              const SizedBox(width: 2),
                              Text(
                                '${game.playtime}h',
                                style: GoogleFonts.inter(
                                    fontSize: 9, color: _kMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE USERS LIST — Solo usuarios online, navegan al Chat
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveUsersList extends StatelessWidget {
  const _ActiveUsersList({required this.users});
  final List<SocialUser> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: users.map((u) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _UserCard(user: u),
      )).toList(),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final SocialUser user;

  @override
  Widget build(BuildContext context) {
    final repCfg = user.reputation.config;
    // Indicador online: siempre verde ya que filtramos solo online
    const kOnlineGreen = Color(0xFF39FF7E);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(user: user)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            // Avatar con dot online
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: repCfg.color, width: 2),
                    color: user.avatarBgColor ?? _kBgCard,
                  ),
                  child: user.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, e) =>
                                _InitialsAvatar(initials: user.initials),
                          ),
                        )
                      : _InitialsAvatar(initials: user.initials),
                ),
                // Dot online verde
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kOnlineGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kBgCard, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: kOnlineGreen.withValues(alpha: 0.5),
                          blurRadius: 4,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user.username,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _kWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(children: [
                        const Icon(Icons.star_rounded, size: 11, color: _kYellow),
                        const SizedBox(width: 2),
                        Text(
                          '${user.reputationScore}',
                          style: GoogleFonts.inter(fontSize: 11, color: _kMuted),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.reputationLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: repCfg.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${user.commonGames} juegos en común · Nv.${user.level}',
                    style: GoogleFonts.inter(fontSize: 10, color: _kSub),
                  ),
                ],
              ),
            ),
            // Flecha de chat
            const Icon(Icons.chevron_right_rounded, size: 16, color: _kSub),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({this.initials});
  final String? initials;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          initials ?? '?',
          style: GoogleFonts.inter(
            color: _kWhite,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
