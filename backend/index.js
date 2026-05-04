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
const MONGO_URI = process.env.MONGO_URI || 'mongodb://database:27017/bound2game';

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

// ── Levantar el servidor con soporte WebSocket ────────────────────────────
// Envolvemos Express en un servidor HTTP nativo para que Socket.io pueda
// compartir el mismo puerto sin cambiar ninguna ruta REST existente.
const server = http.createServer(app);  // ← AÑADIDO (Fase III)
const io = new Server(server, {         // ← AÑADIDO (Fase III)
    cors: { origin: '*', methods: ['GET', 'POST'] },
});

// Inicializar namespace de chat
chatSocket(io);                         // ← AÑADIDO (Fase III)

server.listen(PORT, () => {             // ← AÑADIDO (Fase III — reemplaza app.listen)
    console.log(`🚀 Servidor corriendo en el puerto ${PORT}`);
});
