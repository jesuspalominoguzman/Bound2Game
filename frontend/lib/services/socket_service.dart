// =============================================================================
// socket_service.dart — Bound2Game Flutter
//
// Servicio Singleton para gestionar la conexión WebSocket con el backend.
// Utiliza el paquete `socket_io_client` apuntando al namespace `/chat`.
//
// Dependencia requerida en pubspec.yaml:
//   socket_io_client: ^2.0.3+1
//
// IP Docker Android Emulator: 10.0.2.2 (equivale a 127.0.0.1 del host)
// =============================================================================

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // ── Singleton ───────────────────────────────────────────────────────────────
  SocketService._internal();
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  // ── Estado interno ──────────────────────────────────────────────────────────
  IO.Socket? _socket;

  /// Devuelve `true` si el socket existe y está conectado al servidor.
  bool get isConnected => _socket?.connected ?? false;

  // ── Conexión ────────────────────────────────────────────────────────────────

  /// Conecta al namespace `/chat` y une al usuario a la [roomId] indicada.
  ///
  /// Llama a este método al abrir [ChatScreen]. Si ya hay una conexión activa
  /// reutiliza el socket y solo emite `joinRoom`.
  void connect(String roomId) {
    // Reutilizar socket si ya está conectado (Singleton garantiza unicidad)
    if (_socket != null && _socket!.connected) {
      _joinRoom(roomId);
      return;
    }

    _socket = IO.io(
      'http://10.0.2.2:3000/chat', // Namespace /chat del backend
      IO.OptionBuilder()
          .setTransports(['websocket'])       // Fuerza WebSocket puro (sin polling)
          .disableAutoConnect()               // Controlamos la conexión manualmente
          .setReconnectionAttempts(5)         // Reintentos ante caída de red
          .setReconnectionDelay(2000)         // 2s entre reintentos
          .build(),
    );

    // ── Listeners de ciclo de vida ──────────────────────────────────────────
    _socket!.onConnect((_) {
      print('🟢 [SocketService] Conectado al namespace /chat');
      _joinRoom(roomId);
    });

    _socket!.onDisconnect((_) {
      print('🔴 [SocketService] Desconectado del servidor');
    });

    _socket!.onConnectError((err) {
      print('🔴 [SocketService] Error de conexión: $err');
    });

    _socket!.connect();
  }

  /// Envía el evento `joinRoom` al servidor para suscribirse a la sala.
  void _joinRoom(String roomId) {
    _socket?.emit('joinRoom', {'roomId': roomId});
    print('📥 [SocketService] joinRoom → $roomId');
  }

  // ── Envío de mensajes ───────────────────────────────────────────────────────

  /// Emite un mensaje al servidor bajo el evento `sendMessage`.
  ///
  /// - [roomId]   : ID único de la sala (ej. "userId1_userId2" ordenado).
  /// - [userId]   : MongoDB ObjectId del usuario autenticado.
  /// - [content]  : Texto del mensaje o URL del GIF de Giphy.
  /// - [type]     : `'text'` o `'gif'`.
  void sendMessage({
    required String roomId,
    required String userId,
    required String content,
    required String type,
  }) {
    if (!isConnected) {
      print('⚠️ [SocketService] sendMessage ignorado: socket no conectado');
      return;
    }

    _socket!.emit('sendMessage', {
      'roomId': roomId,
      'senderId': userId,
      'content': content,
      'messageType': type,
    });
  }

  // ── Escucha de eventos ──────────────────────────────────────────────────────

  /// Registra un callback para recibir nuevos mensajes en tiempo real.
  ///
  /// Úsalo en `initState` de [ChatScreen]:
  /// ```dart
  /// SocketService().onNewMessage((data) {
  ///   setState(() => _messages.insert(0, _fromJson(data)));
  /// });
  /// ```
  void onNewMessage(void Function(dynamic data) callback) {
    _socket?.on('newMessage', callback);
  }

  /// Registra un callback para recibir el historial inicial de mensajes.
  void onChatHistory(void Function(dynamic data) callback) {
    _socket?.on('chatHistory', callback);
  }

  /// Registra un callback para errores emitidos por el servidor.
  void onError(void Function(dynamic data) callback) {
    _socket?.on('chatError', callback);
  }

  // ── Desconexión ─────────────────────────────────────────────────────────────

  /// Desconecta el socket y libera recursos.
  ///
  /// Llama a este método en `dispose()` de [ChatScreen].
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    print('🔌 [SocketService] Socket desconectado y liberado');
  }
}
