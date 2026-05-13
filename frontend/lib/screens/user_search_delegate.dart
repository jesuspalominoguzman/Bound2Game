// =============================================================================
// user_search_delegate.dart — Bound2Game Flutter
//
// SearchDelegate que busca usuarios en la BD en tiempo real.
// - Tap en la tarjeta → abre la pantalla de juegos del usuario (preview público)
// - Botón icono → envía/cancela solicitud de amistad
// - Paleta: negro (#1A1A1A) + amarillo (#FFB800)
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/game_model.dart' hide User;
import 'game_detail_screen.dart';
import 'user_profile_screen.dart';

// ── Paleta negro/amarillo ─────────────────────────────────────────────────────
const _bg        = Color(0xFF121212);
const _bgCard    = Color(0xFF1A1A1A);
const _bgSearch  = Color(0xFF1E1E1E);
const _border    = Color(0xFF2A2A2A);
const _yellow    = Color(0xFFFFB800);
const _yellowDim = Color(0x33FFB800); // 20% alpha
const _textMain  = Colors.white;
const _textSub   = Color(0xFF888888);
const _textMuted = Color(0xFF555555);

// =============================================================================
// Delegate principal
// =============================================================================

class UserSearchDelegate extends SearchDelegate<void> {
  UserSearchDelegate({required this.myFriendIds})
      : super(searchFieldLabel: 'Buscar jugador...');

  final Set<String> myFriendIds;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: _bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgSearch,
        elevation: 0,
        iconTheme: IconThemeData(color: _textMain),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: _textMuted),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: _textMain, fontSize: 15),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: _textSub),
            onPressed: () { query = ''; showSuggestions(context); },
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textMain),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildBody(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    if (query.trim().isEmpty) return const _EmptyQueryHint();

    // Debounce: sólo lanzar petición cuando el usuario deja de escribir 400ms
    if (query != _lastQuery) {
      _lastQuery = query;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        // ignore: invalid_use_of_protected_member
        (context as Element).markNeedsBuild();
      });
    }

    return FutureBuilder<List<UserSearchResult>>(
      future: ApiService.searchUsers(query.trim()),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: _yellow, strokeWidth: 2,
            ),
          );
        }
        if (snap.hasError) {
          return _ErrorHint(message: snap.error.toString());
        }
        final users = snap.data ?? [];
        if (users.isEmpty) return _NoResults(query: query);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: users.length,
          itemBuilder: (ctx, i) => _UserTile(
            user: users[i],
            initialStatus: myFriendIds.contains(users[i].id) ? 'friends' : 'none',
          ),
        );
      },
    );
  }

  @override
  void close(BuildContext context, void result) {
    _debounce?.cancel();
    super.close(context, result);
  }
}

// =============================================================================
// Tile de usuario — toca la tarjeta para ver sus juegos; icono para amistad
// =============================================================================

class _UserTile extends StatefulWidget {
  const _UserTile({required this.user, required this.initialStatus});
  final UserSearchResult user;
  final String initialStatus; // 'none' | 'pending' | 'friends'

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  late String _status;
  bool _loading = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  // ── Abre la pantalla de perfil del usuario (disponible para todos) ──────────
  void _openGames(BuildContext ctx) {
    final minUser = User(
      id: widget.user.id,
      username: widget.user.username,
      avatarUrl: widget.user.avatarUrl,
    );
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => UserProfileScreen(user: minUser),
    ));
  }

  // ── Enviar / aceptar solicitud de amistad ──────────────────────────────────
  Future<void> _handleFriendAction() async {
    if (_status == 'pending' || _loading) return;
    if (widget.user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ID de usuario inválido'),
        backgroundColor: Color(0xFF1A1A1A),
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService.sendFriendRequest(widget.user.id);
      if (mounted) setState(() => _status = result == 'accepted' ? 'friends' : result);

      if (mounted) {
        final msg = switch (result) {
          'accepted' => '¡Ahora sois amigos! 🎮',
          'pending'  => 'Solicitud enviada a ${widget.user.username}',
          'friends'  => 'Ya sois amigos',
          _          => 'Estado: $result',
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFF2A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.user.username.length >= 2
        ? widget.user.username.substring(0, 2).toUpperCase()
        : widget.user.username.toUpperCase();

    const avatarColors = [
      Color(0xFFFFB800), Color(0xFFFF7043), Color(0xFF7B61FF),
      Color(0xFF00B4D8), Color(0xFFFF6B9D), Color(0xFF4AF626),
    ];
    final bgColor = avatarColors[widget.user.id.hashCode.abs() % avatarColors.length];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) { setState(() => _pressed = false); _openGames(context); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFF222222) : _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed ? _yellow.withValues(alpha: 0.5) : _border,
            width: _pressed ? 1.5 : 1,
          ),
          boxShadow: _pressed ? [
            BoxShadow(color: _yellow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ] : null,
        ),
        child: Row(
          children: [
            // ── Avatar ───────────────────────────────────────────────────────
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(color: _yellow.withValues(alpha: 0.3), width: 1.5),
              ),
              child: widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                  ? ClipOval(child: Image.network(widget.user.avatarUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(child: Text(initials,
                          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)))))
                  : Center(child: Text(initials,
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 14),

            // ── Info ─────────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.username,
                    style: const TextStyle(color: _textMain, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: _yellow, size: 12),
                    const SizedBox(width: 4),
                    Text('${widget.user.karma} karma',
                      style: const TextStyle(color: _textSub, fontSize: 11)),
                    const SizedBox(width: 8),
                    const Icon(Icons.videogame_asset_rounded, color: _textMuted, size: 12),
                    const SizedBox(width: 4),
                    const Text('Ver juegos', style: TextStyle(color: _textMuted, fontSize: 11)),
                  ]),
                ],
              ),
            ),

            // ── Botón amistad ─────────────────────────────────────────────────
            const SizedBox(width: 8),
            _loading
                ? const SizedBox(width: 36, height: 36,
                    child: Padding(padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(color: _yellow, strokeWidth: 2)))
                : _FriendButton(status: _status, onTap: _handleFriendAction),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Botón de amistad (negro/amarillo)
// =============================================================================

class _FriendButton extends StatelessWidget {
  const _FriendButton({required this.status, required this.onTap});
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, fgColor, bgColor) = switch (status) {
      'friends' => (Icons.check_circle_rounded, _yellow, _yellowDim),
      'pending' => (Icons.hourglass_top_rounded, _yellow, _yellowDim),
      _         => (Icons.person_add_alt_1_rounded, Colors.black, _yellow),
    };

    final label = switch (status) {
      'friends' => 'Amigos',
      'pending' => 'Enviada',
      _         => 'Añadir',
    };

    return GestureDetector(
      onTap: (status == 'pending' || status == 'friends') ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (status == 'none') ? _yellow : _yellowDim,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fgColor, size: 15),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              color: fgColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}



// =============================================================================
// Estados vacíos / error
// =============================================================================

class _EmptyQueryHint extends StatelessWidget {
  const _EmptyQueryHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: _yellowDim, shape: BoxShape.circle,
            border: Border.all(color: _yellow.withValues(alpha: 0.3))),
          child: const Icon(Icons.person_search_rounded, color: _yellow, size: 36),
        ),
        const SizedBox(height: 20),
        const Text('Busca jugadores por nombre\npara ver su perfil y juegos',
          style: TextStyle(color: _textSub, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: _yellowDim, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _yellow.withValues(alpha: 0.4))),
          child: const Text('Escribe un nombre para empezar',
            style: TextStyle(color: _yellow, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _ErrorHint extends StatelessWidget {
  const _ErrorHint({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: _yellowDim, shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, color: _yellow, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Error de conexión',
            style: TextStyle(color: _textMain, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message,
            style: const TextStyle(color: _textSub, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 3, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.search_off_rounded, color: _textMuted, size: 52),
          const SizedBox(height: 16),
          Text('Sin resultados para\n"$query"',
            style: const TextStyle(color: _textSub, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
