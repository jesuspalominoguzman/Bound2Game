// Esta es la pantalla social. Aquí es donde vemos a nuestros amigos, quién está conectado y qué juegos están pegando fuerte ahora mismo.
// La idea es que sea el centro de la comunidad de la app.

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/user_card.dart';
import '../services/api_service.dart';
import '../services/presence_service.dart';
import '../models/game_model.dart' as gm;
import 'user_search_delegate.dart';
import 'user_profile_screen.dart';
import 'game_detail_screen.dart';

// Mis colores para que todo quede conjuntado.
const _bg        = Color(0xFF292929);
const _bgCard    = Color(0xFF1A1A1A);
const _border    = Color(0xFF252525);
const _textMain  = Colors.white;
const _textSub   = Color(0xFF888888);
const _textMuted = Color(0xFF555555);
const _green     = Color(0xFF4AF626);
const _yellow    = Color(0xFFFFB800);

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchFocused = false;
  bool _showOnlineOnly = false;
  String _searchQuery = '';

  late Future<List<User>> _friendsFuture;
  late Future<List<UserSearchResult>> _pendingFuture;

  List<User> _friendsList = [];
  StreamSubscription<Map<String, dynamic>>? _presenceSub;

  @override
  void initState() {
    super.initState();
    // Al entrar, cargamos los datos y nos ponemos a escuchar los cambios de presencia en tiempo real.
    _loadData();

    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()),
    );
    _searchFocus.addListener(
      () => setState(() => _isSearchFocused = _searchFocus.hasFocus),
    );

    // Esto es clave: escuchamos al servidor por si alguien se conecta o desconecta.
    _presenceSub = PresenceService.instance.presenceUpdates.listen(_onPresenceUpdate);
  }

  // Si un amigo se conecta o se desconecta, actualizamos la lista al momento.
  void _onPresenceUpdate(Map<String, dynamic> data) {
    if (!mounted) return;
    final userId = data['userId'] as String?;
    final isOnline = data['isOnline'] as bool?;
    if (userId != null && isOnline != null) {
      setState(() {
        _friendsList = _friendsList.map((f) {
          if (f.id == userId) return f.copyWith(isOnline: isOnline);
          return f;
        }).toList();
      });
    }
  }

  // Cargamos los amigos y las solicitudes que tengamos pendientes.
  void _loadData() {
    _friendsFuture = ApiService.fetchFriends().then((friends) {
      if (mounted) setState(() => _friendsList = friends);
      return friends;
    });
    _pendingFuture = ApiService.getPendingRequests();
  }


  Future<void> _refresh() async {
    setState(_loadData);
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Abrimos el buscador para encontrar a gente nueva.
  void _openUserSearch() {
    showSearch(
      context: context,
      delegate: B2GUserSearchDelegate(),
    ).then((_) => setState(_loadData)); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // El botón para buscar jugadores.
      floatingActionButton: FutureBuilder<List<User>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          return FloatingActionButton(
            heroTag: 'social_search_fab',
            onPressed: () => _openUserSearch(),
            backgroundColor: _yellow,
            foregroundColor: Colors.black,
            elevation: 6,
            tooltip: 'Buscar jugadores',
            child: const Icon(Icons.person_search_rounded, size: 24),
          );
        },
      ),
      body: FutureBuilder<List<User>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _yellow, strokeWidth: 2),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: _textSub, size: 48),
                  const SizedBox(height: 16),
                  const Text('Error al cargar amigos', style: TextStyle(color: _textSub)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Reintentar', style: TextStyle(color: _yellow)),
                  )
                ],
              ),
            );
          }

          // Filtramos la lista según lo que escriba el usuario o si quiere ver solo a los conectados.
          final filtered = _friendsList.where((user) {
            final matchesSearch = _searchQuery.isEmpty ||
                user.username.toLowerCase().contains(_searchQuery);
            final matchesOnline = !_showOnlineOnly || user.isOnline;
            return matchesSearch && matchesOnline;
          }).toList();

          final onlineCount = _friendsList.where((u) => u.isOnline).length;


          return RefreshIndicator(
            onRefresh: _refresh,
            color: _yellow,
            backgroundColor: _bgCard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Aquí mostramos si alguien nos ha mandado una solicitud de amistad.
                SliverToBoxAdapter(
                  child: _PendingRequestsSection(
                    future: _pendingFuture,
                    onAction: () => setState(_loadData),
                  ),
                ),

                // Una sección chula que mira a qué están jugando mis amigos.
                SliverToBoxAdapter(
                  child: _PopularGamesSection(friends: _friendsList),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // La lista de amigos con su buscador y filtro.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tus Amigos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textMain,
                              ),
                            ),
                            Text(
                              '${filtered.length} encontrados',
                              style: const TextStyle(fontSize: 12, color: _textSub),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SocialSearchBar(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                isFocused: _isSearchFocused,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _OnlineToggleButton(
                              isActive: _showOnlineOnly,
                              count: onlineCount,
                              onTap: () => setState(() => _showOnlineOnly = !_showOnlineOnly),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Si no tenemos amigos o no coinciden con la búsqueda, mostramos un mensaje.
                _friendsList.isEmpty
                    ? SliverToBoxAdapter(
                        child: _NoFriendsState(),
                      )
                    : filtered.isEmpty
                        ? SliverToBoxAdapter(
                            child: _EmptySocialState(query: _searchQuery),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => UserCard(
                                  user: filtered[index],
                                  isFriend: true,
                                  onReturn: _refresh,
                                ),
                                childCount: filtered.length,
                              ),
                            ),
                          ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _textMain,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// Sección dinámica de juegos populares entre amigos
// ───────────────────────────────────────────────────────────────────────────────

// =============================================================================
// Sección de solicitudes de amistad pendientes — paleta amarillo/negro
// =============================================================================

class _PendingRequestsSection extends StatelessWidget {
  const _PendingRequestsSection({required this.future, required this.onAction});
  final Future<List<UserSearchResult>> future;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserSearchResult>>(
      future: future,
      builder: (ctx, snap) {
        // No mostrar nada mientras carga o si hay error
        if (snap.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        if (snap.hasError) return const SizedBox.shrink();
        final requests = snap.data ?? [];
        if (requests.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFB800),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.5)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.person_add_alt_1_rounded, color: _yellow, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${requests.length} solicitud${requests.length == 1 ? '' : 'es'} pendiente${requests.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: _yellow, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            ...requests.map((req) => _PendingRequestTile(
              request: req,
              onAction: onAction,
            )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _PendingRequestTile extends StatefulWidget {
  const _PendingRequestTile({required this.request, required this.onAction});
  final UserSearchResult request;
  final VoidCallback onAction;

  @override
  State<_PendingRequestTile> createState() => _PendingRequestTileState();
}

class _PendingRequestTileState extends State<_PendingRequestTile> {
  bool _accepting = false;
  bool _done = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await ApiService.sendFriendRequest(widget.request.id);
      if (mounted) {
        setState(() => _done = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Ahora eres amigo de ${widget.request.username}! 🎮'),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        // Breve pausa y recargar la pantalla
        await Future.delayed(const Duration(milliseconds: 600));
        widget.onAction();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _accepting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFF2A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();

    final initials = widget.request.username.length >= 2
        ? widget.request.username.substring(0, 2).toUpperCase()
        : widget.request.username.toUpperCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _yellow.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: _yellow.withValues(alpha: 0.06), blurRadius: 12)],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _yellow,
              border: Border.all(color: _yellow.withValues(alpha: 0.5), width: 2),
            ),
            child: Center(child: Text(initials,
              style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.request.username,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.star_rounded, color: _yellow, size: 11),
                const SizedBox(width: 3),
                Text('${widget.request.karma} karma',
                  style: const TextStyle(color: _textSub, fontSize: 11)),
                const SizedBox(width: 8),
                const Text('quiere ser tu amigo',
                  style: TextStyle(color: _textSub, fontSize: 11)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          // Botón Aceptar
          _accepting
              ? const SizedBox(width: 32, height: 32,
                  child: CircularProgressIndicator(color: _yellow, strokeWidth: 2))
              : GestureDetector(
                  onTap: _accept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _yellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Aceptar',
                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sección "Populares entre tus amigos" — carátulas reales de cada amigo
// =============================================================================

/// Agrupa los juegos recientes de los amigos por título y muestra
/// hasta 12 entradas únicas. Al tocar una portada se abre el modal del juego.
class _PopularGamesSection extends StatelessWidget {
  const _PopularGamesSection({required this.friends});
  final List<User> friends;

  @override
  Widget build(BuildContext context) {
    // Construir mapa: título → (coverUrl, [amigos que lo tienen])
    final Map<String, ({String coverUrl, List<User> players})> gameMap = {};

    for (final friend in friends) {
      for (int i = 0; i < friend.recentGames.length; i++) {
        final title = friend.recentGames[i];
        final cover = i < friend.recentGameCovers.length
            ? friend.recentGameCovers[i]
            : '';
        if (cover.isEmpty) continue;

        if (gameMap.containsKey(title)) {
          gameMap[title]!.players.add(friend);
        } else {
          gameMap[title] = (coverUrl: cover, players: [friend]);
        }
      }
    }

    if (gameMap.isEmpty) return const SizedBox.shrink();

    // Ordenar: primero los que más amigos comparten (más "popular")
    final entries = gameMap.entries.toList()
      ..sort((a, b) => b.value.players.length.compareTo(a.value.players.length));
    final visible = entries.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Populares entre tus amigos'),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final entry = visible[i];
              return _CoverCard(
                gameTitle: entry.key,
                coverUrl: entry.value.coverUrl,
                players: entry.value.players,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CoverCard extends StatefulWidget {
  const _CoverCard({
    required this.gameTitle,
    required this.coverUrl,
    required this.players,
  });
  final String gameTitle;
  final String coverUrl;
  final List<User> players;

  @override
  State<_CoverCard> createState() => _CoverCardState();
}

class _CoverCardState extends State<_CoverCard> {
  bool _pressed = false;

  void _openGameModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GameFriendsBottomSheet(
        gameTitle: widget.gameTitle,
        coverUrl: widget.coverUrl,
        players: widget.players,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _openGameModal(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        width: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pressed ? _yellow.withValues(alpha: 0.7) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.5 : 0.3),
              blurRadius: _pressed ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1A1A1A),
                  child: const Icon(Icons.videogame_asset_rounded,
                      color: Color(0xFF333333), size: 28),
                ),
              ),
              // Gradiente inferior para legibilidad
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
              // Mini-avatares de amigos en esquina inferior derecha
              Positioned(
                bottom: 5, right: 5,
                child: _MiniAvatarStack(players: widget.players, maxVisible: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini stack de avatares circulares ────────────────────────────────────────

class _MiniAvatarStack extends StatelessWidget {
  const _MiniAvatarStack({required this.players, this.maxVisible = 3});
  final List<User> players;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = players.take(maxVisible).toList();
    const size = 20.0;
    const overlap = 12.0;
    final totalWidth = size + (visible.length - 1) * overlap;

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(visible.length, (i) {
          final player = visible[i];
          return Positioned(
            left: i * overlap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: player.avatarBgColor,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Center(
                child: Text(
                  player.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Bottom sheet del juego con lista de amigos ────────────────────────────────

class _GameFriendsBottomSheet extends StatelessWidget {
  const _GameFriendsBottomSheet({
    required this.gameTitle,
    required this.coverUrl,
    required this.players,
  });
  final String gameTitle;
  final String coverUrl;
  final List<User> players;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Portada + título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Portada clickeable
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // Cerrar modal
                    final mockGame = gm.Game(
                      id: 0,
                      title: gameTitle,
                      cover: coverUrl,
                      platform: gm.Platform.steam, // Default
                      genre: '',
                      playtime: 0,
                      status: gm.GameStatus.unplayed,
                      pcReq: gm.PcReq.yellow,
                      hasCosmetics: false,
                      price: 0.0,
                      year: DateTime.now().year,
                    );
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GameDetailScreen(baseGame: mockGame),
                    ));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      coverUrl,
                      width: 72, height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 72, height: 96,
                        color: const Color(0xFF292929),
                        child: const Icon(Icons.videogame_asset_rounded,
                            color: Color(0xFF444444), size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: _yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${players.length} amigo${players.length == 1 ? '' : 's'} ${players.length == 1 ? 'lo juega' : 'lo juegan'}',
                          style: const TextStyle(color: _yellow, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Divider
          Container(height: 1, color: const Color(0xFF252525)),
          const SizedBox(height: 16),

          // Título de sección
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.people_rounded, color: _yellow, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Amigos que juegan esto',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Lista de avatares de amigos
          SizedBox(
            height: 90,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: players.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (ctx, i) => _FriendAvatarButton(
                player: players[i],
                onTap: () {
                  Navigator.of(context).pop(); // cerrar bottom sheet
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UserProfileScreen(user: players[i]),
                  ));
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Padding seguro para el bottom inset
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _FriendAvatarButton extends StatefulWidget {
  const _FriendAvatarButton({required this.player, required this.onTap});
  final User player;
  final VoidCallback onTap;

  @override
  State<_FriendAvatarButton> createState() => _FriendAvatarButtonState();
}

class _FriendAvatarButtonState extends State<_FriendAvatarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circular
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.player.avatarBgColor,
                border: Border.all(
                  color: _pressed
                      ? _yellow.withValues(alpha: 0.8)
                      : _yellow.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.player.avatarBgColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.player.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Nombre
            Text(
              widget.player.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Indicador online
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: widget.player.isOnline ? _green : _textSub,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  widget.player.isOnline ? 'En Línea' : 'Desc.',
                  style: TextStyle(
                    color: widget.player.isOnline ? _green : _textSub,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Componentes de Búsqueda y Filtro
// ─────────────────────────────────────────────────────────────────────────────

class _SocialSearchBar extends StatelessWidget {
  const _SocialSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 42,
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? _yellow.withValues(alpha: 0.5) : _border,
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: _textMain, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar jugador...',
          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _textMuted,
            size: 18,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.clear(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: _textSub,
                    size: 16,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}

class _OnlineToggleButton extends StatelessWidget {
  const _OnlineToggleButton({
    required this.isActive,
    required this.count,
    required this.onTap,
  });

  final bool isActive;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? _green.withValues(alpha: 0.15) : _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? _green.withValues(alpha: 0.4) : _border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? _green : _textMuted,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: _green.withValues(alpha: 0.5), blurRadius: 4)]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isActive ? 'En línea ($count)' : 'En línea',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? _green : _textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados Vacíos
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySocialState extends StatelessWidget {
  const _EmptySocialState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: _textMuted,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'No hay jugadores online en este momento'
                  : 'Sin resultados para "$query"',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textMain,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFriendsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _yellow.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _yellow.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: _yellow,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aún no tienes amigos en Bound2Game',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textMain,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pulsa el botón amarillo para buscar\njugadores y añadirlos como amigos.',
              style: TextStyle(
                fontSize: 14,
                color: _textSub,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
