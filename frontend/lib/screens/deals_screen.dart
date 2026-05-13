// Esta es la pantalla donde buscamos los chollos. Conectamos con el servidor para pillar los juegos gratis y las mejores ofertas.
// La idea es que se vea todo muy visual y sea fácil encontrar qué jugar sin gastar pasta.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/deal_model.dart';
import '../services/api_service.dart';
import '../widgets/deals_widgets.dart';
import 'game_detail_screen.dart';
import 'store_detail_screen.dart';

const _bg = Color(0xFF0A0A0A);
const _yellow = Color(0xFFFFB800);
const _textMain = Color(0xFFE8E8E8);
const _textSub = Color(0xFF7A7A7A);

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  // Aquí guardo las peticiones al servidor para usarlas con FutureBuilder.
  late Future<List<Deal>> _freeGamesFuture;
  late Future<List<Deal>> _topDealsFuture;
  late Future<List<Deal>> _upcomingGamesFuture;

  @override
  void initState() {
    super.initState();
    // Nada más cargar la pantalla, pedimos los datos al servidor.
    _loadData();
  }

  // Llamamos a la API para traer los juegos gratis, los destacados y lo que está por salir.
  void _loadData() {
    _freeGamesFuture = ApiService.fetchFreeGames();
    _topDealsFuture = ApiService.fetchDeals();
    _upcomingGamesFuture = ApiService.fetchUpcomingGames();
  }

  // Si el usuario toca un juego, lo mandamos a la pantalla de detalles con toda la info.
  void _navigateToGame(Deal deal) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameDetailScreen(baseGame: deal.toGame()),
    ));
  }

  // Para ver qué hay en una tienda específica (Steam, Epic...).
  void _navigateToStore(DealStore store) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StoreDetailScreen(store: store),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // El típico "tirar para abajo" para refrescar las ofertas si ha salido algo nuevo.
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _loadData()),
        color: _yellow, backgroundColor: const Color(0xFF1A1A1A),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            
            // El carrusel de arriba del todo para los juegos gratis, que es lo que más interesa.
            SliverToBoxAdapter(
              child: FutureBuilder<List<Deal>>(
                future: _freeGamesFuture,
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 380, child: Center(child: CircularProgressIndicator(color: _yellow, strokeWidth: 2)));
                  }
                  final deals = snapshot.data ?? [];
                  return HeroCarousel(deals: deals, onTap: _navigateToGame);
                },
              ),
            ),

            // Sección de las mejores ofertas que hay ahora mismo.
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.local_fire_department_rounded,
                title: 'Mejores Ofertas',
                color: const Color(0xFFFF5252),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Deal>>(
                future: _topDealsFuture,
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 190);
                  final deals = snapshot.data!;
                  return SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: deals.length,
                      itemBuilder: (ctx, i) => DealCard(deal: deals[i], onTap: () => _navigateToGame(deals[i])),
                    ),
                  );
                },
              ),
            ),

            // Para que la gente sepa qué juegos van a salir pronto.
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.rocket_launch_rounded,
                title: 'Próximos Lanzamientos',
                color: const Color(0xFF9B6DFF),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Deal>>(
                future: _upcomingGamesFuture,
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 120);
                  final deals = snapshot.data!;
                  return Container(
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: deals.length,
                      itemBuilder: (ctx, i) => _UpcomingItem(deal: deals[i]),
                    ),
                  );
                },
              ),
            ),

            // La rejilla de tiendas por si el usuario quiere filtrar por una concreta.
            SliverToBoxAdapter(
              child: StoreSection(onStoreTap: _navigateToStore),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// Un pequeño widget para poner los títulos de cada sección con un iconito al lado.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, required this.color});
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: color)),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.2)),
        ],
      ),
    );
  }
}

// El diseño de las tarjetas para los juegos que van a salir pronto.
class _UpcomingItem extends StatelessWidget {
  const _UpcomingItem({required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF242424))),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.network(deal.thumbUrl, width: 80, height: 120, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 80, color: Colors.grey[900])),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(deal.title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(deal.releaseDate ?? 'Próximamente', style: const TextStyle(fontSize: 10, color: _textSub, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
