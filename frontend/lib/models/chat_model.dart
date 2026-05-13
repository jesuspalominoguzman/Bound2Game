// Este es el modelo para los mensajes del chat. He incluido soporte para texto, emojis y GIFs de Giphy para que las conversaciones sean más divertidas.

enum MessageType { text, emoji, gif }

// Cada mensaje individual tiene su ID, su texto, quién lo mandó y a qué hora.
class ChatMessage {
  final String id;
  final String text;
  final bool isMe; // Para saber si el mensaje es nuestro o del otro y ponerlo a la derecha o izquierda.
  final DateTime timestamp;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.type = MessageType.text,
  });

  // Este método convierte lo que nos llega del servidor (por el socket) a nuestro formato de mensaje.
  factory ChatMessage.fromSocketData(dynamic data, String currentUserId) {
    final isMe = data['senderId'].toString() == currentUserId;
    final typeStr = data['messageType']?.toString() ?? 'text';
    
    MessageType type;
    if (typeStr == 'gif') {
      type = MessageType.gif;
    } else if (typeStr == 'emoji') {
      type = MessageType.emoji;
    } else {
      type = MessageType.text;
    }

    return ChatMessage(
      id: data['_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: data['content'] as String? ?? '',
      isMe: isMe,
      // Convertimos la hora a la hora local del móvil para que no salgan horas raras.
      timestamp: DateTime.tryParse(data['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      type: type,
    );
  }
}
