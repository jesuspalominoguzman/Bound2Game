// =============================================================================
// chat.socket.js — Bound2Game Backend
//
// Controlador de WebSockets para:
//   • Chat efímero entre jugadores (namespace /chat)
//   • Presencia en tiempo real: isOnline en MongoDB
//
// Uso en index.js:
//   const chatSocket = require('./sockets/chat.socket');
//   chatSocket(io);
// =============================================================================

const Message = require('../src/models/Message');
const User    = require('../src/models/User');

// Mapa socketId → userId para gestionar disconnects de presencia
const socketUserMap = new Map();

/**
 * Inicializa el namespace /chat y los manejadores de presencia.
 * @param {import('socket.io').Server} io
 */
module.exports = function initChatSocket(io) {
    const chatNamespace = io.of('/chat');

    chatNamespace.on('connection', (socket) => {
        console.log(`🔌 [Chat] Cliente conectado: ${socket.id}`);

        // ── userConnected ────────────────────────────────────────────────────
        // El cliente emite esto al abrir la app / volver a primer plano.
        // Payload: { userId: string }
        socket.on('userConnected', async ({ userId }) => {
            if (!userId) return;
            socketUserMap.set(socket.id, userId);
            try {
                await User.findByIdAndUpdate(userId, { isOnline: true });
                console.log(`🟢 [Presence] ${userId} → En Línea`);
                
                // Unir al usuario a su propia sala privada para notificaciones dirigidas
                socket.join(`user_${userId}`);
                console.log(`🏠 [Presence] Socket ${socket.id} unido a sala: user_${userId}`);
                
                // Notificar a TODOS los clientes conectados para actualización en tiempo real
                chatNamespace.emit('presenceUpdate', { userId, isOnline: true });
            } catch (err) {
                console.error('🔴 [Presence] Error al actualizar isOnline=true:', err);
            }
        });

        // ── joinRoom ─────────────────────────────────────────────────────────
        socket.on('joinRoom', async ({ roomId }) => {
            if (!roomId) return;

            // Salir de salas anteriores
            const currentRooms = Array.from(socket.rooms).filter(
                (r) => r !== socket.id
            );
            currentRooms.forEach((r) => socket.leave(r));

            socket.join(roomId);
            console.log(`📥 [Chat] Socket ${socket.id} unido a sala: ${roomId}`);

            // Enviar historial (últimas 50 mensajes dentro de la ventana 24h TTL)
            try {
                const history = await Message.find({ chatRoomId: roomId })
                    .sort({ createdAt: 1 })
                    .limit(50)
                    .lean();

                socket.emit('chatHistory', history);
            } catch (err) {
                console.error('🔴 [Chat] Error al cargar historial:', err);
                socket.emit('chatError', { message: 'No se pudo cargar el historial.' });
            }
        });

        // ── sendMessage ──────────────────────────────────────────────────────
        // Payload: { roomId, senderId, content, messageType }
        socket.on('sendMessage', async ({ roomId, senderId, content, messageType }) => {
            if (!roomId || !senderId || !content) {
                socket.emit('chatError', { message: 'Faltan campos requeridos.' });
                return;
            }

            const type = ['text', 'gif'].includes(messageType) ? messageType : 'text';

            try {
                const newMessage = await Message.create({
                    chatRoomId: roomId,
                    senderId,
                    content,
                    messageType: type,
                });

                chatNamespace.to(roomId).emit('newMessage', {
                    _id:          newMessage._id,
                    chatRoomId:   newMessage.chatRoomId,
                    senderId:     newMessage.senderId,
                    content:      newMessage.content,
                    messageType:  newMessage.messageType,
                    createdAt:    newMessage.createdAt,
                });

                console.log(`💬 [Chat] Mensaje [${type}] en sala ${roomId} de ${senderId}`);

                // ── Enviar Notificación Push al destinatario ──────────────────
                // Asumimos que el roomId tiene el formato userId1_userId2
                const ids = roomId.split('_');
                const recipientId = ids.find(id => id !== senderId);

                if (recipientId) {
                    // Notificar al destinatario a través de su sala privada si está conectado
                    // Esto permite mostrar notificaciones locales en la app aunque no esté en el chat
                    chatNamespace.to(`user_${recipientId}`).emit('newMessage', {
                        _id:          newMessage._id,
                        chatRoomId:   newMessage.chatRoomId,
                        senderId:     newMessage.senderId,
                        content:      newMessage.content,
                        messageType:  newMessage.messageType,
                        createdAt:    newMessage.createdAt,
                    });
                }
            } catch (err) {
                console.error('🔴 [Chat] Error al guardar mensaje:', err);
                socket.emit('chatError', { message: 'No se pudo enviar el mensaje.' });
            }
        });

        // ── disconnect ───────────────────────────────────────────────────────
        // Se dispara automáticamente cuando el socket se cierra (app en background / cerrada).
        socket.on('disconnect', async (reason) => {
            console.log(`🔌 [Chat] Cliente desconectado: ${socket.id} — Razón: ${reason}`);

            const userId = socketUserMap.get(socket.id);
            if (userId) {
                socketUserMap.delete(socket.id);
                try {
                    await User.findByIdAndUpdate(userId, { isOnline: false });
                    console.log(`🔴 [Presence] ${userId} → Desconectado`);
                    // Notificar a TODOS los clientes conectados para actualización en tiempo real
                    chatNamespace.emit('presenceUpdate', { userId, isOnline: false });
                } catch (err) {
                    console.error('🔴 [Presence] Error al actualizar isOnline=false:', err);
                }
            }
        });
    });
};

