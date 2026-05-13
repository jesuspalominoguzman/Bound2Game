// Esta es la pantalla de Ajustes. Aquí es donde el usuario puede configurar su perfil, meter las piezas de su PC y decidir qué tiendas quiere ver.
// He intentado que sea muy modular para que sea fácil añadir más opciones en el futuro.

import 'package:flutter/material.dart';
import '../models/deal_model.dart';
import '../services/deals_prefs_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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
const _red     = Color(0xFFFF4040);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DealsPrefService? _svc;
  bool _loading = true;

  final _cpuCtrl = TextEditingController();
  final _gpuCtrl = TextEditingController();
  final _ramCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();

  final _steamCtrl = TextEditingController();
  final _epicCtrl = TextEditingController();
  final _xboxCtrl = TextEditingController();
  final _discordCtrl = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Al cargar la pantalla, nos traemos los datos del perfil y las preferencias de las tiendas.
    DealsPrefService.instance.then((s) {
      if (mounted) setState(() { _svc = s; _loading = false; });
    });
    ApiService.fetchMyProfile().then((user) {
      if (mounted) {
        final pc = user.pcComponents;
        _cpuCtrl.text = pc['cpu']?.toString() ?? '';
        _gpuCtrl.text = pc['gpu']?.toString() ?? '';
        _ramCtrl.text = pc['ram']?.toString() ?? '';
        _storageCtrl.text = pc['storage']?.toString() ?? '';

        _steamCtrl.text = user.steamId ?? '';
        _epicCtrl.text = user.epicId ?? '';
        _xboxCtrl.text = user.xboxId ?? '';
        _discordCtrl.text = user.discordId ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _cyan)));
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.white)),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Elegir qué tiendas quieres ver en la pantalla de ofertas.
                  _SectionLabel(icon: Icons.storefront_rounded, iconColor: _cyan, title: 'Tiendas Visibles', subtitle: 'Oculta las plataformas que no uses'),
                  const SizedBox(height: 8),
                  _StoreVisibilityCard(svc: _svc!, onChanged: () => setState(() {})),

                  const SizedBox(height: 24),

                  // Las piezas de tu PC para que la app sepa si te van los juegos.
                  _SectionLabel(icon: Icons.computer_rounded, iconColor: _green, title: 'Especificaciones de tu PC', subtitle: 'Usado para calcular compatibilidad'),
                  const SizedBox(height: 8),
                  _PcComponentsCard(cpuCtrl: _cpuCtrl, gpuCtrl: _gpuCtrl, ramCtrl: _ramCtrl, storageCtrl: _storageCtrl),

                  const SizedBox(height: 24),

                  // Tus IDs de Steam, Epic, etc. para el perfil.
                  _SectionLabel(icon: Icons.videogame_asset_rounded, iconColor: Colors.blueAccent, title: 'Plataformas Vinculadas', subtitle: 'Tus perfiles públicos'),
                  const SizedBox(height: 8),
                  _PlatformsCard(steamCtrl: _steamCtrl, epicCtrl: _epicCtrl, xboxCtrl: _xboxCtrl, discordCtrl: _discordCtrl),

                  const SizedBox(height: 24),

                  _SectionLabel(icon: Icons.tune_rounded, iconColor: _purple, title: 'General', subtitle: 'Opciones de la aplicación'),
                  const SizedBox(height: 8),
                  _GeneralCard(),

                  const SizedBox(height: 32),

                  // Por si quieres salir de la cuenta.
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () async {
                        await AuthService.clearSession();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                        }
                      },
                      child: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Un pequeño componente para poner los títulos de cada sección.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.iconColor, required this.title, required this.subtitle});
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: iconColor)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMain)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: _textMuted)),
        ]),
      ],
    );
  }
}

// Aquí es donde el usuario elige qué tiendas quiere ver.
class _StoreVisibilityCard extends StatelessWidget {
  const _StoreVisibilityCard({required this.svc, required this.onChanged});
  final DealsPrefService svc;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Column(
        children: DealStore.values.map((store) {
          final cfg = store.config;
          final visible = svc.isStoreVisible(store);
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: visible ? cfg.background : _bgCard2, borderRadius: BorderRadius.circular(7)), child: Icon(cfg.icon, size: 13, color: visible ? cfg.color : _textMuted)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cfg.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: visible ? _textMain : _textMuted)),
                  Text(visible ? 'Visible' : 'Oculta', style: TextStyle(fontSize: 10, color: visible ? _green : _textMuted)),
                ])),
                Switch(value: visible, onChanged: (v) async { await svc.setStoreVisible(store, v); onChanged(); }, activeThumbColor: cfg.color),
              ]),
            ),
            if (store != DealStore.values.last) Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 14)),
          ]);
        }).toList(),
      ),
    );
  }
}

// Opciones generales de la app.
class _GeneralCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dark_mode_rounded, _purple, 'Tema', 'Oscuro'),
      (Icons.language_rounded, _cyan, 'Idioma', 'Español'),
      (Icons.info_outline_rounded, _textSub, 'Versión', '1.0.0'),
    ];
    return Container(
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Column(children: items.asMap().entries.map((e) {
        final item = e.value;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: item.$2.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)), child: Icon(item.$1, size: 13, color: item.$2)),
              const SizedBox(width: 10),
              Expanded(child: Text(item.$3, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMain))),
              Text(item.$4, style: const TextStyle(fontSize: 11, color: _textSub)),
              const Icon(Icons.chevron_right_rounded, size: 14, color: _textMuted),
            ]),
          ),
          if (e.key != items.length - 1) Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 14)),
        ]);
      }).toList()),
    );
  }
}

// El formulario para actualizar las piezas del PC.
class _PcComponentsCard extends StatefulWidget {
  const _PcComponentsCard({required this.cpuCtrl, required this.gpuCtrl, required this.ramCtrl, required this.storageCtrl});
  final TextEditingController cpuCtrl, gpuCtrl, ramCtrl, storageCtrl;
  @override
  State<_PcComponentsCard> createState() => _PcComponentsCardState();
}

class _PcComponentsCardState extends State<_PcComponentsCard> {
  bool _saving = false;
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.updatePcComponents(cpu: widget.cpuCtrl.text.trim(), gpu: widget.gpuCtrl.text.trim(), ram: double.tryParse(widget.ramCtrl.text.trim()), storage: widget.storageCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Guardado!', style: TextStyle(color: _green))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _TextFieldRow(label: 'CPU', ctrl: widget.cpuCtrl, hint: 'Ej. i7-13700K'),
        const SizedBox(height: 12),
        _TextFieldRow(label: 'GPU', ctrl: widget.gpuCtrl, hint: 'Ej. RTX 4070'),
        const SizedBox(height: 12),
        _TextFieldRow(label: 'RAM (GB)', ctrl: widget.ramCtrl, hint: 'Ej. 32', keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _TextFieldRow(label: 'Disco', ctrl: widget.storageCtrl, hint: 'Ej. 1TB NVMe'),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 42, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _yellow, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text('Guardar Especificaciones', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)))),
      ]),
    );
  }
}

// Para vincular las cuentas de redes sociales y juegos.
class _PlatformsCard extends StatefulWidget {
  const _PlatformsCard({required this.steamCtrl, required this.epicCtrl, required this.xboxCtrl, required this.discordCtrl});
  final TextEditingController steamCtrl, epicCtrl, xboxCtrl, discordCtrl;
  @override
  State<_PlatformsCard> createState() => _PlatformsCardState();
}

class _PlatformsCardState extends State<_PlatformsCard> {
  bool _saving = false;
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.updatePlatforms(steamId: widget.steamCtrl.text.trim(), epicId: widget.epicCtrl.text.trim(), xboxId: widget.xboxCtrl.text.trim(), discordId: widget.discordCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Plataformas actualizadas!', style: TextStyle(color: _green))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _TextFieldRow(label: 'Steam', ctrl: widget.steamCtrl, hint: 'ID de Steam'),
        const SizedBox(height: 12),
        _TextFieldRow(label: 'Epic', ctrl: widget.epicCtrl, hint: 'ID de Epic'),
        const SizedBox(height: 12),
        _TextFieldRow(label: 'Xbox', ctrl: widget.xboxCtrl, hint: 'Gamertag'),
        const SizedBox(height: 12),
        _TextFieldRow(label: 'Discord', ctrl: widget.discordCtrl, hint: 'Usuario'),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 42, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Guardar Plataformas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)))),
      ]),
    );
  }
}

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({required this.label, required this.ctrl, required this.hint, this.keyboardType});
  final String label, hint;
  final TextEditingController ctrl;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(color: _textMain, fontSize: 13, fontWeight: FontWeight.w600))),
      Expanded(child: TextField(controller: ctrl, keyboardType: keyboardType, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: _textMuted), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: _bgCard2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))),
    ]);
  }
}
