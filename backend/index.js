require('dotenv').config();
const express = require('express');
const http    = require('http');          // ← AÑADIDO (Fase III)
const { Server } = require('socket.io'); // ← AÑADIDO (Fase III)
const mongoose = require('mongoose');
const cors = require('cors');

// Socket controllers
const chatSocket = require('./sockets/chat.socket'); // ← AÑADIDO (Fase III)

// Rutas
const gameRoutes = require('./src/routes/gameRoutes');
const userRoutes = require('./src/routes/userRoutes');

// Inicializamos la app de Express
const app = express();

// Middlewares (Para entender JSON y permitir peticiones desde Flutter)
app.use(cors());
app.use(express.json());

// Puerto y URI de conexión (Preparado para funcionar con Docker)
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://Jpalominoo:Bound2Game@cluster0.ptmyjlc.mongodb.net/bound2game?retryWrites=true&w=majority&appName=Cluster0';

// Conexión a MongoDB (Ahora ACTIVADA)
mongoose.connect(MONGO_URI)
    .then(() => console.log('🟢 Conectado a la base de datos de Bound2Game (MongoDB)'))
    .catch(err => console.error('🔴 Error al conectar a MongoDB:', err));

// Rutas base
app.use('/api/games', gameRoutes);
app.use('/api/users', userRoutes);

// Ruta de prueba
app.get('/', (req, res) => {
    res.json({ mensaje: '¡El backend de Bound2Game está funcionando perfectamente!' });
});

// ── Rutas para Verificación de Deep Linking (HTTPS App Links) ───────────────
// Android: Verifica que esta app es la dueña del dominio
app.get('/.well-known/assetlinks.json', (req, res) => {
    res.json([{
        "relation": ["delegate_permission/common.handle_all_urls"],
        "target": {
            "namespace": "android_app",
            "package_name": "com.example.frontend",
            // TODO: El usuario debe poner su SHA256 real aquí para producción
            "sha256_cert_fingerprints": ["FA:C6:17:45:DC:09:03:78:6F:B9:ED:46:29:0D:96:9B:03:9F:99:7D:6A:10:26:11:05:0F:50:42:8C:45:93:13"]
        }
    }]);
});

// iOS: Universal Links
app.get('/.well-known/apple-app-site-association', (req, res) => {
    res.set('Content-Type', 'application/json');
    res.json({
        "applinks": {
            "apps": [],
            "details": [{
                "appID": "YOUR_TEAM_ID.com.example.frontend",
                "paths": ["/user/*"]
            }]
        }
    });
});

// ── Levantar el servidor con soporte WebSocket ────────────────────────────
// Envolvemos Express en un servidor HTTP nativo para que Socket.io pueda
// compartir el mismo puerto sin cambiar ninguna ruta REST existente.
const server = http.createServer(app);  // ← AÑADIDO (Fase III)
const io = new Server(server, {         // ← AÑADIDO (Fase III)
    cors: { origin: '*', methods: ['GET', 'POST'] },
    // Configuración agresiva de heartbeat (hilo de comprobación de conexión)
    // El servidor hace "ping" cada 5s y si no hay respuesta en 5s, emite 'disconnect'
    pingInterval: 5000,
    pingTimeout: 5000,
});

// Hacer accesible la instancia de io en la app de express
app.set('io', io);

// Inicializar namespace de chat
chatSocket(io);                         // ← AÑADIDO (Fase III)

server.listen(PORT, '0.0.0.0', () => {             // ← MODIFICADO para dispositivos físicos
    console.log(`🚀 Servidor corriendo en http://0.0.0.0:${PORT}`);
});
