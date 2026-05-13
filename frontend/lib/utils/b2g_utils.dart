// Aquí tengo guardadas unas cuantas utilidades que uso en varias partes de la app para no repetir código.
// Son cosas básicas como formatear fechas o abrir enlaces en el navegador.

import 'package:url_launcher/url_launcher.dart';

class B2GUtils {
  // Formatea la hora para que salga bonita, tipo 14:30.
  static String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Esto es para que en el chat salga "Hoy" o "Ayer" en vez de la fecha completa si es reciente.
  static String formatDateBadge(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hoy';
    if (d == today.subtract(const Duration(days: 1))) return 'Ayer';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Un pequeño truco para crear un ID único para la sala de chat entre dos personas.
  // Ordenamos los IDs para que el resultado sea siempre el mismo sea quien sea el que mande el mensaje.
  static String buildRoomId(String id1, String id2) {
    return (id1.compareTo(id2) <= 0) ? '${id1}_$id2' : '${id2}_$id1';
  }

  // Para abrir enlaces de ofertas o perfiles directamente en el navegador del móvil.
  static Future<void> launchExternalUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
