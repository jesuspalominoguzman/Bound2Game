// Este es el buscador de usuarios. Sirve para encontrar a gente en la base de datos y agregarlos como amigos.
// He intentado que sea rápido y que la interfaz no se trabe al buscar.

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'user_profile_screen.dart';

// Mis colores para que el buscador pegue con el resto de la app.
const _bg        = Color(0xFF121212);
const _bgCard    = Color(0xFF1A1A1A);
const _bgSearch  = Color(0xFF1E1E1E);
const _border    = Color(0xFF2A2A2A);
const _yellow    = Color(0xFFFFB800);
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
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: _textSub),
        border: InputBorder.none,
      ),
    );
  }

  // El botón de la "X" para borrar lo que hayamos escrito y empezar de nuevo.
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

  // El botón de volver atrás, por si nos arrepentimos de buscar.
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _yellow, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _SearchBody(query: query);

  @override
  Widget buildSuggestions(BuildContext context) => _SearchBody(query: query);
}

// Aquí es donde ocurre la búsqueda real. He metido un "debounce" para no freír el servidor a peticiones mientras el usuario escribe.
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

  // Esperamos un poquito (400ms) después de que el usuario deje de escribir para lanzar la búsqueda.
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _yellow, strokeWidth: 2));
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)));
    }

    if (_results.isEmpty && widget.query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search_rounded, size: 64, color: _textMuted),
            const SizedBox(height: 16),
            Text('No se encontraron usuarios para "${widget.query}"', 
              style: const TextStyle(color: _textSub)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _results.length,
      itemBuilder: (context, index) => _UserCard(user: _results[index]),
    );
  }
}

// La tarjetita de cada usuario que encontramos. Tiene el botón para mandar la solicitud de amistad.
class _UserCard extends StatefulWidget {
  const _UserCard({required this.user});
  final UserSearchResult user;

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _isRequesting = false;
  String _friendStatus = 'none'; // 'none', 'pending', 'accepted', 'friends'

  @override
  void initState() {
    super.initState();
  }

  // Al pulsar el botón, mandamos la solicitud. Si el otro ya nos la había mandado, nos hacemos amigos directamente.
  Future<void> _handleFriendRequest() async {
    setState(() => _isRequesting = true);
    try {
      final status = await ApiService.sendFriendRequest(widget.user.id);
      if (mounted) {
        setState(() {
          _friendStatus = status;
          _isRequesting = false;
        });
        String msg = status == 'accepted' ? '¡Ahora sois amigos!' : 'Solicitud enviada';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: _bgCard,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequesting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: _bgSearch,
          backgroundImage: widget.user.avatarUrl != null ? NetworkImage(widget.user.avatarUrl!) : null,
          child: widget.user.avatarUrl == null
            ? const Icon(Icons.person_rounded, color: _yellow)
            : null,
        ),
        title: Text(widget.user.username, style: const TextStyle(color: _textMain, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Row(
          children: [
            const Icon(Icons.star_rounded, size: 14, color: _yellow),
            const SizedBox(width: 4),
            Text('${widget.user.karma} karma', style: const TextStyle(color: _textSub, fontSize: 12)),
          ],
        ),
        trailing: _isRequesting 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _yellow, strokeWidth: 2))
          : IconButton(
              icon: Icon(
                _friendStatus == 'accepted' || _friendStatus == 'friends' 
                  ? Icons.check_circle_rounded 
                  : _friendStatus == 'pending' 
                    ? Icons.pending_rounded 
                    : Icons.person_add_rounded,
                color: _friendStatus != 'none' ? _yellow : _textSub,
              ),
              onPressed: _handleFriendRequest,
            ),
        onTap: () {
          // Si tocamos en el usuario, nos lleva a ver su perfil público para ver a qué juega.
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => UserProfileScreen(user: User(
              id: widget.user.id,
              username: widget.user.username,
              avatarUrl: widget.user.avatarUrl,
              karma: widget.user.karma,
              // Campos mínimos para que UserProfileScreen no falle
              email: '',
              recentGames: [],
              recentGameCovers: [],
              isOnline: false,
            )),
          ));
        },
      ),
    );
  }
}
