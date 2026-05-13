// Este es el chat. La idea es que sea algo rápido y que los mensajes no se guarden para siempre, para que sea más privado.
// He intentado que se parezca a cualquier app de mensajería moderna, pero con los colores de nuestra app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giphy_get/giphy_get.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../utils/b2g_utils.dart';
import '../widgets/chat_widgets.dart';

const _kGiphyApiKey = 'BSgmdKZuDX7iOouqo0eDnQl0340CRxc8';
const _bg = Color(0xFF0D0D0D);
const _yellow = Color(0xFFFFB800);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user, this.roomId});
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
  String? _currentUserId;
  late final String _roomId;
  final List<ChatMessage> _messages = [];
  final _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    // Arrancamos el chat y preparamos el teclado/emojis.
    _initChat();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_focusNode.hasFocus) _showEmojiPicker = false;
      });
    });
  }

  // Aquí configuramos todo: sacamos nuestro ID, el del otro jugador y nos conectamos al socket para recibir los mensajes en tiempo real.
  Future<void> _initChat() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;

    setState(() {
      _currentUserId = user?.id ?? 'UNKNOWN';
      // Creamos un ID de sala único para nosotros dos.
      _roomId = widget.roomId ?? B2GUtils.buildRoomId(_currentUserId!, widget.user.id);
    });

    _socketService.connect(_roomId);

    // Cuando entramos al chat, cargamos los mensajes anteriores para ver de qué estábamos hablando.
    _socketService.onChatHistory((data) {
      if (!mounted) return;
      final list = (data as List).map((m) => ChatMessage.fromSocketData(m, _currentUserId!)).toList();
      setState(() {
        _messages..clear()..addAll(list.reversed);
      });
    });

    // Si nos llega un mensaje nuevo mientras tenemos el chat abierto, lo metemos directamente al principio de la lista.
    _socketService.onNewMessage((data) {
      if (!mounted) return;
      setState(() => _messages.insert(0, ChatMessage.fromSocketData(data, _currentUserId!)));
    });
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Mandamos un mensaje de texto normal. Le he puesto una pequeña vibración para que se note al pulsar.
  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _socketService.sendMessage(roomId: _roomId, userId: _currentUserId!, content: text, type: 'text');
    _textCtrl.clear();
    _showEmojiPicker = false;
  }

  // Para mandar GIFs. Uso la API de Giphy, que tiene de todo.
  Future<void> _sendGif() async {
    _focusNode.unfocus();
    setState(() => _showEmojiPicker = false);

    final gif = await GiphyGet.getGif(
      context: context,
      apiKey: _kGiphyApiKey,
      lang: GiphyLanguage.spanish,
      tabColor: const Color(0xFF00E5FF),
    );

    if (gif == null || !mounted) return;
    final gifUrl = gif.images?.original?.url;
    if (gifUrl == null) return;

    HapticFeedback.lightImpact();
    _socketService.sendMessage(roomId: _roomId, userId: _currentUserId!, content: gifUrl, type: 'gif');
  }

  void _sendEmoji(String emoji) {
    HapticFeedback.selectionClick();
    _socketService.sendMessage(roomId: _roomId, userId: _currentUserId!, content: emoji, type: 'text');
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

  // Esto es para que aparezca la fecha (ej: "Hoy", "Ayer") cuando los mensajes son de días distintos.
  bool _showDateBadge(int index) {
    if (index == _messages.length - 1) return true;
    final curr = _messages[index].timestamp;
    final prev = _messages[index + 1].timestamp;
    return curr.day != prev.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _yellow, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          ChatAppBar(user: widget.user),
          const EphemeralBanner(),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _focusNode.unfocus();
                setState(() => _showEmojiPicker = false);
              },
              // La lista de mensajes va al revés porque los más nuevos suelen ir abajo.
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
                      if (_showDateBadge(i)) DateBadge(label: B2GUtils.formatDateBadge(msg.timestamp)),
                      MessageBubble(
                        message: msg,
                        timeLabel: B2GUtils.formatTime(msg.timestamp),
                        showAvatar: !msg.isMe && (i == _messages.length - 1 || _messages[i + 1].isMe),
                        user: widget.user,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _showEmojiPicker ? EmojiPickerWidget(onEmoji: _sendEmoji) : const SizedBox.shrink(),
          ),
          ChatInputBar(
            controller: _textCtrl,
            focusNode: _focusNode,
            isFocused: _isFocused,
            showEmojiPicker: _showEmojiPicker,
            onSend: _sendText,
            onToggleEmoji: _toggleEmojiPicker,
            onGifTap: _sendGif,
          ),
        ],
      ),
    );
  }
}
