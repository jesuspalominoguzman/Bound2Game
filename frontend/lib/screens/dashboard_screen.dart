// =============================================================================
// dashboard_screen.dart — Bound2Game Flutter (Android)
// Fuente: Dashboard.tsx (InterfazdeusuarioBound2game - CORRECTO)
// =============================================================================

import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../widgets/platform_badge.dart';
import '../widgets/reputation_badge.dart';
import '../widgets/pc_req_dot.dart';

// ── Constantes de color (extraídas del CSS de Dashboard.tsx) ─────────────────
const _bgCard    = Color(0xFF181818);
const _bgCard2   = Color(0xFF1C1C1C);
const _border    = Color(0xFF252525);
const _textMain  = Color(0xFFD1D1D1);
const _textMuted = Color(0xFF555555);
const _textSub   = Color(0xFF888888);
const _cyan      = Color(0xFF00E5FF);
const _green     = Color(0xFF4AF626);
const _yellow    = Color(0xFFFFB800);
const _purple    = Color(0xFF7B61FF);
const _red       = Color(0xFFFF4040);

// ── Datos locales del Dashboard ───────────────────────────────────────────────

final _stats = [
  _StatData(label: 'Juegos en biblioteca', value: '142',   icon: Icons.sports_esports_rounded, color: _cyan),
  _StatData(label: 'Horas jugadas',        value: '1.847', icon: Icons.schedule_rounded,       color: _green),
  _StatData(label: 'Juegos completados',   value: '38',    icon: Icons.emoji_events_rounded,   color: _yellow),
  _StatData(label: 'Amigos activos',       value: '24',    icon: Icons.people_rounded,         color: _purple),
];

final _quickActions = [
  _QuickAction(label: 'Encontrar Grupo', icon: Icons.people_rounded,          color: _cyan,   tabIndex: 2),
  _QuickAction(label: 'Elegir Juego',    icon: Icons.sports_esports_rounded,  color: _green,  tabIndex: 3),
  _QuickAction(label: 'Ver Backlog',     icon: Icons.monitor_rounded,         color: _yellow, tabIndex: 3),
];

final _specBars = [
  _SpecBar(label: 'CPU', value: 28),
  _SpecBar(label: 'GPU', value: 22),
  _SpecBar(label: 'RAM', value: 38),
  _SpecBar(label: 'SSD', value: 30),
];

class _StatData  { const _StatData({required this.label, required this.value, required this.icon, required this.color}); final String label, value; final IconData icon; final Color color; }
class _QuickAction { const _QuickAction({required this.label, required this.icon, required this.color, required this.tabIndex}); final String label; final IconData icon; final Color color; final int tabIndex; }
class _SpecBar   { const _SpecBar({required this.label, required this.value}); final String label; final int value; }

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onNavigate});

  /// Callback para cambiar de pestaña en MainLayout.
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final recentGames   = sampleGames.take(4).toList();
    final featuredUsers = sampleUsers.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _WelcomeBanner(),
        const SizedBox(height: 16),
        _StatsGrid(),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Juegos Recientes',
          actionLabel: 'Ver biblioteca',
          onTap: () => onNavigate?.call(1),
        ),
        const SizedBox(height: 12),
        _RecentGamesGrid(games: recentGames),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Miembros Destacados',
          actionLabel: 'Ver comunidad',
          onTap: () => onNavigate?.call(2),
        ),
        const SizedBox(height: 12),
        _CommunityList(users: featuredUsers),
        const SizedBox(height: 24),
        _SystemStatusCard(),
        const SizedBox(height: 16),
        _QuickActionsCard(onNavigate: onNavigate),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome Banner
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F2A), Color(0xFF0A2A1F), Color(0xFF101010)],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withOpacity(0.15)),
      ),
      child: Stack(
        children: [
          // Glow superior izquierdo
          Positioned(
            top: -30, left: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_cyan.withOpacity(0.12), Colors.transparent]),
              ),
            ),
          ),
          // Contenido
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bienvenido de vuelta,', style: TextStyle(fontSize: 12, color: _cyan)),
              const SizedBox(height: 4),
              const Text('NightSaber_X', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ReputationBadge(reputation: Reputation.legendary, label: '★ Leyenda de la Comunidad'),
                  const SizedBox(width: 8),
                  Text('Nv.87 · 4.9 ★', style: TextStyle(fontSize: 11, color: _textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 12, color: _textSub),
                    const SizedBox(width: 6),
                    Text('The Witcher 3 · Hace 2h · 3h jugadas',
                        style: TextStyle(fontSize: 11, color: _textSub)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid — 2 columnas (equivalente a grid-cols-2 en móvil)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stat.icon, size: 16, color: stat.color),
              Icon(Icons.trending_up_rounded, size: 12, color: _green),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
              const SizedBox(height: 3),
              Text(stat.label, style: TextStyle(fontSize: 10, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel, this.onTap});
  final String title, actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textMain)),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(actionLabel, style: TextStyle(fontSize: 12, color: _cyan)),
              Icon(Icons.chevron_right_rounded, size: 14, color: _cyan),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Games Grid — GridView.builder, aspecto 3:4, overlay con gradiente
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
        childAspectRatio: 3 / 4, // ratio 3:4 exacto del diseño original
      ),
      itemCount: games.length,
      itemBuilder: (_, i) => _GameCard(game: games[i]),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _bgCard,
          border: Border.all(color: _border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Portada del juego
            Image.network(
              game.cover,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _bgCard2,
                child: const Icon(Icons.sports_esports_rounded, color: _border, size: 40),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(color: _bgCard2,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _cyan)));
              },
            ),

            // PC Req dot — esquina superior derecha
            Positioned(
              top: 8, right: 8,
              child: PcReqDot(pcReq: game.pcReq),
            ),

            // Overlay gradiente inferior con info
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xD9000000), Color(0x4D000000), Colors.transparent],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(game.title,
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PlatformBadge(platform: game.platform),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 9, color: _textSub),
                            const SizedBox(width: 2),
                            Text('${game.playtime}h', style: TextStyle(fontSize: 9, color: _textSub)),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Community Members List
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityList extends StatelessWidget {
  const _CommunityList({required this.users});
  final List<User> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: users.map((u) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
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
    final repCfg = user.reputation.config;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: repCfg.color, width: 2),
                  color: user.avatarColor ?? _bgCard2,
                ),
                child: user.avatar != null
                    ? ClipOval(child: Image.network(user.avatar!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _InitialsAvatar(user: user)))
                    : _InitialsAvatar(user: user),
              ),
              // Dot de estado
              Positioned(
                bottom: -2, right: -2,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: repCfg.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bgCard, width: 2),
                    boxShadow: [BoxShadow(color: repCfg.color.withOpacity(0.6), blurRadius: 4)],
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
                    Text(user.name, style: const TextStyle(fontSize: 13, color: _textMain, fontWeight: FontWeight.w600)),
                    Row(children: [
                      Icon(Icons.star_rounded, size: 10, color: const Color(0xFFFFD700)),
                      const SizedBox(width: 2),
                      Text('${user.score}', style: TextStyle(fontSize: 11, color: _textSub)),
                    ]),
                  ],
                ),
                const SizedBox(height: 4),
                ReputationBadge(reputation: user.reputation, label: user.reputationLabel),
                const SizedBox(height: 4),
                Text('${user.commonGames} juegos en común · Nv.${user.level}',
                    style: TextStyle(fontSize: 10, color: _textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.user});
  final User user;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(user.initials ?? '?',
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// System Status Card — barras de specs PC + juego destacado
// ─────────────────────────────────────────────────────────────────────────────

class _SystemStatusCard extends StatelessWidget {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Icon(Icons.memory_rounded, size: 16, color: _cyan),
            const SizedBox(width: 8),
            const Text('Estado del Sistema', style: TextStyle(fontSize: 14, color: _textMain, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          // Imagen del juego con AspectRatio 16:7
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.network(
                'https://images.unsplash.com/photo-1633355194356-1a2b1995cc62?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=400',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: _bgCard2,
                    child: const Icon(Icons.sports_esports_rounded, color: _border)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Starfield', style: TextStyle(fontSize: 13, color: _textMain, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Último lanzamiento destacado', style: TextStyle(fontSize: 11, color: _textSub)),
          const SizedBox(height: 12),
          // Barras de specs
          ..._specBars.map((s) => _SpecBarRow(spec: s)),
          const SizedBox(height: 10),
          // Banner de no compatible
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _red.withOpacity(0.2)),
            ),
            child: const Text('✗ Tu PC no cumple los requisitos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: _red, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          // Botón de análisis
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: _cyan,
                side: BorderSide(color: _cyan.withOpacity(0.2)),
                backgroundColor: _cyan.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Ver análisis completo →', style: TextStyle(fontSize: 12, color: _cyan)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecBarRow extends StatefulWidget {
  const _SpecBarRow({required this.spec});
  final _SpecBar spec;
  @override
  State<_SpecBarRow> createState() => _SpecBarRowState();
}

class _SpecBarRowState extends State<_SpecBarRow> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween<double>(begin: 0, end: widget.spec.value / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.spec.label, style: TextStyle(fontSize: 11, color: _textSub)),
              Text('No compatible', style: TextStyle(fontSize: 11, color: _red)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 4,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => LinearProgressIndicator(
                  value: _anim.value,
                  backgroundColor: _border,
                  color: _red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Card
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({this.onNavigate});
  final ValueChanged<int>? onNavigate;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Acciones Rápidas',
              style: TextStyle(fontSize: 14, color: _textMain, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._quickActions.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _QuickActionButton(action: a, onNavigate: onNavigate),
          )),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action, this.onNavigate});
  final _QuickAction action;
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bgCard2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onNavigate?.call(action.tabIndex),
        borderRadius: BorderRadius.circular(10),
        splashColor: action.color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            children: [
              Icon(action.icon, size: 15, color: action.color),
              const SizedBox(width: 12),
              Text(action.label, style: const TextStyle(fontSize: 12, color: _textMain)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, size: 14, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
