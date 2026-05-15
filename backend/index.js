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

// ── Página de aterrizaje para Deep Linking (Fallback Navegador) ──────────────
// Si el App Link falla y el usuario cae en el navegador, le damos un botón
// para forzar la apertura de la app mediante el esquema custom.
app.get('/user/:userId', (req, res) => {
    const userId = req.params.userId;
    res.send(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Abriendo Bound2Game...</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { 
            background: #0A0A0A; 
            color: white; 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; 
            display: flex; 
            flex-direction: column; 
            align-items: center; 
            justify-content: center; 
            height: 100vh; 
            margin: 0; 
            text-align: center;
          }
          .card {
            background: #161616;
            padding: 40px;
            border-radius: 24px;
            border: 1px solid #222;
            box-shadow: 0 20px 40px rgba(0,0,0,0.4);
            max-width: 320px;
            width: 90%;
          }
          .logo { 
            width: 80px; 
            height: 80px;
            background: #FFB800;
            border-radius: 20px; 
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 40px;
            box-shadow: 0 10px 20px rgba(255, 184, 0, 0.2);
          }
          h2 { margin: 0 0 10px 0; font-size: 24px; font-weight: 800; }
          p { color: #888; font-size: 15px; margin-bottom: 30px; line-height: 1.5; }
          .btn { 
            background: #FFB800; 
            color: black; 
            padding: 16px 40px; 
            border-radius: 14px; 
            text-decoration: none; 
            font-weight: 800; 
            font-size: 16px; 
            display: inline-block;
            transition: transform 0.2s;
          }
          .btn:active { transform: scale(0.96); }
        </style>
        <script>
          // Intentar redirigir automáticamente al abrir la página
          setTimeout(() => {
            window.location.href = "bound2game://user/${userId}";
          }, 500);
        </script>
      </head>
      <body>
        <div class="card">
          <div class="logo">🎮</div>
          <h2>Bound2Game</h2>
          <p>Te hemos enviado un perfil para que lo veas en la aplicación.</p>
          <a href="bound2game://user/${userId}" class="btn">ABRIR EN LA APP</a>
        </div>
      </body>
      </html>
    `);
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
