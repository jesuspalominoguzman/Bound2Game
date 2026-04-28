require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

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

// Levantar el servidor
app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en el puerto ${PORT}`);
});
