// =============================================================================
// user_profile_screen.dart — Bound2Game Flutter
//
// Pantalla de perfil público de un usuario.
// Muestra avatar, karma, juegos recientes y botón "Ver biblioteca completa".
// Paleta: negro (#1A1A1A) + amarillo (#FFB800)
// =============================================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/game_model.dart' hide User;
import '../services/api_service.dart';
import 'friend_library_screen.dart';
import 'game_detail_screen.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _bg       = Color(0xFF121212);
const _bgCard   = Color(0xFF1A1A1A);
const _bgCard2  = Color(0xFF222222);
const _border   = Color(0xFF2A2A2A);
const _yellow   = Color(0xFFFFB800);
const _yellowDim = Color(0x33FFB800);
const _textMain = Colors.white;
const _textSub  = Color(0xFF888888);

// =============================================================================
// Pantalla principal
// =============================================================================

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.user});
  final User user;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<List<ApiGame>> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = ApiService.getUserLibraryPreview(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar con avatar grande ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _bg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _yellow.withValues(alpha: 0.15),
                      _bg,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Avatar
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: u.avatarBgColor,
                        border: Border.all(color: _yellow, width: 3),
                        boxShadow: [
                          BoxShadow(color: _yellow.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
                        ],
                      ),
                      child: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                          ? ClipOval(child: Image.network(u.avatarUrl!, fit: BoxFit.cover))
                          : Center(child: Text(u.initials,
                              style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(height: 12),
                    Text(u.username,
                      style: const TextStyle(color: _textMain, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    // Karma badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: _yellowDim,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _yellow.withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: _yellow, size: 14),
                        const SizedBox(width: 5),
                        Text('${u.karma} karma',
                          style: const TextStyle(color: _yellow, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── Bio (si existe) ──────────────────────────────────────────────
          if (u.bio != null && u.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote_rounded, color: _yellow, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(u.bio!,
                        style: const TextStyle(color: _textSub, fontSize: 13, height: 1.5))),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Sección: juegos recientes ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Juegos recientes',
                    style: TextStyle(color: _textMain, fontSize: 16, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FriendLibraryScreen(friend: widget.user),
                    )),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Ver biblioteca', style: TextStyle(
                          color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 14),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Grid de portadas o lista de juegos ────────────────────────────
          SliverToBoxAdapter(
            child: FutureBuilder<List<ApiGame>>(
              future: _previewFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: _yellow, strokeWidth: 2)),
                  );
                }

                final games = snap.data ?? [];

                if (games.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(children: [
                        const Icon(Icons.videogame_asset_off_rounded, color: _textSub, size: 36),
                        const SizedBox(height: 12),
                        Text('${u.username} no tiene juegos en su biblioteca',
                          style: const TextStyle(color: _textSub, fontSize: 13),
                          textAlign: TextAlign.center),
                      ]),
                    ),
                  );
                }

                // Mostrar hasta 4 carátulas en grid 2×2
                final preview = games.take(4).toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: preview.length,
                    itemBuilder: (ctx, i) => _GameCover(game: preview[i]),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// =============================================================================
// Portada de juego en el grid
// =============================================================================

class _GameCover extends StatefulWidget {
  const _GameCover({required this.game});
  final ApiGame game;

  @override
  State<_GameCover> createState() => _GameCoverState();
}

class _GameCoverState extends State<_GameCover> {
  bool _pressed = false;

  void _open() {
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameDetailScreen(baseGame: g)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); _open(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed ? _yellow.withValues(alpha: 0.7) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.6 : 0.35),
              blurRadius: _pressed ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.game.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: _bgCard2,
                  child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videogame_asset_rounded, color: Color(0xFF444444), size: 32),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(widget.game.title,
                          style: const TextStyle(color: _textSub, fontSize: 11),
                          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  )),
                ),
              ),
              // Gradiente inferior con título
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent],
                    ),
                  ),
                  child: Text(widget.game.title,
                    style: const TextStyle(color: _textMain, fontSize: 11, fontWeight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
