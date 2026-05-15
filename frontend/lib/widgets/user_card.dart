// =============================================================================
// user_card.dart — Bound2Game Flutter (Android)
// Fuente: Social.tsx → UserCard / PlayerCard component
//
// Widget reutilizable para mostrar un jugador de la comunidad.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/user_profile_screen.dart';
import '../screens/chat_screen.dart';
import '../services/api_service.dart';

// ── Constantes de color ───────────────────────────────────────────────────────
const _bgCard    = Color(0xFF1A1A1A); // Nueva directriz
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
    this.onReturn,
  });

  final User user;
  final bool isFriend;
  final VoidCallback? onReturn;

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isPressed = false;
  late _FriendState _state;

  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _state = widget.isFriend ? _FriendState.friends : _FriendState.none;
  }

  Future<void> _handleAction() async {
    if (_state == _FriendState.friends) {
      // Si es amigo, el chat se abre desde el ícono
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)),
      );
      return;
    }
    if (_actionLoading) return;

    setState(() => _actionLoading = true);
    try {
      final result = await ApiService.sendFriendRequest(widget.user.id);
      if (mounted) {
        setState(() {
          if (result == 'accepted') {
            _state = _FriendState.friends;
          } else if (result == 'pending') {
            _state = _FriendState.pending;
          } else if (result == 'none') {
            _state = _FriendState.none;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $e'),
            backgroundColor: const Color(0xFF1A1A1A),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(user: widget.user),
          ),
        );
        if (widget.onReturn != null) widget.onReturn!();
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
            color: _isPressed ? _yellow.withValues(alpha: 0.3) : _border,
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
                        widget.user.isOnline ? 'En Línea' : 'Desconectado',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.user.isOnline ? _green : _textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Juegos recientes del amigo (datos reales del backend)
                  if (widget.user.recentGames.isEmpty)
                    const Text(
                      'Sin juegos en biblioteca',
                      style: TextStyle(fontSize: 11, color: _textSub),
                    )
                  else
                    Text(
                      widget.user.recentGames.take(2).join(', '),
                      style: const TextStyle(fontSize: 11, color: _textSub),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Botón de acción (Máquina de estados)
            _actionLoading
                ? const SizedBox(
                    width: 40, height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
                    ),
                  )
                : IconButton(
                    onPressed: _handleAction,
                    icon: _buildActionIcon(),
                    color: _state == _FriendState.none
                        ? _textMain
                        : _state == _FriendState.pending
                            ? _yellow
                            : _yellow,
                    style: IconButton.styleFrom(
                      backgroundColor: _state == _FriendState.friends
                          ? _yellow.withValues(alpha: 0.1)
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
  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user.avatarBgColor,
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
  final User user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        user.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
