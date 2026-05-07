const express = require('express');
const router = express.Router();
const gameController = require('../controllers/gameController');

// GET /api/games/search?title=nombre_del_juego
router.get('/search', gameController.searchGame);

// GET /api/games/deals?limit=20   → Top deals de CheapShark
router.get('/deals',  gameController.getDeals);

// GET /api/games/free             → Juegos gratuitos activos
router.get('/free',   gameController.getFreeGames);

module.exports = router;
