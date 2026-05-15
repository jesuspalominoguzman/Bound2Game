import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AvatarPickerSheet extends StatefulWidget {
  final Function(String?) onSelected;
  const AvatarPickerSheet({super.key, required this.onSelected});

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _avatars = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    setState(() => _isLoading = true);
    try {
      // Filtramos por los juegos mejor valorados de los últimos 2 años (2023-2024)
      // Esto nos garantiza artes conceptuales de alta calidad de juegos actuales
      final uri = Uri.parse('https://api.rawg.io/api/games?key=${ApiService.rawgKey}&ordering=-metacritic&dates=2023-01-01,2024-12-31&page_size=21');
      
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final results = data['results'] as List? ?? [];
        setState(() {
          _avatars = results
              .map((g) => g['background_image']?.toString())
              .where((url) => url != null && url.isNotEmpty)
              .cast<String>()
              .toList();
        });
      }
    } catch (e) {
      print('Error cargando avatares premium: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFFFB800);
    const bg = Color(0xFF1A1A1A);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Tirador superior (Handle)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 50, height: 5,
            decoration: BoxDecoration(
              color: Colors.white24, 
              borderRadius: BorderRadius.circular(10)
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Elige tu Avatar', 
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    Text('Personajes icónicos del gaming', 
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    widget.onSelected(null);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Eliminar', 
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Grid de avatares con efectos
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: yellow))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _avatars.length,
                  itemBuilder: (ctx, i) {
                      return GestureDetector(
                        onTap: () {
                          widget.onSelected(_avatars[i]);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.05), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              _avatars[i],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.white.withOpacity(0.05),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white10)
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.white10),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
