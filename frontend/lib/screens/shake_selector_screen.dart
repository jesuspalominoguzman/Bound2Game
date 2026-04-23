// shake_selector_screen.dart — Bound2Game Flutter
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import 'game_detail_screen.dart';

const _bg     = Color(0xFF101010);
const _bgCard = Color(0xFF181818);
const _bgCard2 = Color(0xFF1C1C1C);
const _border  = Color(0xFF252525);
const _textMain  = Color(0xFFD1D1D1);
const _textMuted = Color(0xFF555555);
const _textSub   = Color(0xFF888888);
const _cyan   = Color(0xFF00E5FF);
const _green  = Color(0xFF4AF626);
const _yellow = Color(0xFFFFB800);
const _purple = Color(0xFF7B61FF);

// ── Filter model ─────────────────────────────────────────────────────────────

enum _DurationFilter { any, short, medium, long }
enum _ModeFilter     { any, singleplayer, multiplayer }

extension _DurationLabel on _DurationFilter {
  String get label {
    switch (this) {
      case _DurationFilter.any:    return 'Me da igual';
      case _DurationFilter.short:  return '< 10h';
      case _DurationFilter.medium: return '10–40h';
      case _DurationFilter.long:   return '> 40h';
    }
  }
}

extension _ModeLabel on _ModeFilter {
  String get label {
    switch (this) {
      case _ModeFilter.any:          return 'Me da igual';
      case _ModeFilter.singleplayer: return 'Singleplayer';
      case _ModeFilter.multiplayer:  return 'Multiplayer';
    }
  }
}

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
  final Set<GameStatus> _statusFilter = {};
  final Set<String>     _genreFilter  = {};
  _DurationFilter _durationFilter = _DurationFilter.any;
  _ModeFilter     _modeFilter     = _ModeFilter.any;

  // ── Phase & result ─────────────────────────────────────────────────────────
  _Phase _phase = _Phase.filters;
  Game? _result;

  // ── Spin animation ─────────────────────────────────────────────────────────
  late AnimationController _spinCtrl;
  late Animation<double>   _spinAnim;
  int _spinIndex = 0;
  List<Game> _spinPool = [];
  int _targetIndex = 0;

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
    // TODO(backend): GET /api/library/random?status=...&genre=...&duration=...
    return sampleGames.where((g) {
      if (_statusFilter.isNotEmpty && !_statusFilter.contains(g.status)) {
        return false;
      }
      if (_genreFilter.isNotEmpty && !_genreFilter.contains(g.genre)) {
        return false;
      }
      if (_durationFilter != _DurationFilter.any && g.hltb != null) {
        final h = g.hltb!.main ?? g.hltb!.extra ?? 0;
        if (_durationFilter == _DurationFilter.short  && h >= 10)  return false;
        if (_durationFilter == _DurationFilter.medium && (h < 10 || h > 40)) return false;
        if (_durationFilter == _DurationFilter.long   && h <= 40)  return false;
      }
      if (_modeFilter == _ModeFilter.singleplayer) {
        if (g.hltb == null || (g.hltb!.main ?? 0) == 0) return false;
      }
      if (_modeFilter == _ModeFilter.multiplayer) {
        if (g.hltb != null && (g.hltb!.main ?? 0) > 0) return false;
      }
      return true;
    }).toList();
  }

  // ── Unique genres in pool ──────────────────────────────────────────────────
  List<String> get _genres =>
      sampleGames.map((g) => g.genre).toSet().toList()..sort();

  // ── Spin logic ─────────────────────────────────────────────────────────────
  void _onSpinTick() {
    if (_spinPool.isEmpty) return;
    const totalSteps = 60; // virtual steps across the animation
    final step = (_spinAnim.value * totalSteps).floor();
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
    final pool = _filtered;
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ningún juego coincide con los filtros'),
          backgroundColor: _bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _border),
          ),
        ),
      );
      return;
    }
    _spinPool    = pool;
    _targetIndex = Random().nextInt(pool.length);
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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF151515),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.casino_rounded, color: _cyan, size: 18),
            const SizedBox(width: 8),
            const Text('Selector Inteligente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _phase == _Phase.filters
            ? _FiltersView(
                key: const ValueKey('filters'),
                statusFilter:   _statusFilter,
                genreFilter:    _genreFilter,
                genres:         _genres,
                durationFilter: _durationFilter,
                modeFilter:     _modeFilter,
                poolCount:      _filtered.length,
                onStatusToggle: (s) => setState(() {
                  _statusFilter.contains(s)
                      ? _statusFilter.remove(s)
                      : _statusFilter.add(s);
                }),
                onGenreToggle: (g) => setState(() {
                  _genreFilter.contains(g)
                      ? _genreFilter.remove(g)
                      : _genreFilter.add(g);
                }),
                onDurationChanged: (d) =>
                    setState(() => _durationFilter = d),
                onModeChanged: (m) =>
                    setState(() => _modeFilter = m),
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
// _FiltersView
// =============================================================================

class _FiltersView extends StatelessWidget {
  const _FiltersView({
    super.key,
    required this.statusFilter,
    required this.genreFilter,
    required this.genres,
    required this.durationFilter,
    required this.modeFilter,
    required this.poolCount,
    required this.onStatusToggle,
    required this.onGenreToggle,
    required this.onDurationChanged,
    required this.onModeChanged,
    required this.onSpin,
  });

  final Set<GameStatus>    statusFilter;
  final Set<String>        genreFilter;
  final List<String>       genres;
  final _DurationFilter    durationFilter;
  final _ModeFilter        modeFilter;
  final int                poolCount;
  final ValueChanged<GameStatus>      onStatusToggle;
  final ValueChanged<String>          onGenreToggle;
  final ValueChanged<_DurationFilter> onDurationChanged;
  final ValueChanged<_ModeFilter>     onModeChanged;
  final VoidCallback onSpin;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Estado ────────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FilterSection(
              title: 'Estado',
              icon: Icons.flag_rounded,
              child: Wrap(
                spacing: 8,
                children: GameStatus.values.map((s) {
                  final sel = statusFilter.contains(s);
                  return _FilterChip(
                    label: s.label,
                    isSelected: sel,
                    color: s.color,
                    onTap: () => onStatusToggle(s),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Género ────────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FilterSection(
              title: 'Género',
              icon: Icons.category_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: genres.map((g) {
                  final sel = genreFilter.contains(g);
                  return _FilterChip(
                    label: g,
                    isSelected: sel,
                    color: _purple,
                    onTap: () => onGenreToggle(g),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Duración ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FilterSection(
              title: 'Duración (HLTB)',
              icon: Icons.timer_rounded,
              child: Wrap(
                spacing: 8,
                children: _DurationFilter.values.map((d) {
                  return _FilterChip(
                    label: d.label,
                    isSelected: durationFilter == d,
                    color: _yellow,
                    onTap: () => onDurationChanged(d),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Modo ──────────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FilterSection(
              title: 'Modo de juego',
              icon: Icons.people_rounded,
              child: Wrap(
                spacing: 8,
                children: _ModeFilter.values.map((m) {
                  return _FilterChip(
                    label: m.label,
                    isSelected: modeFilter == m,
                    color: _cyan,
                    onTap: () => onModeChanged(m),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // ── Botón principal ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 100),
            child: Column(
              children: [
                // Contador de juegos que coinciden
                Text(
                  '$poolCount ${poolCount == 1 ? 'juego coincide' : 'juegos coinciden'} con tus filtros',
                  style: const TextStyle(fontSize: 12, color: _textSub),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Botón grande
                GestureDetector(
                  onTap: onSpin,
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: poolCount > 0
                          ? const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF7B61FF)],
                            )
                          : null,
                      color: poolCount == 0 ? _bgCard2 : null,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: poolCount > 0
                          ? [
                              BoxShadow(
                                color: _cyan.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              )
                            ]
                          : null,
                      border: poolCount == 0
                          ? Border.all(color: _border)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: poolCount > 0 ? Colors.black : _textMuted,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '¡SORPRÉNDEME!',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: poolCount > 0 ? Colors.black : _textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        const Text(
          'Buscando tu próximo juego...',
          style: TextStyle(fontSize: 14, color: _textSub),
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
                  backgroundColor: _border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(_cyan, _green, animation.value)!,
                  ),
                  minHeight: 3,
                ),
                const SizedBox(height: 8),
                Text(
                  animation.value < 0.5
                      ? 'Barajando...'
                      : 'Casi...',
                  style: const TextStyle(fontSize: 11, color: _textMuted),
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
            border: Border.all(color: _border, width: 2),
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
                    color: _bgCard2,
                    child: const Icon(Icons.sports_esports_rounded,
                        color: _border, size: 48),
                  ),
                ),
                // Gradient overlay with title
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 11,
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
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13, color: _green),
                SizedBox(width: 6),
                Text('¡Tu próximo juego es!',
                    style: TextStyle(fontSize: 12, color: _green,
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
                  color: _cyan.withValues(alpha: 0.25),
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
                  color: _bgCard2,
                  child: const Icon(Icons.sports_esports_rounded,
                      color: _border, size: 60),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            game.title,
            style: const TextStyle(
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
                  style: const TextStyle(fontSize: 12, color: _textSub)),
              const Text('  ·  ',
                  style: TextStyle(fontSize: 12, color: _textMuted)),
              Text(game.platform.displayName,
                  style: const TextStyle(fontSize: 12, color: _textSub)),
              if (game.hltb?.main != null) ...[
                const Text('  ·  ',
                    style: TextStyle(fontSize: 12, color: _textMuted)),
                Text('~${game.hltb!.main}h',
                    style: const TextStyle(fontSize: 12, color: _cyan)),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Otro juego',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSub,
                    side: const BorderSide(color: _border),
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
                  label: const Text('Ver Detalles',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
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

// =============================================================================
// Shared sub-widgets
// =============================================================================

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.icon, required this.child});
  final String   title;
  final IconData icon;
  final Widget   child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _cyan),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: _textMain)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });
  final String   label;
  final bool     isSelected;
  final Color    color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : _bgCard2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : _border,
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
