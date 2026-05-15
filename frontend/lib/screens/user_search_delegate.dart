// Este es el buscador de usuarios. Sirve para encontrar a gente en la base de datos y agregarlos como amigos.
// He intentado que sea rápido y que la interfaz no se trabe al buscar.

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'user_profile_screen.dart';

// ── CONFIGURACIÓN VISUAL ─────────────────────────────────────────────────────
const _bg        = Color(0xFF121212);
const _bgCard    = Color(0xFF1A1A1A);
const _border    = Color(0xFF2A2A2A);
const _yellow    = Color(0xFFFFB800);
const _yellowDim = Color(0x1AFFB800);
const _textMain  = Colors.white;
const _textSub   = Color(0xFF888888);
const _textMuted = Color(0xFF555555);

// El buscador principal. He configurado los colores para que se vea oscuro y resalte el amarillo.
class B2GUserSearchDelegate extends SearchDelegate<String?> {
  B2GUserSearchDelegate() : super(
    searchFieldLabel: 'Buscar amigos...',
    searchFieldStyle: const TextStyle(color: Colors.white, fontSize: 16),
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: _bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgCard,
        elevation: 0,
        iconTheme: IconThemeData(color: _yellow),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: _textSub),
        border: InputBorder.none,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _yellow,
        selectionColor: _yellowDim,
        selectionHandleColor: _yellow,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded, color: _yellow),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _SearchBody(query: query);

  @override
  Widget buildSuggestions(BuildContext context) => _SearchBody(query: query);
}

// ── CUERPO DE LA BÚSQUEDA ────────────────────────────────────────────────────
class _SearchBody extends StatefulWidget {
  const _SearchBody({required this.query});
  final String query;

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  Timer? _debounce;
  List<UserSearchResult> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(_SearchBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _performSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (widget.query.trim().isEmpty) {
      setState(() { _results = []; _isLoading = false; });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final users = await ApiService.searchUsers(widget.query);
        if (mounted) {
          setState(() {
            _results = users;
            _isLoading = false;
            _error = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.isEmpty) return const _EmptyQueryHint();
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: _yellow, strokeWidth: 2));
    if (_error != null) return _ErrorHint(message: _error!);
    if (_results.isEmpty) return _NoResults(query: widget.query);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _results.length,
      itemBuilder: (context, index) => _UserCard(
        user: _results[index],
        onStatusChanged: (newStatus) {
          setState(() {
            _results[index] = _results[index].copyWith(friendStatus: newStatus);
          });
        },
        onReturn: () => _performSearch(),
      ),
    );
  }
}

// ── TARJETA DE USUARIO ───────────────────────────────────────────────────────
class _UserCard extends StatefulWidget {
  const _UserCard({required this.user, required this.onStatusChanged, required this.onReturn});
  final UserSearchResult user;
  final Function(String) onStatusChanged;
  final VoidCallback onReturn;
  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _loading = false;
  String _status = 'none';
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _status = widget.user.friendStatus ?? 'none';
  }

  @override
  void didUpdateWidget(_UserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.friendStatus != widget.user.friendStatus) {
      _status = widget.user.friendStatus ?? 'none';
    }
  }

  Future<void> _handleFriendAction() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.sendFriendRequest(widget.user.id);
      if (mounted) {
        setState(() {
          _status = res;
          _loading = false;
        });
        widget.onStatusChanged(res);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.user.username.length >= 2 
        ? widget.user.username.substring(0, 2).toUpperCase() 
        : widget.user.username.toUpperCase();
    
    final colors = [Colors.cyan, Colors.purple, Colors.orange, Colors.pink, Colors.blue, Colors.teal];
    final bgColor = colors[widget.user.username.length % colors.length];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => UserProfileScreen(user: User(
            id: widget.user.id,
            username: widget.user.username,
            avatarUrl: widget.user.avatarUrl,
            karma: widget.user.karma,
            email: '',
            recentGames: [],
            recentGameCovers: [],
            isOnline: false,
          )),
        ));
        widget.onReturn();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            // Avatar
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(color: _yellow.withValues(alpha: 0.3), width: 1.5),
              ),
              child: widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                  ? ClipOval(child: Image.network(widget.user.avatarUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(initials,
                          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)))))
                  : Center(child: Text(initials,
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 14),

            // Info
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

            // Botón
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

// ── BOTÓN DE AMISTAD ─────────────────────────────────────────────────────────
class _FriendButton extends StatelessWidget {
  const _FriendButton({required this.status, required this.onTap});
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, fgColor, bgColor) = switch (status) {
      'friends' || 'accepted' => (Icons.check_circle_rounded, _yellow, _yellowDim),
      'pending'               => (Icons.hourglass_top_rounded, _yellow, _yellowDim),
      _                       => (Icons.person_add_alt_1_rounded, Colors.black, _yellow),
    };

    final label = switch (status) {
      'friends' || 'accepted' => 'Amigos',
      'pending'               => 'Enviada',
      _                       => 'Añadir',
    };

    return GestureDetector(
      onTap: (status == 'friends') ? null : onTap,
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

// ── WIDGETS AUXILIARES ───────────────────────────────────────────────────────
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
