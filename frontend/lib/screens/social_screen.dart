// =============================================================================
// social_screen.dart — Bound2Game Flutter (Android)
// Fuente: InterfazdeusuarioBound2game - CORRECTO
//   └── src/app/pages/Social.tsx
//
// Arquitectura:
//   • Capa de datos : mockUsers (de user_model.dart)
//     → Sustituir por FutureBuilder + SocialService.fetchFeed() en producción.
//   • Estado        : StatefulWidget — búsqueda + filtro de estado online.
//   • Scroll        : BouncingScrollPhysics para sensación iOS/fluida.
//   • Secciones:
//       1. Estadísticas sociales (online, amigos, afinidad media)
//       2. Matchmaking de Alta Afinidad (horizontal scroll)
//       3. Barra de búsqueda + toggle online
//       4. Lista completa de jugadores (ListView.builder)
// =============================================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/user_card.dart';
import 'chat_screen.dart';

// ── Constantes de color ───────────────────────────────────────────────────────
const _bgCard    = Color(0xFF181818);
const _border    = Color(0xFF252525);
const _textMain  = Color(0xFFD1D1D1);
const _textMuted = Color(0xFF555555);
const _textSub   = Color(0xFF888888);
const _cyan      = Color(0xFF00E5FF);
const _green     = Color(0xFF4AF626);
const _purple    = Color(0xFF7B61FF);

// =============================================================================
// SOCIAL SCREEN
// =============================================================================

/// Pantalla de comunidad y matchmaking de Bound2Game.
///
/// Corresponde a `Social.tsx` del diseño de referencia.
/// Incluye:
/// - Estadísticas sociales del usuario actual.
/// - Sección de alta afinidad (matchmaking carousel).
/// - Búsqueda y filtro de la lista de jugadores.
/// - Lista de jugadores con [UserCard] (ListView.builder).
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

  // ── Datos filtrados ────────────────────────────────────────────────────────
  List<SocialUser> get _filteredUsers {
    // TODO(backend): Mover el filtrado al servidor:
    //   GET /api/social/users?search=[query]&online=[_showOnlineOnly]
    return mockUsers.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.username.toLowerCase().contains(_searchQuery) ||
          user.tags.any((t) => t.toLowerCase().contains(_searchQuery));
      final matchesOnline = !_showOnlineOnly || user.isOnline;
      return matchesSearch && matchesOnline;
    }).toList();
  }

  /// Jugadores con afinidad ≥ 50% para la sección de matchmaking.
  List<SocialUser> get _highAffinityUsers =>
      mockUsers.where((u) => u.affinityScore >= 50).toList()
        ..sort((a, b) => b.affinityScore.compareTo(a.affinityScore));

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()),
    );
    _searchFocus.addListener(
      () => setState(() => _isSearchFocused = _searchFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;
    final highAffinity = _highAffinityUsers;
    final onlineCount = mockUsers.where((u) => u.isOnline).length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Padding superior ─────────────────────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Estadísticas sociales ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SocialStatsRow(
              totalUsers: mockUsers.length,
              onlineCount: onlineCount,
              avgAffinity: _avgAffinity,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Sección de Alta Afinidad (matchmaking) ───────────────────────────
        if (highAffinity.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _MatchmakingSection(users: highAffinity),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],

        // ── Barra de búsqueda + toggle online ────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchAndFilterRow(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              isFocused: _isSearchFocused,
              showOnlineOnly: _showOnlineOnly,
              onlineCount: onlineCount,
              totalCount: filtered.length,
              onToggleOnline: () =>
                  setState(() => _showOnlineOnly = !_showOnlineOnly),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Lista de jugadores ────────────────────────────────────────────────
        filtered.isEmpty
            ? SliverToBoxAdapter(
                child: _EmptySocialState(query: _searchQuery),
              )
            : SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: UserCard(
                      key: ValueKey(user.id),
                      user: user,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(user: user),
                        ),
                      ),
                      onConnect: () {
                        // TODO(backend): SocialService.sendFriendRequest(user.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Solicitud enviada a ${user.username}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _bgCard,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: _border),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

        // ── Padding inferior (clearance del BottomBar) ────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  /// Afinidad media de todos los usuarios mock.
  int get _avgAffinity {
    if (mockUsers.isEmpty) return 0;
    return (mockUsers.map((u) => u.affinityScore).reduce((a, b) => a + b) /
            mockUsers.length)
        .round();
  }
}

// =============================================================================
// _SocialStatsRow — Tarjetas de estadísticas sociales
// Corresponde al bloque de métricas de Social.tsx
// =============================================================================

class _SocialStatsRow extends StatelessWidget {
  const _SocialStatsRow({
    required this.totalUsers,
    required this.onlineCount,
    required this.avgAffinity,
  });

  final int totalUsers;
  final int onlineCount;
  final int avgAffinity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatMiniCard(
            icon: Icons.people_rounded,
            value: '$totalUsers',
            label: 'Jugadores',
            color: _cyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.circle,
            value: '$onlineCount',
            label: 'En línea',
            color: _green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.favorite_rounded,
            value: '$avgAffinity%',
            label: 'Afinidad media',
            color: _purple,
          ),
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: _textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _MatchmakingSection — Carousel de Alta Afinidad
// Corresponde a la sección de jugadores sugeridos de Social.tsx
// =============================================================================

/// Sección destacada que muestra jugadores con alta afinidad al usuario actual.
///
/// Usa [UserCardExpanded] en un scroll horizontal.
/// El índice de afinidad se calcula en [SocialUser.affinityScore]; en
/// producción este valor vendría directamente del backend con ML.
///
/// TODO(backend): GET /api/social/recommendations → Lista ordenada por score
class _MatchmakingSection extends StatelessWidget {
  const _MatchmakingSection({required this.users});
  final List<SocialUser> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de sección
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cyan.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: _cyan,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alta Afinidad',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${users.length} jugadores compatibles contigo',
                  style: const TextStyle(fontSize: 10, color: _textSub),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Carousel horizontal de tarjetas
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) => UserCardExpanded(
              key: ValueKey(users[index].id),
              user: users[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(user: users[index]),
                ),
              ),
              onConnect: () {
                // TODO(backend): SocialService.sendFriendRequest(users[index].id);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _SearchAndFilterRow — Búsqueda + toggle "Solo online"
// =============================================================================

class _SearchAndFilterRow extends StatelessWidget {
  const _SearchAndFilterRow({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.showOnlineOnly,
    required this.onlineCount,
    required this.totalCount,
    required this.onToggleOnline,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool showOnlineOnly;
  final int onlineCount;
  final int totalCount;
  final VoidCallback onToggleOnline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección + contador
        Row(
          children: [
            const Text(
              'Jugadores',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              '$totalCount encontrados',
              style: const TextStyle(fontSize: 10, color: _textSub),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Barra de búsqueda
        Row(
          children: [
            Expanded(child: _SocialSearchBar(
              controller: controller,
              focusNode: focusNode,
              isFocused: isFocused,
            )),
            const SizedBox(width: 8),
            // Botón toggle "Solo online"
            _OnlineToggleButton(
              isActive: showOnlineOnly,
              count: onlineCount,
              onTap: onToggleOnline,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SocialSearchBar — Campo de búsqueda para la sección social
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? _cyan.withValues(alpha: 0.45)
              : const Color(0xFF2A2A2A),
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: _cyan.withValues(alpha: 0.07), blurRadius: 10)]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: _textMain, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar jugador o tag...',
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

// ─────────────────────────────────────────────────────────────────────────────
// _OnlineToggleButton — Botón de filtro "Solo online"
// ─────────────────────────────────────────────────────────────────────────────

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
          color: isActive
              ? _green.withValues(alpha: 0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? _green.withValues(alpha: 0.4)
                : const Color(0xFF2A2A2A),
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
                    ? [BoxShadow(
                        color: _green.withValues(alpha: 0.5),
                        blurRadius: 4,
                      )]
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

// =============================================================================
// _EmptySocialState — Estado vacío de búsqueda
// =============================================================================

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
            const SizedBox(height: 8),
            const Text(
              'Prueba otro nombre, tag o desactiva el filtro online',
              style: TextStyle(fontSize: 12, color: _textSub),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
