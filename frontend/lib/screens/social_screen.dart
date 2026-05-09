// =============================================================================
// social_screen.dart — Bound2Game Flutter
// =============================================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/game_model.dart' hide User;
import '../widgets/user_card.dart';
import '../services/api_service.dart';
import 'game_detail_screen.dart';

// ── Constantes de color ───────────────────────────────────────────────────────
const _bg        = Color(0xFF292929);
const _bgCard    = Color(0xFF1A1A1A);
const _border    = Color(0xFF252525);
const _textMain  = Colors.white;
const _textMuted = Color(0xFF555555);
const _textSub   = Color(0xFF888888);
const _green     = Color(0xFF4AF626);
const _yellow    = Color(0xFFFFB800);
const _cyan      = Color(0xFF00E5FF);

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

  @override
  void initState() {
    super.initState();
    _loadFriends();
    
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()),
    );
    _searchFocus.addListener(
      () => setState(() => _isSearchFocused = _searchFocus.hasFocus),
    );
  }

  void _loadFriends() {
    _friendsFuture = ApiService.fetchFriends();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadFriends();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FutureBuilder<List<User>>(
        future: _friendsFuture,
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
                  Text('Error al cargar amigos', style: TextStyle(color: _textSub)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Reintentar', style: TextStyle(color: _cyan)),
                  )
                ],
              ),
            );
          }

          final friends = snapshot.data ?? [];
          
          final filtered = friends.where((user) {
            final matchesSearch = _searchQuery.isEmpty ||
                user.username.toLowerCase().contains(_searchQuery);
            final matchesOnline = !_showOnlineOnly || user.isOnline;
            return matchesSearch && matchesOnline;
          }).toList();

          final onlineCount = friends.where((u) => u.isOnline).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            color: _cyan,
            backgroundColor: _bgCard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Sección 1: Populares entre tus amigos (Simulada por ahora)
                SliverToBoxAdapter(
                  child: const _SectionHeader(title: 'Populares entre tus amigos'),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 140,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: sampleGames.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final game = sampleGames[index];
                        final playingFriends = friends.take((index % 2) + 2).toList();
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GameDetailScreen(baseGame: game),
                              ),
                            );
                          },
                          child: _GameCoverCard(game: game, playingFriends: playingFriends),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ── Sección 2: Tus Amigos ──────────────────────────────────────────
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

                // ── Lista de amigos ────────────────────────────────────────────────
                friends.isEmpty
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
                                ),
                                childCount: filtered.length,
                              ),
                            ),
                          ),

                // Padding inferior
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

class _GameCoverCard extends StatelessWidget {
  const _GameCoverCard({
    required this.game,
    required this.playingFriends,
  });
  
  final Game game;
  final List<User> playingFriends;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _bgCard,
        image: DecorationImage(
          image: NetworkImage(game.cover),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          if (playingFriends.isNotEmpty)
            Positioned(
              bottom: 5,
              right: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: playingFriends.asMap().entries.map((entry) {
                  final friend = entry.value;
                  return Align(
                    widthFactor: 0.6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _bgCard, width: 1.5),
                        color: friend.avatarBgColor,
                      ),
                      child: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                friend.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _FallbackInitial(user: friend),
                              ),
                            )
                          : _FallbackInitial(user: friend),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _FallbackInitial extends StatelessWidget {
  const _FallbackInitial({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        user.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
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
                color: _cyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: _cyan,
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
              'Encuentra a otros jugadores usando\nla barra de búsqueda superior.',
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
