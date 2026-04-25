require('dotenv').config();
const express = require('express');
const cors = require('cors');

const gameRoutes = require('./src/routes/gameRoutes');

// Inicializamos la app de Express
const app = express();

// Middlewares (Para entender JSON y permitir peticiones desde Flutter)
app.use(cors());
app.use(express.json());

// Puerto
const PORT = process.env.PORT || 3000;

// Rutas base
app.use('/api/games', gameRoutes);

// Ruta de prueba
app.get('/', (req, res) => {
    res.json({ mensaje: '¡El backend de Bound2Game está funcionando perfectamente!' });
});

// Levantar el servidor
app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en el puerto ${PORT}`);
});