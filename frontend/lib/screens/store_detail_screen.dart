// =============================================================================
// store_detail_screen.dart — Bound2Game Flutter
// Catálogo completo de una tienda con filtros avanzados y GridView 2 columnas.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/deal_model.dart';
import '../models/game_model.dart';
import '../widgets/discount_badge.dart';
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

// ── Constantes de filtro ──────────────────────────────────────────────────────

const _priceLabels = ['Todos', '<10 €', '<20 €', '<40 €'];
const _modeLabels  = ['Todos', 'Single Player', 'Multijugador'];

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
  int _priceIdx = 0;
  String? _genreFilter;
  int _modeIdx = 0;

  DealStore get _store => widget.store;
  DealStoreConfig get _cfg => _store.config;

  // ── Lista filtrada ─────────────────────────────────────────────────────────

  List<GameDeal> get _filtered {
    return sampleDeals.where((d) {
      if (d.store != _store) return false;

      // Precio
      if (_priceIdx == 1 && d.salePrice >= 10)  return false;
      if (_priceIdx == 2 && d.salePrice >= 20)  return false;
      if (_priceIdx == 3 && d.salePrice >= 40)  return false;

      // Género
      if (_genreFilter != null && d.genre != _genreFilter) return false;

      // Modo
      if (_modeIdx == 1 && d.playerMode == PlayerMode.multi)  return false;
      if (_modeIdx == 2 && d.playerMode == PlayerMode.solo)   return false;

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

          // ── Barra de filtros (sticky) ────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(
              priceIdx: _priceIdx,
              modeIdx: _modeIdx,
              genreFilter: _genreFilter,
              availableGenres: _availableGenres,
              storeColor: _cfg.color,
              onPriceChanged: (i) => setState(() => _priceIdx = i),
              onModeChanged: (i) => setState(() => _modeIdx = i),
              onGenreChanged: (g) => setState(() => _genreFilter = g),
            ),
          ),

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

// =============================================================================
// _FilterBarDelegate — SliverPersistentHeader con chips de filtro
// =============================================================================

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final int priceIdx;
  final int modeIdx;
  final String? genreFilter;
  final List<String> availableGenres;
  final Color storeColor;
  final ValueChanged<int> onPriceChanged;
  final ValueChanged<int> onModeChanged;
  final ValueChanged<String?> onGenreChanged;

  const _FilterBarDelegate({
    required this.priceIdx,
    required this.modeIdx,
    required this.genreFilter,
    required this.availableGenres,
    required this.storeColor,
    required this.onPriceChanged,
    required this.onModeChanged,
    required this.onGenreChanged,
  });

  @override double get minExtent => 100;
  @override double get maxExtent => 100;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF131313),
      child: Column(
        children: [
          // Fila 1: Precio + Modo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                _FilterLabel(label: 'Precio:'),
                ...List.generate(_priceLabels.length, (i) => _FilterChip(
                  label: _priceLabels[i],
                  active: priceIdx == i,
                  color: storeColor,
                  onTap: () => onPriceChanged(i),
                )),
                const SizedBox(width: 12),
                _FilterLabel(label: 'Modo:'),
                ...List.generate(_modeLabels.length, (i) => _FilterChip(
                  label: _modeLabels[i],
                  active: modeIdx == i,
                  color: storeColor,
                  onTap: () => onModeChanged(i),
                )),
              ],
            ),
          ),
          // Fila 2: Géneros
          if (availableGenres.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  _FilterLabel(label: 'Género:'),
                  _FilterChip(
                    label: 'Todos',
                    active: genreFilter == null,
                    color: storeColor,
                    onTap: () => onGenreChanged(null),
                  ),
                  ...availableGenres.map((g) => _FilterChip(
                    label: g,
                    active: genreFilter == g,
                    color: storeColor,
                    onTap: () => onGenreChanged(genreFilter == g ? null : g),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate old) =>
      old.priceIdx != priceIdx || old.modeIdx != modeIdx ||
      old.genreFilter != genreFilter;
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Text(label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF555555),
            fontWeight: FontWeight.w600)),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label, required this.active,
    required this.color, required this.onTap,
  });
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.18) : const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : const Color(0xFF252525),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: active ? color : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

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
