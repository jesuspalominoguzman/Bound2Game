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
const _orange  = Color(0xFFFF9800);

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
          _fullGame = Game(id: widget.baseGame.id, entryId: actualEntryId, title: widget.baseGame.title, platform: Platform.fromString(apiGame.platform), genre: apiGame.genres.isNotEmpty ? apiGame.genres.first : widget.baseGame.genre, playtime: apiGame.userPlaytime ?? widget.baseGame.playtime, status: widget.baseGame.status, cover: widget.baseGame.cover, hasCosmetics: widget.baseGame.hasCosmetics, pcReq: PcReq.fromString(compStatus), price: double.tryParse(apiGame.currentPrice ?? '0') ?? widget.baseGame.price, year: apiGame.releaseYear ?? widget.baseGame.year, rentability: apiGame.rentability, metacritic: apiGame.metacritic, esrbRating: apiGame.esrbRating, genres: apiGame.genres.isNotEmpty ? apiGame.genres : widget.baseGame.genres, hltb: HltbTimes(main: apiGame.hltbMainStory?.round(), completionist: apiGame.hltbCompletionist?.round()), pcSpecs: widget.baseGame.pcSpecs, pcRequirements: apiGame.pcRequirements ?? widget.baseGame.pcRequirements);
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
                // Botón de biblioteca
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: _isTogglingLibrary
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_isOwned ? Icons.library_add_check_rounded : Icons.add_circle_outline_rounded),
                    label: Text(_isOwned ? 'En Biblioteca (Click para quitar)' : 'Añadir a Biblioteca', style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isOwned ? _green.withValues(alpha: 0.15) : _yellow,
                      foregroundColor: _isOwned ? _green : Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _isOwned ? _green.withValues(alpha: 0.5) : Colors.transparent)),
                      elevation: 0,
                    ),
                    onPressed: _isTogglingLibrary ? null : _toggleLibrary,
                  ),
                ),

                // Botón Editar Detalles (solo si es dueño)
                if (_isOwned) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Editar Detalles', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bgCard,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _border)),
                        elevation: 0,
                      ),
                      onPressed: _showEditDialog,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Módulo ROI
                _RoiModule(game: game, isOwned: _isOwned),
                const SizedBox(height: 16),

                // Módulo Requisitos PC
                if (game.platform.isPc) ...[
                  _PcReqModule(game: game),
                  const SizedBox(height: 16)
                ],

                // Módulo HLTB
                if (game.hltb != null) ...[
                  _HltbModule(game: game),
                  const SizedBox(height: 16)
                ],

                // Comparador de Precios
                _PriceCompareModule(game: game, deals: _deals),
                const SizedBox(height: 16),

                // Ficha Técnica General
                _InfoModule(game: game),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Lógica para editar la entrada de la biblioteca (estado y horas)
  Future<void> _showEditDialog() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;
    final targetId = _addedEntryId ?? widget.entryId;
    if (targetId == null) return;

    String selectedStatus = _fullGame?.status == GameStatus.playing ? 'Playing' :
                            _fullGame?.status == GameStatus.completed ? 'Completed' :
                            _fullGame?.status == GameStatus.abandoned ? 'Abandoned' : 'Backlog';
    Platform selectedPlatform = _fullGame?.platform ?? Platform.steam;
    final playtimeCtrl = TextEditingController(text: _fullGame?.playtime.toString() ?? '0');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
          title: const Text('Editar Entrada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estado', style: TextStyle(color: _textSub, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                child: DropdownButton<String>(
                  value: selectedStatus,
                  dropdownColor: _bgCard,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white),
                  items: [
                    {'val': 'Backlog', 'label': 'Pendiente'},
                    {'val': 'Playing', 'label': 'Jugando'},
                    {'val': 'Completed', 'label': 'Completado'},
                    {'val': 'Abandoned', 'label': 'Abandonado'},
                  ].map((s) => DropdownMenuItem(value: s['val'] as String, child: Text(s['label'] as String))).toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Plataforma', style: TextStyle(color: _textSub, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                child: DropdownButton<Platform>(
                  value: selectedPlatform,
                  dropdownColor: _bgCard,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white),
                  items: Platform.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPlatform = v!),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Horas jugadas', style: TextStyle(color: _textSub, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: playtimeCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(fillColor: _bg, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: _textSub))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _yellow, foregroundColor: Colors.black),
              onPressed: () async {
                await ApiService.updateLibraryEntry(
                  userId: user.id, 
                  entryId: targetId, 
                  status: selectedStatus, 
                  playtime: int.tryParse(playtimeCtrl.text) ?? 0,
                  platform: selectedPlatform.displayName,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadDetails();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGETS Y MÓDULOS REFACTORIZADOS
// =============================================================================

class _GameSliverAppBar extends StatelessWidget {
  const _GameSliverAppBar({required this.game, required this.isInWishlist, required this.isOwned, required this.onWishlistToggle});
  final Game game; final bool isInWishlist, isOwned; final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 440, pinned: true, backgroundColor: _bg,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(game.cover, fit: BoxFit.cover),
            Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF292929), Colors.transparent], stops: [0.0, 0.5]))),
            
            // Badges informativos sobre la carátula
            Positioned(
              bottom: 60, left: 16, right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _HeaderChip(icon: Icons.computer_rounded, label: game.platform.displayName, color: game.platform.color),
                      const SizedBox(width: 8),
                      _HeaderChip(icon: Icons.check_circle_rounded, label: game.pcReq.config.label, color: game.pcReq.config.color),
                      const SizedBox(width: 8),
                      _HeaderChip(icon: Icons.access_time_filled_rounded, label: '${game.playtime}h jugadas', color: _cyan),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(game.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label, required this.color});
  final IconData icon; final String label; final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _RoiModule extends StatelessWidget {
  const _RoiModule({required this.game, required this.isOwned});
  final Game game;
  final bool isOwned;

  @override
  Widget build(BuildContext context) {
    // Si el juego está en la biblioteca y el usuario ha registrado horas reales,
    // usamos esas horas para el cálculo. Si no, usamos la estimación de HLTB.
    final bool usingRealHours = isOwned && (game.playtime) > 0;
    final int hoursForCalc = usingRealHours
        ? game.playtime
        : (game.hltb?.main ?? 0);

    final cph   = _costPerHour(game.price, hoursForCalc);
    final color = _roiColor(cph);

    // La columna central cambia color y etiqueta según la fuente de horas.
    final Color hoursColor  = usingRealHours ? _orange : _cyan;
    final String hoursLabel = usingRealHours ? 'Tus horas reales' : 'HLTB est.';
    final String hoursValue = hoursForCalc > 0 ? '${hoursForCalc}h' : '--';

    return _ModuleCard(
      icon: Icons.analytics_rounded, iconColor: _purple, title: 'Rentabilidad Teórica (ROI)',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RoiStat(label: 'Precio', value: '${game.price.toStringAsFixed(0)}€', color: Colors.white),
              _RoiStat(label: hoursLabel, value: hoursValue, color: hoursColor),
              _RoiStat(label: 'Coste/hora', value: hoursForCalc > 0 ? '${cph.toStringAsFixed(2)}€/h' : '--', color: hoursForCalc > 0 ? color : _textSub),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.trending_up_rounded, size: 14, color: color),
              const SizedBox(width: 8),
              Text(_roiLabel(cph).toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _RoiStat extends StatelessWidget {
  const _RoiStat({required this.label, required this.value, required this.color});
  final String label, value; final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: _textSub)),
    ]);
  }
}

class _PcReqModule extends StatelessWidget {
  const _PcReqModule({required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    return _ModuleCard(
      icon: Icons.memory_rounded, iconColor: _green, title: 'Compatibilidad PC',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(color: game.pcReq.config.background, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [PcReqDot(pcReq: game.pcReq), const SizedBox(width: 10), Text(game.pcReq.config.label, style: TextStyle(color: game.pcReq.config.color, fontWeight: FontWeight.bold))]),
          ),
          if (game.pcRequirements != null && game.pcRequirements!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('REQUISITOS MÍNIMOS:', style: TextStyle(color: _textSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 8),
            Html(data: game.pcRequirements!, style: {"body": Style(color: _textMain, fontSize: FontSize(11), margin: Margins.zero, padding: HtmlPaddings.zero)}),
          ],
        ],
      ),
    );
  }
}

class _HltbModule extends StatelessWidget {
  const _HltbModule({required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    final main = game.hltb?.main ?? 0;
    final compl = game.hltb?.completionist ?? 0;
    return _ModuleCard(
      icon: Icons.speed_rounded, iconColor: _yellow, title: 'How Long To Beat',
      child: Column(
        children: [
          _HltbBar(label: 'Historia Principal', hours: main, color: _cyan, total: compl > 0 ? compl : main),
          const SizedBox(height: 12),
          _HltbBar(label: 'Completista 100%', hours: compl, color: _purple, total: compl),
        ],
      ),
    );
  }
}

class _HltbBar extends StatelessWidget {
  const _HltbBar({required this.label, required this.hours, required this.color, required this.total});
  final String label; final int hours, total; final Color color;
  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (hours / total).clamp(0.0, 1.0) : 1.0;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: _textMain, fontSize: 11)),
        Text('~$hours h', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: color, minHeight: 6)),
    ]);
  }
}

class _PriceCompareModule extends StatelessWidget {
  const _PriceCompareModule({required this.game, required this.deals});
  final Game game; final List<GameDeal> deals;
  @override
  Widget build(BuildContext context) {
    return _ModuleCard(
      icon: Icons.compare_arrows_rounded, iconColor: _yellow, title: 'Comparador de Precios',
      child: deals.isEmpty 
        ? const Text('No hay ofertas disponibles en este momento.', style: TextStyle(color: _textSub, fontSize: 12))
        : Column(children: deals.map((d) => _DealRow(deal: d)).toList()),
    );
  }
}

class _DealRow extends StatelessWidget {
  const _DealRow({required this.deal});
  final GameDeal deal;
  @override
  Widget build(BuildContext context) {
    final cfg = deal.store.config;
    return InkWell(
      onTap: () => launchUrl(Uri.parse(deal.dealUrl ?? "")),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)), child: Icon(cfg.icon, size: 14, color: cfg.color)),
          const SizedBox(width: 12),
          Expanded(child: Text(deal.storeName ?? cfg.name, style: const TextStyle(color: _textMain, fontSize: 13, fontWeight: FontWeight.w600))),
          if (deal.discountPercent > 0) ...[
            Text('${deal.originalPrice.toStringAsFixed(0)}€', style: const TextStyle(color: _textSub, fontSize: 10, decoration: TextDecoration.lineThrough)),
            const SizedBox(width: 8),
          ],
          Text(deal.salePriceLabel, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          if (deal.discountPercent > 0) ...[
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _cyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text('-${deal.discountPercent}%', style: const TextStyle(color: _cyan, fontSize: 10, fontWeight: FontWeight.bold))),
          ],
          const SizedBox(width: 8),
          const Icon(Icons.open_in_new_rounded, size: 12, color: _textSub),
        ]),
      ),
    );
  }
}

class _InfoModule extends StatelessWidget {
  const _InfoModule({required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    return _ModuleCard(
      icon: Icons.info_outline_rounded, iconColor: _cyan, title: 'Información General',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 16) / 3;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _InfoChip(label: 'Plataforma', value: game.platform.displayName, width: itemWidth),
                  _InfoChip(label: 'Año', value: game.year.toString(), width: itemWidth),
                  _InfoChip(label: 'Estado', value: game.status.label, valueColor: game.status.color, width: itemWidth),
                  _InfoChip(label: 'Horas jugadas', value: '${game.playtime}h', valueColor: _cyan, width: itemWidth),
                  if (game.esrbRating != null) _InfoChip(label: 'ESRB', value: game.esrbRating!, width: itemWidth),
                ],
              ),
              if (game.genres.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(children: [const Icon(Icons.folder_open_rounded, size: 14, color: _textSub), const SizedBox(width: 8), Expanded(child: Text(game.genres.join(' • '), style: const TextStyle(color: _textSub, fontSize: 11)))]),
              ],
            ],
          );
        }
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, this.valueColor, required this.width});
  final String label, value; final Color? valueColor; final double width;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
      child: Column(children: [
        Text(label, style: const TextStyle(color: _textSub, fontSize: 8)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.icon, required this.iconColor, required this.title, required this.child});
  final IconData icon; final Color iconColor; final String title; final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 16, color: iconColor), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white))]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
