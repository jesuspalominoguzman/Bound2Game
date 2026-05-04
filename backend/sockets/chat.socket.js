// =============================================================================
// chat.socket.js — Bound2Game Backend
//
// Controlador de WebSockets para el chat efímero entre jugadores.
// Exporta una única función que recibe la instancia de Socket.io y registra
// todos los eventos bajo el namespace '/chat', sin tocar el servidor HTTP.
//
// Uso en index.js (añadir SOLO estas dos líneas):
//   const chatSocket = require('./sockets/chat.socket');
//   chatSocket(io);
// =============================================================================

const Message = require('../src/models/Message');

/**
 * Inicializa el namespace /chat y todos sus manejadores de eventos.
 * @param {import('socket.io').Server} io - Instancia principal de Socket.io
 */
module.exports = function initChatSocket(io) {
    // ── Namespace dedicado ──────────────────────────────────────────────────
    // Aísla el tráfico de chat del resto de namespaces del servidor.
    const chatNamespace = io.of('/chat');

    chatNamespace.on('connection', (socket) => {
        console.log(`🔌 [Chat] Cliente conectado: ${socket.id}`);

        // ── joinRoom ────────────────────────────────────────────────────────
        // El cliente envía { roomId } para suscribirse a una sala concreta.
        // La sala se nombra como "<userId1>_<userId2>" (IDs ordenados
        // alfabéticamente para garantizar unicidad bidireccional).
        socket.on('joinRoom', async ({ roomId }) => {
            if (!roomId) return;

            // Salir de cualquier sala anterior (cada socket solo ocupa una)
            const currentRooms = Array.from(socket.rooms).filter(
                (r) => r !== socket.id
            );
            currentRooms.forEach((r) => socket.leave(r));

            // Entrar a la nueva sala
            socket.join(roomId);
            console.log(`📥 [Chat] Socket ${socket.id} unido a sala: ${roomId}`);

            // Enviar historial de las últimas 50 mensajes de la sala
            // (dentro de la ventana de 24h gracias al TTL)
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

        // ── sendMessage ─────────────────────────────────────────────────────
        // Payload esperado: { roomId, senderId, content, messageType }
        // Persiste en MongoDB (con TTL 24h) y emite a todos en la sala.
        socket.on('sendMessage', async ({ roomId, senderId, content, messageType }) => {
            // Validación básica de campos requeridos
            if (!roomId || !senderId || !content) {
                socket.emit('chatError', { message: 'Faltan campos requeridos.' });
                return;
            }

            const type = ['text', 'gif'].includes(messageType) ? messageType : 'text';

            try {
                // Persistir en MongoDB — el TTL se encarga de borrar tras 24h
                const newMessage = await Message.create({
                    chatRoomId: roomId,
                    senderId,
                    content,
                    messageType: type,
                });

                // Emitir a todos los miembros de la sala (incluido el remitente)
                chatNamespace.to(roomId).emit('newMessage', {
                    _id: newMessage._id,
                    chatRoomId: newMessage.chatRoomId,
                    senderId: newMessage.senderId,
                    content: newMessage.content,
                    messageType: newMessage.messageType,
                    createdAt: newMessage.createdAt,
                });

                console.log(`💬 [Chat] Mensaje [${type}] en sala ${roomId} de ${senderId}`);
            } catch (err) {
                console.error('🔴 [Chat] Error al guardar mensaje:', err);
                socket.emit('chatError', { message: 'No se pudo enviar el mensaje.' });
            }
        });

        // ── disconnect ──────────────────────────────────────────────────────
        socket.on('disconnect', (reason) => {
            console.log(`🔌 [Chat] Cliente desconectado: ${socket.id} — Razón: ${reason}`);
        });
    });
};
