// =============================================================================
// Message.js — Bound2Game Backend
//
// Modelo Mongoose para los mensajes del chat efímero entre jugadores.
// El índice TTL sobre 'createdAt' permite que MongoDB elimine automáticamente
// los documentos tras 86400 segundos (24 horas), sin ningún cron externo.
// =============================================================================

const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
    {
        // Sala a la que pertenece el mensaje (ej. "user1Id_user2Id" ordenado).
        chatRoomId: {
            type: String,
            required: true,
            index: true,          // Índice normal para consultas por sala
        },

        // Usuario que envió el mensaje (referencia a User._id).
        senderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },

        // Contenido del mensaje. Para GIFs almacenamos la URL directa de Giphy.
        content: {
            type: String,
            required: true,
            trim: true,
        },

        // Tipo de mensaje para que el cliente renderice correctamente.
        messageType: {
            type: String,
            enum: ['text', 'gif'],
            default: 'text',
        },
    },
    {
        // 'timestamps: true' crea automáticamente 'createdAt' y 'updatedAt'.
        // El índice TTL apunta a 'createdAt'.
        timestamps: true,
    }
);

// ── Índice TTL ─────────────────────────────────────────────────────────────────
// MongoDB ejecuta un proceso de fondo cada 60 segundos que elimina los
// documentos cuyo 'createdAt' supere el umbral de 86400 segundos (24h).
messageSchema.index({ createdAt: 1 }, { expireAfterSeconds: 86400 });

module.exports = mongoose.model('Message', messageSchema);
