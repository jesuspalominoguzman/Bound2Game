// Estos son los widgets que usamos para el chat. La barra de arriba, las burbujas de mensaje, el selector de emojis...
// He intentado que todo tenga un aire premium y que sea muy cómodo de usar.

import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../screens/user_profile_screen.dart';

// Mis colores para el chat. Amarillo para mis mensajes y gris oscuro para los del otro.
const _textMain = Color(0xFFE0E0E0);
const _textMuted = Color(0xFF4A4A4A);
const _yellow   = Color(0xFFFFB800);
const _green    = Color(0xFF39FF7E);
const _bgCard   = Color(0xFF181818);
const _border   = Color(0xFF252525);

// La parte de arriba del chat. He puesto que si tocas el nombre o el avatar, te mande directo al perfil del otro jugador.
class ChatAppBar extends StatelessWidget {
  const ChatAppBar({super.key, required this.user});
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
          // Botón para volver atrás.
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.arrow_back_rounded, color: _textMain, size: 22),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UserProfileScreen(user: user),
              )),
              child: Row(
                children: [
                  _AvatarWithPresence(user: user),
                  const SizedBox(width: 10),
                  _UserInfo(user: user),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// El circulito con la foto del usuario. Si está conectado, le ponemos un puntito verde brillante para que se note.
class _AvatarWithPresence extends StatelessWidget {
  const _AvatarWithPresence({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  errorBuilder: (_, _, _) => _FallbackInitial(user: user)))
              : _FallbackInitial(user: user),
        ),
        // Solo mostramos el punto verde si el servidor nos dice que está online.
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
    );
  }
}

// Si no hay foto, ponemos la primera letra de su nombre.
class _FallbackInitial extends StatelessWidget {
  const _FallbackInitial({required this.user});
  final User user;
  @override
  Widget build(BuildContext context) => Center(child: Text(
      user.username[0].toUpperCase(),
      style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800)));
}

class _UserInfo extends StatelessWidget {
  const _UserInfo({required this.user});
  final User user;
  @override
  Widget build(BuildContext context) {
    return Expanded(
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
    );
  }
}

// Un pequeño aviso arriba para recordar que los mensajes se borran a las 24 horas. ¡Que nadie se asuste!
class EphemeralBanner extends StatelessWidget {
  const EphemeralBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1500),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2200), width: 1)),
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

// La línea que separa los mensajes por días. Queda más ordenado así.
class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: _border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label, style: const TextStyle(fontSize: 10, color: _textMuted)),
          ),
          Expanded(child: Container(height: 1, color: _border)),
        ],
      ),
    );
  }
}

// La burbuja del mensaje. Si lo mando yo, es amarilla; si me lo mandan, es gris oscura. También soporta GIFs y emojis gigantes.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
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
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Si no soy yo, mostramos su avatar pequeñito al lado del mensaje.
          if (!isMe) ...[
            SizedBox(
              width: 30,
              child: showAvatar
                  ? CircleAvatar(
                      radius: 13,
                      backgroundColor: user.avatarBgColor,
                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? Text(user.username[0].toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w700))
                          : null,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Si solo es un emoji, lo ponemos bien grande que queda chulo.
                if (isEmoji)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(message.text, style: const TextStyle(fontSize: 36)),
                  )
                // Si es un GIF, lo mostramos con bordes redondeados.
                else if (message.type == MessageType.gif)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.text,
                      width: MediaQuery.of(context).size.width * 0.55,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 140, height: 80, color: _bgCard,
                        child: const Center(child: Icon(Icons.broken_image_outlined, color: _textMuted, size: 28)),
                      ),
                    ),
                  )
                // Mensaje de texto normal.
                else
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: isMe ? _yellow : _bgCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: isMe ? null : Border.all(color: _border),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(fontSize: 13, color: isMe ? Colors.black : _textMain, height: 1.3),
                    ),
                  ),
                // La hora del mensaje aquí debajo en pequeñito.
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(timeLabel, style: const TextStyle(fontSize: 9, color: _textMuted)),
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

// Un selector rápido de emojis para no tener que abrir el teclado siempre.
class EmojiPickerWidget extends StatelessWidget {
  const EmojiPickerWidget({super.key, required this.onEmoji});
  final void Function(String) onEmoji;

  static const _kEmojis = ['😂','❤️','🔥','👾','🎮','💀','😎','🤝','👀','💯','🫡','⚡','🏆','🎯','💥','🚀','👑','🫶','😤','😮','🤯','🥶','😱','🤙'];

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
          child: Center(child: Text(_kEmojis[i], style: const TextStyle(fontSize: 24))),
        ),
      ),
    );
  }
}

// La barrita de abajo donde escribes. Se expande si escribes mucho y tiene los botones para emojis y GIFs.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
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
          // Botón para emojis.
          _IconActionBtn(
            icon: showEmojiPicker ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
            color: showEmojiPicker ? _yellow : _textMuted,
            onTap: onToggleEmoji,
          ),
          // Botón para GIFs.
          _IconActionBtn(icon: Icons.gif_box_outlined, color: _textMuted, onTap: onGifTap),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: _border)),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4, minLines: 1,
                decoration: const InputDecoration(hintText: 'Escribe un mensaje...', hintStyle: TextStyle(color: _textMuted, fontSize: 14), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ),
          // El botón de enviar con un poco de sombra amarilla para que destaque.
          GestureDetector(
            onTap: onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _yellow, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _yellow.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  const _IconActionBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: color, size: 24)),
    );
  }
}
