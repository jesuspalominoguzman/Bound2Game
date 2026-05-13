// Este archivo es el que hace que el chat funcione en tiempo real.
// Usamos WebSockets para que los mensajes lleguen al instante, como en WhatsApp, sin tener que estar refrescando la pantalla cada dos por tres.

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'api_service.dart';

class SocketService {
  // Lo hacemos Singleton para que solo haya una conexión abierta en toda la app y no volvamos loco al servidor.
  SocketService._internal();
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  socket_io.Socket? _socket;

  // Una forma rápida de saber si estamos conectados o si la conexión se ha caído.
  bool get isConnected => _socket?.connected ?? false;

  // Nos conectamos a la "sala" de chat. Si ya estábamos conectados, simplemente nos unimos a la sala que toca.
  void connect(String roomId) {
    if (_socket != null && _socket!.connected) {
      _joinRoom(roomId);
      return;
    }

    _socket = socket_io.io(
      '${ApiService.baseUrl}/chat', 
      socket_io.OptionBuilder()
          .setTransports(['websocket'])       // Usamos solo websockets, que es más rápido.
          .disableAutoConnect()               
          .setReconnectionAttempts(5)         
          .setReconnectionDelay(2000)         
          .build(),
    );

    // Controlamos los eventos de la conexión para saber qué está pasando.
    _socket!.onConnect((_) {
      debugPrint('🟢 Conectado al chat');
      _joinRoom(roomId);
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔴 Desconectado del chat');
    });

    _socket!.onConnectError((err) {
      debugPrint('🔴 Error al intentar conectar: $err');
    });

    _socket!.connect();
  }

  // Le decimos al servidor en qué sala queremos estar para recibir solo los mensajes de esa conversación.
  void _joinRoom(String roomId) {
    _socket?.emit('joinRoom', {'roomId': roomId});
  }

  // Mandamos un mensaje (texto o GIF) al servidor para que se lo pase al otro usuario.
  void sendMessage({
    required String roomId,
    required String userId,
    required String content,
    required String type,
  }) {
    if (!isConnected) {
      debugPrint('⚠️ No se puede mandar el mensaje porque no hay conexión');
      return;
    }

    _socket!.emit('sendMessage', {
      'roomId': roomId,
      'senderId': userId,
      'content': content,
      'messageType': type,
    });
  }

  // Aquí es donde nos quedamos escuchando por si llega un mensaje nuevo para pintarlo en la pantalla.
  void onNewMessage(void Function(dynamic data) callback) {
    _socket?.on('newMessage', callback);
  }

  // Para cargar los mensajes antiguos cuando entramos en el chat.
  void onChatHistory(void Function(dynamic data) callback) {
    _socket?.on('chatHistory', callback);
  }

  // Por si el servidor nos manda algún error relacionado con el chat.
  void onError(void Function(dynamic data) callback) {
    _socket?.on('chatError', callback);
  }

  // Al salir del chat, cerramos la conexión para no gastar batería ni datos innecesariamente.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('🔌 Conexión de socket cerrada');
  }
}
