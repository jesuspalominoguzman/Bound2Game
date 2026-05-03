// =============================================================================
// shake_selector_screen.dart — Bound2Game Flutter
//
// Refactorización:
// - Paleta unificada: #292929 / #1A1A1A / #FFB800.
// - Usa AdvancedFiltersModal para configurar filtros.
// - Animación con shuffle() para que no sea repetitiva, asegurando
//   que el último frame coincide con el resultado.
// =============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game_model.dart';
import '../widgets/advanced_filters_modal.dart';
import 'game_detail_screen.dart';

// ── Paleta del tema definitivo ─────────────────────────────────────────────────
const _kBg      = Color(0xFF292929);
const _kBgCard  = Color(0xFF1A1A1A);
const _kBorder  = Color(0xFF2A2A2A);
const _kYellow  = Color(0xFFFFB800);
const _kWhite   = Color(0xFFFFFFFF);
const _kMuted   = Color(0xFF888888);
const _kSub     = Color(0xFF555555);

// ── State phases ─────────────────────────────────────────────────────────────
enum _Phase { filters, spinning, result }

// =============================================================================
// ShakeSelectorScreen
// =============================================================================

class ShakeSelectorScreen extends StatefulWidget {
  const ShakeSelectorScreen({super.key});

  @override
  State<ShakeSelectorScreen> createState() => _ShakeSelectorScreenState();
}

class _ShakeSelectorScreenState extends State<ShakeSelectorScreen>
    with TickerProviderStateMixin {

  // ── Filter state ───────────────────────────────────────────────────────────
  LibraryFilters _filters = const LibraryFilters();

  // ── Phase & result ─────────────────────────────────────────────────────────
  _Phase _phase = _Phase.filters;
  Game? _result;

  // ── Spin animation ─────────────────────────────────────────────────────────
  late AnimationController _spinCtrl;
  late Animation<double>   _spinAnim;
  int _spinIndex = 0;
  List<Game> _spinPool = [];
  int _targetIndex = 0;
  final int _totalSteps = 60; // Pasos virtuales de la animación

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _spinAnim = CurvedAnimation(parent: _spinCtrl, curve: Curves.decelerate);
    _spinCtrl.addListener(_onSpinTick);
    _spinCtrl.addStatusListener(_onSpinStatus);
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  // ── Filtered pool ──────────────────────────────────────────────────────────
  List<Game> get _filtered {
    return _filters.apply(sampleGames);
  }

  // ── Unique genres in pool ──────────────────────────────────────────────────
  List<String> get _genres =>
      sampleGames.map((g) => g.genre).toSet().toList()..sort();

  // ── Configurar filtros (abre AdvancedFiltersModal) ─────────────────────────
  Future<void> _openFilters() async {
    final result = await showAdvancedFilters(
      context: context,
      current: _filters,
      availableGenres: _genres,
    );
    if (result != null) {
      setState(() => _filters = result);
    }
  }

  // ── Spin logic ─────────────────────────────────────────────────────────────
  void _onSpinTick() {
    if (_spinPool.isEmpty) return;
    final step = (_spinAnim.value * _totalSteps).floor();
    setState(() => _spinIndex = step % _spinPool.length);
  }

  void _onSpinStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      setState(() {
        _result = _spinPool[_targetIndex];
        _phase  = _Phase.result;
      });
    }
  }

  void _startSpin() {
    final pool = _filtered.toList();
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ningún juego coincide con los filtros',
            style: GoogleFonts.inter(color: _kYellow, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          backgroundColor: _kBgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _kBorder),
          ),
        ),
      );
      return;
    }

    // Barajamos aleatoriamente la lista de carátulas para que la animación no sea repetitiva
    pool.shuffle(Random());
    _spinPool = pool;
    
    // Al finalizar la animación (_spinAnim.value == 1.0), el índice calculado será (_totalSteps % pool.length).
    // Guardamos ese índice para garantizar que _result sea el último frame visualizado.
    _targetIndex = _totalSteps % _spinPool.length;
    
    _spinCtrl.reset();
    setState(() { _phase = _Phase.spinning; _result = null; });
    _spinCtrl.forward();
  }

  void _retry() {
    _spinCtrl.reset();
    setState(() { _phase = _Phase.filters; _result = null; });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBgCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.casino_rounded, color: _kYellow, size: 18),
            const SizedBox(width: 8),
            Text(
              'Selección Aleatoria',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kWhite,
              ),
            ),
          ],
        ),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: _kBorder)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _phase == _Phase.filters
            ? _FiltersView(
                key: const ValueKey('filters'),
                poolCount: _filtered.length,
                onConfigure: _openFilters,
                onSpin: _startSpin,
              )
            : _phase == _Phase.spinning
                ? _SpinView(
                    key: const ValueKey('spin'),
                    pool:       _spinPool,
                    spinIndex:  _spinIndex,
                    animation:  _spinAnim,
                  )
                : _ResultView(
                    key: const ValueKey('result'),
                    game:   _result!,
                    onRetry: _retry,
                    onDetail: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GameDetailScreen(game: _result!),
                      ),
                    ),
                  ),
      ),
    );
  }
}

// =============================================================================
// _FiltersView — Configuración inicial
// =============================================================================

class _FiltersView extends StatelessWidget {
  const _FiltersView({
    super.key,
    required this.poolCount,
    required this.onConfigure,
    required this.onSpin,
  });

  final int poolCount;
  final VoidCallback onConfigure;
  final VoidCallback onSpin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono ilustrativo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kBgCard,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.touch_app_rounded, color: _kYellow, size: 48),
            ),
            const SizedBox(height: 32),

            // Título principal
            Text(
              '¿No sabes a qué jugar?',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _kWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Configura tus filtros o déjalo todo al azar.\nAgita tu teléfono o presiona el botón para elegir tu próxima aventura.',
              style: GoogleFonts.inter(fontSize: 13, color: _kMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Contador y Botón de filtros
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kBgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Juegos disponibles',
                          style: GoogleFonts.inter(fontSize: 11, color: _kSub, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          poolCount.toString(),
                          style: GoogleFonts.inter(fontSize: 24, color: _kWhite, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onConfigure,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: Text(
                      'Filtros',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kYellow,
                      side: const BorderSide(color: _kBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón grande
            GestureDetector(
              onTap: onSpin,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  gradient: poolCount > 0
                      ? LinearGradient(
                          colors: [_kYellow, _kYellow.withValues(alpha: 0.75)],
                        )
                      : null,
                  color: poolCount == 0 ? _kBgCard : null,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: poolCount > 0
                      ? [
                          BoxShadow(
                            color: _kYellow.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          )
                        ]
                      : null,
                  border: poolCount == 0
                      ? Border.all(color: _kBorder)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: poolCount > 0 ? Colors.black : _kMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Selección Aleatoria',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: poolCount > 0 ? Colors.black : _kMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
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
// _SpinView — Animación de carrusel de portadas
// =============================================================================

class _SpinView extends StatelessWidget {
  const _SpinView({
    super.key,
    required this.pool,
    required this.spinIndex,
    required this.animation,
  });

  final List<Game> pool;
  final int        spinIndex;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curr = pool[spinIndex];
    final next = pool[(spinIndex + 1) % pool.length];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Buscando tu próximo juego...',
          style: GoogleFonts.inter(fontSize: 14, color: _kMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),

        // Carrusel animado
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Tarjeta trasera (siguiente)
              Positioned(
                top: 16,
                child: _SpinCard(game: next, scale: 0.88, opacity: 0.5),
              ),
              // Tarjeta principal (actual)
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  // Slide vertical entre frames
                  final frac = (animation.value * 60) % 1.0;
                  final offset = frac * -20.0;
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: _SpinCard(game: curr, scale: 1.0, opacity: 1.0),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Barra de progreso de ralentización
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) => Column(
              children: [
                LinearProgressIndicator(
                  value: animation.value,
                  backgroundColor: _kBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(_kYellow.withValues(alpha: 0.5), _kYellow, animation.value)!,
                  ),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 12),
                Text(
                  animation.value < 0.5
                      ? 'Barajando...'
                      : 'Casi...',
                  style: GoogleFonts.inter(fontSize: 11, color: _kMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpinCard extends StatelessWidget {
  const _SpinCard({required this.game, required this.scale, required this.opacity});
  final Game   game;
  final double scale, opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 180,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  game.cover,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, _) => Container(
                    color: _kBgCard,
                    child: const Icon(Icons.sports_esports_rounded,
                        color: _kBorder, size: 48),
                  ),
                ),
                // Gradient overlay with title
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      game.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _ResultView — Juego seleccionado
// =============================================================================

class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.game,
    required this.onRetry,
    required this.onDetail,
  });

  final Game         game;
  final VoidCallback onRetry;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // Badge de resultado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _kYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kYellow.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 13, color: _kYellow),
                const SizedBox(width: 6),
                Text('¡Tu próximo juego es!',
                    style: GoogleFonts.inter(fontSize: 12, color: _kYellow,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Portada grande con sombra
          Container(
            width: 200,
            height: 267,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kYellow.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                game.cover,
                fit: BoxFit.cover,
                errorBuilder: (context, error, _) => Container(
                  color: _kBgCard,
                  child: const Icon(Icons.sports_esports_rounded,
                      color: _kBorder, size: 60),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            game.title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Metadatos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(game.genre,
                  style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
              Text('  ·  ',
                  style: GoogleFonts.inter(fontSize: 12, color: _kBorder)),
              Text(game.platform.displayName,
                  style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
              if (game.hltb?.main != null) ...[
                Text('  ·  ',
                    style: GoogleFonts.inter(fontSize: 12, color: _kBorder)),
                Text('~${game.hltb!.main}h',
                    style: GoogleFonts.inter(fontSize: 12, color: _kWhite, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          const SizedBox(height: 40),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text('Otro juego',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kWhite,
                    side: const BorderSide(color: _kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.info_rounded, size: 16),
                  label: Text('Ver Detalles',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
