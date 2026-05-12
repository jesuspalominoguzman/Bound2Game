// =============================================================================
// game_detail_screen.dart — Bound2Game Flutter
// Fuente: TechDetail.tsx + Backlog.tsx (InterfazdeusuarioBound2game)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game_model.dart';
import '../models/deal_model.dart';
import '../widgets/platform_badge.dart';
import '../widgets/pc_req_dot.dart';
import '../widgets/discount_badge.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

// ── Color tokens (tema definitivo #292929/#1A1A1A/#FFB800) ──────────────────
const _bg      = Color(0xFF292929);
const _bgCard  = Color(0xFF1A1A1A);
const _bgCard2 = Color(0xFF222222);
const _border  = Color(0xFF2A2A2A);
const _textMain  = Color(0xFFE0E0E0);
const _textMuted = Color(0xFF555555);
const _textSub   = Color(0xFF888888);
const _yellow  = Color(0xFFFFB800);
const _green   = Color(0xFF4AF626);
const _red     = Color(0xFFFF4040);
const _purple  = Color(0xFF7B61FF);
// _cyan se mantiene solo donde se referencia en módulos legacy
const _cyan    = Color(0xFF00E5FF);

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
  String? _addedEntryId; // entryId devuelto por el servidor al añadir
  Game? _fullGame;
  List<GameDeal> _deals = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() { _isLoading = true; });
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('No session');

      // 1. Fetch Deals
      final allDeals = await ApiService.fetchDeals(limit: 60);
      final titleLower = widget.baseGame.title.toLowerCase();
      final filteredDeals = allDeals.where((d) => 
        d.title.toLowerCase().contains(titleLower) || titleLower.contains(d.title.toLowerCase())
      ).toList();

      _deals = filteredDeals.map((d) {
        DealStore store = DealStore.steam;
        final sName = d.storeName.toLowerCase();
        if (sName.contains('epic')) { store = DealStore.epic; }
        else if (sName.contains('playstation') || sName.contains('ps')) { store = DealStore.psStore; }
        else if (sName.contains('xbox')) { store = DealStore.xbox; }
        else if (sName.contains('nintendo')) { store = DealStore.nintendo; }
        else if (sName.contains('instant')) { store = DealStore.instantGaming; }

        return GameDeal(
          gameId: widget.baseGame.id.toString(),
          gameTitle: d.title,
          store: store,
          originalPrice: d.normalPrice,
          salePrice: d.salePrice,
          discountPercent: d.normalPrice > 0 ? ((d.normalPrice - d.salePrice) / d.normalPrice * 100).round() : 0,
          isFree: d.salePrice == 0,
        );
      }).toList();

      String? actualEntryId = widget.entryId;

      // 2. Fetch Game Details from Library if entryId exists
      if (actualEntryId == null) {
        // Verificar si el juego ya está en la biblioteca
        final library = await ApiService.getLibrary(user.id);
        try {
          final match = library.firstWhere((g) => g.title.toLowerCase() == widget.baseGame.title.toLowerCase());
          actualEntryId = match.entryId;
          _addedEntryId = actualEntryId;
          _addedToLibraryLocal = true;
        } catch (_) {
          // No está en la biblioteca
        }
      }

      if (actualEntryId == null) {
        if (mounted) {
          setState(() {
            _fullGame = widget.baseGame;
            _isLoading = false;
          });
        }
        return;
      }

      final details = await ApiService.getGameDetails(
        userId: user.id,
        entryId: actualEntryId,
      );

      final apiGame = details['game'] as ApiGame;
      final compStatus = details['compatibility'] as String?;

      if (mounted) {
        // Si no hay steamAppID, el juego probablemente sea de Epic o cliente propio
        final effectivePlatform = (widget.baseGame.platform == Platform.steam &&
                (apiGame.steamAppID == null || apiGame.steamAppID!.isEmpty))
            ? Platform.epic
            : widget.baseGame.platform;

        setState(() {
          _fullGame = Game(
            id: widget.baseGame.id,
            entryId: widget.entryId,
            title: widget.baseGame.title,
            platform: effectivePlatform,
            genre: apiGame.genres.isNotEmpty ? apiGame.genres.first : widget.baseGame.genre,
            playtime: apiGame.userPlaytime ?? widget.baseGame.playtime,
            status: widget.baseGame.status,
            cover: widget.baseGame.cover,
            pcReq: PcReq.fromString(compStatus),
            hasCosmetics: widget.baseGame.hasCosmetics,
            price: double.tryParse(apiGame.currentPrice ?? '0') ?? widget.baseGame.price,
            year: apiGame.releaseYear ?? widget.baseGame.year,
            rentability: apiGame.rentability,
            metacritic: apiGame.metacritic,
            esrbRating: apiGame.esrbRating,
            genres: apiGame.genres.isNotEmpty ? apiGame.genres : widget.baseGame.genres,
            hltb: HltbTimes(
              main: apiGame.hltbMainStory?.round(),
              completionist: apiGame.hltbCompletionist?.round(),
            ),
            pcSpecs: widget.baseGame.pcSpecs,
            pcRequirements: apiGame.pcRequirements ?? widget.baseGame.pcRequirements,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // _error = e.toString();
          _fullGame = widget.baseGame;
          _isLoading = false;
        });
      }
    }
  }

  /// ¿El usuario tiene este juego en su biblioteca?
  bool get _isOwned {
    if (_removedFromLibraryLocal) return false;
    if (_addedToLibraryLocal) return true;
    return _fullGame?.entryId != null || widget.entryId != null || _addedEntryId != null;
  }

  /// Estado del corazón (Lista de Deseados).
  /// Se desmarca automáticamente si _isOwned pasa a true.
  bool _isInWishlist = false;

  /// Añadir / Quitar de la biblioteca
  Future<void> _toggleLibrary() async {
    setState(() => _isTogglingLibrary = true);
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('No session');

      if (_isOwned) {
        // Quitar
        // Si no tenemos entryId real (ej. añadido localmente en esta misma sesión),
        // intentar borrar por ID podría fallar si la API no soporta DELETE por gameId.
        // Pero en MVP lo intentamos, o usamos el entryId si existe.
        final targetId = _addedEntryId ?? widget.entryId ?? widget.baseGame.id.toString();
        await ApiService.removeFromLibrary(userId: user.id, entryId: targetId);
        if (mounted) {
          setState(() {
            _removedFromLibraryLocal = true;
            _addedToLibraryLocal = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Juego eliminado de la biblioteca', style: TextStyle(color: Colors.white, fontSize: 13)),
            backgroundColor: _bgCard,
          ));
        }
      } else {
        // Añadir
        final newEntryId = await ApiService.addToLibrary(
          userId: user.id,
          gameTitle: widget.baseGame.title,
          platform: widget.baseGame.platform.displayName, // En vez de 'PC' forzado
        );
        if (mounted) {
          setState(() {
            _addedToLibraryLocal = true;
            _addedEntryId = newEntryId; // guardamos el id real para poder borrarlo
            _removedFromLibraryLocal = false;
            _isInWishlist = false; // Desmarcar de deseados si se añade a la biblioteca
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('¡Juego añadido a la biblioteca!', style: TextStyle(color: _green, fontSize: 13)),
            backgroundColor: _bgCard,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: _red, fontSize: 13)),
          backgroundColor: _bgCard,
        ));
      }
    } finally {
      if (mounted) setState(() => _isTogglingLibrary = false);
    }
  }

  /// Intenta añadir/quitar el juego de la Lista de Deseados.
  /// Si el juego ya está en la biblioteca, muestra un snackbar informativo.
  void _toggleWishlist() {
    if (_isOwned) {
      // Regla de negocio: no se puede desear algo que ya posees
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Este juego ya se encuentra en tu biblioteca',
            style: TextStyle(
              color: _yellow,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: _bgCard,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _border),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isInWishlist = !_isInWishlist;
      // Si tras marcar deseado el juego ya está en biblioteca, desmarcamos
      if (_isOwned && _isInWishlist) _isInWishlist = false;
    });
  }

  Future<void> _showEditDialog() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;
    final targetId = _addedEntryId ?? widget.entryId;
    if (targetId == null) return;

    String selectedStatus = _fullGame?.status == GameStatus.playing ? 'Playing' :
                            _fullGame?.status == GameStatus.completed ? 'Completed' :
                            _fullGame?.status == GameStatus.abandoned ? 'Abandoned' : 'Backlog';
    final playtimeCtrl = TextEditingController(text: _fullGame?.playtime.toString() ?? '0');

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
              title: const Text('Editar Entrada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado', style: TextStyle(color: _textSub, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      dropdownColor: _bgCard,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'Backlog', child: Text('Pendiente')),
                        DropdownMenuItem(value: 'Playing', child: Text('Jugando')),
                        DropdownMenuItem(value: 'Completed', child: Text('Completado')),
                        DropdownMenuItem(value: 'Abandoned', child: Text('Abandonado')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedStatus = v!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Plataforma', style: TextStyle(color: _textSub, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButton<Platform>(
                      value: _fullGame?.platform ?? Platform.steam,
                      dropdownColor: _bgCard,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      items: Platform.values.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            // Update local game immediately for the dropdown state
                            _fullGame = _fullGame!.copyWith(platform: v);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Horas jugadas', style: TextStyle(color: _textSub, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: playtimeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _bg,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _yellow)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: TextStyle(color: _textSub)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _yellow, foregroundColor: Colors.black),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    setState(() => _isLoading = true);
                    try {
                      final int playtime = int.tryParse(playtimeCtrl.text) ?? 0;
                      await ApiService.updateLibraryEntry(
                        userId: user.id,
                        entryId: targetId,
                        status: selectedStatus,
                        playtime: playtime,
                        platform: _fullGame!.platform.displayName,
                      );
                      // Refrescar
                      final details = await ApiService.getGameDetails(userId: user.id, entryId: targetId);
                      final compStatus = details['compatibility'] as String?;
                      if (mounted) {
                        setState(() {
                          _fullGame = _fullGame!.copyWith(
                            playtime: playtime,
                            status: selectedStatus == 'Playing' ? GameStatus.playing :
                                    selectedStatus == 'Completed' ? GameStatus.completed :
                                    selectedStatus == 'Abandoned' ? GameStatus.abandoned : GameStatus.unplayed,
                            pcReq: PcReq.fromString(compStatus),
                          );
                          _isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrada actualizada'), backgroundColor: _bgCard));
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: _red));
                      }
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _fullGame == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _yellow)),
      );
    }

    final game = _fullGame!;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar con imagen Hero ─────────────────────────────────
          _GameSliverAppBar(
            game: game,
            isInWishlist: _isInWishlist,
            isOwned:      _isOwned,
            onWishlistToggle: _toggleWishlist,
          ),

          // ── Cuerpo de la pantalla ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón Agregar/Quitar de Biblioteca
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
                  _RoiModule(game: game),
                  const SizedBox(height: 16),

                  // Módulo Requisitos PC — solo si es juego de PC
                  if (game.platform.isPc && (game.pcSpecs != null || game.pcReq != PcReq.yellow || (game.pcRequirements != null && game.pcRequirements!.isNotEmpty && game.pcRequirements != 'No disponibles'))) ...[
                    _PcReqModule(game: game),
                    const SizedBox(height: 16),
                  ],

                  // Módulo HLTB
                  if (game.hltb != null) ...[
                    _HltbModule(game: game),
                    const SizedBox(height: 16),
                  ],

                  // Módulo Cosméticos
                  if (game.hasCosmetics && game.cosmetics != null) ...[
                    _CosmeticsModule(game: game),
                    const SizedBox(height: 16),
                  ],

                  // Módulo Comparador de Precios
                  _PriceCompareModule(game: game, deals: _deals),
                  const SizedBox(height: 16),

                  // Info general
                  _InfoModule(game: game),
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
    required this.isInWishlist,
    required this.isOwned,
    required this.onWishlistToggle,
  });

  final Game game;
  final bool isInWishlist;
  final bool isOwned;
  final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    // El corazón es amarillo si está en wishlist, gris si no.
    // Si el juego ya es de la biblioteca, el corazón usa el color de
    // "ya en biblioteca" (amarillo tenue) para indicar el estado.
    final heartColor = isOwned
        ? _yellow.withValues(alpha: 0.45)   // en biblioteca: tenue
        : isInWishlist
            ? _yellow                        // deseado activo
            : Colors.white;

    final heartIcon = (isOwned || isInWishlist)
        ? Icons.favorite_rounded
        : Icons.favorite_border_rounded;

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
          onTap: onWishlistToggle,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(heartIcon, color: heartColor, size: 20),
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
                errorBuilder: (context, error, stackTrace) => Container(
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
            // Badges inferiores — solo mostrar PC req si es un juego de PC
            Positioned(
              bottom: 50,
              left: 16,
              child: Row(
                children: [
                  PlatformBadge(platform: game.platform),
                  if (game.platform.isPc) ...[
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
                  if (isOwned && game.playtime > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _border.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${game.playtime}h jugadas',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
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



class _RoiModule extends StatelessWidget {
  const _RoiModule({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    // Usamos HLTB main story para la rentabilidad teórica
    final int hltbHours = game.hltb?.main ?? 0;
    // Ignoramos la rentabilidad del backend si es 0, y calculamos localmente.
    final cph = (game.rentability != null && game.rentability! > 0) 
        ? game.rentability! 
        : _costPerHour(game.price, hltbHours);
    final color = _roiColor(cph);
    final label = _roiLabel(cph);

    return _ModuleCard(
      icon: Icons.analytics_rounded,
      iconColor: _purple,
      title: 'Rentabilidad Teórica (ROI)',
      child: Column(
        children: [
          Row(
            children: [
              // Precio — si no es PC y vale 0, no es gratis sino sin datos
              Expanded(
                child: _RoiStat(
                  label: 'Precio',
                  value: game.price == 0
                      ? (game.platform.isPc ? 'Gratis' : 'N/D')
                      : '\$${game.price.toStringAsFixed(0)}',
                  color: _textMain,
                ),
              ),
              // Horas HLTB
              Expanded(
                child: _RoiStat(
                  label: 'HLTB est.',
                  value: hltbHours > 0 ? '${hltbHours}h' : '—',
                  color: _cyan,
                ),
              ),
              // Coste por hora
              Expanded(
                child: _RoiStat(
                  label: 'Coste/hora',
                  value: game.price == 0 || hltbHours == 0
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
    final cfg = game.pcReq.config;
    final specs = game.pcSpecs;

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
          // Requisitos HTML
          if (game.pcRequirements != null && game.pcRequirements!.isNotEmpty && game.pcRequirements != 'No disponibles')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _bg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Html(
                data: game.pcRequirements,
                style: {
                  "body": Style(
                    color: _textSub,
                    fontSize: FontSize(12),
                    fontFamily: 'Inter',
                    margin: Margins.zero,
                  ),
                  "strong": Style(
                    color: _textMain,
                    fontWeight: FontWeight.w600,
                  ),
                  "li": Style(
                    margin: Margins.only(bottom: 4),
                  ),
                  "ul": Style(
                    margin: Margins.only(left: 12),
                    padding: HtmlPaddings.zero,
                  ),
                },
              ),
            )
          else if (specs != null) ...[
            _SpecBar(label: 'CPU', spec: specs.cpu),
            _SpecBar(label: 'GPU', spec: specs.gpu),
            _SpecBar(label: 'RAM', spec: specs.ram),
            _SpecBar(label: 'SSD', spec: specs.storage),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Compatibilidad calculada (especificaciones detalladas no disponibles)',
                style: TextStyle(fontSize: 12, color: _textSub),
                textAlign: TextAlign.center,
              ),
            ),
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
    final genreLabel = game.genres.isNotEmpty
        ? game.genres.take(3).join(' · ')
        : (game.genre.isNotEmpty && game.genre != 'Varios' ? game.genre : null);

    return _ModuleCard(
      icon: Icons.info_outline_rounded,
      iconColor: _cyan,
      title: 'Información General',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: chips principales
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Plataforma', value: game.platform.displayName),
              _InfoChip(label: 'Año', value: game.year > 0 ? '${game.year}' : 'N/D'),
              _InfoChip(
                  label: 'Estado',
                  value: game.status.label,
                  valueColor: game.status.color),
              if (game.playtime > 0)
                _InfoChip(label: 'Horas jugadas', value: '${game.playtime}h', valueColor: _cyan),
              if (game.rating != null && game.rating! > 0)
                _InfoChip(
                    label: 'Rating',
                    value: '★ ${game.rating!.toStringAsFixed(1)}',
                    valueColor: _yellow),
              if (game.metacritic != null && game.metacritic! > 0)
                _InfoChip(
                    label: 'Metacritic',
                    value: '${game.metacritic}',
                    valueColor: game.metacritic! >= 75
                        ? const Color(0xFF4AF626)
                        : game.metacritic! >= 50
                            ? _yellow
                            : const Color(0xFFFF4040)),
              if (game.esrbRating != null)
                _InfoChip(label: 'ESRB', value: game.esrbRating!),
            ],
          ),
          // Géneros (si los hay)
          if (genreLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.label_rounded, size: 12, color: _textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    genreLabel,
                    style: const TextStyle(fontSize: 11, color: _textSub),
                  ),
                ),
              ],
            ),
          ],
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
/// recibiendo los deals reales obtenidos por la API.
class _PriceCompareModule extends StatelessWidget {
  const _PriceCompareModule({required this.game, required this.deals});
  final Game game;
  final List<GameDeal> deals;

  @override
  Widget build(BuildContext context) {
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
