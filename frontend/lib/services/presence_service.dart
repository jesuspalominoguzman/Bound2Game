// Este servicio se encarga de decir al servidor si estamos conectados o no. 
// Así nuestros amigos pueden ver el punto verde en su lista y saber que podemos chatear o echar una partida.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'api_service.dart';

class PresenceService {
  // Lo hacemos Singleton para que solo haya una instancia controlando nuestra presencia.
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  sio.Socket? _socket;
  String? _userId;
  bool _isConnected = false;

  // Este es el chorro de datos que manda las actualizaciones de quién se conecta y quién se desconecta a toda la app.
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get presenceUpdates => _presenceController.stream;

  final _friendRequestController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get friendRequestUpdates => _friendRequestController.stream;

  // Guardamos el ID del usuario cuando hace login.
  void init(String userId) {
    _userId = userId;
  }

  // Nos conectamos al servidor y le gritamos: "¡Eh, que ya estoy aquí!" mandándole nuestro ID.
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
      debugPrint('🟢 Presence: Ya estamos en línea');
      _socket!.emit('userConnected', {'userId': _userId});
    });

    // Escuchamos cuando alguien cambia su estado para avisar a la pantalla social y que se actualicen los puntos verdes.
    _socket!.on('presenceUpdate', (data) {
      if (data != null && data is Map<String, dynamic>) {
        _presenceController.add(data);
      } else if (data != null) {
        _presenceController.add(Map<String, dynamic>.from(data));
      }
    });

    // Escuchamos nuevas solicitudes de amistad o aceptaciones
    _socket!.on('friendRequest', (data) {
      debugPrint('🔔 Presence: Notificación de amistad recibida: $data');
      if (data != null && data is Map<String, dynamic>) {
        _friendRequestController.add(data);
      } else if (data != null) {
        _friendRequestController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('🔴 Presence: Nos hemos desconectado');
    });

    _socket!.onError((err) {
      debugPrint('🔴 Presence Error: $err');
    });

    _socket!.connect();
  }

  // Cuando cerramos la app o la dejamos en segundo plano, le decimos al servidor que nos vamos.
  void disconnect() {
    if (_socket != null && _isConnected) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      debugPrint('🔴 Presence: Desconexión manual');
    }
  }

  // Para cuando el usuario cierra sesión, que no se quede su ID por ahí guardado.
  void clear() {
    disconnect();
    _userId = null;
  }

  void dispose() {
    _presenceController.close();
    _friendRequestController.close();
  }
}
