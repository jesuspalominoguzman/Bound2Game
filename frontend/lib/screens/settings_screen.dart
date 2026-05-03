// =============================================================================
// settings_screen.dart — Bound2Game Flutter
// Pantalla de Ajustes con sección de notificaciones de ofertas y filtros.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/deal_model.dart';
import '../services/deals_prefs_service.dart';

const _bg      = Color(0xFF101010);
const _bgCard  = Color(0xFF181818);
const _bgCard2 = Color(0xFF1C1C1C);
const _border  = Color(0xFF252525);
const _textMain  = Color(0xFFD1D1D1);
const _textMuted = Color(0xFF555555);
const _textSub   = Color(0xFF888888);
const _cyan    = Color(0xFF00E5FF);
const _green   = Color(0xFF4AF626);
const _yellow  = Color(0xFFFFB800);
const _purple  = Color(0xFF7B61FF);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DealsPrefService? _svc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DealsPrefService.instance.then((s) {
      if (mounted) setState(() { _svc = s; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _cyan)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sección: Notificaciones de Ofertas ─────────────────
                  _SectionLabel(
                    icon: Icons.notifications_active_rounded,
                    iconColor: _yellow,
                    title: 'Notificaciones de Juegos Gratuitos',
                    subtitle: 'Activa alertas por tienda',
                  ),
                  const SizedBox(height: 8),
                  _NotifTogglesCard(svc: _svc!, onChanged: () => setState(() {})),

                  const SizedBox(height: 24),

                  // ── Sección: Tiendas Visibles ──────────────────────────
                  _SectionLabel(
                    icon: Icons.storefront_rounded,
                    iconColor: _cyan,
                    title: 'Tiendas Visibles en Ofertas',
                    subtitle: 'Oculta las plataformas que no uses',
                  ),
                  const SizedBox(height: 8),
                  _StoreVisibilityCard(svc: _svc!, onChanged: () => setState(() {})),

                  const SizedBox(height: 24),

                  // ── Sección: General (placeholder) ────────────────────
                  _SectionLabel(
                    icon: Icons.tune_rounded,
                    iconColor: _purple,
                    title: 'General',
                    subtitle: 'Opciones de la aplicación',
                  ),
                  const SizedBox(height: 8),
                  _GeneralCard(),
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
// _SectionLabel
// =============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _textMain),
            ),
            Text(subtitle,
                style: const TextStyle(fontSize: 10, color: _textMuted)),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// _NotifTogglesCard — Toggles de notificación por tienda
// =============================================================================

class _NotifTogglesCard extends StatelessWidget {
  const _NotifTogglesCard({required this.svc, required this.onChanged});
  final DealsPrefService svc;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: DealStore.values.map((store) {
          final cfg = store.config;
          final enabled = svc.isFreeGamesAlertEnabled(store);
          final isLast = store == DealStore.values.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: cfg.background,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(cfg.icon, size: 13, color: cfg.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cfg.name,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textMain),
                      ),
                    ),
                    Switch(
                      value: enabled,
                      onChanged: (v) async {
                        await svc.setFreeGamesAlert(store, v);
                        onChanged();
                      },
                      activeThumbColor: cfg.color,
                      activeTrackColor: cfg.color.withValues(alpha: 0.25),
                      inactiveThumbColor: _textMuted,
                      inactiveTrackColor: _border,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 14)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// _StoreVisibilityCard — Visibilidad de tiendas en la pantalla de Ofertas
// =============================================================================

class _StoreVisibilityCard extends StatelessWidget {
  const _StoreVisibilityCard({required this.svc, required this.onChanged});
  final DealsPrefService svc;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: DealStore.values.map((store) {
          final cfg = store.config;
          final visible = svc.isStoreVisible(store);
          final isLast = store == DealStore.values.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: visible ? cfg.background : _bgCard2,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        cfg.icon,
                        size: 13,
                        color: visible ? cfg.color : _textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cfg.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: visible ? _textMain : _textMuted,
                            ),
                          ),
                          Text(
                            visible ? 'Visible en Ofertas' : 'Oculta',
                            style: TextStyle(
                              fontSize: 10,
                              color: visible ? _green : _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: visible,
                      onChanged: (v) async {
                        await svc.setStoreVisible(store, v);
                        onChanged();
                      },
                      activeThumbColor: cfg.color,
                      activeTrackColor: cfg.color.withValues(alpha: 0.25),
                      inactiveThumbColor: _textMuted,
                      inactiveTrackColor: _border,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 14)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// _GeneralCard — Opciones generales (placeholder para futuras opciones)
// =============================================================================

class _GeneralCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dark_mode_rounded, _purple, 'Tema', 'Oscuro'),
      (Icons.language_rounded, _cyan, 'Idioma', 'Español'),
      (Icons.info_outline_rounded, _textSub, 'Versión', '1.0.0'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: item.$2.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(item.$1, size: 13, color: item.$2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.$3,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textMain),
                      ),
                    ),
                    Text(item.$4,
                        style: const TextStyle(fontSize: 11, color: _textSub)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 14, color: _textMuted),
                  ],
                ),
              ),
              if (!isLast)
                Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 14)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
