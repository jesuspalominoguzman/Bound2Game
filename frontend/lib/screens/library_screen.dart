// =============================================================================
// library_screen.dart — Bound2Game Flutter (Android)
// Fuente: InterfazdeusuarioBound2game - CORRECTO
//   └── src/app/pages/Library.tsx
//
// Arquitectura:
//   • Capa de datos: mockGames (alias de sampleGames del modelo)
//     → Sustituir por FutureBuilder + GameService.fetchLibrary() en producción.
//   • Estado: StatefulWidget con búsqueda y filtrado por plataforma.
//   • Grid: GridView.builder — SliverGridDelegateWithFixedCrossAxisCount(2)
//   • Barra de búsqueda: filtrado visual en tiempo real (sin red).
//   • Filtros: chips de plataforma + "Todos".
// =============================================================================

import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../widgets/game_library_card.dart';
import 'game_detail_screen.dart';
import 'shake_selector_screen.dart';

// ── Constantes de color ───────────────────────────────────────────────────────
const _bgCard    = Color(0xFF181818);
const _border    = Color(0xFF252525);
const _textMain  = Color(0xFFD1D1D1);
const _textMuted = Color(0xFF555555);
const _textSub   = Color(0xFF888888);
const _cyan      = Color(0xFF00E5FF);

// =============================================================================
// CAPA DE DATOS MOCK
//
// TODO(backend): Reemplazar `_mockGames` por una llamada al servicio real:
//
//   Future<List<Game>> _loadGames() async {
//     return GameService.fetchLibrary(userId: currentUser.id);
//   }
//
// Y envolver el GridView en un FutureBuilder:
//
//   FutureBuilder<List<Game>>(
//     future: _loadGames(),
//     builder: (context, snapshot) {
//       if (snapshot.connectionState != ConnectionState.done)
//         return const Center(child: CircularProgressIndicator());
//       if (snapshot.hasError) return _ErrorView(error: snapshot.error);
//       return _LibraryGrid(games: snapshot.data!);
//     },
//   );
// =============================================================================

/// Fuente de datos mock — alias de sampleGames definido en game_model.dart.
/// Ningún nombre de juego está hardcodeado en la UI; todo proviene de este
/// objeto de datos.
final List<Game> _mockGames = sampleGames;

// =============================================================================
// LIBRARY SCREEN
// =============================================================================

/// Pantalla principal de la Biblioteca de juegos.
///
/// Corresponde a `Library.tsx` del diseño de referencia React.
/// Contiene:
/// - Header con título y contador de juegos.
/// - Barra de búsqueda con filtrado en tiempo real.
/// - Chips de filtro por plataforma.
/// - Grid de 2 columnas de [GameLibraryCard].
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  // ── Estado de búsqueda y filtrado ─────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchFocused = false;

  /// Plataforma seleccionada para filtrar. null = "Todas".
  Platform? _selectedPlatform;

  /// Texto de búsqueda normalizado.
  String _searchQuery = '';

  // ── Datos filtrados (computed) ────────────────────────────────────────────
  List<Game> get _filteredGames {
    // TODO(backend): Este filtrado se haría en el servidor con query params:
    //   GET /api/library?userId=X&platform=steam&search=witcher
    return _mockGames.where((game) {
      final matchesPlatform =
          _selectedPlatform == null || game.platform == _selectedPlatform;
      final matchesSearch = _searchQuery.isEmpty ||
          game.title.toLowerCase().contains(_searchQuery);
      return matchesPlatform && matchesSearch;
    }).toList();
  }

  // ── Plataformas únicas presentes en la biblioteca ─────────────────────────
  List<Platform> get _availablePlatforms {
    return _mockGames.map((g) => g.platform).toSet().toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
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

  void _openDetail(BuildContext context, Game game) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => GameDetailScreen(game: game),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGames;

    return Stack(
      children: [
        Column(
          children: [
            // ── Barra de búsqueda + filtros ────────────────────────────────
            _LibraryTopBar(
              searchCtrl: _searchCtrl,
              searchFocus: _searchFocus,
              isSearchFocused: _isSearchFocused,
              availablePlatforms: _availablePlatforms,
              selectedPlatform: _selectedPlatform,
              onPlatformSelected: (p) => setState(() => _selectedPlatform = p),
              totalGames: _mockGames.length,
              filteredCount: filtered.length,
            ),
            // ── Grid de juegos ─────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(query: _searchQuery)
                  : _LibraryGrid(
                      games: filtered,
                      onGameTap: (game) => _openDetail(context, game),
                    ),
            ),
          ],
        ),

        // ── FAB "Shake to Play" ────────────────────────────────────────────
        Positioned(
          bottom: 90,
          right: 16,
          child: const _ShakeToPlayFab(),
        ),
      ],
    );
  }
}

// =============================================================================
// _LibraryTopBar — Header + búsqueda + chips de filtro
// Corresponde a la sección de filtros de Library.tsx
// =============================================================================

class _LibraryTopBar extends StatelessWidget {
  const _LibraryTopBar({
    required this.searchCtrl,
    required this.searchFocus,
    required this.isSearchFocused,
    required this.availablePlatforms,
    required this.selectedPlatform,
    required this.onPlatformSelected,
    required this.totalGames,
    required this.filteredCount,
  });

  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final bool isSearchFocused;
  final List<Platform> availablePlatforms;
  final Platform? selectedPlatform;
  final ValueChanged<Platform?> onPlatformSelected;
  final int totalGames;
  final int filteredCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101010),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título de sección ──────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 18, color: _cyan),
              const SizedBox(width: 8),
              const Text(
                'Mi Biblioteca',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Contador de juegos
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cyan.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '$filteredCount / $totalGames juegos',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Barra de búsqueda ──────────────────────────────────────────────
          _LibrarySearchBar(
            controller: searchCtrl,
            focusNode: searchFocus,
            isFocused: isSearchFocused,
          ),
          const SizedBox(height: 10),

          // ── Chips de filtro por plataforma ─────────────────────────────────
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Chip "Todas"
                _PlatformFilterChip(
                  label: 'Todas',
                  isSelected: selectedPlatform == null,
                  color: _cyan,
                  onTap: () => onPlatformSelected(null),
                ),
                const SizedBox(width: 6),
                // Chips de cada plataforma disponible
                ...availablePlatforms.map((platform) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _PlatformFilterChip(
                      label: platform.displayName,
                      isSelected: selectedPlatform == platform,
                      color: platform.color,
                      onTap: () => onPlatformSelected(
                        selectedPlatform == platform ? null : platform,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: _border, height: 1),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LibrarySearchBar — Campo de búsqueda con efecto focus animado
// Corresponde al <input type="search"> de Library.tsx
// ─────────────────────────────────────────────────────────────────────────────

class _LibrarySearchBar extends StatelessWidget {
  const _LibrarySearchBar({
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
            ? [BoxShadow(color: _cyan.withValues(alpha: 0.08), blurRadius: 10)]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: _textMain, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar en tu biblioteca...',
          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _textMuted,
            size: 18,
          ),
          // Botón para limpiar búsqueda
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
// _PlatformFilterChip — Chip individual de filtro de plataforma
// Corresponde a los botones de filtro de Library.tsx
// ─────────────────────────────────────────────────────────────────────────────

class _PlatformFilterChip extends StatelessWidget {
  const _PlatformFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : const Color(0xFF2A2A2A),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : _textSub,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _LibraryGrid — GridView.builder de 2 columnas
// Corresponde al grid de juegos de Library.tsx
// =============================================================================

class _LibraryGrid extends StatelessWidget {
  const _LibraryGrid({required this.games, required this.onGameTap});

  final List<Game> games;
  final ValueChanged<Game> onGameTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3 / 4,
      ),
      itemCount: games.length,
      // TODO(backend): snapshot.data![index] cuando se use FutureBuilder.
      itemBuilder: (context, index) {
        final game = games[index];
        return Hero(
          tag: 'game-cover-${game.id}',
          child: GameLibraryCard(
            key: ValueKey(game.id),
            game: game,
            onTap: () => onGameTap(game),
          ),
        );
      },
    );
  }
}

// =============================================================================
// _ShakeToPlayFab — Botón flotante que navega al Selector Inteligente
// =============================================================================

class _ShakeToPlayFab extends StatelessWidget {
  const _ShakeToPlayFab();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ShakeSelectorScreen(),
        ),
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF7B61FF)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 18),
            SizedBox(width: 8),
            Text(
              'Shake to Play',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _EmptyState — Vista cuando no hay resultados de búsqueda/filtro
// =============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                Icons.search_off_rounded,
                color: _textMuted,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'No hay juegos en esta plataforma'
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
              'Prueba con otro filtro o término de búsqueda',
              style: TextStyle(fontSize: 12, color: _textSub),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
