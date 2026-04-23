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
import '../models/user_model.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFF0D0D0D);
const _bgCard    = Color(0xFF181818);
const _bgCard2   = Color(0xFF1E1E1E);
const _border    = Color(0xFF252525);
const _textMain  = Color(0xFFE0E0E0);
const _textMuted = Color(0xFF4A4A4A);
const _textSub   = Color(0xFF777777);
const _cyan      = Color(0xFF00E5FF);
const _cyanDark  = Color(0xFF00B8CC);
const _green     = Color(0xFF39FF7E);

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

List<ChatMessage> _mockMessages(String username) => [
  ChatMessage(
    id: 'm1', text: '¡Hola! ¿Jugamos algo esta noche?',
    isMe: false,
    timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
  ),
  ChatMessage(
    id: 'm2', text: '¡Claro! Estaba pensando en Elden Ring co-op.',
    isMe: true,
    timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  ChatMessage(
    id: 'm3', text: '¿Tienes pase de temporada? Hay DLC nuevo 🔥',
    isMe: false,
    timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
  ),
  ChatMessage(
    id: 'm4', text: 'Sí, lo compré ayer en oferta en Steam. ¡-60%!',
    isMe: true,
    timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
  ),
  ChatMessage(
    id: 'm5', text: '¡Genial! Te mando invitación a las 22:00 👾',
    isMe: false,
    timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
  ),
];

// =============================================================================
// ChatScreen
// =============================================================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user});
  final SocialUser user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isFocused = false;
  bool _showEmojiPicker = false;

  late final List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _mockMessages(widget.user.username);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_focusNode.hasFocus) _showEmojiPicker = false;
      });
    });
  }

  @override
  void dispose() {
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
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isMe: true,
          timestamp: DateTime.now(),
        ),
      );
      _textCtrl.clear();
      _showEmojiPicker = false;
    });
  }

  void _sendEmoji(String emoji) {
    HapticFeedback.selectionClick();
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: emoji,
          isMe: true,
          timestamp: DateTime.now(),
          type: MessageType.emoji,
        ),
      );
    });
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
                        showAvatar: !msg.isMe &&
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
            onGifTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('GIFs próximamente disponibles 🎬',
                    style: TextStyle(fontSize: 12)),
                backgroundColor: Color(0xFF1A1A1A),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            ),
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
  final SocialUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 8, right: 16, bottom: 10,
      ),
      child: Row(
        children: [
          // Botón atrás
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.arrow_back_rounded,
                  color: _textMain, size: 22),
            ),
          ),
          const SizedBox(width: 4),

          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF252525),
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(user.username[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: _cyan))
                    : null,
              ),
              // Indicador online
              if (user.isOnline)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF111111), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
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
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: _textMain,
                  ),
                ),
                Text(
                  user.isOnline
                      ? 'En línea'
                      : 'Desconectado',
                  style: TextStyle(
                    fontSize: 10,
                    color: user.isOnline ? _green : _textMuted,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Botón más opciones
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.more_vert_rounded,
                color: _textSub, size: 20),
          ),
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
        color: const Color(0xFF0A1520),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1A2535), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF4A8FBF)),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'Chat efímero · Los mensajes se eliminan cada 24 horas',
              style: TextStyle(fontSize: 10, color: Color(0xFF4A8FBF)),
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
            child: Text(_label,
                style: const TextStyle(fontSize: 10, color: _textMuted)),
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
  final SocialUser user;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final isEmoji = message.type == MessageType.emoji;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar del otro (solo en último de su bloque)
          if (!isMe) ...[
            SizedBox(
              width: 30,
              child: showAvatar
                  ? CircleAvatar(
                      radius: 13,
                      backgroundColor: const Color(0xFF252525),
                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? Text(user.username[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10, color: _cyan))
                          : null,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],

          // Burbuja
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isEmoji)
                  // Emoji grande sin burbuja
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(message.text,
                        style: const TextStyle(fontSize: 36)),
                  )
                else
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.68,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: isMe ? _cyan : _bgCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            Radius.circular(isMe ? 16 : 4),
                        bottomRight:
                            Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: isMe
                          ? [BoxShadow(
                              color: _cyan.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )]
                          : [],
                      border: isMe
                          ? null
                          : Border.all(color: _border),
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
                  child: Text(timeLabel,
                      style: const TextStyle(
                          fontSize: 9, color: _textMuted)),
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
  '😂', '❤️', '🔥', '👾', '🎮', '💀', '😎', '🤝',
  '👀', '💯', '🫡', '⚡', '🏆', '🎯', '💥', '🚀',
  '👑', '🫶', '😤', '😮', '🤯', '🥶', '😱', '🤙',
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
              child: Text(_kEmojis[i],
                  style: const TextStyle(fontSize: 24)),
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
        left: 10, right: 10, top: 8,
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
            color: showEmojiPicker ? _cyan : _textSub,
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
                  color: isFocused
                      ? _cyan.withValues(alpha: 0.45)
                      : _border,
                  width: isFocused ? 1.5 : 1,
                ),
                boxShadow: isFocused
                    ? [BoxShadow(
                        color: _cyan.withValues(alpha: 0.06),
                        blurRadius: 12,
                      )]
                    : [],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                    color: _textMain, fontSize: 13, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
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
                            colors: [_cyan, _cyanDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasText ? null : _bgCard2,
                    shape: BoxShape.circle,
                    border: hasText
                        ? null
                        : Border.all(color: _border),
                    boxShadow: hasText
                        ? [BoxShadow(
                            color: _cyan.withValues(alpha: 0.3),
                            blurRadius: 10,
                          )]
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
    required this.icon, required this.color, required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 36, height: 42,
      child: Center(
        child: Icon(icon, size: 22, color: color),
      ),
    ),
  );
}
