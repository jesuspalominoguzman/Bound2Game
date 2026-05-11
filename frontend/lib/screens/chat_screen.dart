// =============================================================================
// chat_screen.dart — Bound2Game Flutter
//
// Chat efímero 1 a 1 entre dos jugadores.
// Características:
//   · Mensajes con timestamp, ListView.reversed para orden natural
//   · Aviso de "chat efímero" con banner discreto al inicio
//   · Campo de texto con acciones: Texto, Emoji picker, GIF (placeholder)
//   · Burbujas neón cian (propio) / oscuras (del otro)
//   · TODO(backend): Conectar a WebSocket + almacenamiento temporal 24h
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giphy_get/giphy_get.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import 'user_profile_screen.dart';

// TODO: Mueve esta clave a una variable de entorno o a flutter_dotenv.
// Obtén tu API Key gratuita en https://developers.giphy.com/
const _kGiphyApiKey = 'BSgmdKZuDX7iOouqo0eDnQl0340CRxc8';

// El ID real lo obtendremos del AuthService en el initState


// ── Tokens ────────────────────────────────────────────────────────────────────
const _bg       = Color(0xFF0D0D0D);
const _bgCard   = Color(0xFF181818);
const _bgCard2  = Color(0xFF1E1E1E);
const _border   = Color(0xFF252525);
const _textMain = Color(0xFFE0E0E0);
const _textMuted = Color(0xFF4A4A4A);
const _textSub  = Color(0xFF777777);
const _yellow   = Color(0xFFFFB800);
const _yellowDark = Color(0xFFCC9200);
const _green    = Color(0xFF39FF7E);

// =============================================================================
// MODEL: ChatMessage
// =============================================================================

/// Modelo de mensaje de chat con timestamp.
/// TODO(backend): Persistencia efímera en Redis/TTL 24h.
class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

enum MessageType { text, emoji, gif }

// ── Datos de ejemplo (mensajes de bienvenida simulados) ──────────────────────

// =============================================================================
// ChatScreen
// =============================================================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.user,

    /// ID único de la sala. Si no se pasa se genera automáticamente
    /// ordenando los IDs de ambos usuarios para garantizar unicidad.
    this.roomId,
  });
  final User user;
  final String? roomId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isFocused = false;
  bool _showEmojiPicker = false;

  // ── WebSocket ─────────────────────────────────────────────────────────────
  final _socketService = SocketService();
  late final String _roomId;

  late final List<ChatMessage> _messages;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _messages = [];

    // Obtener ID del usuario actual de forma asíncrona
    AuthService.getCurrentUser().then((user) {
      if (!mounted) return;
      setState(() {
        _currentUserId = user?.id ?? 'UNKNOWN';
        // Calcular roomId único y estable para esta pareja de usuarios
        _roomId = widget.roomId ?? _buildRoomId(_currentUserId!, widget.user.id);
      });

      // Conectar al WebSocket y unirse a la sala
      _socketService.connect(_roomId);

      // Escuchar historial inicial (llega al hacer joinRoom)
      _socketService.onChatHistory((data) {
        if (!mounted) return;
        final list = (data as List).map((m) => _fromSocketData(m)).toList();
        setState(() {
          _messages
            ..clear()
            ..addAll(list.reversed); // reversed porque ListView es reverse:true
        });
      });

      // Escuchar nuevos mensajes en tiempo real
      _socketService.onNewMessage((data) {
        if (!mounted) return;
        setState(() => _messages.insert(0, _fromSocketData(data)));
      });
    });

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_focusNode.hasFocus) _showEmojiPicker = false;
      });
    });
  }

  /// Genera un roomId estable ordenando los IDs lexicográficamente.
  /// Acepta el [int] id de [User] y el userId actual (String).
  static String _buildRoomId(String currentUserId, String otherUserId) {
    final a = currentUserId;
    final b = otherUserId;
    return (a.compareTo(b) <= 0) ? '${a}_$b' : '${b}_$a';
  }

  /// Convierte el payload JSON del socket en un [ChatMessage] local.
  ChatMessage _fromSocketData(dynamic data) {
    final isMe = data['senderId'].toString() == _currentUserId;
    final type = data['messageType'] == 'gif'
        ? MessageType.gif
        : MessageType.text;
    return ChatMessage(
      id:
          data['_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      text: data['content'] as String,
      isMe: isMe,
      timestamp:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      type: type,
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Enviar mensaje ─────────────────────────────────────────────────────────

  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    // Enviar al servidor via WebSocket (persiste en Mongo con TTL 24h)
    _socketService.sendMessage(
      roomId: _roomId,
      userId: _currentUserId!,
      content: text,
      type: 'text',
    );

    // Limpiamos el texto, el mensaje aparecerá cuando el servidor lo rebote por onNewMessage
    _textCtrl.clear();
    _showEmojiPicker = false;
  }

  // ── GIF via Giphy ─────────────────────────────────────────────────────────

  /// Abre el buscador nativo de GIFs de Giphy, obtiene la URL de la imagen
  /// original y la envía como mensaje de tipo 'gif' a través del WebSocket.
  Future<void> _sendGif() async {
    // Ocultar teclado y emoji picker antes de abrir el selector
    _focusNode.unfocus();
    setState(() => _showEmojiPicker = false);

    final gif = await GiphyGet.getGif(
      context: context,
      apiKey: _kGiphyApiKey,
      lang: GiphyLanguage.spanish, // Búsquedas en español
      tabColor: const Color(0xFF00E5FF), // Color cyan del tema
    );

    // El usuario canceló el selector o no seleccionó ningún GIF
    if (gif == null || !mounted) return;

    // Obtener la URL de la imagen original (mejor calidad)
    final gifUrl = gif.images?.original?.url;
    if (gifUrl == null) return;

    HapticFeedback.lightImpact();

    // Enviar al servidor via WebSocket
    _socketService.sendMessage(
      roomId: _roomId,
      userId: _currentUserId!,
      content: gifUrl,
      type: 'gif',
    );
  }

  void _sendEmoji(String emoji) {
    HapticFeedback.selectionClick();
    // Enviar al servidor via WebSocket
    _socketService.sendMessage(
      roomId: _roomId,
      userId: _currentUserId!,
      content: emoji,
      type: 'text', // Los emojis se mandan como texto normal
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _showDateBadge(int index) {
    if (index == _messages.length - 1) return true;
    final curr = _messages[index].timestamp;
    final prev = _messages[index + 1].timestamp;
    return curr.day != prev.day;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _yellow, strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── AppBar ───────────────────────────────────────────────────────
          _ChatAppBar(user: widget.user),

          // ── Banner efímero ───────────────────────────────────────────────
          _EphemeralBanner(),

          // ── Lista de mensajes ────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () {
                _focusNode.unfocus();
                setState(() => _showEmojiPicker = false);
              },
              child: ListView.builder(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                reverse: true,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final msg = _messages[i];
                  return Column(
                    children: [
                      // Badge de fecha
                      if (_showDateBadge(i)) _DateBadge(date: msg.timestamp),
                      _MessageBubble(
                        message: msg,
                        timeLabel: _formatTime(msg.timestamp),
                        showAvatar:
                            !msg.isMe &&
                            (i == _messages.length - 1 ||
                                _messages[i + 1].isMe),
                        user: widget.user,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Emoji Picker ─────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _showEmojiPicker
                ? _EmojiPicker(onEmoji: _sendEmoji)
                : const SizedBox.shrink(),
          ),

          // ── Input inferior ───────────────────────────────────────────────
          _ChatInputBar(
            controller: _textCtrl,
            focusNode: _focusNode,
            isFocused: _isFocused,
            showEmojiPicker: _showEmojiPicker,
            onSend: _sendText,
            onToggleEmoji: _toggleEmojiPicker,
            onGifTap: _sendGif, // ← Fase III: selector Giphy real
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ChatAppBar
// =============================================================================

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 8,
        right: 16,
        bottom: 10,
      ),
      child: Row(
        children: [
          // Botón atrás
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.arrow_back_rounded, color: _textMain, size: 22),
            ),
          ),
          const SizedBox(width: 4),

          // Avatar + nombre CLICKABLES → abren el perfil del usuario
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UserProfileScreen(user: user),
              )),
              child: Row(
                children: [
                  // Avatar con borde amarillo
                  Stack(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: user.avatarBgColor,
                          border: Border.all(color: _yellow.withValues(alpha: 0.6), width: 2),
                        ),
                        child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? ClipOval(child: Image.network(user.avatarUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(child: Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800)))))
                            : Center(child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800))),
                      ),
                      // Indicador online
                      if (user.isOnline)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 11, height: 11,
                            decoration: BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF111111), width: 2),
                              boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.5), blurRadius: 4)],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // Nombre + estado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(user.username,
                            style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: _textMain)),
                          const SizedBox(width: 5),
                          const Icon(Icons.open_in_new_rounded, color: _yellow, size: 12),
                        ]),
                        Text(
                          user.isOnline ? 'En línea · Toca para ver perfil' : 'Desconectado · Toca para ver perfil',
                          style: TextStyle(fontSize: 10, color: user.isOnline ? _green : _textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Los 3 puntos han sido eliminados
        ],
      ),
    );
  }
}

// =============================================================================
// _EphemeralBanner — Aviso de chat efímero
// =============================================================================

class _EphemeralBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1500),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF2A2200), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 12, color: _yellow.withValues(alpha: 0.7)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Chat efímero · Los mensajes se eliminan cada 24 horas',
              style: TextStyle(fontSize: 10, color: _yellow.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _DateBadge — Separador de fecha
// =============================================================================

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});
  final DateTime date;

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hoy';
    if (d == today.subtract(const Duration(days: 1))) return 'Ayer';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: _border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _label,
              style: const TextStyle(fontSize: 10, color: _textMuted),
            ),
          ),
          Expanded(child: Container(height: 1, color: _border)),
        ],
      ),
    );
  }
}

// =============================================================================
// _MessageBubble — Burbuja de mensaje
// =============================================================================

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.timeLabel,
    required this.showAvatar,
    required this.user,
  });

  final ChatMessage message;
  final String timeLabel;
  final bool showAvatar;
  final User user;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final isEmoji = message.type == MessageType.emoji;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // Avatar del otro (solo en último de su bloque)
          if (!isMe) ...[
            SizedBox(
              width: 30,
              child: showAvatar
                  ? CircleAvatar(
                      radius: 13,
                      backgroundColor: user.avatarBgColor,
                      backgroundImage:
                          user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? Text(
                              user.username[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10, color: Colors.black, fontWeight: FontWeight.w700))
                          : null,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],

          // Burbuja
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (isEmoji)
                  // Emoji grande sin burbuja
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      message.text,
                      style: const TextStyle(fontSize: 36),
                    ),
                  )
                else if (message.type == MessageType.gif)
                  // ── Burbuja GIF ─────────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.text,
                      width: MediaQuery.of(context).size.width * 0.55,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.55,
                          height: 140,
                          color: _bgCard,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _yellow,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        width: 140,
                        height: 80,
                        color: _bgCard,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: _textMuted,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.68,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? _yellow : _bgCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: isMe
                          ? [
                              BoxShadow(
                                color: _yellow.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                      border: isMe ? null : Border.all(color: _border),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: isMe ? Colors.black : _textMain,
                        height: 1.3,
                      ),
                    ),
                  ),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    timeLabel,
                    style: const TextStyle(fontSize: 9, color: _textMuted),
                  ),
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// =============================================================================
// _EmojiPicker — Panel de emojis
// =============================================================================

const _kEmojis = [
  '😂',
  '❤️',
  '🔥',
  '👾',
  '🎮',
  '💀',
  '😎',
  '🤝',
  '👀',
  '💯',
  '🫡',
  '⚡',
  '🏆',
  '🎯',
  '💥',
  '🚀',
  '👑',
  '🫶',
  '😤',
  '😮',
  '🤯',
  '🥶',
  '😱',
  '🤙',
];

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.onEmoji});
  final void Function(String) onEmoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: _kEmojis.length,
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => onEmoji(_kEmojis[i]),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
            ),
            child: Center(
              child: Text(_kEmojis[i], style: const TextStyle(fontSize: 24)),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _ChatInputBar — Barra de entrada inferior
// =============================================================================

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.showEmojiPicker,
    required this.onSend,
    required this.onToggleEmoji,
    required this.onGifTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool showEmojiPicker;
  final VoidCallback onSend;
  final VoidCallback onToggleEmoji;
  final VoidCallback onGifTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón emoji
          _IconActionBtn(
            icon: showEmojiPicker
                ? Icons.keyboard_rounded
                : Icons.emoji_emotions_outlined,
            color: showEmojiPicker ? _yellow : _textSub,
            onTap: onToggleEmoji,
          ),
          const SizedBox(width: 6),

          // Campo de texto
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: _bgCard2,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isFocused ? _yellow.withValues(alpha: 0.5) : _border,
                  width: isFocused ? 1.5 : 1,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: _yellow.withValues(alpha: 0.07),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  color: _textMain,
                  fontSize: 13,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Botón GIF
          _IconActionBtn(
            icon: Icons.gif_box_outlined,
            color: _textSub,
            onTap: onGifTap,
          ),
          const SizedBox(width: 6),

          // Botón enviar
          ListenableBuilder(
            listenable: controller,
            builder: (ctx, _) {
              final hasText = controller.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: onSend,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: hasText
                        ? const LinearGradient(
                            colors: [_yellow, _yellowDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasText ? null : _bgCard2,
                    shape: BoxShape.circle,
                    border: hasText ? null : Border.all(color: _border),
                    boxShadow: hasText
                        ? [BoxShadow(color: _yellow.withValues(alpha: 0.35), blurRadius: 10)]
                        : [],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: hasText ? Colors.black : _textMuted,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  const _IconActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 36,
      height: 42,
      child: Center(child: Icon(icon, size: 22, color: color)),
    ),
  );
}
