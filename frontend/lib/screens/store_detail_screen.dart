// =============================================================================
// store_detail_screen.dart — Bound2Game Flutter
// Catálogo completo de una tienda con filtros avanzados y GridView 2 columnas.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/deal_model.dart';
import '../models/game_model.dart';
import '../widgets/advanced_filters_modal.dart';
import '../widgets/store_logo.dart';
import '../services/api_service.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF101010);
const _bgCard  = Color(0xFF181818);
const _bgCard2 = Color(0xFF1C1C1C);
const _border  = Color(0xFF252525);
const _textMain  = Color(0xFFD1D1D1);
const _textMuted = Color(0xFF555555);
const _green   = Color(0xFF4AF626);

Future<void> _launchDealUrl(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

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
  late Future<List<Deal>> _dealsFuture;
  List<Deal> _allDeals = [];

  DealStore get _store => widget.store;
  DealStoreConfig get _cfg => _store.config;

  @override
  void initState() {
    super.initState();
    _dealsFuture = _fetchStoreDeals();
  }

  Future<List<Deal>> _fetchStoreDeals() async {
    final deals = await ApiService.fetchDeals(limit: 200);
    // Filtrar solo los de la tienda
    _allDeals = deals.where((d) => d.storeEnum == _store).toList();
    return _allDeals;
  }

  // ── Lista filtrada ─────────────────────────────────────────────────────────

  List<Deal> get _filtered {
    return _allDeals.where((d) {
      // Precio
      if (_filters.priceEnabled && d.salePrice > _filters.maxPrice) return false;

      // Género: Deal no tiene genre por defecto
      if (_filters.genreEnabled && _filters.genres.isNotEmpty) {
        return false; // Por ahora no filtramos por género si no lo tenemos de API
      }

      return true;
    }).toList()
      ..sort((a, b) => b.calculatedDiscount.compareTo(a.calculatedDiscount));
  }

  List<String> get _availableGenres {
    return []; // No disponemos de géneros en la vista de Deals
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Deal>>(
      future: _dealsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final deals = isLoading ? <Deal>[] : _filtered;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar con color de tienda ───────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: _bg,
            // ── Acciones (filtros) ──────────────────────────────────────────
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
            // ── Botón atrás ─────────────────────────────────────────────────
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
            // ── Branding centrado en el área expandida ───────────────────────
            // NO usamos 'title' de FlexibleSpaceBar para evitar el conflicto
            // con el leading. Todo el branding va dentro de 'background'.
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradiente de fondo
                  Container(
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

                  // Branding centrado — con padding superior para respetar
                  // la AppBar colapsada (≈ kToolbarHeight = 56px)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo real de la tienda
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _cfg.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: StoreLogoWidget(store: widget.store, size: 32),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Nombre de la tienda
                        Text(
                          _cfg.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // Contador de ofertas
                        if (isLoading)
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _cfg.color, strokeWidth: 2))
                        else
                          Text(
                            '${_allDeals.length} ofertas disponibles',
                          style: TextStyle(
                            fontSize: 11,
                            color: _cfg.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    onTap: () => _launchDealUrl(deals[i].dealUrl),
                  ),
                  childCount: deals.length,
                ),
              ),
            ),
          ],
        ),
      );
      },
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
  final Deal deal;
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
            color: deal.salePrice <= 0
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
                child: deal.thumbUrl.isNotEmpty
                    ? Image.network(
                        deal.thumbUrl,
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
                    deal.title,
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
                            if (deal.salePrice > 0 && deal.calculatedDiscount > 0)
                              Text(
                                '${deal.normalPrice.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontSize: 9, color: _textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              deal.salePrice <= 0 ? 'GRATIS' : '${deal.salePrice.toStringAsFixed(2)} €',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w900,
                                color: deal.salePrice <= 0 ? _green : _textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge descuento
                      if (deal.calculatedDiscount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(4)),
                          child: Text('-${deal.calculatedDiscount}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black)),
                        ),
                    ],
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
