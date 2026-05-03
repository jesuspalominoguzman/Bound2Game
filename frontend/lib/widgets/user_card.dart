// =============================================================================
// user_card.dart — Bound2Game Flutter (Android)
// Fuente: Social.tsx → UserCard / PlayerCard component
//
// Widget reutilizable para mostrar un jugador de la comunidad.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/profile_screen.dart';
import '../screens/chat_screen.dart';

// ── Constantes de color ───────────────────────────────────────────────────────
const _bgCard    = Color(0xFF1A1A1A); // Nueva directriz
const _bgCard2   = Color(0xFF1C1C1C);
const _border    = Color(0xFF252525);
const _textMain  = Colors.white;
const _textSub   = Color(0xFF888888);
const _green     = Color(0xFF4AF626);
const _yellow    = Color(0xFFFFB800);

enum _FriendState { none, pending, friends }

class UserCard extends StatefulWidget {
  const UserCard({
    super.key,
    required this.user,
    this.isFriend = false,
  });

  final SocialUser user;
  final bool isFriend;

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isPressed = false;
  late _FriendState _state;

  @override
  void initState() {
    super.initState();
    // Inyectar estado inicial de amistad
    _state = widget.isFriend ? _FriendState.friends : _FriendState.none;
  }

  void _handleAction() {
    setState(() {
      if (_state == _FriendState.none) {
        _state = _FriendState.pending;
      } else if (_state == _FriendState.pending) {
        _state = _FriendState.none;
      } else if (_state == _FriendState.friends) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(user: widget.user),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              user: widget.user,
              isOwnProfile: false,
            ),
          ),
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isPressed ? const Color(0xFF222222) : _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isPressed ? _yellow.withOpacity(0.3) : _border,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _UserAvatar(user: widget.user),
            const SizedBox(width: 14),

            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.username,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Estado de conexión
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.user.isOnline ? _green : _textSub,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.user.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.user.isOnline ? _green : _textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Juegos en común
                  Text(
                    '${widget.user.commonGames} juegos en común',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textSub,
                    ),
                  ),
                ],
              ),
            ),

            // Botón de acción (Máquina de estados)
            IconButton(
              onPressed: _handleAction,
              icon: _buildActionIcon(),
              color: _state == _FriendState.none
                  ? _textMain
                  : _state == _FriendState.pending
                      ? _yellow
                      : _yellow, // Usar amarillo como acento para acciones completadas
              style: IconButton.styleFrom(
                backgroundColor: _state == _FriendState.friends 
                    ? _yellow.withOpacity(0.1) 
                    : const Color(0xFF292929),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon() {
    switch (_state) {
      case _FriendState.none:
        return const Icon(Icons.person_add_rounded, size: 20);
      case _FriendState.pending:
        return const Icon(Icons.pending_rounded, size: 20);
      case _FriendState.friends:
        return const Icon(Icons.send_rounded, size: 20);
    }
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});
  final SocialUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user.avatarBgColor ?? _bgCard2,
      ),
      child: user.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, _) =>
                    _InitialsContent(user: user),
              ),
            )
          : _InitialsContent(user: user),
    );
  }
}

class _InitialsContent extends StatelessWidget {
  const _InitialsContent({required this.user});
  final SocialUser user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        user.initials ?? '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
