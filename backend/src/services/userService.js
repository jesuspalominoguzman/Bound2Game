const User = require('../models/User');
const mongoose = require('mongoose');

/**
 * Servicio para gestionar lógica compleja de usuarios
 */
class UserService {
    /**
     * Gestiona el flujo de solicitudes de amistad (Enviar / Aceptar)
     * @returns {Object} { status: string, message: string }
     */
    async manageFriendRequest(senderId, targetId, io) {
        if (senderId === targetId) {
            throw { status: 400, message: 'No puedes enviarte una solicitud a ti mismo' };
        }

        const [sender, receiver] = await Promise.all([
            User.findById(senderId),
            User.findById(targetId)
        ]);

        if (!sender || !receiver) {
            throw { status: 404, message: 'Usuario no encontrado' };
        }

        // 1. ¿Ya son amigos?
        const alreadyFriends = sender.friends.map(id => id.toString()).includes(targetId);
        if (alreadyFriends) {
            return { status: 409, code: 'friends', message: 'Ya sois amigos' };
        }

        // 2. ¿El TARGET nos envió una solicitud previa? → ACEPTAR
        const hasPendingFromTarget = sender.pendingRequests.map(id => id.toString()).includes(targetId);
        if (hasPendingFromTarget) {
            sender.friends.push(targetId);
            receiver.friends.push(senderId);
            sender.pendingRequests = sender.pendingRequests.filter(id => id.toString() !== targetId);
            
            await Promise.all([sender.save(), receiver.save()]);

            if (io) {
                io.of('/chat').to(`user_${targetId}`).emit('friendRequest', {
                    username: sender.username,
                    userId: senderId,
                    type: 'accepted'
                });
            }

            return { status: 200, code: 'accepted', message: '¡Solicitud aceptada! Ahora sois amigos.' };
        }

        // 3. ¿Ya enviamos una solicitud antes?
        const alreadySent = receiver.pendingRequests.map(id => id.toString()).includes(senderId);
        if (alreadySent) {
            return { status: 409, code: 'pending', message: 'Solicitud ya enviada' };
        }

        // 4. ENVIAR solicitud
        receiver.pendingRequests.push(senderId);
        await receiver.save();

        if (io) {
            io.of('/chat').to(`user_${targetId}`).emit('friendRequest', {
                username: sender.username,
                userId: senderId,
                type: 'request'
            });
        }

        return { status: 200, code: 'pending', message: 'Solicitud de amistad enviada correctamente.' };
    }
}

module.exports = new UserService();
