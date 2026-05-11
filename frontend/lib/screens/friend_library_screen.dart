// =============================================================================
// friend_library_screen.dart — Bound2Game Flutter
//
// Muestra "Juegos que le gustan a [Username]" cargando la biblioteca pública
// del amigo desde GET /api/users/:friendId/library-public (JWT requerido).
// Al pulsar un juego navega a GameDetailScreen.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/game_model.dart' hide User;
import '../services/api_service.dart';
import 'game_detail_screen.dart';

// ── Paleta de colores (coherente con el resto de la app) ──────────────────────
const _bg       = Color(0xFF292929);
const _bgCard   = Color(0xFF1A1A1A);
const _border   = Color(0xFF252525);
const _textMain = Colors.white;
const _textSub  = Color(0xFF888888);
const _cyan     = Color(0xFF00E5FF);
const _yellow   = Color(0xFFFFB800);

class FriendLibraryScreen extends StatefulWidget {
  const FriendLibraryScreen({super.key, required this.friend});

  /// Amigo cuya biblioteca vamos a mostrar.
  final User friend;

  @override
  State<FriendLibraryScreen> createState() => _FriendLibraryScreenState();
}

class _FriendLibraryScreenState extends State<FriendLibraryScreen> {
  late Future<List<ApiGame>> _libraryFuture;

  @override
  void initState() {
    super.initState();
    _libraryFuture = ApiService.getFriendLibrary(widget.friend.id);
  }

  void _retry() => setState(() {
        _libraryFuture = ApiService.getFriendLibrary(widget.friend.id);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Juegos de ${widget.friend.username}',
              style: const TextStyle(
                color: _textMain,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Biblioteca del amigo',
              style: TextStyle(color: _textSub, fontSize: 11),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<ApiGame>>(
        future: _libraryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _cyan, strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          }

          final games = snapshot.data ?? [];

          if (games.isEmpty) {
            return _EmptyState(username: widget.friend.username);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${games.length} juego${games.length == 1 ? '' : 's'} en su biblioteca',
                    style: const TextStyle(color: _textSub, fontSize: 12),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _GameTile(game: games[index]),
                    childCount: games.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile de juego — navega a GameDetailScreen al pulsar
// ─────────────────────────────────────────────────────────────────────────────

class _GameTile extends StatefulWidget {
  const _GameTile({required this.game});
  final ApiGame game;

  @override
  State<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<_GameTile> {
  bool _pressed = false;

  void _openDetail() {
    // Convertir ApiGame → Game mínimo para pasar a GameDetailScreen
    final g = Game(
      id:       widget.game.id.hashCode,
      entryId:  widget.game.entryId,
      title:    widget.game.title,
      platform: Platform.steam,
      genre:    '',
      playtime: 0,
      status:   GameStatus.unplayed,
      cover:    widget.game.coverUrl,
      pcReq:    PcReq.yellow,
      hasCosmetics: false,
      price:    double.tryParse(widget.game.currentPrice ?? '0') ?? 0,
      year:     0,
      hltb: widget.game.hltbMainStory != null
          ? HltbTimes(main: widget.game.hltbMainStory!.toInt())
          : null,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameDetailScreen(baseGame: g)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _openDetail();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFF222222) : _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed ? _yellow.withValues(alpha: 0.35) : _border,
          ),
        ),
        child: Row(
          children: [
            // Portada
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
              child: Image.network(
                widget.game.coverUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFF111111),
                  child: const Icon(Icons.videogame_asset_rounded,
                      color: Color(0xFF333333), size: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game.title,
                      style: const TextStyle(
                        color: _textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.game.hltbMainStory != null)
                      Text(
                        '~${widget.game.hltbMainStory!.toStringAsFixed(0)}h historia principal',
                        style: const TextStyle(color: _textSub, fontSize: 11),
                      ),
                    if (widget.game.status != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _StatusBadge(status: widget.game.status!),
                      ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.chevron_right_rounded, color: Color(0xFF444444), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge de estado del juego (Backlog / Playing / Completed / Abandoned)
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _color {
    switch (status) {
      case 'Playing':   return const Color(0xFF4A6CF7);
      case 'Completed': return const Color(0xFF4AF626);
      case 'Abandoned': return const Color(0xFFFF4040);
      default:          return const Color(0xFF888888);
    }
  }

  String get _label {
    switch (status) {
      case 'Playing':   return 'Jugando';
      case 'Completed': return 'Completado';
      case 'Abandoned': return 'Abandonado';
      default:          return 'Backlog';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados de error y vacío
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: _textSub, size: 48),
            const SizedBox(height: 16),
            Text(
              message.contains('403')
                  ? 'Solo puedes ver la biblioteca de tus amigos'
                  : 'Error al cargar la biblioteca',
              style: const TextStyle(color: _textSub, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar', style: TextStyle(color: _cyan)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videogame_asset_off_rounded, color: _cyan, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              '$username no tiene juegos en su biblioteca',
              style: const TextStyle(
                color: _textMain,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
