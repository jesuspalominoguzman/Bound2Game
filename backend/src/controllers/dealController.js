const dealService = require('../services/dealService');

/**
 * GET /api/games/deals?limit=100
 * Obtiene los mejores deals actuales de CheapShark
 */
const getDeals = async (req, res) => {
    try {
        const limit = Math.min(parseInt(req.query.limit || '100', 10), 200);
        const deals = await dealService.getDeals(limit);
        return res.json({ deals });
    } catch (error) {
        console.error('Error en dealController.getDeals:', error.message);
        return res.status(500).json({ error: 'Error al obtener deals.' });
    }
};

/**
 * GET /api/games/free
 * Obtiene los juegos gratuitos activos
 */
const getFreeGames = async (req, res) => {
    try {
        const freeGames = await dealService.getFreeGames();
        return res.json({ freeGames });
    } catch (error) {
        console.error('Error en dealController.getFreeGames:', error.message);
        return res.status(500).json({ error: 'Error al obtener juegos gratuitos.' });
    }
};

/**
 * GET /api/games/upcoming
 * Obtiene los próximos lanzamientos
 */
const getUpcomingGames = async (req, res) => {
    try {
        const upcomingGames = await dealService.getUpcomingGames();
        return res.json({ upcomingGames });
    } catch (error) {
        console.error('Error en dealController.getUpcomingGames:', error.message);
        return res.status(500).json({ error: 'Error al obtener próximos lanzamientos.' });
    }
};

/**
 * GET /api/games/deals/:title
 * Obtiene las ofertas de un juego específico
 */
const getDealsByGame = async (req, res) => {
    try {
        const { title } = req.params;
        if (!title) return res.status(400).json({ error: 'Título es requerido' });
        
        const deals = await dealService.getDealsByGame(title);
        return res.json({ deals });
    } catch (error) {
        console.error('Error en dealController.getDealsByGame:', error.message);
        return res.status(500).json({ error: 'Error al obtener deals del juego.' });
    }
};

module.exports = {
    getDeals,
    getFreeGames,
    getUpcomingGames,
    getDealsByGame
};
