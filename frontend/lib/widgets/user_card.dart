// =============================================================================
// user_card.dart — Bound2Game Flutter (Android)
// Fuente: Social.tsx → UserCard / PlayerCard component
//
// Widget reutilizable para mostrar un jugador de la comunidad.
// Usado en: SocialScreen (lista de amigos), futura GlobalSearch.
//
// Variantes:
//   [UserCard]          → Tarjeta compacta para ListView (modo list)
//   [UserCardExpanded]  → Tarjeta con tags y más info (modo matchmaking)
// =============================================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';

// ── Constantes de color ───────────────────────────────────────────────────────
const _bgCard  = Color(0xFF181818);
const _bgCard2 = Color(0xFF1C1C1C);
const _border  = Color(0xFF252525);
const _textMain  = Color(0xFFD1D1D1);
const _textMuted = Color(0xFF555555);
const _textSub   = Color(0xFF888888);
const _cyan    = Color(0xFF00E5FF);
const _green   = Color(0xFF4AF626);
const _yellow  = Color(0xFFFFB800);
const _purple  = Color(0xFF7B61FF);

// =============================================================================
// UserCard — Tarjeta compacta (modo lista)
// =============================================================================

/// Tarjeta compacta de jugador para usar en ListView.builder.
///
/// Muestra: avatar con dot de estado online, nombre, badge de reputación,
/// nivel, juegos en común y acción de contacto.
///
/// Diseñada para reutilizarse en la búsqueda global y otras pantallas.
class UserCard extends StatefulWidget {
  const UserCard({
    super.key,
    required this.user,
    this.onTap,
    this.onConnect,
  });

  final SocialUser user;

  /// Navegar al perfil del usuario.
  final VoidCallback? onTap;

  /// Acción de conectar/añadir amigo.
  final VoidCallback? onConnect;

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final repCfg = widget.user.reputationConfig;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isPressed ? const Color(0xFF1F1F1F) : _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isPressed
                ? repCfg.color.withValues(alpha: 0.25)
                : _border,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: repCfg.color.withValues(alpha: 0.06),
                    blurRadius: 12,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // ── Avatar con dot de online ─────────────────────────────────────
            _UserAvatar(user: widget.user, repColor: repCfg.color),
            const SizedBox(width: 12),

            // ── Info principal ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username + score
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.user.username,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Score de reputación
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.user.reputationScore.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textSub,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Badge de reputación
                  _ReputationBadge(user: widget.user),
                  const SizedBox(height: 6),

                  // Meta: nivel + juegos en común + amigos mutuos
                  Row(
                    children: [
                      _MetaChip(
                        icon: Icons.military_tech_rounded,
                        label: 'Nv.${widget.user.level}',
                        color: _yellow,
                      ),
                      const SizedBox(width: 6),
                      _MetaChip(
                        icon: Icons.sports_esports_rounded,
                        label: '${widget.user.commonGames} en común',
                        color: _cyan,
                      ),
                      const SizedBox(width: 6),
                      if (widget.user.mutualFriends > 0)
                        _MetaChip(
                          icon: Icons.people_rounded,
                          label: '${widget.user.mutualFriends}',
                          color: _purple,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Botón de conectar ────────────────────────────────────────────
            _ConnectButton(
              onTap: widget.onConnect,
              repColor: repCfg.color,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// UserCardExpanded — Tarjeta con tags y afinidad (modo matchmaking)
// =============================================================================

/// Tarjeta expandida para la sección de Alta Afinidad.
/// Incluye barra de afinidad, tags y juegos en común.
class UserCardExpanded extends StatelessWidget {
  const UserCardExpanded({
    super.key,
    required this.user,
    this.onTap,
    this.onConnect,
  });

  final SocialUser user;
  final VoidCallback? onTap;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    final repCfg = user.reputationConfig;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: repCfg.color.withValues(alpha: 0.2)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              repCfg.color.withValues(alpha: 0.04),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar + nombre
            Row(
              children: [
                _UserAvatar(user: user, repColor: repCfg.color, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textMain,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      _ReputationBadge(user: user),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra de afinidad
            _AffinityBar(score: user.affinityScore),
            const SizedBox(height: 10),

            // Tags de personalidad (máx 2)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: user.tags
                  .take(2)
                  .map((tag) => _TagChip(label: tag))
                  .toList(),
            ),
            const SizedBox(height: 10),

            // Juegos en común (primero 2)
            if (user.commonGameTitles.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Juegos en común:',
                    style: TextStyle(fontSize: 9, color: _textSub),
                  ),
                  const SizedBox(height: 3),
                  ...user.commonGameTitles.take(2).map(
                        (title) => Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 4,
                                color: _cyan,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: _textSub,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            const SizedBox(height: 10),

            // Botón de invitar
            SizedBox(
              width: double.infinity,
              height: 32,
              child: OutlinedButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.person_add_rounded, size: 13),
                label: const Text(
                  'Invitar',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: repCfg.color,
                  side: BorderSide(color: repCfg.color.withValues(alpha: 0.4)),
                  backgroundColor: repCfg.color.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Sub-widgets reutilizables internos
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// _UserAvatar — Avatar con borde de reputación y dot de online
// ─────────────────────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.user,
    required this.repColor,
    this.size = 48,
  });

  final SocialUser user;
  final Color repColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Círculo del avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: repColor, width: 2),
            color: user.avatarBgColor ?? _bgCard2,
          ),
          child: user.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    user.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, _) =>
                        _InitialsContent(user: user, size: size),
                  ),
                )
              : _InitialsContent(user: user, size: size),
        ),
        // Dot de estado online/offline
        Positioned(
          bottom: -1,
          right: -1,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: user.isOnline ? _green : _textMuted,
              shape: BoxShape.circle,
              border: Border.all(color: _bgCard, width: 2),
              boxShadow: user.isOnline
                  ? [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.5),
                        blurRadius: 5,
                      )
                    ]
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _InitialsContent extends StatelessWidget {
  const _InitialsContent({required this.user, required this.size});
  final SocialUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        user.initials ?? '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReputationBadge — Badge de reputación con color del sistema de karma
// ─────────────────────────────────────────────────────────────────────────────

class _ReputationBadge extends StatelessWidget {
  const _ReputationBadge({required this.user});
  final SocialUser user;

  @override
  Widget build(BuildContext context) {
    final cfg = user.reputationConfig;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cfg.background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: cfg.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        user.reputationLabel,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: cfg.color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MetaChip — Chip de metadato compacto (ícono + texto)
// ─────────────────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ConnectButton — Botón circular de acción
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({this.onTap, required this.repColor});
  final VoidCallback? onTap;
  final Color repColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: repColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: repColor.withValues(alpha: 0.3)),
        ),
        child: Icon(
          Icons.person_add_rounded,
          size: 16,
          color: repColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AffinityBar — Barra de afinidad animada
// ─────────────────────────────────────────────────────────────────────────────

class _AffinityBar extends StatefulWidget {
  const _AffinityBar({required this.score});
  final int score;

  @override
  State<_AffinityBar> createState() => _AffinityBarState();
}

class _AffinityBarState extends State<_AffinityBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(begin: 0, end: widget.score / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    Future.delayed(
      const Duration(milliseconds: 300),
      () { if (mounted) _ctrl.forward(); },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Color de la barra según puntuación
    final Color barColor = widget.score >= 80
        ? _green
        : widget.score >= 50
            ? _cyan
            : _yellow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Afinidad',
              style: const TextStyle(fontSize: 9, color: _textSub),
            ),
            Text(
              '${widget.score}%',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => LinearProgressIndicator(
                value: _anim.value,
                backgroundColor: const Color(0xFF2A2A2A),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TagChip — Chip de tag de personalidad
// ─────────────────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          color: _textSub,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
