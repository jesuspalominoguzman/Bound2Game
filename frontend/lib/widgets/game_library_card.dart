// =============================================================================
// game_library_card.dart — Bound2Game Flutter (Android)
// Fuente: Library.tsx → GameCard component
//
// Tarjeta de juego para el GridView de la biblioteca.
// Muestra: portada, badge de plataforma, dot de PC req, estado y título.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/game_model.dart';
import 'platform_badge.dart';
import 'pc_req_dot.dart';

// ── Constantes de color (alineadas con dashboard_screen.dart) ────────────────
const _bgCard    = Color(0xFF181818);
const _bgCard2   = Color(0xFF1C1C1C);
const _border    = Color(0xFF252525);
const _textSub   = Color(0xFF888888);
const _cyan      = Color(0xFF00E5FF);

// =============================================================================
// GameLibraryCard — Widget público reutilizable
// =============================================================================

/// Tarjeta de juego para el GridView de la Biblioteca.
///
/// Corresponde al `GameCard` de Library.tsx.
/// Diseñada para un grid de 2 columnas con ratio 3:4.
class GameLibraryCard extends StatefulWidget {
  const GameLibraryCard({super.key, required this.game, this.onTap});

  final Game game;
  final VoidCallback? onTap;

  @override
  State<GameLibraryCard> createState() => _GameLibraryCardState();
}

class _GameLibraryCardState extends State<GameLibraryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) {
        _hoverCtrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _hoverCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: _bgCard,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Portada del juego ───────────────────────────────────────
                _CoverImage(coverUrl: widget.game.cover),

                // ── PC Req Dot — esquina superior derecha ───────────────────
                Positioned(
                  top: 8,
                  right: 8,
                  child: PcReqDot(pcReq: widget.game.pcReq),
                ),

                // ── Badge de estado — esquina superior izquierda ────────────
                Positioned(
                  top: 8,
                  left: 8,
                  child: _StatusChip(status: widget.game.status),
                ),

                // ── Overlay gradiente inferior con título y plataforma ───────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _CardFooter(game: widget.game),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CoverImage — Imagen de portada con loading y error state
// ─────────────────────────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverUrl});
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: _bgCard2,
        child: const Center(
          child: Icon(
            Icons.sports_esports_rounded,
            color: _border,
            size: 40,
          ),
        ),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: _bgCard2,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _cyan,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusChip — Chip de estado del juego (Playing, Completed, etc.)
// Corresponde a los pills de estado en Library.tsx
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final GameStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: status.color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CardFooter — Overlay con gradiente, plataforma, título y horas
// ─────────────────────────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xE6000000), Color(0x80000000), Colors.transparent],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título del juego
          Text(
            game.title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          // Fila: plataforma + horas jugadas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo de plataforma (PlatformBadge existente)
              PlatformBadge(platform: game.platform),
              // Horas jugadas
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 9, color: _textSub),
                  const SizedBox(width: 2),
                  Text(
                    '${game.playtime}h',
                    style: const TextStyle(fontSize: 9, color: _textSub),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
