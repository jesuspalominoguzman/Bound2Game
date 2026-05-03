// =============================================================================
// library_screen.dart — Bound2Game Flutter (Android)
// Fuente: InterfazdeusuarioBound2game - CORRECTO
//   └── src/app/pages/Library.tsx
//
// Refactorización v2 — Tema visual definitivo #292929/#1A1A1A/#FFB800:
//   • Eliminado título estático (lo muestra DynamicAppBar).
//   • Barra de búsqueda Expanded + contador de juegos en Row responsive.
//   • Filtros avanzados multi-categoría vía AdvancedFiltersModal.
//   • Paleta unificada con el resto de la app.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';
import '../widgets/game_library_card.dart';
import '../widgets/advanced_filters_modal.dart';
import 'game_detail_screen.dart';
import 'shake_selector_screen.dart';

// ── Paleta del tema definitivo ─────────────────────────────────────────────────
const _kBg      = Color(0xFF292929);
const _kBgCard  = Color(0xFF1A1A1A);
const _kBorder  = Color(0xFF2A2A2A);
const _kYellow  = Color(0xFFFFB800);
const _kWhite   = Color(0xFFFFFFFF);
const _kMuted   = Color(0xFF888888);
const _kSub     = Color(0xFF555555);

// =============================================================================
// CAPA DE DATOS MOCK
//
// TODO(backend): Reemplazar `_mockGames` por una llamada al servicio real:
//
//   Future<List<Game>> _loadGames() async {
//     return GameService.fetchLibrary(userId: currentUser.id);
//   }
//
// Y envolver el GridView en un FutureBuilder<List<Game>>.
// =============================================================================

final List<Game> _mockGames = sampleGames;

// =============================================================================
// LIBRARY SCREEN
// =============================================================================

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {

  // ── Estado de búsqueda ────────────────────────────────────────────────────
  final TextEditingController _searchCtrl  = TextEditingController();
  final FocusNode             _searchFocus = FocusNode();
  bool   _isSearchFocused = false;
  String _searchQuery     = '';

  // ── Filtros avanzados ─────────────────────────────────────────────────────
  LibraryFilters _filters = const LibraryFilters();

  List<_FilterTag> get _activeFilterTags {
    final tags = <_FilterTag>[];
    if (_filters.platformEnabled) {
      for (final p in _filters.platforms) {
        tags.add(_FilterTag(p.displayName, () => setState(() {
          final s = Set<Platform>.from(_filters.platforms)..remove(p);
          _filters = _filters.copyWith(platforms: s);
        })));
      }
    }
    if (_filters.genreEnabled) {
      for (final g in _filters.genres) {
        tags.add(_FilterTag(g, () => setState(() {
          final s = Set<String>.from(_filters.genres)..remove(g);
          _filters = _filters.copyWith(genres: s);
        })));
      }
    }
    if (_filters.statusEnabled) {
      for (final s in _filters.statuses) {
        tags.add(_FilterTag(s.label, () => setState(() {
          final st = Set<GameStatus>.from(_filters.statuses)..remove(s);
          _filters = _filters.copyWith(statuses: st);
        })));
      }
    }
    if (_filters.durationEnabled) {
      for (final d in _filters.durations) {
        tags.add(_FilterTag(d.label, () => setState(() {
          final s = Set<FilterDuration>.from(_filters.durations)..remove(d);
          _filters = _filters.copyWith(durations: s);
        })));
      }
    }
    if (_filters.modalityEnabled) {
      for (final m in _filters.modalities) {
        tags.add(_FilterTag(m.label, () => setState(() {
          final s = Set<FilterModality>.from(_filters.modalities)..remove(m);
          _filters = _filters.copyWith(modalities: s);
        })));
      }
    }
    return tags;
  }

  // ── Géneros disponibles (derivado de los datos) ────────────────────────────
  List<String> get _availableGenres => _mockGames
      .map((g) => g.genre)
      .toSet()
      .toList()
    ..sort();

  // ── Juegos filtrados (computed) ────────────────────────────────────────────
  List<Game> get _filteredGames {
    // 1. Texto de búsqueda
    var result = _mockGames.where((game) {
      return _searchQuery.isEmpty ||
          game.title.toLowerCase().contains(_searchQuery);
    }).toList();

    // 2. Filtros avanzados
    if (!_filters.isEmpty) {
      result = _filters.apply(result);
    }

    return result;
  }


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

  Future<void> _openFilters() async {
    final result = await showAdvancedFilters(
      context: context,
      current: _filters,
      availableGenres: _availableGenres,
    );
    if (result != null) {
      setState(() => _filters = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGames;

    return Stack(
      children: [
        Column(
          children: [
            // ── Barra superior ─────────────────────────────────────────────
            _LibraryTopBar(
              searchCtrl:       _searchCtrl,
              searchFocus:      _searchFocus,
              isSearchFocused:  _isSearchFocused,
              totalGames:       _mockGames.length,
              filteredCount:    filtered.length,
              activeTags:       _activeFilterTags,
              onFilterTap:      _openFilters,
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

        // ── FAB "Shake to Play" ──────────────────────────────────────────
        Positioned(
          bottom: 24, // Bajado para estar cerca del navbar, no en el centro
          right: 16,
          child: const _ShakeToPlayFab(),
        ),
      ],
    );
  }
}

// =============================================================================
// _LibraryTopBar — Búsqueda responsive + contador + botón de filtros
// =============================================================================

class _LibraryTopBar extends StatelessWidget {
  const _LibraryTopBar({
    required this.searchCtrl,
    required this.searchFocus,
    required this.isSearchFocused,
    required this.totalGames,
    required this.filteredCount,
    required this.activeTags,
    required this.onFilterTap,
  });

  final TextEditingController searchCtrl;
  final FocusNode             searchFocus;
  final bool                  isSearchFocused;
  final int                   totalGames;
  final int                   filteredCount;
  final List<_FilterTag>      activeTags;
  final VoidCallback          onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBgCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row responsive: [SearchBar expandida] [Contador] ──────────────
          Row(
            children: [
              // Campo de búsqueda — ocupa todo el espacio libre
              Expanded(
                child: _LibrarySearchBar(
                  controller: searchCtrl,
                  focusNode:  searchFocus,
                  isFocused:  isSearchFocused,
                ),
              ),
              const SizedBox(width: 8),

              // Contador de juegos (se encoge automáticamente)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: Text(
                  '$filteredCount/$totalGames\njuegos',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Fila de acción: botón de filtros + tags ───────────────────────
          Row(
            children: [
              // Botón filtros avanzados
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: activeTags.isNotEmpty
                        ? _kYellow.withValues(alpha: 0.15)
                        : _kBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activeTags.isNotEmpty
                          ? _kYellow.withValues(alpha: 0.5)
                          : _kBorder,
                      width: activeTags.isNotEmpty ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 13,
                        color: activeTags.isNotEmpty ? _kYellow : _kMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activeTags.isNotEmpty
                            ? 'Filtros (${activeTags.length})'
                            : 'Filtros',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: activeTags.isNotEmpty ? _kYellow : _kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Lista horizontal de filtros activos
              if (activeTags.isNotEmpty)
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: activeTags.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ActiveFilterChipWidget(tag: activeTags[index]),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),
          Container(height: 1, color: _kBorder),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LibrarySearchBar — Campo de búsqueda con foco animado
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
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? _kYellow.withValues(alpha: 0.45)
              : _kBorder,
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: _kYellow.withValues(alpha: 0.06), blurRadius: 10)]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.inter(color: _kWhite, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar en tu biblioteca...',
          hintStyle: GoogleFonts.inter(color: _kSub, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _kSub, size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.clear(),
                  child: const Icon(Icons.close_rounded, color: _kMuted, size: 16),
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
// Clases y Widgets Auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _FilterTag {
  _FilterTag(this.label, this.onRemove);
  final String label;
  final VoidCallback onRemove;
}

class _ActiveFilterChipWidget extends StatelessWidget {
  const _ActiveFilterChipWidget({required this.tag});
  final _FilterTag tag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tag.onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _kBgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kYellow.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _kWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.close_rounded, size: 12, color: _kMuted),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _LibraryGrid — GridView.builder de 2 columnas
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
        crossAxisCount:   2,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
        childAspectRatio: 3 / 4,
      ),
      itemCount: games.length,
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
// _ShakeToPlayFab — Botón flotante → ShakeSelectorScreen
// =============================================================================

class _ShakeToPlayFab extends StatelessWidget {
  const _ShakeToPlayFab();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ShakeSelectorScreen()),
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          // Gradiente actualizado al amarillo de la marca
          gradient: LinearGradient(
            colors: [_kYellow, _kYellow.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _kYellow.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              'Shake to Play',
              style: GoogleFonts.inter(
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
// _EmptyState — Vista cuando no hay resultados
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
                color: _kBgCard,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.search_off_rounded, color: _kMuted, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'No hay juegos con estos filtros'
                  : 'Sin resultados para "$query"',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otro filtro o término de búsqueda',
              style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
