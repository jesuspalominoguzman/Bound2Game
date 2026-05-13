// =============================================================================
// deals_screen.dart — Bound2Game Flutter (API Real Integration)
//
// Orden de secciones:
//   1. Hero Carousel  → Juegos Gratuitos (Glassmorphism)
//   2. Mejores Ofertas → Tarjetas calculadas horizontalmente
//   3. Próximos Lanzamientos → Timeline horizontal
//   4. Explorar por Tienda  → Grid
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/deal_model.dart';
import '../models/game_model.dart';
import 'game_detail_screen.dart';
import 'store_detail_screen.dart';
import '../widgets/store_logo.dart';
import '../services/api_service.dart';

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

// ── Helpers: cruzar Deal → Game ─────────────────────────────────────────────

Platform _storeToGamePlatform(DealStore store) {
  switch (store) {
    case DealStore.steam:         return Platform.steam;
    case DealStore.epic:          return Platform.epic;
    default:                      return Platform.integrated;
  }
}

Game _dealToGame(Deal deal) => Game(
  id: int.tryParse(deal.id) ?? 9999,
  title: deal.title,
  platform: _storeToGamePlatform(deal.storeEnum),
  genre: 'Varios',
  playtime: 0, status: GameStatus.unplayed,
  cover: deal.thumbUrl,
  pcReq: PcReq.green, hasCosmetics: false,
  price: deal.normalPrice, year: DateTime.now().year,
);

// _resolveGame: ya no depende de sampleGames, usa solo datos de la oferta
Game _resolveGame(Deal deal) => _dealToGame(deal);

Future<void> _launchDealUrl(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

String _formatDate(String dateStr) {
  try {
    final dt = DateTime.parse(dateStr);
    const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return dateStr;
  }
}

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

  late Future<List<Deal>> _freeGamesFuture;
  late Future<List<Deal>> _topDealsFuture;
  late Future<List<Deal>> _upcomingGamesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _freeGamesFuture = ApiService.fetchFreeGames();
      _topDealsFuture = ApiService.fetchDeals(limit: 10);
      _upcomingGamesFuture = ApiService.fetchUpcomingGames();
    });
  }

  void _toggleWishlist(String id) =>
      setState(() => _wishlist.contains(id)
          ? _wishlist.remove(id)
          : _wishlist.add(id));

  void _openGame(Deal deal) => _launchDealUrl(deal.dealUrl);

  Widget _buildLoading() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(color: _cyan, strokeWidth: 2),
      ),
    );
  }

  Widget _buildError(VoidCallback onRetry) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: _textSub, size: 32),
            const SizedBox(height: 12),
            Text('Error al cargar ofertas', style: GoogleFonts.outfit(color: _textSub)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: _cyan),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: _cyan,
        backgroundColor: _bgCard,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── 1. Hero Carousel (juegos gratuitos) ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FutureBuilder<List<Deal>>(
                  future: _freeGamesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return _buildLoading();
                    if (snapshot.hasError) return _buildError(() => setState(() { _freeGamesFuture = ApiService.fetchFreeGames(); }));
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                    return _HeroCarousel(deals: snapshot.data!, onTap: _openGame);
                  },
                ),
              ),
            ),

            // ── 2. Mejores Ofertas ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: FutureBuilder<List<Deal>>(
                future: _topDealsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return _buildLoading();
                  if (snapshot.hasError) return _buildError(() => setState(() { _topDealsFuture = ApiService.fetchDeals(limit: 10); }));
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                  return _TopDealsSection(deals: snapshot.data!, onTap: _openGame);
                },
              ),
            ),

            // ── 3. Timeline próximos lanzamientos ───────────────────────────
            SliverToBoxAdapter(
              child: FutureBuilder<List<Deal>>(
                future: _upcomingGamesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return _buildLoading();
                  if (snapshot.hasError) return _buildError(() => setState(() { _upcomingGamesFuture = ApiService.fetchUpcomingGames(); }));
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                  return _UpcomingSection(
                    deals: snapshot.data!,
                    wishlist: _wishlist,
                    onToggleWishlist: _toggleWishlist,
                  );
                },
              ),
            ),

            // ── 4. Explorar por tienda ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _StoreSection(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _TopDealsSection — Lista horizontal de Deals con descuento real calculado
// =============================================================================

class _TopDealsSection extends StatelessWidget {
  final List<Deal> deals;
  final void Function(Deal) onTap;
  
  const _TopDealsSection({required this.deals, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) return const SizedBox.shrink();
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
                child: const Icon(Icons.local_fire_department_rounded,
                    size: 14, color: _cyan),
              ),
              const SizedBox(width: 10),
              Text(
                'Mejores Ofertas',
                style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: _textMain, letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        // Horizontal list
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: deals.length,
            itemBuilder: (ctx, i) {
              return DealCard(deal: deals[i], onTap: () => onTap(deals[i]));
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DealCard — Tarjeta de descuento
// =============================================================================

class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.deal, required this.onTap});
  final Deal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cfg = deal.storeEnum.config;
    final discount = deal.calculatedDiscount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    height: 85, width: double.infinity,
                    child: deal.thumbUrl.isNotEmpty
                        ? Image.network(deal.thumbUrl, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: _bgCard2))
                        : Container(color: _bgCard2),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('-$discount%',
                          style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w900,
                            color: Colors.black,
                          )),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tienda
                    Row(
                      children: [
                        Icon(cfg.icon, size: 10, color: cfg.color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(cfg.name,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: cfg.color),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Título
                    Text(deal.title,
                        style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: _textMain, height: 1.1,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    // Precios
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (discount > 0)
                          Text('${deal.normalPrice.toStringAsFixed(2)}€',
                              style: const TextStyle(
                                fontSize: 10, color: _textSub,
                                decoration: TextDecoration.lineThrough,
                              )),
                        if (discount > 0) const SizedBox(width: 4),
                        Text(deal.salePrice == 0 ? 'GRATIS' : '${deal.salePrice.toStringAsFixed(2)}€',
                            style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: deal.salePrice == 0 ? _green : _textMain,
                            )),
                      ],
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
// _HeroCarousel — PageView Animado (Cover Flow)
// =============================================================================

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({
    required this.deals,
    required this.onTap,
  });

  final List<Deal> deals;
  final void Function(Deal) onTap;

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
  final Deal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cfg = deal.storeEnum.config;
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
              deal.thumbUrl.isNotEmpty
                  ? Image.network(
                      deal.thumbUrl,
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
                        deal.title,
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
                      if (deal.normalPrice > 0)
                        Text(
                          '${deal.normalPrice.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 13, color: Color(0xFF888888),
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Botón RECLAMAR
                      GestureDetector(
                        onTap: () => _launchDealUrl(deal.dealUrl),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: deal.dealUrl != null ? _yellow : _textMuted,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: deal.dealUrl != null ? [
                              BoxShadow(
                                color: _yellow.withValues(alpha: 0.3),
                                blurRadius: 12, offset: const Offset(0, 4),
                              )
                            ] : [],
                          ),
                          child: Center(
                            child: Text(
                              deal.dealUrl != null ? 'RECLAMAR AHORA' : 'NO DISPONIBLE',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
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
  const _UpcomingSection({required this.deals, required this.wishlist, required this.onToggleWishlist});
  final List<Deal> deals;
  final Set<String> wishlist;
  final void Function(String) onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) return const SizedBox.shrink();

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
            itemCount: deals.length,
            itemBuilder: (ctx, i) {
              final deal = deals[i];
              final inWishlist = wishlist.contains(deal.id);
              return _UpcomingCard(
                deal: deal,
                inWishlist: inWishlist,
                onToggle: () => onToggleWishlist(deal.id),
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
    required this.deal, required this.inWishlist, required this.onToggle,
  });
  final Deal deal;
  final bool inWishlist;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
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
              child: deal.thumbUrl.isNotEmpty
                  ? Image.network(deal.thumbUrl, fit: BoxFit.cover,
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
                  Text(deal.title,
                      style: GoogleFonts.outfit(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: _textMain,
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),

                  // Fecha real de lanzamiento
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 9, color: _textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          deal.releaseDate != null
                              ? _formatDate(deal.releaseDate!)
                              : 'Próximamente',
                          style: const TextStyle(
                              fontSize: 9, color: _textMuted),
                          overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
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

        // Grid (Estático ahora que no dependemos de sampleDeals)
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
              return _StoreCard(
                store: store,
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
    required this.store, required this.onTap,
  });
  final DealStore store;
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
                  child: StoreLogoWidget(store: store, size: 24),
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
                    const Text(
                      'Explorar',
                      style: TextStyle(
                        fontSize: 9,
                        color: _textSub,
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
