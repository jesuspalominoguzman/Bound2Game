// =============================================================================
// advanced_filters_modal.dart — Bound2Game Flutter (Android)
//
// Widget reutilizable para filtros avanzados de la biblioteca y el módulo
// "Shake to Play". Expuesto como función helper showAdvancedFilters() para
// abrir un bottom sheet modal.
//
// Categorías: Plataforma, Género, Estado, Duración, Modalidad.
//
// Lógica de "Deshabilitar Categoría":
//   Cada categoría tiene un bool 'enabled'. Al tocar el título de la categoría
//   esta se apaga (opacidad baja, valores no aplicados). Al volver a tocar,
//   se enciende. No existe la opción "Me da igual".
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';

// ── Paleta del tema definitivo ─────────────────────────────────────────────────
const _kBg     = Color(0xFF1A1A1A);
const _kBgDeep = Color(0xFF131313);
const _kBorder = Color(0xFF2A2A2A);
const _kYellow = Color(0xFFFFB800);
const _kWhite  = Color(0xFFFFFFFF);
const _kMuted  = Color(0xFF888888);
const _kSub    = Color(0xFF444444);

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE FILTROS
// ─────────────────────────────────────────────────────────────────────────────

/// Estado de filtros avanzados. Inmutable snapshot para comparar cambios.
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

  // Banderas de categoría activa
  final bool platformEnabled;
  final bool genreEnabled;
  final bool statusEnabled;
  final bool durationEnabled;
  final bool modalityEnabled;
  final bool priceEnabled;

  final double maxPrice;

  LibraryFilters copyWith({
    Set<Platform>?       platforms,
    Set<String>?          genres,
    Set<GameStatus>?      statuses,
    Set<FilterDuration>?  durations,
    Set<FilterModality>?  modalities,
    bool? platformEnabled,
    bool? genreEnabled,
    bool? statusEnabled,
    bool? durationEnabled,
    bool? modalityEnabled,
    bool? priceEnabled,
    double? maxPrice,
  }) {
    return LibraryFilters(
      platforms:        platforms        ?? this.platforms,
      genres:           genres           ?? this.genres,
      statuses:         statuses         ?? this.statuses,
      durations:        durations        ?? this.durations,
      modalities:       modalities       ?? this.modalities,
      platformEnabled:  platformEnabled  ?? this.platformEnabled,
      genreEnabled:     genreEnabled     ?? this.genreEnabled,
      statusEnabled:    statusEnabled    ?? this.statusEnabled,
      durationEnabled:  durationEnabled  ?? this.durationEnabled,
      modalityEnabled:  modalityEnabled  ?? this.modalityEnabled,
      priceEnabled:     priceEnabled     ?? this.priceEnabled,
      maxPrice:         maxPrice         ?? this.maxPrice,
    );
  }

  /// true si los filtros activos son todos vacíos (= sin filtro aplicado)
  bool get isEmpty =>
      (!platformEnabled || platforms.isEmpty) &&
      (!genreEnabled    || genres.isEmpty)    &&
      (!statusEnabled   || statuses.isEmpty)  &&
      (!durationEnabled || durations.isEmpty) &&
      (!modalityEnabled || modalities.isEmpty) &&
      (!priceEnabled);

  /// Filtra una lista de juegos según los filtros activos.
  List<Game> apply(List<Game> games) {
    return games.where((game) {
      if (platformEnabled && platforms.isNotEmpty &&
          !platforms.contains(game.platform)) { return false; }

      if (genreEnabled && genres.isNotEmpty &&
          !genres.any((g) => game.genre.toLowerCase().contains(g.toLowerCase()))) { return false; }

      if (statusEnabled && statuses.isNotEmpty &&
          !statuses.contains(game.status)) { return false; }

      if (durationEnabled && durations.isNotEmpty &&
          !durations.any((d) => d.matches(game.playtime))) { return false; }

      if (modalityEnabled && modalities.isNotEmpty) {
        // Heurística: juegos "en línea" tienen playtime > 100h o son MOBA/Sports
        final isMulti = game.playtime > 100 ||
            game.genre.toLowerCase().contains('moba') ||
            game.genre.toLowerCase().contains('sport');
        final wantsMulti  = modalities.contains(FilterModality.multi);
        final wantsSingle = modalities.contains(FilterModality.single);
        if (wantsMulti  && !isMulti)  { return false; }
        if (wantsSingle && isMulti)   { return false; }
      }

      if (priceEnabled && game.price > maxPrice) {
        return false;
      }

      return true;
    }).toList();
  }
}

// ── Enums auxiliares ──────────────────────────────────────────────────────────

/// Rangos de duración para filtrado.
enum FilterDuration {
  short('< 10 horas',   0,  10),
  medium('10\u201340 horas', 10,  40),
  long('> 40 horas',   40, 99999);

  const FilterDuration(this.label, this.minH, this.maxH);
  final String label;
  final int minH, maxH;
  bool matches(int playtime) => playtime >= minH && playtime < maxH;
}

/// Modalidad de juego para filtrado.
enum FilterModality {
  single('Single Player'),
  multi('Multijugador');

  const FilterModality(this.label);
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// FUNCIÓN HELPER — Abre el bottom sheet modal
// ─────────────────────────────────────────────────────────────────────────────

/// Abre el [AdvancedFiltersModal] como bottom sheet.
/// Devuelve los filtros seleccionados o null si el usuario cierra sin aplicar.
Future<LibraryFilters?> showAdvancedFilters({
  required BuildContext context,
  required LibraryFilters current,
  required List<String> availableGenres,
  bool showPriceFilter = false,
}) {
  return showModalBottomSheet<LibraryFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AdvancedFiltersModal(
      current: current,
      availableGenres: availableGenres,
      showPriceFilter: showPriceFilter,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────

class AdvancedFiltersModal extends StatefulWidget {
  const AdvancedFiltersModal({
    super.key,
    required this.current,
    required this.availableGenres,
    this.showPriceFilter = false,
  });

  final LibraryFilters current;
  final List<String> availableGenres;
  final bool showPriceFilter;

  @override
  State<AdvancedFiltersModal> createState() => _AdvancedFiltersModalState();
}

class _AdvancedFiltersModalState extends State<AdvancedFiltersModal> {
  late LibraryFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.current;
  }

  // ── Toggle helpers ────────────────────────────────────────────────────────

  void _togglePlatform(Platform p) {
    final updated = Set<Platform>.from(_filters.platforms);
    updated.contains(p) ? updated.remove(p) : updated.add(p);
    setState(() => _filters = _filters.copyWith(platforms: updated));
  }

  void _toggleGenre(String g) {
    final updated = Set<String>.from(_filters.genres);
    updated.contains(g) ? updated.remove(g) : updated.add(g);
    setState(() => _filters = _filters.copyWith(genres: updated));
  }

  void _toggleStatus(GameStatus s) {
    final updated = Set<GameStatus>.from(_filters.statuses);
    updated.contains(s) ? updated.remove(s) : updated.add(s);
    setState(() => _filters = _filters.copyWith(statuses: updated));
  }

  void _toggleDuration(FilterDuration d) {
    final updated = Set<FilterDuration>.from(_filters.durations);
    updated.contains(d) ? updated.remove(d) : updated.add(d);
    setState(() => _filters = _filters.copyWith(durations: updated));
  }

  void _toggleModality(FilterModality m) {
    final updated = Set<FilterModality>.from(_filters.modalities);
    updated.contains(m) ? updated.remove(m) : updated.add(m);
    setState(() => _filters = _filters.copyWith(modalities: updated));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.85),
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _kSub,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: _kYellow, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Filtros avanzados',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kWhite,
                  ),
                ),
                const Spacer(),
                // Botón limpiar todo
                GestureDetector(
                  onTap: () => setState(() => _filters = const LibraryFilters()),
                  child: Text(
                    'Limpiar',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _kMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: _kBorder),

          // ── Cuerpo scrollable ──────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Plataforma ─────────────────────────────────────────────
                  _FilterCategory(
                    title: 'Plataforma',
                    enabled: _filters.platformEnabled,
                    onToggleEnabled: () => setState(() => _filters = _filters.copyWith(
                        platformEnabled: !_filters.platformEnabled)),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: Platform.values.map((p) => _FilterChip(
                        label: p.displayName,
                        selected: _filters.platforms.contains(p),
                        accentColor: p.color,
                        enabled: _filters.platformEnabled,
                        onTap: () => _togglePlatform(p),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Género ─────────────────────────────────────────────────
                  _FilterCategory(
                    title: 'Género',
                    enabled: _filters.genreEnabled,
                    onToggleEnabled: () => setState(() => _filters = _filters.copyWith(
                        genreEnabled: !_filters.genreEnabled)),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: widget.availableGenres.map((g) => _FilterChip(
                        label: g,
                        selected: _filters.genres.contains(g),
                        accentColor: _kYellow,
                        enabled: _filters.genreEnabled,
                        onTap: () => _toggleGenre(g),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Estado ─────────────────────────────────────────────────
                  _FilterCategory(
                    title: 'Estado',
                    enabled: _filters.statusEnabled,
                    onToggleEnabled: () => setState(() => _filters = _filters.copyWith(
                        statusEnabled: !_filters.statusEnabled)),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: GameStatus.values.map((s) => _FilterChip(
                        label: s.label,
                        selected: _filters.statuses.contains(s),
                        accentColor: s.color,
                        enabled: _filters.statusEnabled,
                        onTap: () => _toggleStatus(s),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Duración ───────────────────────────────────────────────
                  _FilterCategory(
                    title: 'Duración',
                    enabled: _filters.durationEnabled,
                    onToggleEnabled: () => setState(() => _filters = _filters.copyWith(
                        durationEnabled: !_filters.durationEnabled)),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: FilterDuration.values.map((d) => _FilterChip(
                        label: d.label,
                        selected: _filters.durations.contains(d),
                        accentColor: _kYellow,
                        enabled: _filters.durationEnabled,
                        onTap: () => _toggleDuration(d),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Modalidad ──────────────────────────────────────────────
                  _FilterCategory(
                    title: 'Modalidad',
                    enabled: _filters.modalityEnabled,
                    onToggleEnabled: () => setState(() => _filters = _filters.copyWith(
                        modalityEnabled: !_filters.modalityEnabled)),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: FilterModality.values.map((m) => _FilterChip(
                        label: m.label,
                        selected: _filters.modalities.contains(m),
                        accentColor: _kYellow,
                        enabled: _filters.modalityEnabled,
                        onTap: () => _toggleModality(m),
                      )).toList(),
                    ),
                  ),

                  if (widget.showPriceFilter) ...[
                    const SizedBox(height: 12),
                    _FilterCategory(
                      title: 'Precio Máximo',
                      enabled: _filters.priceEnabled,
                      onToggleEnabled: () => setState(() =>
                          _filters = _filters.copyWith(
                              priceEnabled: !_filters.priceEnabled)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0€', style: GoogleFonts.inter(fontSize: 11, color: _kMuted)),
                                Text('${_filters.maxPrice.toInt()}€', style: GoogleFonts.inter(fontSize: 13, color: _kYellow, fontWeight: FontWeight.w700)),
                                Text('100€', style: GoogleFonts.inter(fontSize: 11, color: _kMuted)),
                              ],
                            ),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: _kYellow,
                                inactiveTrackColor: _kBgDeep,
                                thumbColor: _kYellow,
                                trackHeight: 4,
                                overlayColor: _kYellow.withValues(alpha: 0.2),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              ),
                              child: Slider(
                                value: _filters.maxPrice,
                                min: 0,
                                max: 100,
                                divisions: 20,
                                onChanged: (val) {
                                  setState(() {
                                    _filters = _filters.copyWith(maxPrice: val);
                                    if (!_filters.priceEnabled) {
                                      _filters = _filters.copyWith(priceEnabled: true);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Botón aplicar ──────────────────────────────────────────────────
          Container(
            color: _kBg,
            padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(_filters),
                child: Container(
                  decoration: BoxDecoration(
                    color: _kYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Aplicar filtros',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterCategory — Cabecera de categoría con toggle de habilitación
// ─────────────────────────────────────────────────────────────────────────────

class _FilterCategory extends StatelessWidget {
  const _FilterCategory({
    required this.title,
    required this.enabled,
    required this.onToggleEnabled,
    required this.child,
  });

  final String title;
  final bool enabled;
  final VoidCallback onToggleEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título interactivo — tap para encender/apagar categoría
        GestureDetector(
          onTap: onToggleEnabled,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: enabled ? 1.0 : 0.4,
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: enabled ? _kYellow : _kMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: enabled ? 1.0 : 0.4,
                  child: Icon(
                    enabled
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_rounded,
                    color: enabled ? _kYellow : _kSub,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Chips con opacidad según estado de categoría
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.3,
          child: IgnorePointer(
            ignoring: !enabled,
            child: child,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterChip — Chip individual de selección
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.15)
              : _kBgDeep,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: 0.55)
                : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accentColor : _kMuted,
          ),
        ),
      ),
    );
  }
}
