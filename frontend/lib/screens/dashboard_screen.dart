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
import '../models/user_model.dart';
import '../models/game_model.dart' as gm;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'game_detail_screen.dart';
import 'library_screen.dart';

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

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onNavigate});
  final ValueChanged<int>? onNavigate;

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  // Datos del usuario autenticado (cargados al init)
  String? _userId;
  Future<_DashboardData>? _future;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userId = user.id;
        _future = _fetchDashboard(user.id);
      });
    }
  }

  Future<_DashboardData> _fetchDashboard(String userId) async {
    final results = await Future.wait([
      ApiService.getLibrary(userId),
      ApiService.getStats(userId),
      ApiService.fetchFriends(),
    ]);
    return _DashboardData(
      games: results[0] as List<ApiGame>,
      stats: results[1] as LibraryStats,
      friends: results[2] as List<User>,
    );
  }

  void reloadDashboard() {
    if (!mounted) return;
    if (_userId != null) {
      setState(() {
        _future = _fetchDashboard(_userId!);
      });
    } else {
      _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_future == null) {
      // Todavía cargando el userId de SharedPreferences
      return const Center(
        child: CircularProgressIndicator(color: _kYellow, strokeWidth: 2),
      );
    }

    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _kYellow, strokeWidth: 2),
          );
        }
        if (snapshot.hasError) {
          return _ErrorState(error: snapshot.error.toString(), onRetry: reloadDashboard);
        }

        final data        = snapshot.data!;
        final recentGames = data.games.take(4).toList();
        final stats       = data.stats;
        final onlineUsers = data.friends.where((u) => u.isOnline).take(4).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            const _SectionLabel(text: 'MIS ESTADÍSTICAS'),
            const SizedBox(height: 12),
            _StatsGrid(stats: stats),
            const SizedBox(height: 32),

            _SectionHeader(
              title: 'Juegos Recientes',
              actionLabel: 'Ver biblioteca',
              onTap: () => widget.onNavigate?.call(1),
            ),
            const SizedBox(height: 14),

            if (recentGames.isEmpty)
              const _EmptyLibraryHint()
            else
              _RecentGamesGrid(games: recentGames),

            const SizedBox(height: 32),
            _SectionHeader(
              title: 'Usuarios activos',
              actionLabel: 'Ver comunidad',
              onTap: () => widget.onNavigate?.call(3),
            ),
            const SizedBox(height: 14),
            _ActiveUsersList(users: onlineUsers),
          ],
        );
      },
    );
  }
}

// Agregado de datos del dashboard
class _DashboardData {
  final List<ApiGame>  games;
  final LibraryStats   stats;
  final List<User>     friends;
  const _DashboardData({required this.games, required this.stats, required this.friends});
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
  const _StatsGrid({required this.stats});
  final LibraryStats stats;

  @override
  Widget build(BuildContext context) {
    final data = [
      _StatData(value: '${stats.total}',          description: 'Juegos en biblioteca'),
      _StatData(value: '${stats.estimatedHours}', description: 'Horas jugadas'),
      _StatData(value: '${stats.completed}',      description: 'Completados'),
      _StatData(value: '${stats.backlog}',         description: 'Pendientes'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: data.length,
      itemBuilder: (_, i) => _StatCard(stat: data[i]),
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
  final List<ApiGame> games;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 3 / 4,
      ),
      itemCount: games.length,
      itemBuilder: (context, i) => _ApiGameCard(game: games[i]),
    );
  }
}

class _ApiGameCard extends StatelessWidget {
  const _ApiGameCard({required this.game});
  final ApiGame game;

  @override
  Widget build(BuildContext context) {
    // Usar la misma función que la biblioteca para mantener la coherencia
    // en plataformas, horas jugadas reales, etc.
    final gm.Game localGame = LibraryScreenState.apiGameToLocal(game);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameDetailScreen(
              baseGame: localGame,
              entryId: game.entryId,
            ),
          ),
        ).then((_) {
          context.findAncestorStateOfType<DashboardScreenState>()?.reloadDashboard();
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(color: _kBgCard, border: Border.all(color: _kBorder)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                game.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _kBgCard,
                  child: const Icon(Icons.sports_esports_rounded, color: _kBorder, size: 40),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: _kBgCard,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kYellow)),
                  );
                },
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Color(0xE6000000), Color(0x4D000000), Colors.transparent],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(game.title,
                          style: GoogleFonts.inter(fontSize: 11, color: _kWhite,
                              fontWeight: FontWeight.w600, height: 1.3),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (game.status != null) ...[
                        const SizedBox(height: 3),
                        _StatusBadge(status: game.status!),
                      ],
                      if (localGame.playtime > 0) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.schedule_rounded, size: 9, color: _kMuted),
                          const SizedBox(width: 2),
                          Text('${localGame.playtime}h',
                              style: GoogleFonts.inter(fontSize: 9, color: _kMuted)),
                        ]),
                      ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  Color get _color { switch (status) {
    case 'Playing':   return const Color(0xFF4A6CF7);
    case 'Completed': return const Color(0xFF4AF626);
    case 'Abandoned': return const Color(0xFFFF4040);
    default:          return const Color(0xFF8E8E8E);
  }}
  String get _label { switch (status) {
    case 'Playing':   return 'Jugando';
    case 'Completed': return 'Completado';
    case 'Abandoned': return 'Abandonado';
    default:          return 'Pendiente';
  }}
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(_label, style: GoogleFonts.inter(fontSize: 8, color: _color, fontWeight: FontWeight.w600)),
    );
  }
}

// Widget: biblioteca vacia (usuario nuevo)
class _EmptyLibraryHint extends StatelessWidget {
  const _EmptyLibraryHint();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kBgCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.library_add_rounded, color: _kYellow, size: 32),
        const SizedBox(height: 12),
        Text('Tu biblioteca está vacía',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _kWhite),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Busca un juego y áñadelo para empezar.',
            style: GoogleFonts.inter(fontSize: 11, color: _kMuted),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// Widget: estado de error con botono de reintentar
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: _kMuted, size: 40),
        const SizedBox(height: 16),
        Text('No se pudo conectar', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: _kWhite)),
        const SizedBox(height: 8),
        Text(error, style: GoogleFonts.inter(fontSize: 11, color: _kMuted), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _kYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kYellow.withValues(alpha: 0.4)),
            ),
            child: Text('Reintentar', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _kYellow)),
          ),
        ),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE USERS LIST — Solo usuarios online, navegan al Chat
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveUsersList extends StatelessWidget {
  const _ActiveUsersList({required this.users});
  final List<User> users;

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
  final User user;

  @override
  Widget build(BuildContext context) {
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
                    border: Border.all(color: _kYellow, width: 2),
                    color: user.avatarBgColor,
                  ),
                  child: user.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, e) =>
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
                  Text(
                    user.username,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _kWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'En línea ahora',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: kOnlineGreen,
                      fontWeight: FontWeight.w500,
                    ),
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
