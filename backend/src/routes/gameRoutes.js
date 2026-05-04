const express = require('express');
const router = express.Router();
const gameController = require('../controllers/gameController');

// Definir la ruta GET /api/games/search
// Se llamará usando /api/games/search?title=nombre_del_juego
router.get('/search', gameController.searchGame);

module.exports = router;
