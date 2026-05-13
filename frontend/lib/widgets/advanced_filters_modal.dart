// Esta es la ventana de filtros avanzados. La uso tanto en la biblioteca como en el "Shake to Play" para elegir exactamente qué tipo de juego queremos buscar.
// He intentado que sea muy visual, con etiquetas de colores que peguen con cada plataforma.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';

const _kBg     = Color(0xFF1A1A1A);
const _kBgDeep = Color(0xFF131313);
const _kBorder = Color(0xFF2A2A2A);
const _kYellow = Color(0xFFFFB800);
const _kMuted  = Color(0xFF888888);
const _kSub    = Color(0xFF444444);

// Aquí guardamos todos los filtros que el usuario ha seleccionado: plataforma, género, cuánto dura el juego...
class LibraryFilters {
  const LibraryFilters({
    this.platforms       = const {},
    this.genres          = const {},
    this.statuses        = const {},
    this.durations       = const {},
    this.modalities      = const {},
    this.platformEnabled  = true,
    this.genreEnabled     = true,
    this.statusEnabled    = true,
    this.durationEnabled  = true,
    this.modalityEnabled  = true,
    this.priceEnabled     = true,
    this.maxPrice         = 100.0,
  });

  final Set<Platform>       platforms;
  final Set<String>          genres;
  final Set<GameStatus>      statuses;
  final Set<FilterDuration>  durations;
  final Set<FilterModality>  modalities;

  final bool platformEnabled;
  final bool genreEnabled;
  final bool statusEnabled;
  final bool durationEnabled;
  final bool modalityEnabled;
  final bool priceEnabled;
  final double maxPrice;

  LibraryFilters copyWith({
    Set<Platform>?       platforms, Set<String>? genres, Set<GameStatus>? statuses,
    Set<FilterDuration>? durations, Set<FilterModality>? modalities,
    bool? platformEnabled, bool? genreEnabled, bool? statusEnabled,
    bool? durationEnabled, bool? modalityEnabled, bool? priceEnabled, double? maxPrice,
  }) {
    return LibraryFilters(
      platforms: platforms ?? this.platforms, genres: genres ?? this.genres,
      statuses: statuses ?? this.statuses, durations: durations ?? this.durations,
      modalities: modalities ?? this.modalities, platformEnabled: platformEnabled ?? this.platformEnabled,
      genreEnabled: genreEnabled ?? this.genreEnabled, statusEnabled: statusEnabled ?? this.statusEnabled,
      durationEnabled: durationEnabled ?? this.durationEnabled, modalityEnabled: modalityEnabled ?? this.modalityEnabled,
      priceEnabled: priceEnabled ?? this.priceEnabled, maxPrice: maxPrice ?? this.maxPrice,
    );
  }

  // Este es el filtro de verdad. Coge la lista de juegos y va quitando los que no cumplen con lo que hemos marcado.
  List<Game> apply(List<Game> games) {
    return games.where((game) {
      if (platformEnabled && platforms.isNotEmpty && !platforms.contains(game.platform)) return false;
      if (genreEnabled && genres.isNotEmpty && !genres.any((g) => game.genre.toLowerCase().contains(g.toLowerCase()))) return false;
      if (statusEnabled && statuses.isNotEmpty && !statuses.contains(game.status)) return false;
      if (durationEnabled && durations.isNotEmpty && !durations.any((d) => d.matches(game.playtime))) return false;
      if (modalityEnabled && modalities.isNotEmpty) {
        final isMulti = game.playtime > 100 || game.genre.toLowerCase().contains('moba') || game.genre.toLowerCase().contains('sport');
        if (modalities.contains(FilterModality.multi) && !isMulti) return false;
        if (modalities.contains(FilterModality.single) && isMulti) return false;
      }
      if (priceEnabled && game.price > maxPrice) return false;
      return true;
    }).toList();
  }
}

// Rangos de duración para que el usuario elija si quiere algo rápido o un juego largo.
enum FilterDuration {
  short('< 10 horas', 0, 10),
  medium('10-40 horas', 10, 40),
  long('> 40 horas', 40, 99999);
  const FilterDuration(this.label, this.minH, this.maxH);
  final String label;
  final int minH, maxH;
  bool matches(int playtime) => playtime >= minH && playtime < maxH;
}

enum FilterModality { single('Single Player'), multi('Multijugador'); const FilterModality(this.label); final String label; }

// Una función rápida para abrir la ventanita de filtros desde cualquier parte de la app.
Future<LibraryFilters?> showAdvancedFilters({required BuildContext context, required LibraryFilters current, required List<String> availableGenres, bool showPriceFilter = false}) {
  return showModalBottomSheet<LibraryFilters>(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => AdvancedFiltersModal(current: current, availableGenres: availableGenres, showPriceFilter: showPriceFilter),
  );
}

class AdvancedFiltersModal extends StatefulWidget {
  const AdvancedFiltersModal({super.key, required this.current, required this.availableGenres, this.showPriceFilter = false});
  final LibraryFilters current;
  final List<String> availableGenres;
  final bool showPriceFilter;
  @override
  State<AdvancedFiltersModal> createState() => _AdvancedFiltersModalState();
}

class _AdvancedFiltersModalState extends State<AdvancedFiltersModal> {
  late LibraryFilters _filters;
  @override
  void initState() { super.initState(); _filters = widget.current; }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(color: _kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // El título y el botón de limpiar para volver a empezar.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.tune_rounded, color: _kYellow, size: 18),
              const SizedBox(width: 8),
              Text('Filtros avanzados', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              GestureDetector(onTap: () => setState(() => _filters = const LibraryFilters()), child: const Text('Limpiar', style: TextStyle(color: _kMuted, fontSize: 12))),
            ]),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Secciones de filtros: Plataforma, Género, Estado...
                _FilterCategory(title: 'Plataforma', enabled: _filters.platformEnabled, onToggleEnabled: () => setState(() => _filters = _filters.copyWith(platformEnabled: !_filters.platformEnabled)), child: Wrap(spacing: 8, runSpacing: 8, children: Platform.values.map((p) => _FilterChip(label: p.displayName, selected: _filters.platforms.contains(p), accentColor: p.color, enabled: _filters.platformEnabled, onTap: () { final up = Set<Platform>.from(_filters.platforms); up.contains(p) ? up.remove(p) : up.add(p); setState(() => _filters = _filters.copyWith(platforms: up)); })).toList())),
                const SizedBox(height: 20),
                _FilterCategory(title: 'Género', enabled: _filters.genreEnabled, onToggleEnabled: () => setState(() => _filters = _filters.copyWith(genreEnabled: !_filters.genreEnabled)), child: Wrap(spacing: 8, runSpacing: 8, children: widget.availableGenres.map((g) => _FilterChip(label: g, selected: _filters.genres.contains(g), accentColor: _kYellow, enabled: _filters.genreEnabled, onTap: () { final up = Set<String>.from(_filters.genres); up.contains(g) ? up.remove(g) : up.add(g); setState(() => _filters = _filters.copyWith(genres: up)); })).toList())),
                const SizedBox(height: 20),
                _FilterCategory(title: 'Estado', enabled: _filters.statusEnabled, onToggleEnabled: () => setState(() => _filters = _filters.copyWith(statusEnabled: !_filters.statusEnabled)), child: Wrap(spacing: 8, runSpacing: 8, children: GameStatus.values.map((s) => _FilterChip(label: s.label, selected: _filters.statuses.contains(s), accentColor: s.color, enabled: _filters.statusEnabled, onTap: () { final up = Set<GameStatus>.from(_filters.statuses); up.contains(s) ? up.remove(s) : up.add(s); setState(() => _filters = _filters.copyWith(statuses: up)); })).toList())),
                const SizedBox(height: 20),
                _FilterCategory(title: 'Duración', enabled: _filters.durationEnabled, onToggleEnabled: () => setState(() => _filters = _filters.copyWith(durationEnabled: !_filters.durationEnabled)), child: Wrap(spacing: 8, runSpacing: 8, children: FilterDuration.values.map((d) => _FilterChip(label: d.label, selected: _filters.durations.contains(d), accentColor: _kYellow, enabled: _filters.durationEnabled, onTap: () { final up = Set<FilterDuration>.from(_filters.durations); up.contains(d) ? up.remove(d) : up.add(d); setState(() => _filters = _filters.copyWith(durations: up)); })).toList())),
                const SizedBox(height: 20),
                _FilterCategory(title: 'Modalidad', enabled: _filters.modalityEnabled, onToggleEnabled: () => setState(() => _filters = _filters.copyWith(modalityEnabled: !_filters.modalityEnabled)), child: Wrap(spacing: 8, runSpacing: 8, children: FilterModality.values.map((m) => _FilterChip(label: m.label, selected: _filters.modalities.contains(m), accentColor: _kYellow, enabled: _filters.modalityEnabled, onTap: () { final up = Set<FilterModality>.from(_filters.modalities); up.contains(m) ? up.remove(m) : up.add(m); setState(() => _filters = _filters.copyWith(modalities: up)); })).toList())),
                if (widget.showPriceFilter) ...[
                  const SizedBox(height: 12),
                  _FilterCategory(
                    title: 'Precio Máximo',
                    enabled: _filters.priceEnabled,
                    onToggleEnabled: () => setState(() => _filters = _filters.copyWith(priceEnabled: !_filters.priceEnabled)),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('0€', style: GoogleFonts.inter(fontSize: 11, color: _kMuted)),
                        Text('${_filters.maxPrice.toInt()}€', style: GoogleFonts.inter(fontSize: 13, color: _kYellow, fontWeight: FontWeight.bold)),
                        const Text('100€', style: TextStyle(fontSize: 11, color: _kMuted)),
                      ]),
                      Slider(value: _filters.maxPrice, min: 0, max: 100, divisions: 20, activeColor: _kYellow, inactiveColor: _kBgDeep, onChanged: (v) => setState(() => _filters = _filters.copyWith(maxPrice: v, priceEnabled: true))),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
          // Botón final para aplicar todo y ver los resultados.
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(width: double.infinity, height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _kYellow, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.of(context).pop(_filters), child: const Text('Aplicar filtros', style: TextStyle(fontWeight: FontWeight.bold)))),
          ),
        ],
      ),
    );
  }
}

// Un pequeño componente para cada grupo de filtros. Lo guay es que puedes apagar una categoría entera.
class _FilterCategory extends StatelessWidget {
  const _FilterCategory({required this.title, required this.enabled, required this.onToggleEnabled, required this.child});
  final String title; final bool enabled; final VoidCallback onToggleEnabled; final Widget child;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(onTap: onToggleEnabled, child: Row(children: [
        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: enabled ? _kYellow : _kMuted, letterSpacing: 1.2)),
        const SizedBox(width: 8),
        Icon(enabled ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, color: enabled ? _kYellow : _kSub, size: 18),
      ])),
      const SizedBox(height: 10),
      AnimatedOpacity(duration: const Duration(milliseconds: 200), opacity: enabled ? 1.0 : 0.3, child: IgnorePointer(ignoring: !enabled, child: child)),
    ]);
  }
}

// Las etiquetas individuales que pulsas para seleccionar un filtro.
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.accentColor, required this.enabled, required this.onTap});
  final String label; final bool selected; final Color accentColor; final bool enabled; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: selected ? accentColor.withValues(alpha: 0.15) : _kBgDeep, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? accentColor.withValues(alpha: 0.55) : _kBorder, width: selected ? 1.5 : 1)),
        child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? accentColor : _kMuted)),
      ),
    );
  }
}
