// =============================================================================
// store_detail_screen.dart — Bound2Game Flutter
// Catálogo completo de una tienda con filtros avanzados y GridView 2 columnas.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/deal_model.dart';
import '../models/game_model.dart';
import '../widgets/discount_badge.dart';
import '../widgets/advanced_filters_modal.dart';
import 'game_detail_screen.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF101010);
const _bgCard  = Color(0xFF181818);
const _bgCard2 = Color(0xFF1C1C1C);
const _border  = Color(0xFF252525);
const _textMain  = Color(0xFFD1D1D1);
const _textMuted = Color(0xFF555555);
const _green   = Color(0xFF4AF626);

// ── Helpers: cruzar GameDeal con sampleGames ──────────────────────────────────

Platform _storeToGamePlatform(DealStore store) {
  switch (store) {
    case DealStore.steam:        return Platform.steam;
    case DealStore.epic:         return Platform.epic;
    case DealStore.instantGaming:return Platform.ig;
    default:                     return Platform.integrated;
  }
}

Game _dealToGame(GameDeal deal) => Game(
  id: int.tryParse(deal.gameId) ?? 9999,
  title: deal.gameTitle,
  platform: _storeToGamePlatform(deal.store),
  genre: deal.genre ?? 'Varios',
  playtime: 0,
  status: GameStatus.unplayed,
  cover: deal.gameCover ?? '',
  pcReq: PcReq.green,
  hasCosmetics: false,
  price: deal.originalPrice,
  year: DateTime.now().year,
);

Game _resolveGame(GameDeal deal) => sampleGames.firstWhere(
  (g) => g.id.toString() == deal.gameId,
  orElse: () => _dealToGame(deal),
);

// =============================================================================
// StoreDetailScreen
// =============================================================================

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key, required this.store});
  final DealStore store;

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  LibraryFilters _filters = const LibraryFilters(priceEnabled: false);

  DealStore get _store => widget.store;
  DealStoreConfig get _cfg => _store.config;

  // ── Lista filtrada ─────────────────────────────────────────────────────────

  List<GameDeal> get _filtered {
    return sampleDeals.where((d) {
      if (d.store != _store) return false;

      // Precio
      if (_filters.priceEnabled && d.salePrice > _filters.maxPrice) return false;

      // Género
      if (_filters.genreEnabled && _filters.genres.isNotEmpty) {
        if (d.genre == null) return false;
        if (!_filters.genres.any((g) => d.genre!.toLowerCase().contains(g.toLowerCase()))) return false;
      }

      // Modo
      if (_filters.modalityEnabled && _filters.modalities.isNotEmpty) {
        final wantsMulti = _filters.modalities.contains(FilterModality.multi);
        final wantsSingle = _filters.modalities.contains(FilterModality.single);
        final isMulti = d.playerMode == PlayerMode.multi;
        if (wantsMulti && !isMulti) return false;
        if (wantsSingle && isMulti) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
  }

  List<String> get _availableGenres {
    final genres = sampleDeals
        .where((d) => d.store == _store && d.genre != null)
        .map((d) => d.genre!)
        .toSet()
        .toList()
      ..sort();
    return genres;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final deals = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar con color de tienda ───────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: _bg,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                onPressed: () async {
                  final result = await showAdvancedFilters(
                    context: context,
                    current: _filters,
                    availableGenres: _availableGenres,
                    showPriceFilter: true,
                  );
                  if (result != null) {
                    setState(() => _filters = result);
                  }
                },
              ),
            ],
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _cfg.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_cfg.icon, color: _cfg.color, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _cfg.name,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${sampleDeals.where((d) => d.store == _store).length} ofertas',
                    style: TextStyle(
                      fontSize: 10, color: _cfg.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _cfg.color.withValues(alpha: 0.25),
                      _bg,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // (Se eliminó _FilterBarDelegate a favor de AdvancedFiltersModal)

          // ── Grid de juegos ───────────────────────────────────────────────
          if (deals.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 48,
                        color: Color(0xFF333333)),
                    SizedBox(height: 12),
                    Text('Sin resultados con estos filtros',
                        style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _DealGridCard(
                    deal: deals[i],
                    storeColor: _cfg.color,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GameDetailScreen(game: _resolveGame(deals[i])),
                      ),
                    ),
                  ),
                  childCount: deals.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// (Filtros en línea eliminados)

// =============================================================================
// _DealGridCard — Tarjeta de juego 2 columnas
// =============================================================================

class _DealGridCard extends StatelessWidget {
  const _DealGridCard({
    required this.deal, required this.storeColor, required this.onTap,
  });
  final GameDeal deal;
  final Color storeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: deal.isFree
                ? _green.withValues(alpha: 0.3)
                : _border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: deal.gameCover != null
                    ? Image.network(
                        deal.gameCover!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: _bgCard2,
                              child: const Icon(Icons.sports_esports_rounded,
                                  color: Color(0xFF333333), size: 32)),
                      )
                    : Container(color: _bgCard2),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.gameTitle,
                    style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: _textMain,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // Precio
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!deal.isFree && deal.discountPercent > 0)
                              Text(
                                deal.originalPriceLabel,
                                style: const TextStyle(
                                  fontSize: 9, color: _textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              deal.salePriceLabel,
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w900,
                                color: deal.isFree ? _green : _textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge descuento
                      if (deal.discountPercent > 0)
                        DiscountBadge(deal: deal, small: true),
                    ],
                  ),
                  // Género
                  if (deal.genre != null) ...[
                    const SizedBox(height: 4),
                    Text(deal.genre!,
                        style: const TextStyle(fontSize: 9, color: _textMuted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
