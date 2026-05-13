import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/game_model.dart' as gm;
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'game_detail_screen.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _bg       = Color(0xFF121212);
const _bgCard   = Color(0xFF1A1A1A);
const _bgCard2  = Color(0xFF222222);
const _border   = Color(0xFF2A2A2A);
const _yellow   = Color(0xFFFFB800);
const _textMain = Colors.white;
const _textSub  = Color(0xFF888888);
const _cyan      = Color(0xFF00E5FF);

// Colores de plataformas
const _colorDiscord  = Color(0xFF5865F2);
const _colorSteam    = Color(0xFF1B2838);
const _colorSteamTxt = Color(0xFF66C0F4);
const _colorEpic     = Color(0xFF2A2A2A);
const _colorXbox     = Color(0xFF107C10);

// =============================================================================
// Pantalla principal de Perfil
// =============================================================================

class UserProfileScreen extends StatefulWidget {
  final User user; // Trae datos básicos desde la búsqueda o lista de amigos
  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  bool _isLoadingProfile = true;
  late Future<List<ApiGame>> _libraryFuture;
  Color _dominantColor = _yellow;

  @override
  void initState() {
    super.initState();
    // Cargar perfil completo (Karma, Amigos, PC, Steam ID)
    _loadProfile();
    // Cargar biblioteca (Intenta cargar completa, si no son amigos fallback a preview)
    _libraryFuture = _loadLibrary();
  }

  Future<void> _loadProfile() async {
    try {
      final u = await ApiService.getUserProfilePublic(widget.user.id);
      _updatePalette(u.avatarUrl);
      if (mounted) {
        setState(() {
          _user = u;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // No mostramos error específico en la UI por ahora
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _updatePalette(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(NetworkImage(url));
      if (mounted) {
        setState(() {
          _dominantColor = palette.dominantColor?.color ?? _yellow;
        });
      }
    } catch (_) {}
  }

  Future<List<ApiGame>> _loadLibrary() async {
    try {
      return await ApiService.getFriendLibrary(widget.user.id);
    } catch (e) {
      // Fallback si no son amigos o hay error de permisos
      return await ApiService.getUserLibraryPreview(widget.user.id);
    }
  }

  Future<void> _rateUser(User u, String action) async {
    final oldRating = u.userRating;
    final oldKarma = u.karma;
    
    int newKarma = oldKarma;
    String newRating = 'none';

    if (action == 'like') {
      if (oldRating == 'like') {
        newRating = 'none';
        newKarma--;
      } else {
        newRating = 'like';
        newKarma += (oldRating == 'dislike' ? 2 : 1);
      }
    } else {
      if (oldRating == 'dislike') {
        newRating = 'none';
        newKarma++;
      } else {
        newRating = 'dislike';
        newKarma -= (oldRating == 'like' ? 2 : 1);
      }
    }

    setState(() {
      _user = u.copyWith(karma: newKarma, userRating: newRating);
    });

    try {
      final res = await ApiService.rateUser(u.id, action);
      if (mounted) {
        setState(() {
          _user = u.copyWith(
            karma: res['karma'] as int,
            userRating: res['userRating'] as String,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _user = u.copyWith(karma: oldKarma, userRating: oldRating);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al valorar usuario: $e', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: _yellow,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el usuario original hasta que cargue el completo para mantener la UI fluida
    final u = _user ?? widget.user;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top Gradient y Avatar ──────────────────────────────────────
          _buildAppBar(u),

          // ── Indicador de carga si está buscando datos ──────────────────
          if (_isLoadingProfile)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator(color: _yellow)),
                  ),
                )
              else ...[
                // ── Bio ──────────────────────────────────────────────────────
                if (u.bio != null && u.bio!.isNotEmpty) _buildBio(u.bio!),

                // ── Estadísticas rápidas (Amigos, Karma) ─────────────────────
                _buildStats(u),

                // ── Acciones de Karma (Like / Dislike) ───────────────────────
                _buildKarmaActions(u),

                // ── Plataformas ──────────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('Plataformas Vinculadas', style: TextStyle(color: _textMain, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _PlatformCard(
                          platform: 'Steam',
                          nickname: u.steamId ?? '',
                          bgColor: _colorSteam,
                          iconColor: _colorSteamTxt,
                          icon: Icons.videogame_asset,
                          isOwnProfile: false,
                        ),
                        const SizedBox(height: 10),
                        _PlatformCard(
                          platform: 'Epic Games',
                          nickname: u.epicId ?? '',
                          bgColor: _colorEpic,
                          iconColor: Colors.white,
                          icon: Icons.games_rounded,
                          isOwnProfile: false,
                        ),
                        const SizedBox(height: 10),
                        _PlatformCard(
                          platform: 'Xbox Live',
                          nickname: u.xboxId ?? '',
                          bgColor: _colorXbox.withValues(alpha: 0.15),
                          iconColor: _colorXbox,
                          icon: Icons.gamepad_rounded,
                          isOwnProfile: false,
                        ),
                        const SizedBox(height: 10),
                        _PlatformCard(
                          platform: 'Discord',
                          nickname: u.discordId ?? '',
                          bgColor: _colorDiscord.withValues(alpha: 0.15),
                          iconColor: _colorDiscord,
                          icon: Icons.discord,
                          isOwnProfile: false,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Mi Equipo (PC) ───────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('Mi Equipo (PC)', style: TextStyle(color: _textMain, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _PcSpecsGrid(specs: u.pcComponents),
                  ),
                ),

                // ── Separador ────────────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Divider(color: _border),
                  ),
                ),

                // ── Juegos ───────────────────────────────────────────────────
                FutureBuilder<List<ApiGame>>(
                  future: _libraryFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: _yellow),
                        )),
                      );
                    }

                    final games = snap.data ?? [];
                    if (games.isEmpty) return _buildEmptyLibrary(u);

                    // Ordenar por playtime (si existe) de mayor a menor
                    final sortedGames = List<ApiGame>.from(games);
                    sortedGames.sort((a, b) => (b.userPlaytime ?? 0).compareTo(a.userPlaytime ?? 0));

                    final topGames = sortedGames.take(4).toList();
                    final restGames = sortedGames.skip(4).toList();

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        // Título "Más jugados"
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Text('Más jugados',
                              style: TextStyle(color: _textMain, fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        // Grid de 4 juegos
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: topGames.length,
                            itemBuilder: (ctx, i) => _GameCover(game: topGames[i]),
                          ),
                        ),

                        // Acordeón con el resto de juegos
                        if (restGames.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildGamesAccordion(restGames),
                        ],
                        
                        const SizedBox(height: 80), // Margen inferior
                      ]),
                    );
                  },
                ),
              ],
        ],
      ),
    );
  }

  // ── Widgets Extractos ──────────────────────────────────────────────────────

  Widget _buildAppBar(User u) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: _bg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (ctx, constraints) {
          final top = constraints.biggest.height;
          // Cálculo de opacidad: desaparece por completo al llegar a kToolbarHeight
          final opacity = ((top - kToolbarHeight) / (240 - kToolbarHeight)).clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            collapseMode: CollapseMode.parallax,
            background: Opacity(
              opacity: opacity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo dinámico
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _dominantColor.withValues(alpha: 0.4),
                          _bg,
                        ],
                      ),
                    ),
                  ),
                  // Avatar y Nombre
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: u.avatarBgColor,
                            border: Border.all(color: _dominantColor, width: 3),
                            boxShadow: [
                              BoxShadow(color: _dominantColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
                            ],
                          ),
                          child: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                              ? ClipOval(child: Image.network(u.avatarUrl!, fit: BoxFit.cover))
                              : Center(child: Text(u.initials,
                                  style: const TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900))),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(u.username,
                                style: const TextStyle(color: _textMain, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            if (u.isOnline) ...[
                              const SizedBox(width: 8),
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF4AF626), shape: BoxShape.circle)),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBio(String bio) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote_rounded, color: _yellow, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(bio, style: const TextStyle(color: _textSub, fontSize: 13, height: 1.5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(User u) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatWidget(label: 'AMIGOS', value: '${u.friendsCount}', icon: Icons.group_rounded),
            _StatWidget(label: 'KARMA', value: '${u.karma}', icon: Icons.star_rounded, isHighlighted: true),
          ],
        ),
      ),
    );
  }

  Widget _buildKarmaActions(User u) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _KarmaButton(
              icon: Icons.thumb_up_rounded,
              label: 'Like',
              isActive: u.userRating == 'like',
              color: const Color(0xFF00E676),
              onTap: () => _rateUser(u, 'like'),
            ),
            const SizedBox(width: 16),
            _KarmaButton(
              icon: Icons.thumb_down_rounded,
              label: 'Dislike',
              isActive: u.userRating == 'dislike',
              color: const Color(0xFFFF1744),
              onTap: () => _rateUser(u, 'dislike'),
            ),
          ],
        ),
      ),
    );
  }

  // _buildStats se mantiene


  Widget _buildEmptyLibrary(User u) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(children: [
            const Icon(Icons.videogame_asset_off_rounded, color: _textSub, size: 36),
            const SizedBox(height: 12),
            Text('${u.username} no tiene juegos públicos',
                style: const TextStyle(color: _textSub, fontSize: 13), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _buildGamesAccordion(List<ApiGame> games) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: ExpansionTile(
            collapsedIconColor: _yellow,
            iconColor: _yellow,
            title: Text('Ver todos los juegos (${games.length})', 
                style: const TextStyle(color: _textMain, fontSize: 14, fontWeight: FontWeight.w600)),
            children: games.map((g) => _GameListTile(game: g)).toList(),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Widgets Secundarios
// =============================================================================

class _StatWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlighted;

  const _StatWidget({required this.label, required this.value, required this.icon, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHighlighted ? _yellow.withValues(alpha: 0.3) : _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: isHighlighted ? _yellow : _textSub, size: 16),
              const SizedBox(width: 6),
              Text(value, style: TextStyle(color: isHighlighted ? _yellow : _textMain, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _textSub, fontSize: 10, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

// Widget eliminado, usamos _PcSpecsGrid


class _GameListTile extends StatelessWidget {
  final ApiGame game;
  const _GameListTile({required this.game});

  void _open(BuildContext context) {
    final g = gm.Game(
      id:       game.id.hashCode,
      entryId:  game.entryId,
      title:    game.title,
      platform: gm.Platform.steam,
      genre:    '',
      playtime: game.userPlaytime ?? 0,
      status:   gm.GameStatus.unplayed,
      cover:    game.imageUrl,
      pcReq:    gm.PcReq.yellow,
      hasCosmetics: false,
      price:    double.tryParse(game.currentPrice ?? '0') ?? 0,
      year:     0,
    );
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameDetailScreen(baseGame: g)));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => _open(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(game.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 40, height: 40, color: _bgCard2)),
      ),
      title: Text(game.title, style: const TextStyle(color: _textMain, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: game.userPlaytime != null && game.userPlaytime! > 0
          ? Text('${game.userPlaytime} horas', style: const TextStyle(color: _yellow, fontSize: 12))
          : const Text('Sin horas registradas', style: TextStyle(color: _textSub, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: _textSub, size: 20),
    );
  }
}

class _GameCover extends StatefulWidget {
  final ApiGame game;
  const _GameCover({required this.game});

  @override
  State<_GameCover> createState() => _GameCoverState();
}

class _GameCoverState extends State<_GameCover> {
  bool _pressed = false;

  void _open() {
    final g = gm.Game(
      id:       widget.game.id.hashCode,
      entryId:  widget.game.entryId,
      title:    widget.game.title,
      platform: gm.Platform.steam,
      genre:    '',
      playtime: widget.game.userPlaytime ?? 0,
      status:   gm.GameStatus.unplayed,
      cover:    widget.game.imageUrl,
      pcReq:    gm.PcReq.yellow,
      hasCosmetics: false,
      price:    double.tryParse(widget.game.currentPrice ?? '0') ?? 0,
      year:     0,
    );
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameDetailScreen(baseGame: g)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); _open(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed ? _yellow.withValues(alpha: 0.7) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.6 : 0.35),
              blurRadius: _pressed ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.game.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: _bgCard2,
                  child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videogame_asset_rounded, color: Color(0xFF444444), size: 32),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(widget.game.title,
                          style: const TextStyle(color: _textSub, fontSize: 11),
                          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  )),
                ),
              ),
              // Gradiente inferior con título y horas
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.game.title,
                        style: const TextStyle(color: _textMain, fontSize: 11, fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (widget.game.userPlaytime != null && widget.game.userPlaytime! > 0)
                        Text('${widget.game.userPlaytime}h', style: const TextStyle(color: _yellow, fontSize: 10, fontWeight: FontWeight.bold)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Reutilizados de profile_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

class _PcSpecsGrid extends StatelessWidget {
  const _PcSpecsGrid({required this.specs});
  final Map<String, dynamic> specs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _PcSpecRow(icon: Icons.memory_rounded, label: 'CPU', value: specs['cpu']?.toString() ?? '-'),
          const Divider(color: _border, height: 24),
          _PcSpecRow(icon: Icons.developer_board_rounded, label: 'GPU', value: specs['gpu']?.toString() ?? '-'),
          const Divider(color: _border, height: 24),
          _PcSpecRow(icon: Icons.sd_storage_rounded, label: 'RAM', value: '${specs['ram'] ?? '-'} GB'),
          const Divider(color: _border, height: 24),
          _PcSpecRow(icon: Icons.storage_rounded, label: 'Storage', value: specs['storage']?.toString() ?? '-'),
        ],
      ),
    );
  }
}

class _PcSpecRow extends StatelessWidget {
  const _PcSpecRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _cyan),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textSub, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value == '-' || value.isEmpty ? 'No especificado' : value,
            style: const TextStyle(fontSize: 13, color: _textMain, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.nickname,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    required this.isOwnProfile,
  });

  final String platform;
  final String nickname;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final bool isOwnProfile;

  void _handleTap(BuildContext context) {
    Clipboard.setData(ClipboardData(text: nickname));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID copiado al portapapeles', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _yellow,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: iconColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nickname.isEmpty ? 'Aún no especificado' : nickname,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: nickname.isEmpty ? _textSub : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isOwnProfile ? Icons.edit_rounded : Icons.copy_rounded,
              size: 18,
              color: isOwnProfile ? _textSub : iconColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _KarmaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _KarmaButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? color : _textSub, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? color : _textSub, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
