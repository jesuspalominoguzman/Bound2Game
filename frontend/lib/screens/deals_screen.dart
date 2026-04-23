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
  int _heroPage = 0;
  final Set<String> _wishlist = {};

  // Hero = gratuitos primero, luego top deals (máx 8 total)
  List<GameDeal> get _heroDeals {
    final free = sampleDeals.where((d) => d.isFree).toList();
    final top = (sampleDeals.where((d) => !d.isFree).toList()
        ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent)))
        .take(4)
        .toList();
    return [...free, ...top];
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
          // ── 1. AppBar glassmorphism compacto ────────────────────────────
          _GlassAppBar(),

          // ── 2. Hero Carousel (gratuitos + top deals) ────────────────────
          SliverToBoxAdapter(
            child: _HeroCarousel(
              deals: heroes,
              currentPage: _heroPage,
              onPageChanged: (p) => setState(() => _heroPage = p),
              onTap: _openGame,
            ),
          ),

          // ── 3. Timeline próximos lanzamientos ───────────────────────────
          SliverToBoxAdapter(
            child: _UpcomingSection(
              wishlist: _wishlist,
              onToggleWishlist: _toggleWishlist,
            ),
          ),

          // ── 4. Explorar por tienda ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _StoreSection(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// =============================================================================
// _GlassAppBar — AppBar compacto con texto estilizado
// =============================================================================

class _GlassAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final freeCount = sampleDeals.where((d) => d.isFree).length;
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A).withValues(alpha: 0.82),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              left: 18, right: 18, bottom: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ofertas',
                        style: GoogleFonts.outfit(
                          fontSize: 26, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '$freeCount juegos gratis ahora mismo',
                        style: GoogleFonts.outfit(
                          fontSize: 11, color: _cyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicador premium
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B6DFF), Color(0xFF00E5FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'HOT 🔥',
                    style: GoogleFonts.outfit(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      toolbarHeight: MediaQuery.of(context).padding.top + 78,
    );
  }
}

// =============================================================================
// _HeroCarousel — PageView de deals destacados con glassmorphism
// =============================================================================

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.deals,
    required this.currentPage,
    required this.onPageChanged,
    required this.onTap,
  });

  final List<GameDeal> deals;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final void Function(GameDeal) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Label sección
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Row(
            children: [
              Text(
                'Lo mejor ahora',
                style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: _textMain, letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                '${currentPage + 1}/${deals.length}',
                style: const TextStyle(fontSize: 11, color: _textSub),
              ),
            ],
          ),
        ),

        // PageView
        SizedBox(
          height: 220,
          child: PageView.builder(
            padEnds: false,
            controller: PageController(viewportFraction: 0.88),
            itemCount: deals.length,
            onPageChanged: onPageChanged,
            itemBuilder: (ctx, i) => _HeroCard(
              deal: deals[i],
              isActive: i == currentPage,
              onTap: () => onTap(deals[i]),
            ),
          ),
        ),

        // Dots indicadores
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(deals.length, (i) {
            final active = i == currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? _cyan : _textMuted,
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
  const _HeroCard({required this.deal, required this.isActive, required this.onTap});
  final GameDeal deal;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cfg = deal.store.config;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(
          horizontal: 6, vertical: isActive ? 0 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [BoxShadow(
                  color: (deal.isFree ? _green : cfg.color).withValues(alpha: 0.25),
                  blurRadius: 20, offset: const Offset(0, 8),
                )]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
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

              // Gradiente oscuro inferior
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.2, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // Contenido inferior con glassmorphism
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badges fila
                          Row(
                            children: [
                              // Badge tienda
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cfg.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: cfg.color.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cfg.icon, size: 9, color: cfg.color),
                                    const SizedBox(width: 4),
                                    Text(cfg.shortName,
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: cfg.color)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Badge GRATIS o descuento
                              if (deal.isFree)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: _green.withValues(alpha: 0.5)),
                                  ),
                                  child: Text('GRATIS',
                                      style: GoogleFonts.outfit(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: _green)),
                                )
                              else
                                DiscountBadge(deal: deal, small: true),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Título
                          Text(
                            deal.gameTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Precio
                          Row(
                            children: [
                              if (!deal.isFree && deal.discountPercent > 0) ...[
                                Text(
                                  deal.originalPriceLabel,
                                  style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF888888),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                deal.salePriceLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 15, fontWeight: FontWeight.w900,
                                  color: deal.isFree ? _green : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                child: Icon(cfg.icon, color: cfg.color, size: 19),
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
