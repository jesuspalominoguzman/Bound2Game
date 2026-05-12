// =============================================================================
// presence_service.dart — Bound2Game Flutter
//
// Servicio singleton que gestiona el estado de presencia del usuario en tiempo
// real a través del namespace /chat de Socket.io.
//
// Flujo:
//   • App pasa a resumed  → connect() + emit('userConnected', { userId })
//   • App pasa a paused/detached → emit('userDisconnected') + disconnect()
//
// El servidor actualiza User.isOnline en MongoDB al recibir cada evento y
// también lo pone a false automáticamente en el evento 'disconnect' del socket.
// =============================================================================

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'api_service.dart';

class PresenceService {
  // ── Singleton ────────────────────────────────────────────────────────────
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  sio.Socket? _socket;
  String? _userId;
  bool _isConnected = false;

  // Stream para emitir los eventos de presencia a la UI
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get presenceUpdates => _presenceController.stream;

  // ── Inicializar con el ID del usuario autenticado ────────────────────────
  void init(String userId) {
    _userId = userId;
  }

  // ── Conectar al socket y notificar presencia ──────────────────────────────
  void connect() {
    if (_userId == null || _isConnected) return;

    _socket = sio.io(
      '${ApiService.baseUrl}/chat',
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('🟢 [PresenceService] Socket conectado');
      _socket!.emit('userConnected', {'userId': _userId});
    });

    // Redirigir evento de presencia al Stream global
    _socket!.on('presenceUpdate', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _presenceController.add(data);
      } else if (data != null) {
        // En caso de que venga como un map dinámico genérico
        _presenceController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('🔴 [PresenceService] Socket desconectado');
    });

    _socket!.onError((err) {
      debugPrint('🔴 [PresenceService] Error: $err');
    });



    _socket!.connect();
  }

  // ── Desconectar (app va a segundo plano / se cierra) ─────────────────────
  void disconnect() {
    if (_socket != null && _isConnected) {
      // El servidor detectará el disconnect y pondrá isOnline = false
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      debugPrint('🔴 [PresenceService] Desconectado manualmente');
    }
  }

  // ── Limpiar (logout) ─────────────────────────────────────────────────────
  void clear() {
    disconnect();
    _userId = null;
  }

  void dispose() {
    _presenceController.close();
  }
}
