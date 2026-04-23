// =============================================================================
// deals_prefs_service.dart — Bound2Game Flutter
// Servicio de persistencia para el motor de ofertas.
// TODO(backend): Sincronizar con servidor para persistir entre dispositivos.
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';
import '../models/deal_model.dart';

class DealsPrefService {
  DealsPrefService._(this._prefs);

  static DealsPrefService? _instance;
  final SharedPreferences _prefs;

  static const _kHiddenStores    = 'deals_hidden_stores';
  static const _kNotifPrefPrefix = 'deals_notif_free_';

  static Future<DealsPrefService> get instance async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = DealsPrefService._(prefs);
    return _instance!;
  }

  // ── Filtros de plataforma ─────────────────────────────────────────────────

  Set<DealStore> get hiddenStores {
    final raw = _prefs.getStringList(_kHiddenStores) ?? [];
    return raw
        .map((s) => DealStore.values.where((d) => d.name == s).firstOrNull)
        .whereType<DealStore>()
        .toSet();
  }

  bool isStoreVisible(DealStore store) => !hiddenStores.contains(store);

  Future<void> setStoreVisible(DealStore store, bool visible) async {
    final current = hiddenStores;
    if (visible) {
      current.remove(store);
    } else {
      current.add(store);
    }
    await _prefs.setStringList(
      _kHiddenStores,
      current.map((d) => d.name).toList(),
    );
  }

  // ── Notificaciones push ───────────────────────────────────────────────────

  bool isFreeGamesAlertEnabled(DealStore store) =>
      _prefs.getBool('$_kNotifPrefPrefix${store.name}') ?? true;

  Future<void> setFreeGamesAlert(DealStore store, bool enabled) async {
    await _prefs.setBool('$_kNotifPrefPrefix${store.name}', enabled);
    // TODO(backend): Notificar al servidor para actualizar suscripciones push.
  }

  DealNotificationPrefs get notificationPrefs => DealNotificationPrefs(
        freeGamesAlerts: {
          for (final store in DealStore.values)
            store: isFreeGamesAlertEnabled(store),
        },
      );

  Future<void> resetAll() async {
    await _prefs.remove(_kHiddenStores);
    for (final store in DealStore.values) {
      await _prefs.remove('$_kNotifPrefPrefix${store.name}');
    }
  }
}
