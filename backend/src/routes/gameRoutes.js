const express = require('express');
const router = express.Router();
const gameController = require('../controllers/gameController');
const dealController = require('../controllers/dealController');

// GET /api/games/search?title=nombre_del_juego
router.get('/search', gameController.searchGame);

// GET /api/games/deals?limit=20   → Top deals de CheapShark (ahora con caché)
router.get('/deals', dealController.getDeals);

// GET /api/games/free             → Juegos gratuitos activos (ahora con caché)
router.get('/free', dealController.getFreeGames);

// GET /api/games/upcoming         → Próximos lanzamientos
router.get('/upcoming', dealController.getUpcomingGames);

// GET /api/games/deals/:title     → Ofertas para un juego específico
router.get('/deals/:title', dealController.getDealsByGame);

module.exports = router;
