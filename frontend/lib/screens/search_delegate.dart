import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';
import '../services/api_service.dart';
import 'game_detail_screen.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF292929);
const _kBgCard  = Color(0xFF1A1A1A);
const _kBorder  = Color(0xFF2A2A2A);
const _kYellow  = Color(0xFFFFB800);
const _kWhite   = Color(0xFFFFFFFF);
const _kMuted   = Color(0xFFAAAAAA);
const _kSub     = Color(0xFF666666);

// ─────────────────────────────────────────────────────────────────────────────
// B2G SEARCH DELEGATE
// ─────────────────────────────────────────────────────────────────────────────

class B2GSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: IconThemeData(color: _kMuted),
      ),
      scaffoldBackgroundColor: _kBg,
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: GoogleFonts.inter(color: _kSub, fontSize: 16),
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.inter(color: _kWhite, fontSize: 16),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _kYellow,
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Buscar juegos, usuarios...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded, color: _kMuted),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: _kMuted),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _SearchResultsBody(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) return const _SearchEmptyState();
    return _SearchResultsBody(query: query);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget que gestiona el debounce y la llamada real a la API
// ─────────────────────────────────────────────────────────────────────────────

class _SearchResultsBody extends StatefulWidget {
  const _SearchResultsBody({required this.query});
  final String query;

  @override
  State<_SearchResultsBody> createState() => _SearchResultsBodyState();
}

class _SearchResultsBodyState extends State<_SearchResultsBody> {
  Timer? _debounce;
  String _activeQuery = '';
  bool _isLoading = false;
  Game? _result;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _scheduleSearch(widget.query);
  }

  @override
  void didUpdateWidget(_SearchResultsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _scheduleSearch(widget.query);
    }
  }

  void _scheduleSearch(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) return;
    setState(() { _isLoading = true; _notFound = false; });
    _debounce = Timer(const Duration(milliseconds: 600), () => _doSearch(q.trim()));
  }

  Future<void> _doSearch(String q) async {
    if (!mounted) return;
    setState(() { _activeQuery = q; _isLoading = true; _notFound = false; _result = null; });
    try {
      final api = await ApiService.searchGame(q);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _result = Game(
          id:           api.title.hashCode,
          title:        api.title,
          platform:     Platform.steam,
          genre:        'Acción',
          playtime:     0,
          status:       GameStatus.unplayed,
          cover:        api.coverUrl,
          pcReq:        PcReq.yellow,
          hasCosmetics: false,
          price:        double.tryParse(api.currentPrice ?? '0') ?? 0,
          year:         api.addedAt?.year ?? DateTime.now().year,
          rentability:  api.rentability,
          hltb: HltbTimes(
            main:          api.hltbMainStory?.round(),
            completionist: api.hltbCompletionist?.round(),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _notFound = true; });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: _kBg,
        child: const Center(child: CircularProgressIndicator(color: _kYellow, strokeWidth: 2)),
      );
    }
    if (_notFound || _result == null) {
      return _SearchNoResults(query: _activeQuery);
    }
    final game = _result!;
    return Container(
      color: _kBg,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _SearchResultTile(
            game: game,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GameDetailScreen(baseGame: game)),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE — Pantalla premium cuando query está vacío
// ─────────────────────────────────────────────────────────────────────────────

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icono de lupa con glow amarillo ────────────────────────────
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kYellow.withValues(alpha: 0.08),
                border: Border.all(color: _kYellow.withValues(alpha: 0.25), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _kYellow.withValues(alpha: 0.15),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.search_rounded, size: 44, color: _kYellow),
            ),

            const SizedBox(height: 28),

            // ── Título principal ────────────────────────────────────────────
            Text(
              'Encuentra tu próximo juego',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kWhite,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 12),

            // ── Subtítulo ───────────────────────────────────────────────────
            Text(
              'Busca cualquier juego para:',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _kMuted,
              ),
            ),

            const SizedBox(height: 28),

            // ── Bullets visuales ────────────────────────────────────────────
            _SearchFeatureBullet(
              icon: Icons.library_add_rounded,
              title: 'Añadirlo a tu log',
              subtitle: 'Registra cada partida y lleva el control de tu biblioteca',
            ),
            const SizedBox(height: 14),
            _SearchFeatureBullet(
              icon: Icons.memory_rounded,
              title: 'Comprobar specs de tu PC',
              subtitle: 'Verifica si tu equipo cumple los requisitos del juego',
            ),
            const SizedBox(height: 14),
            _SearchFeatureBullet(
              icon: Icons.people_rounded,
              title: 'Encontrar compañeros',
              subtitle: 'Conecta con jugadores que tienen el mismo juego',
            ),

            const SizedBox(height: 32),

            // ── Hint de teclado ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _kBgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard_rounded, size: 14, color: _kSub),
                  const SizedBox(width: 8),
                  Text(
                    'Empieza a escribir para buscar',
                    style: GoogleFonts.inter(fontSize: 12, color: _kSub),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE BULLET — Item visual del empty state
// ─────────────────────────────────────────────────────────────────────────────

class _SearchFeatureBullet extends StatelessWidget {
  const _SearchFeatureBullet({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // Icono con fondo amarillo suave
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: _kYellow),
          ),
          const SizedBox(width: 14),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kWhite,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: _kMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _kSub),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NO RESULTS STATE
// ─────────────────────────────────────────────────────────────────────────────

class _SearchNoResults extends StatelessWidget {
  const _SearchNoResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 52, color: _kSub),
            const SizedBox(height: 16),
            Text(
              'Sin resultados para',
              style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
            ),
            const SizedBox(height: 4),
            Text(
              '"$query"',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otro término de búsqueda',
              style: GoogleFonts.inter(fontSize: 12, color: _kSub),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH RESULT TILE
// ─────────────────────────────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.game, required this.onTap});

  final Game game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _kBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Cover thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Image.network(
                  game.cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, e) => Container(
                    color: _kBgCard,
                    child: const Icon(Icons.videogame_asset_rounded, color: _kSub),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: GoogleFonts.inter(
                      color: _kWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    game.genre,
                    style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _kSub),
          ],
        ),
      ),
    );
  }
}
