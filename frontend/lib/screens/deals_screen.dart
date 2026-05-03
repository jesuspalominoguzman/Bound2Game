// =============================================================================
// deals_screen.dart — Bound2Game Flutter (Estética Premium v2)
//
// Orden de secciones:
//   1. Hero Carousel  → Juegos Gratuitos + Top Deals (glassmorphism)
//   2. Próximos Lanzamientos → timeline horizontal con wishlist toggle
//   3. Explorar por Tienda  → grid 2 columnas → StoreDetailScreen
//
// Toda la navegación a juegos abre GameDetailScreen.
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/deal_model.dart';
import '../models/game_model.dart';
import '../widgets/discount_badge.dart';
import 'game_detail_screen.dart';
import 'store_detail_screen.dart';

// ── Color tokens ──────────────────────────────────────────────────────────────
const _bg      = Color(0xFF0A0A0A);
const _bgCard  = Color(0xFF161616);
const _bgCard2 = Color(0xFF1E1E1E);
const _border  = Color(0xFF242424);
const _textMain  = Color(0xFFE8E8E8);
const _textMuted = Color(0xFF4A4A4A);
const _textSub   = Color(0xFF7A7A7A);
const _cyan    = Color(0xFF00E5FF);
const _green   = Color(0xFF39FF7E);
const _yellow  = Color(0xFFFFB800);
const _purple  = Color(0xFF9B6DFF);

// ── Helpers: cruzar GameDeal → Game ─────────────────────────────────────────

Platform _storeToGamePlatform(DealStore store) {
  switch (store) {
    case DealStore.steam:         return Platform.steam;
    case DealStore.epic:          return Platform.epic;
    case DealStore.instantGaming: return Platform.ig;
    default:                      return Platform.integrated;
  }
}

Game _dealToGame(GameDeal deal) => Game(
  id: int.tryParse(deal.gameId) ?? 9999,
  title: deal.gameTitle,
  platform: _storeToGamePlatform(deal.store),
  genre: deal.genre ?? 'Varios',
  playtime: 0, status: GameStatus.unplayed,
  cover: deal.gameCover ?? '',
  pcReq: PcReq.green, hasCosmetics: false,
  price: deal.originalPrice, year: DateTime.now().year,
);

Game _resolveGame(GameDeal deal) => sampleGames.firstWhere(
  (g) => g.id.toString() == deal.gameId,
  orElse: () => _dealToGame(deal),
);

// =============================================================================
// DealsScreen
// =============================================================================

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final Set<String> _wishlist = {};

  // Hero = únicamente juegos gratuitos
  List<GameDeal> get _heroDeals {
    return sampleDeals.where((d) => d.isFree).toList();
  }

  void _toggleWishlist(String id) =>
      setState(() => _wishlist.contains(id)
          ? _wishlist.remove(id)
          : _wishlist.add(id));

  void _openGame(GameDeal deal) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => GameDetailScreen(game: _resolveGame(deal))),
  );

  @override
  Widget build(BuildContext context) {
    final heroes = _heroDeals;
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. Hero Carousel (Solo juegos gratuitos) ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _HeroCarousel(
                deals: heroes,
                onTap: _openGame,
              ),
            ),
          ),

          // ── 2. Timeline próximos lanzamientos ───────────────────────────
          SliverToBoxAdapter(
            child: _UpcomingSection(
              wishlist: _wishlist,
              onToggleWishlist: _toggleWishlist,
            ),
          ),

          // ── 3. Explorar por tienda ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _StoreSection(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// (Se elimina el _GlassAppBar)

// =============================================================================
// _HeroCarousel — PageView Animado (Cover Flow)
// =============================================================================

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({
    required this.deals,
    required this.onTap,
  });

  final List<GameDeal> deals;
  final void Function(GameDeal) onTap;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deals.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // PageView
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.deals.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: Curves.easeOut.transform(value),
                    child: Opacity(
                      opacity: value.clamp(0.4, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _HeroCard(
                  deal: widget.deals[index],
                  onTap: () => widget.onTap(widget.deals[index]),
                ),
              );
            },
          ),
        ),

        // Dots indicadores
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.deals.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? _yellow : _textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.deal, required this.onTap});
  final GameDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cfg = deal.store.config;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Portada de fondo
              deal.gameCover != null
                  ? Image.network(
                      deal.gameCover!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: _bgCard2),
                    )
                  : Container(color: _bgCard2),

              // Gradiente oscuro inferior agresivo
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Contenido inferior
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tienda
                      Row(
                        children: [
                          Icon(cfg.icon, size: 14, color: cfg.color),
                          const SizedBox(width: 6),
                          Text(cfg.name,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: cfg.color)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Título
                      Text(
                        deal.gameTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Precio original tachado (muy sutil)
                      Text(
                        deal.originalPriceLabel,
                        style: const TextStyle(
                          fontSize: 13, color: Color(0xFF888888),
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón RECLAMAR
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _yellow,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _yellow.withValues(alpha: 0.3),
                              blurRadius: 12, offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'RECLAMAR AHORA',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
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
    );
  }
}

// =============================================================================
// _UpcomingSection — Timeline horizontal de próximos lanzamientos
// =============================================================================

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.wishlist, required this.onToggleWishlist});
  final Set<String> wishlist;
  final void Function(String) onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rocket_launch_rounded,
                    size: 14, color: _purple),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximos Lanzamientos',
                    style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: _textMain, letterSpacing: -0.2,
                    ),
                  ),
                  const Text('Activa el aviso del día de estreno',
                      style: TextStyle(fontSize: 10, color: _textMuted)),
                ],
              ),
            ],
          ),
        ),

        // Timeline horizontal
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: sampleUpcoming.length,
            itemBuilder: (ctx, i) {
              final game = sampleUpcoming[i];
              final inWishlist = wishlist.contains(game.id);
              return _UpcomingCard(
                game: game,
                inWishlist: inWishlist,
                onToggle: () => onToggleWishlist(game.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.game, required this.inWishlist, required this.onToggle,
  });
  final UpcomingGame game;
  final bool inWishlist;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final daysLeft = game.releaseDate.difference(DateTime.now()).inDays;
    final daysLabel = daysLeft <= 0
        ? '¡Ya disponible!'
        : daysLeft == 1 ? 'Mañana' : 'En $daysLeft días';

    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inWishlist
              ? _purple.withValues(alpha: 0.4)
              : _border,
        ),
        boxShadow: inWishlist
            ? [BoxShadow(
                color: _purple.withValues(alpha: 0.12),
                blurRadius: 12,
              )]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portada
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 105, width: double.infinity,
              child: game.cover != null
                  ? Image.network(game.cover!, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: _bgCard2))
                  : Container(color: _bgCard2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(game.title,
                      style: GoogleFonts.outfit(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: _textMain,
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),

                  // Fecha + countdown
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 9, color: _textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(game.releaseDateLabel,
                            style: const TextStyle(
                                fontSize: 9, color: _textMuted),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  Text(daysLabel,
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: daysLeft <= 7 ? _yellow : _textSub,
                      )),
                  const Spacer(),

                  // Botón lista de deseos
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: inWishlist
                            ? _purple.withValues(alpha: 0.22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: inWishlist
                              ? _purple.withValues(alpha: 0.6)
                              : _border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            inWishlist
                                ? Icons.notifications_active_rounded
                                : Icons.add_alert_rounded,
                            size: 11,
                            color: inWishlist ? _purple : _textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            inWishlist ? '¡Activado!' : 'Avisar',
                            style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: inWishlist ? _purple : _textMuted,
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
      ),
    );
  }
}

// =============================================================================
// _StoreSection — Grid 2 col de tiendas → StoreDetailScreen
// =============================================================================

class _StoreSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded,
                    size: 14, color: _cyan),
              ),
              const SizedBox(width: 10),
              Text(
                'Explorar por Tienda',
                style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: _textMain, letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),

        // Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: DealStore.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.0,
            ),
            itemBuilder: (ctx, i) {
              final store = DealStore.values[i];
              final count = sampleDeals.where((d) => d.store == store).length;
              return _StoreCard(
                store: store,
                dealCount: count,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StoreDetailScreen(store: store),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store, required this.dealCount, required this.onTap,
  });
  final DealStore store;
  final int dealCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cfg = store.config;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cfg.color.withValues(alpha: 0.18)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cfg.color.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: cfg.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: store == DealStore.steam
                      ? Image.asset('assets/images/steam_logo.jpeg', width: 24, height: 24, fit: BoxFit.contain)
                      : store == DealStore.epic
                          ? Image.asset('assets/images/epic_logo.jpeg', width: 24, height: 24, fit: BoxFit.contain)
                          : store == DealStore.instantGaming
                              ? Image.asset('assets/images/instant_logo.png', width: 24, height: 24, fit: BoxFit.contain)
                              : Icon(cfg.icon, color: cfg.color, size: 19),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cfg.name,
                        style: GoogleFonts.outfit(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: cfg.color,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      dealCount > 0
                          ? '$dealCount oferta${dealCount != 1 ? "s" : ""}'
                          : 'Sin ofertas',
                      style: TextStyle(
                        fontSize: 9,
                        color: dealCount > 0 ? _textSub : _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 15, color: cfg.color.withValues(alpha: 0.45)),
            ],
          ),
        ),
      ),
    );
  }
}
