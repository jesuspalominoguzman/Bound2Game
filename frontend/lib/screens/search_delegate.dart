// =============================================================================
// search_delegate.dart — Bound2Game Flutter
//
// Búsqueda global a pantalla completa.
// Implementa SearchDelegate con estética oscura (Dark Mode).
// =============================================================================

import 'package:flutter/material.dart';
import '../models/game_model.dart';
import 'game_detail_screen.dart';

const _bg       = Color(0xFF101010);
const _bgCard   = Color(0xFF181818);
const _textMain = Color(0xFFD1D1D1);
const _textSub  = Color(0xFF888888);
const _cyan     = Color(0xFF00E5FF);

class B2GSearchDelegate extends SearchDelegate<String> {
  // Sobrescribe el tema para usar colores oscuros
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF151515),
        elevation: 0,
        iconTheme: IconThemeData(color: _textMain),
      ),
      scaffoldBackgroundColor: _bg,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: _textSub),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: _textMain, fontSize: 16),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _cyan,
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Buscar juegos, usuarios...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded, color: _textSub),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: _textMain),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Para simplificar, mostramos lo mismo que en sugerencias si apreta Enter
    return _buildSuggestionsOrResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestionsOrResults(context);
  }

  Widget _buildSuggestionsOrResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Escribe algo para buscar',
          style: TextStyle(color: _textSub, fontSize: 14),
        ),
      );
    }

    final lowerQuery = query.toLowerCase();
    
    // Filtramos localmente (simulado)
    final results = sampleGames.where((g) => 
      g.title.toLowerCase().contains(lowerQuery) || 
      g.genre.toLowerCase().contains(lowerQuery)
    ).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: _textSub),
            const SizedBox(height: 16),
            Text('No se encontraron resultados para "$query"',
              style: const TextStyle(color: _textSub),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final game = results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Image.network(
                game.cover,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Container(color: _bgCard, child: const Icon(Icons.videogame_asset, color: _textSub)),
              ),
            ),
          ),
          title: Text(
            game.title,
            style: const TextStyle(color: _textMain, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            game.genre,
            style: const TextStyle(color: _textSub, fontSize: 12),
          ),
          onTap: () {
            // Cierra el buscador y navega
            close(context, game.title);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
            );
          },
        );
      },
    );
  }
}
