// Esta es la ficha del juego. Aquí es donde vemos toda la info: cuánto nos ha costado cada hora de vicio (ROI), si el PC puede con él y hasta los precios en otras tiendas.
// He intentado que sea la pantalla más completa de la app porque es donde pasas más tiempo consultando datos.

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game_model.dart';
import '../models/deal_model.dart';
import '../widgets/pc_req_dot.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

// Mis colores para que todo pegue con el diseño oscuro y el amarillo Bound2Game.
const _bg      = Color(0xFF292929);
const _bgCard  = Color(0xFF1A1A1A);
const _border  = Color(0xFF2A2A2A);
const _textMain  = Color(0xFFE0E0E0);
const _textSub   = Color(0xFF888888);
const _yellow  = Color(0xFFFFB800);
const _green   = Color(0xFF4AF626);
const _red     = Color(0xFFFF4040);
const _purple  = Color(0xFF7B61FF);
const _cyan    = Color(0xFF00E5FF);

// Una cuenta rápida para saber cuánto nos sale la hora de vicio basándonos en lo que nos costó el juego.
double _costPerHour(double price, int playtime) {
  if (playtime <= 0) return price;
  return price / playtime;
}

// Colores para el indicador de rentabilidad (ROI). Verde si es un chollo, rojo si sale caro.
Color _roiColor(double cph) {
  if (cph <= 0.20) return _green;
  if (cph <= 0.60) return _yellow;
  return _red;
}

String _roiLabel(double cph) {
  if (cph <= 0.20) return 'Excelente valor';
  if (cph <= 0.60) return 'Precio razonable';
  return 'Precio elevado';
}

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key, required this.baseGame, this.entryId});
  final Game baseGame;
  final String? entryId;
  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  bool _isLoading = false;
  bool _isTogglingLibrary = false;
  bool _addedToLibraryLocal = false;
  bool _removedFromLibraryLocal = false;
  String? _addedEntryId; 
  Game? _fullGame;
  List<GameDeal> _deals = [];

  @override
  void initState() { super.initState(); _loadDetails(); }

  // Pedimos toda la info del juego al servidor: ofertas, requisitos, HLTB...
  Future<void> _loadDetails() async {
    setState(() { _isLoading = true; });
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('No session');

      final dealsForGame = await ApiService.fetchDealsByGame(widget.baseGame.title);
      _deals = dealsForGame.map((d) => GameDeal(gameId: widget.baseGame.id.toString(), gameTitle: d.title, store: d.storeEnum, storeName: d.storeName, originalPrice: d.normalPrice, salePrice: d.salePrice, discountPercent: d.calculatedDiscount, isFree: d.salePrice <= 0, dealUrl: d.dealUrl)).toList();

      String? actualEntryId = widget.entryId;
      if (actualEntryId == null) {
        final library = await ApiService.getLibrary(user.id);
        try {
          final match = library.firstWhere((g) => g.title.toLowerCase() == widget.baseGame.title.toLowerCase());
          actualEntryId = match.entryId;
          _addedEntryId = actualEntryId;
          _addedToLibraryLocal = true;
        } catch (_) {}
      }

      if (actualEntryId == null) {
        if (mounted) setState(() { _fullGame = widget.baseGame; _isLoading = false; });
        return;
      }

      final details = await ApiService.getGameDetails(userId: user.id, entryId: actualEntryId);
      final apiGame = details['game'] as ApiGame;
      final compStatus = details['compatibility'] as String?;

      if (mounted) {
        setState(() {
          _fullGame = Game(id: widget.baseGame.id, entryId: actualEntryId, title: widget.baseGame.title, platform: widget.baseGame.platform, genre: apiGame.genres.isNotEmpty ? apiGame.genres.first : widget.baseGame.genre, playtime: apiGame.userPlaytime ?? widget.baseGame.playtime, status: widget.baseGame.status, cover: widget.baseGame.cover, hasCosmetics: widget.baseGame.hasCosmetics, pcReq: PcReq.fromString(compStatus), price: double.tryParse(apiGame.currentPrice ?? '0') ?? widget.baseGame.price, year: apiGame.releaseYear ?? widget.baseGame.year, rentability: apiGame.rentability, metacritic: apiGame.metacritic, esrbRating: apiGame.esrbRating, genres: apiGame.genres.isNotEmpty ? apiGame.genres : widget.baseGame.genres, hltb: HltbTimes(main: apiGame.hltbMainStory?.round(), completionist: apiGame.hltbCompletionist?.round()), pcSpecs: widget.baseGame.pcSpecs, pcRequirements: apiGame.pcRequirements ?? widget.baseGame.pcRequirements);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _fullGame = widget.baseGame; _isLoading = false; });
    }
  }

  bool get _isOwned {
    if (_removedFromLibraryLocal) return false;
    if (_addedToLibraryLocal) return true;
    return _fullGame?.entryId != null || widget.entryId != null || _addedEntryId != null;
  }

  bool _isInWishlist = false;

  Future<void> _toggleLibrary() async {
    setState(() => _isTogglingLibrary = true);
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('No session');
      if (_isOwned) {
        final targetId = _addedEntryId ?? widget.entryId ?? widget.baseGame.id.toString();
        await ApiService.removeFromLibrary(userId: user.id, entryId: targetId);
        if (mounted) setState(() { _removedFromLibraryLocal = true; _addedToLibraryLocal = false; });
      } else {
        final newId = await ApiService.addToLibrary(userId: user.id, gameTitle: widget.baseGame.title, platform: widget.baseGame.platform.displayName);
        if (mounted) setState(() { _addedToLibraryLocal = true; _addedEntryId = newId; _removedFromLibraryLocal = false; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isTogglingLibrary = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading || _fullGame == null) return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _yellow)));
    final game = _fullGame!;
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _GameSliverAppBar(game: game, isInWishlist: _isInWishlist, isOwned: _isOwned, onWishlistToggle: () => setState(() => _isInWishlist = !_isInWishlist)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(icon: Icon(_isOwned ? Icons.library_add_check_rounded : Icons.add_circle_outline_rounded), label: Text(_isOwned ? 'En Biblioteca (Click para quitar)' : 'Añadir a Biblioteca', style: const TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: _isOwned ? _green.withValues(alpha: 0.15) : _yellow, foregroundColor: _isOwned ? _green : Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _isOwned ? _green.withValues(alpha: 0.5) : Colors.transparent))), onPressed: _isTogglingLibrary ? null : _toggleLibrary)),
                const SizedBox(height: 24),
                _RoiModule(game: game),
                const SizedBox(height: 16),
                if (game.platform.isPc) ...[_PcReqModule(game: game), const SizedBox(height: 16)],
                if (game.hltb != null) ...[_HltbModule(game: game), const SizedBox(height: 16)],
                _PriceCompareModule(game: game, deals: _deals),
                const SizedBox(height: 16),
                _InfoModule(game: game),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Estos son los módulos que he separado para que el código no sea un lío de leer.

class _GameSliverAppBar extends StatelessWidget {
  const _GameSliverAppBar({required this.game, required this.isInWishlist, required this.isOwned, required this.onWishlistToggle});
  final Game game; final bool isInWishlist, isOwned; final VoidCallback onWishlistToggle;
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400, pinned: true, backgroundColor: _bg,
      flexibleSpace: FlexibleSpaceBar(background: Stack(fit: StackFit.expand, children: [Image.network(game.cover, fit: BoxFit.cover), Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xE6292929), Colors.transparent])))] )),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      actions: [IconButton(icon: Icon(isInWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isInWishlist ? _red : Colors.white), onPressed: onWishlistToggle)],
    );
  }
}

class _RoiModule extends StatelessWidget {
  const _RoiModule({required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    final cph = _costPerHour(game.price, game.playtime);
    return _ModuleCard(icon: Icons.analytics_rounded, iconColor: _cyan, title: 'Rentabilidad (ROI)', child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${cph.toStringAsFixed(2)}€ / hora', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _roiColor(cph))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _roiColor(cph).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(_roiLabel(cph), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _roiColor(cph)))),
      ]),
      const SizedBox(height: 8),
      Text('Basado en ${game.playtime} horas jugadas y un coste de ${game.price}€.', style: const TextStyle(fontSize: 11, color: _textSub)),
    ]));
  }
}

class _PcReqModule extends StatelessWidget {
  const _PcReqModule({required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    return _ModuleCard(icon: Icons.computer_rounded, iconColor: _green, title: 'Compatibilidad PC', child: Column(children: [
      Row(children: [PcReqDot(pcReq: game.pcReq), const SizedBox(width: 8), Text(game.pcReq.config.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: game.pcReq.config.color))]),
      const SizedBox(height: 12),
      // Aquí pondríamos las barritas de CPU, GPU y RAM...
    ]));
  }
}

class _HltbModule extends StatelessWidget {
  const _HltbModule({required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    return _ModuleCard(icon: Icons.timer_rounded, iconColor: _purple, title: '¿Cuánto dura?', child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _HltbStat(label: 'Historia', hours: '${game.hltb?.main ?? "--"}h'),
      _HltbStat(label: 'Completo', hours: '${game.hltb?.completionist ?? "--"}h'),
    ]));
  }
}

class _HltbStat extends StatelessWidget {
  const _HltbStat({required this.label, required this.hours});
  final String label, hours;
  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(label, style: const TextStyle(fontSize: 10, color: _textSub)), Text(hours, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))]);
  }
}

class _PriceCompareModule extends StatelessWidget {
  const _PriceCompareModule({required this.game, required this.deals});
  final Game game; final List<GameDeal> deals;
  @override
  Widget build(BuildContext context) {
    return _ModuleCard(icon: Icons.shopping_cart_rounded, iconColor: _yellow, title: 'Comparador de Precios', child: Column(children: deals.map((d) => ListTile(title: Text(d.storeName ?? "Tienda", style: const TextStyle(color: Colors.white, fontSize: 13)), trailing: Text('${d.salePrice}€', style: const TextStyle(color: _green, fontWeight: FontWeight.bold)), onTap: () => launchUrl(Uri.parse(d.dealUrl!)))).toList()));
  }
}

class _InfoModule extends StatelessWidget {
  const _InfoModule({required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    return _ModuleCard(icon: Icons.info_rounded, iconColor: _textSub, title: 'Ficha Técnica', child: Html(data: game.pcRequirements ?? "No hay descripción disponible.", style: {"body": Style(color: _textMain, fontSize: FontSize(12))}));
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.icon, required this.iconColor, required this.title, required this.child});
  final IconData icon; final Color iconColor; final String title; final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 16, color: iconColor), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))]),
      const SizedBox(height: 14),
      child,
    ]));
  }
}
