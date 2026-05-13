// Aquí tengo los componentes que uso para la pantalla de ofertas. Tarjetas, el carrusel de arriba y los logos de las tiendas.
// La idea es que todo sea muy visual y se entienda de un vistazo qué vale la pena y qué no.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/deal_model.dart';
import '../../utils/b2g_utils.dart';
import '../../widgets/store_logo.dart';

// Mis variables de color para no andar escribiendo el código hexadecimal cada dos por tres.
const _textMain  = Color(0xFFE8E8E8);
const _textSub   = Color(0xFF7A7A7A);
const _textMuted = Color(0xFF4A4A4A);
const _green   = Color(0xFF39FF7E);
const _yellow  = Color(0xFFFFB800);
const _bgCard  = Color(0xFF161616);
const _bgCard2 = Color(0xFF1E1E1E);
const _border  = Color(0xFF242424);

// Esta es la tarjetita pequeña que usamos para mostrar las ofertas individuales en las listas horizontales.
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
                // Si el juego tiene descuento, le cascamos una etiqueta verde que resalte.
                if (discount > 0)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(6)),
                      child: Text('-$discount%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
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
                    // Ponemos el iconito de la tienda para saber de dónde viene la oferta.
                    Row(
                      children: [
                        Icon(cfg.icon, size: 10, color: cfg.color),
                        const SizedBox(width: 4),
                        Expanded(child: Text(cfg.name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: cfg.color), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(deal.title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: _textMain, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    _PriceRow(deal: deal, discount: discount),
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

// Para que el precio se vea bien: si tiene descuento, tachamos el anterior y ponemos el nuevo en grande.
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.deal, required this.discount});
  final Deal deal;
  final int discount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (discount > 0)
          Text('${deal.normalPrice.toStringAsFixed(2)}€', style: const TextStyle(fontSize: 10, color: _textSub, decoration: TextDecoration.lineThrough)),
        if (discount > 0) const SizedBox(width: 4),
        Text(deal.salePrice == 0 ? 'GRATIS' : '${deal.salePrice.toStringAsFixed(2)}€',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: deal.salePrice == 0 ? _green : _textMain)),
      ],
    );
  }
}

// El carrusel grande de la parte de arriba. He metido un poco de matemáticas para que las tarjetas se escalen suavemente al moverlas.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.deals, required this.onTap});
  final List<Deal> deals;
  final void Function(Deal) onTap;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Hacemos que se vea un poquito de las tarjetas de los lados.
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
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.deals.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, index) => AnimatedBuilder(
              animation: _pageController,
              builder: (ctx, child) {
                // Aquí calculamos la escala para que la tarjeta del centro se vea más grande que las de los lados.
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                }
                return Transform.scale(scale: Curves.easeOut.transform(value), child: Opacity(opacity: value.clamp(0.4, 1.0), child: child));
              },
              child: _HeroCard(deal: widget.deals[index], onTap: () => widget.onTap(widget.deals[index])),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Los puntitos de abajo para saber por qué página del carrusel vamos.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.deals.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _currentPage ? 22 : 6, height: 6,
            decoration: BoxDecoration(color: i == _currentPage ? _yellow : _textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3)),
          )),
        ),
      ],
    );
  }
}

// La tarjeta que va dentro del carrusel. Es más grande y tiene el botón de "Reclamar" para ir directos al chollo.
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(deal.thumbUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: _bgCard2)),
              // Le pongo un degradado oscuro abajo para que las letras blancas se lean bien.
              const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.transparent, Color(0x99000000), Color(0xF2000000)], stops: [0.0, 0.4, 0.7, 1.0])))),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [Icon(cfg.icon, size: 14, color: cfg.color), const SizedBox(width: 6), Text(cfg.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfg.color))]),
                      const SizedBox(height: 8),
                      Text(deal.title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      if (deal.normalPrice > 0) Text('${deal.normalPrice.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 13, color: Color(0xFF888888), decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      // El botón principal para ir a por el juego.
                      GestureDetector(
                        onTap: () => B2GUtils.launchExternalUrl(deal.dealUrl),
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: deal.dealUrl != null ? _yellow : _textMuted, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text('RECLAMAR AHORA', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0.5))),
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

// Aquí montamos la cuadrícula con todas las tiendas que soportamos, como Steam o Epic.
class StoreSection extends StatelessWidget {
  const StoreSection({super.key, required this.onStoreTap});
  final void Function(DealStore) onStoreTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _yellow.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.storefront_rounded, size: 14, color: _yellow)),
              const SizedBox(width: 10),
              Text('Explorar por Tienda', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.2)),
            ],
          ),
        ),
        // Usamos GridView para que los logos de las tiendas queden bien cuadraditos.
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: DealStore.values.map((s) => _StoreCard(store: s, onTap: () => onStoreTap(s))).toList(),
        ),
      ],
    );
  }
}

// Cada botón de la tienda en la cuadrícula. Solo lleva el logo centrado para que quede limpio.
class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.onTap});
  final DealStore store;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Center(child: StoreLogoWidget(store: store, size: 28)),
      ),
    );
  }
}
