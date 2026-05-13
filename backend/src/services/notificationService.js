const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Ruta al archivo de credenciales de Firebase
const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json');

let messaging;

try {
    if (fs.existsSync(serviceAccountPath)) {
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        messaging = admin.messaging();
        console.log('✅ [NotificationService] Firebase Admin inicializado correctamente');
    } else {
        console.warn('⚠️ [NotificationService] No se encontró firebase-service-account.json. Las notificaciones push estarán desactivadas.');
    }
} catch (error) {
    console.error('❌ [NotificationService] Error al inicializar Firebase Admin:', error.message);
}

/**
 * Envía una notificación push a un usuario específico
 * @param {Object} user - Documento del usuario de Mongoose
 * @param {String} title - Título de la notificación
 * @param {String} body - Cuerpo del mensaje
 * @param {Object} data - Datos adicionales (ej: { type: 'chat', chatId: '...' })
 */
const sendPushNotification = async (user, title, body, data = {}) => {
    if (!messaging || !user.fcmToken) {
        return;
    }

    const message = {
        notification: {
            title,
            body
        },
        data: {
            ...data,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        token: user.fcmToken
    };

    try {
        const response = await messaging.send(message);
        console.log(`🚀 [NotificationService] Notificación enviada a ${user.username}:`, response);
        return response;
    } catch (error) {
        console.error(`❌ [NotificationService] Error enviando a ${user.username}:`, error.message);
        // Si el token es inválido, podríamos limpiarlo de la base de datos
        if (error.code === 'messaging/registration-token-not-registered') {
            user.fcmToken = '';
            await user.save();
        }
    }
};

module.exports = {
    sendPushNotification
};
