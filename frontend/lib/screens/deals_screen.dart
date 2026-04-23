// =============================================================================
// deals_screen.dart — Bound2Game Flutter
// Sistema de Ofertas Globales (Deals Engine)
//
// Lógica de priorización:
//   1. Juegos gratuitos (isFree == true) → sección destacada arriba
//   2. Resto → agrupados por tienda, ordenados por discountPercent desc
//
// Smart View: máximo 5 títulos por tienda + botón "Ver más en [Tienda]"
// Filtros de plataforma: chips persistentes via DealsPrefService
// =============================================================================

import 'package:flutter/material.dart';
import '../models/deal_model.dart';
import '../services/deals_prefs_service.dart';
import '../widgets/discount_badge.dart';

// ── Color tokens (consistentes con el resto de la app) ────────────────────────
const _bg      = Color(0xFF101010);
const _bgCard  = Color(0xFF181818);
const _bgCard2 = Color(0xFF1C1C1C);
const _border  = Color(0xFF252525);
const _textMain  = Color(0xFFD1D1D1);
const _textMuted = Color(0xFF555555);
const _textSub   = Color(0xFF888888);
const _cyan    = Color(0xFF00E5FF);
const _green   = Color(0xFF4AF626);
const _yellow  = Color(0xFFFFB800);

// Límite Smart View por tienda
const int _kSmartViewLimit = 5;

// =============================================================================
// DealsScreen
// =============================================================================

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  DealsPrefService? _svc;
  bool _loading = true;

  /// Tiendas expandidas (más allá del límite Smart View).
  final Set<DealStore> _expandedStores = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _svc = await DealsPrefService.instance;
    if (mounted) setState(() => _loading = false);
  }

  // ── Datos filtrados y priorizados ─────────────────────────────────────────

  List<GameDeal> get _visibleDeals {
    if (_svc == null) return [];
    return sampleDeals
        .where((d) => _svc!.isStoreVisible(d.store))
        .toList();
  }

  List<GameDeal> get _freeDeals =>
      _visibleDeals.where((d) => d.isFree).toList();

  /// Deals pagados agrupados por tienda, ordenados por % desc.
  Map<DealStore, List<GameDeal>> get _dealsByStore {
    final paid = _visibleDeals.where((d) => !d.isFree).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    final map = <DealStore, List<GameDeal>>{};
    for (final deal in paid) {
      map.putIfAbsent(deal.store, () => []).add(deal);
    }
    return map;
  }

  Set<DealStore> get _activeStores {
    if (_svc == null) return DealStore.values.toSet();
    return DealStore.values.where((s) => _svc!.isStoreVisible(s)).toSet();
  }

  Future<void> _toggleStore(DealStore store, bool visible) async {
    await _svc!.setStoreVisible(store, visible);
    setState(() {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _cyan)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────
          _DealsAppBar(
            onSettingsTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _NotifSettingsSheet()),
            ),
          ),

          // ── Chips de filtro ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _PlatformFilterChips(
              activeStores: _activeStores,
              onToggle: _toggleStore,
            ),
          ),

          // ── Sección: Juegos Gratuitos ────────────────────────────────────
          if (_freeDeals.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.card_giftcard_rounded,
              iconColor: _green,
              title: 'Gratis Ahora',
              subtitle: '${_freeDeals.length} juego${_freeDeals.length != 1 ? "s" : ""} disponibles',
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _FreeGameCard(deal: _freeDeals[i]),
                  childCount: _freeDeals.length,
                ),
              ),
            ),
          ],

          // ── Sección: Mejores Ofertas (agrupadas por tienda) ─────────────
          if (_dealsByStore.isNotEmpty)
            _SectionHeader(
              icon: Icons.local_offer_rounded,
              iconColor: _yellow,
              title: 'Mejores Ofertas',
              subtitle: 'Ordenadas por mayor descuento',
            ),

          for (final entry in _dealsByStore.entries) ...[
            // Sticky header de tienda
            SliverPersistentHeader(
              pinned: false,
              delegate: _StoreHeaderDelegate(store: entry.key),
            ),
            // Lista de deals (con Smart View)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: _StoreDealsSliver(
                deals: entry.value,
                store: entry.key,
                isExpanded: _expandedStores.contains(entry.key),
                onExpandTap: () => setState(() {
                  if (_expandedStores.contains(entry.key)) {
                    _expandedStores.remove(entry.key);
                  } else {
                    _expandedStores.add(entry.key);
                  }
                }),
              ),
            ),
          ],

          // Padding inferior para el BottomBar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// =============================================================================
// _DealsAppBar
// =============================================================================

class _DealsAppBar extends StatelessWidget {
  const _DealsAppBar({required this.onSettingsTap});
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: const Color(0xFF151515),
      expandedHeight: 100,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_offer_rounded, color: _cyan, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ofertas Globales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF151515), Color(0xFF101820)],
            ),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: onSettingsTap,
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.notifications_rounded, color: _textSub, size: 18),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _PlatformFilterChips
// =============================================================================

class _PlatformFilterChips extends StatelessWidget {
  const _PlatformFilterChips({
    required this.activeStores,
    required this.onToggle,
  });

  final Set<DealStore> activeStores;
  final void Function(DealStore, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF151515),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: DealStore.values.map((store) {
            final active = activeStores.contains(store);
            final cfg = store.config;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onToggle(store, !active),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? cfg.color.withValues(alpha: 0.15)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? cfg.color.withValues(alpha: 0.5)
                          : _border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cfg.icon,
                        size: 12,
                        color: active ? cfg.color : _textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        cfg.name.split(' ').first, // Nombre corto
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: active ? cfg.color : _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// =============================================================================
// _SectionHeader (SliverToBoxAdapter)
// =============================================================================

class _SectionHeader extends SliverToBoxAdapter {
  _SectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) : super(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textMain,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10, color: _textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
}

// =============================================================================
// _StoreHeaderDelegate — Sticky header de tienda
// =============================================================================

class _StoreHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StoreHeaderDelegate({required this.store});
  final DealStore store;

  @override
  double get minExtent => 42;
  @override
  double get maxExtent => 42;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cfg = store.config;
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cfg.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cfg.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cfg.icon, size: 11, color: cfg.color),
                const SizedBox(width: 4),
                Text(
                  cfg.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cfg.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StoreHeaderDelegate oldDelegate) =>
      oldDelegate.store != store;
}

// =============================================================================
// _StoreDealsSliver — Lista de deals de una tienda con Smart View
// =============================================================================

class _StoreDealsSliver extends StatelessWidget {
  const _StoreDealsSliver({
    required this.deals,
    required this.store,
    required this.isExpanded,
    required this.onExpandTap,
  });

  final List<GameDeal> deals;
  final DealStore store;
  final bool isExpanded;
  final VoidCallback onExpandTap;

  @override
  Widget build(BuildContext context) {
    final visible = isExpanded
        ? deals
        : deals.take(_kSmartViewLimit).toList();
    final hasMore = deals.length > _kSmartViewLimit;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          if (i < visible.length) {
            return RepaintBoundary(child: _DealTile(deal: visible[i]));
          }
          // Botón "Ver más en [Tienda]" / "Ver menos"
          return _ExpandButton(
            storeName: store.config.name,
            isExpanded: isExpanded,
            remaining: deals.length - _kSmartViewLimit,
            onTap: onExpandTap,
          );
        },
        childCount: visible.length + (hasMore ? 1 : 0),
      ),
    );
  }
}

// =============================================================================
// _FreeGameCard — Tarjeta destacada para juego gratuito
// =============================================================================

class _FreeGameCard extends StatelessWidget {
  const _FreeGameCard({required this.deal});
  final GameDeal deal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 100,
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4AF626).withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Imagen de portada
            SizedBox(
              width: 80,
              child: deal.gameCover != null
                  ? Image.network(
                      deal.gameCover!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: _bgCard2,
                        child: const Icon(Icons.sports_esports_rounded,
                            color: _textMuted, size: 28),
                      ),
                    )
                  : Container(
                      color: _bgCard2,
                      child: const Icon(Icons.sports_esports_rounded,
                          color: _textMuted, size: 28),
                    ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        // Badge GRATIS
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: _green.withValues(alpha: 0.4)),
                          ),
                          child: const Text('GRATIS',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _green)),
                        ),
                        const SizedBox(width: 6),
                        // Badge tienda
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: deal.store.config.background,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            deal.store.config.shortName,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: deal.store.config.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      deal.gameTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (deal.expiresAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Hasta el ${deal.expiresAt!.day}/${deal.expiresAt!.month}',
                        style: const TextStyle(
                            fontSize: 10, color: _textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Precio original tachado + GRATIS
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (deal.originalPrice > 0)
                    Text(
                      deal.originalPriceLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  const Text(
                    'GRATIS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _green,
                    ),
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

// =============================================================================
// _DealTile — Fila compacta para oferta pagada
// =============================================================================

class _DealTile extends StatelessWidget {
  const _DealTile({required this.deal});
  final GameDeal deal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Miniatura
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 48,
              child: deal.gameCover != null
                  ? Image.network(
                      deal.gameCover!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: _bgCard2),
                    )
                  : Container(color: _bgCard2),
            ),
          ),
          const SizedBox(width: 10),

          // Título y expiración
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.gameTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (deal.expiresAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Hasta ${deal.expiresAt!.day}/${deal.expiresAt!.month}',
                    style:
                        const TextStyle(fontSize: 10, color: _textMuted),
                  ),
                ],
              ],
            ),
          ),

          // Precio + badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DiscountBadge(deal: deal, small: true),
              const SizedBox(height: 3),
              Text(
                deal.salePriceLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _textMain,
                ),
              ),
              Text(
                deal.originalPriceLabel,
                style: const TextStyle(
                  fontSize: 9,
                  color: _textMuted,
                  decoration: TextDecoration.lineThrough,
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
// _ExpandButton — "Ver más en [Tienda]" / "Ver menos"
// =============================================================================

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({
    required this.storeName,
    required this.isExpanded,
    required this.remaining,
    required this.onTap,
  });

  final String storeName;
  final bool isExpanded;
  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _bgCard2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: _cyan,
            ),
            const SizedBox(width: 6),
            Text(
              isExpanded
                  ? 'Ver menos'
                  : 'Ver más en $storeName (+$remaining)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _cyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _NotifSettingsSheet — Hoja modal de preferencias de notificaciones
// (también accesible desde SettingsScreen)
// =============================================================================

class _NotifSettingsSheet extends StatefulWidget {
  const _NotifSettingsSheet();

  @override
  State<_NotifSettingsSheet> createState() => _NotifSettingsSheetState();
}

class _NotifSettingsSheetState extends State<_NotifSettingsSheet> {
  DealsPrefService? _svc;

  @override
  void initState() {
    super.initState();
    DealsPrefService.instance.then((s) {
      if (mounted) setState(() => _svc = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF151515),
        title: const Text(
          'Alertas de Ofertas',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textMain),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _svc == null
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Descripción
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _cyan.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _cyan.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: _cyan),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recibe alertas cuando un juego se añada gratuitamente en cada tienda.',
                          style: TextStyle(fontSize: 11, color: _textSub),
                        ),
                      ),
                    ],
                  ),
                ),

                // Toggle por tienda
                ...DealStore.values.map((store) {
                  final cfg = store.config;
                  final enabled = _svc!.isFreeGamesAlertEnabled(store);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: enabled
                            ? cfg.color.withValues(alpha: 0.25)
                            : _border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cfg.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cfg.icon, size: 14, color: cfg.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cfg.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textMain,
                                ),
                              ),
                              const Text(
                                'Juegos gratuitos',
                                style: TextStyle(
                                    fontSize: 10, color: _textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: enabled,
                          onChanged: (v) async {
                            await _svc!.setFreeGamesAlert(store, v);
                            setState(() {});
                          },
                          activeThumbColor: cfg.color,
                          activeTrackColor:
                              cfg.color.withValues(alpha: 0.3),
                          inactiveThumbColor: _textMuted,
                          inactiveTrackColor: _border,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
