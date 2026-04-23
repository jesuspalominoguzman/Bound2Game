// =============================================================================
// game_detail_screen.dart — Bound2Game Flutter
// Fuente: TechDetail.tsx + Backlog.tsx (InterfazdeusuarioBound2game)
// =============================================================================

import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../models/deal_model.dart';
import '../widgets/platform_badge.dart';
import '../widgets/pc_req_dot.dart';
import '../widgets/discount_badge.dart';

// ── Color tokens ─────────────────────────────────────────────────────────────
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
const _red     = Color(0xFFFF4040);
const _purple  = Color(0xFF7B61FF);

// =============================================================================
// HELPERS — cálculos de negocio (sin hardcoding; listos para backend)
// =============================================================================

/// Calcula el coste por hora de juego.
/// TODO(backend): recibir [playtime] real del servidor.
double _costPerHour(double price, int playtime) {
  if (playtime <= 0) return price;
  return price / playtime;
}

/// Color del indicador ROI según coste por hora.
Color _roiColor(double cph) {
  if (cph <= 0.20) return _green;
  if (cph <= 0.60) return _yellow;
  return _red;
}

/// Etiqueta ROI.
String _roiLabel(double cph) {
  if (cph <= 0.20) return 'Excelente valor';
  if (cph <= 0.60) return 'Precio razonable';
  return 'Precio elevado';
}

/// Color de barra de specs según porcentaje.
Color _specColor(int value) {
  if (value >= 75) return _green;
  if (value >= 45) return _yellow;
  return _red;
}

// =============================================================================
// GameDetailScreen
// =============================================================================

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key, required this.game});
  final Game game;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  bool _isFavorite = false;

  Game get g => widget.game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar con imagen Hero ─────────────────────────────────
          _GameSliverAppBar(
            game: g,
            isFavorite: _isFavorite,
            onFavoriteToggle: () => setState(() => _isFavorite = !_isFavorite),
          ),

          // ── Cuerpo de la pantalla ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Módulo ROI
                  _RoiModule(game: g),
                  const SizedBox(height: 16),

                  // Módulo Requisitos PC
                  if (g.pcSpecs != null) ...[
                    _PcReqModule(game: g),
                    const SizedBox(height: 16),
                  ],

                  // Módulo HLTB
                  if (g.hltb != null) ...[
                    _HltbModule(game: g),
                    const SizedBox(height: 16),
                  ],

                  // Módulo Cosméticos
                  if (g.hasCosmetics && g.cosmetics != null) ...[
                    _CosmeticsModule(game: g),
                    const SizedBox(height: 16),
                  ],

                  // Módulo Comparador de Precios
                  _PriceCompareModule(game: g),
                  const SizedBox(height: 16),

                  // Info general
                  _InfoModule(game: g),
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
// _GameSliverAppBar
// =============================================================================

class _GameSliverAppBar extends StatelessWidget {
  const _GameSliverAppBar({
    required this.game,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final Game game;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFF151515),
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: onFavoriteToggle,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? _red : Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          game.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 8)],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de portada
            Hero(
              tag: 'game-cover-${game.id}',
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
            // Gradiente sobre la imagen
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            // Badges inferiores
            Positioned(
              bottom: 50,
              left: 16,
              child: Row(
                children: [
                  PlatformBadge(platform: game.platform),
                  const SizedBox(width: 8),
                  PcReqDot(pcReq: game.pcReq),
                  const SizedBox(width: 6),
                  Text(
                    game.pcReq.config.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: game.pcReq.config.color,
                      fontWeight: FontWeight.w600,
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



class _RoiModule extends StatelessWidget {
  const _RoiModule({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    // TODO(backend): Recibir playtime real del servidor.
    final cph = _costPerHour(game.price, game.playtime);
    final color = _roiColor(cph);
    final label = _roiLabel(cph);

    return _ModuleCard(
      icon: Icons.analytics_rounded,
      iconColor: _purple,
      title: 'Rentabilidad (ROI)',
      child: Column(
        children: [
          Row(
            children: [
              // Precio
              Expanded(
                child: _RoiStat(
                  label: 'Precio',
                  value: game.price == 0
                      ? 'Gratis'
                      : '\$${game.price.toStringAsFixed(0)}',
                  color: _textMain,
                ),
              ),
              // Horas jugadas
              Expanded(
                child: _RoiStat(
                  label: 'Jugadas',
                  value: '${game.playtime}h',
                  color: _cyan,
                ),
              ),
              // Coste por hora
              Expanded(
                child: _RoiStat(
                  label: 'Coste/hora',
                  value: game.price == 0
                      ? '—'
                      : '\$${cph.toStringAsFixed(2)}/h',
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Banner de veredicto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insights_rounded, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoiStat extends StatelessWidget {
  const _RoiStat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: _textMuted)),
      ],
    );
  }
}

// =============================================================================
// _PcReqModule — Requisitos de PC con barras animadas
// =============================================================================

class _PcReqModule extends StatelessWidget {
  const _PcReqModule({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final specs = game.pcSpecs!;
    final cfg = game.pcReq.config;

    return _ModuleCard(
      icon: Icons.memory_rounded,
      iconColor: cfg.color,
      title: 'Compatibilidad PC',
      child: Column(
        children: [
          // Veredicto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: cfg.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cfg.color.withValues(alpha: 0.25)),
            ),
            child: Text(
              '${cfg.icon} ${cfg.label}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: cfg.color, fontWeight: FontWeight.w700),
            ),
          ),
          // Barras de specs
          // TODO(backend): Datos reales de UserPcService.getSpecs()
          _SpecBar(label: 'CPU', spec: specs.cpu),
          _SpecBar(label: 'GPU', spec: specs.gpu),
          _SpecBar(label: 'RAM', spec: specs.ram),
          _SpecBar(label: 'SSD', spec: specs.storage),
        ],
      ),
    );
  }
}

class _SpecBar extends StatefulWidget {
  const _SpecBar({required this.label, required this.spec});
  final String label;
  final PcSpec spec;

  @override
  State<_SpecBar> createState() => _SpecBarState();
}

class _SpecBarState extends State<_SpecBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween<double>(begin: 0, end: widget.spec.value / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(
        const Duration(milliseconds: 300), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = _specColor(widget.spec.value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label,
                  style: const TextStyle(fontSize: 11, color: _textSub,
                      fontWeight: FontWeight.w600)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(widget.spec.label,
                      style: const TextStyle(fontSize: 10, color: _textMuted),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              Text('${widget.spec.value}%',
                  style: TextStyle(fontSize: 11, color: color,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) => LinearProgressIndicator(
                  value: _anim.value,
                  backgroundColor: _border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _HltbModule — How Long To Beat
// =============================================================================

class _HltbModule extends StatelessWidget {
  const _HltbModule({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final hltb = game.hltb!;
    final max = [
      hltb.main ?? 0,
      hltb.extra ?? 0,
      hltb.completionist ?? 0,
    ].reduce((a, b) => a > b ? a : b);

    final isEndless = max == 0;

    return _ModuleCard(
      icon: Icons.timer_rounded,
      iconColor: _yellow,
      title: 'How Long To Beat',
      child: isEndless
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Juego multijugador sin fin definido',
                    style: TextStyle(fontSize: 12, color: _textSub)),
              ),
            )
          : Column(
              children: [
                if (hltb.main != null)
                  _HltbBar(
                      label: 'Historia Principal',
                      hours: hltb.main!,
                      maxHours: max,
                      color: _cyan),
                if (hltb.extra != null)
                  _HltbBar(
                      label: 'Historia + Extras',
                      hours: hltb.extra!,
                      maxHours: max,
                      color: _yellow),
                if (hltb.completionist != null)
                  _HltbBar(
                      label: 'Completista 100%',
                      hours: hltb.completionist!,
                      maxHours: max,
                      color: _purple),
              ],
            ),
    );
  }
}

class _HltbBar extends StatefulWidget {
  const _HltbBar({
    required this.label,
    required this.hours,
    required this.maxHours,
    required this.color,
  });
  final String label;
  final int hours, maxHours;
  final Color color;

  @override
  State<_HltbBar> createState() => _HltbBarState();
}

class _HltbBarState extends State<_HltbBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.hours / widget.maxHours)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(
        const Duration(milliseconds: 400), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label,
                  style: const TextStyle(fontSize: 11, color: _textSub)),
              Text('~${widget.hours}h',
                  style: TextStyle(
                      fontSize: 11,
                      color: widget.color,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) => LinearProgressIndicator(
                  value: _anim.value,
                  backgroundColor: _border,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _CosmeticsModule
// =============================================================================

class _CosmeticsModule extends StatelessWidget {
  const _CosmeticsModule({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final c = game.cosmetics!;
    return _ModuleCard(
      icon: Icons.diamond_rounded,
      iconColor: _purple,
      title: 'Cosméticos',
      child: Row(
        children: [
          Expanded(
              child: _RoiStat(
                  label: 'Skins',
                  value: '${c.skins}',
                  color: _purple)),
          Expanded(
              child: _RoiStat(
                  label: 'Items raros',
                  value: '${c.rareItems}',
                  color: _yellow)),
          Expanded(
              child: _RoiStat(
                  label: 'Valor',
                  value: '\$${c.value.toStringAsFixed(0)}',
                  color: _green)),
        ],
      ),
    );
  }
}

// =============================================================================
// _InfoModule — Info básica del juego
// =============================================================================

class _InfoModule extends StatelessWidget {
  const _InfoModule({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    return _ModuleCard(
      icon: Icons.info_outline_rounded,
      iconColor: _cyan,
      title: 'Información General',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _InfoChip(label: 'Género', value: game.genre),
          _InfoChip(label: 'Año', value: '${game.year}'),
          _InfoChip(
              label: 'Estado',
              value: game.status.label,
              valueColor: game.status.color),
          if (game.rating != null)
            _InfoChip(
                label: 'Rating',
                value: '★ ${game.rating!.toStringAsFixed(1)}',
                valueColor: _yellow),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, this.valueColor});
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bgCard2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 9, color: _textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: valueColor ?? _textMain,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// =============================================================================
// _PriceCompareModule — Comparador de precios por tienda
// =============================================================================

/// Módulo que muestra todas las tiendas donde el juego tiene oferta,
/// cruzando los datos via game.id con sampleDeals.
/// TODO(backend): Sustituir sampleDeals por DealsService.fetchDealsForGame(id)
class _PriceCompareModule extends StatelessWidget {
  const _PriceCompareModule({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    // Cruzar por ID (el campo gameId en GameDeal corresponde a Game.id.toString())
    final deals = sampleDeals
        .where((d) => d.gameId == game.id.toString())
        .toList()
      ..sort((a, b) => a.salePrice.compareTo(b.salePrice));

    if (deals.isEmpty) {
      return _ModuleCard(
        icon: Icons.compare_arrows_rounded,
        iconColor: _yellow,
        title: 'Comparador de Precios',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'No se encontraron ofertas activas para este juego.',
            style: TextStyle(fontSize: 12, color: _textSub),
          ),
        ),
      );
    }

    return _ModuleCard(
      icon: Icons.compare_arrows_rounded,
      iconColor: _yellow,
      title: 'Comparador de Precios',
      child: Column(
        children: deals.map((deal) {
          final cfg = deal.store.config;
          final isLast = deal == deals.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Icono de tienda
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: cfg.background,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(cfg.icon, size: 13, color: cfg.color),
                    ),
                    const SizedBox(width: 10),

                    // Nombre de tienda
                    Expanded(
                      child: Text(
                        cfg.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textMain,
                        ),
                      ),
                    ),

                    // Precio original tachado (si hay descuento)
                    if (!deal.isFree && deal.discountPercent > 0) ...
                      [
                        Text(
                          deal.originalPriceLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],

                    // Precio actual
                    Text(
                      deal.salePriceLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: deal.isFree ? _green : _textMain,
                      ),
                    ),

                    // Badge de descuento
                    if (deal.discountPercent > 0) ...
                      [
                        const SizedBox(width: 8),
                        DiscountBadge(deal: deal, small: true),
                      ],
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  height: 1,
                  color: _border,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// _ModuleCard — Contenedor de módulo reutilizable
// =============================================================================

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textMain)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
