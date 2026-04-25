const gameService = require('../services/gameService');

/**
 * Orquesta la búsqueda de información de un juego en múltiples APIs
 * y devuelve un JSON unificado.
 */
const searchGame = async (req, res) => {
    try {
        const { title } = req.query;

        if (!title) {
            return res.status(400).json({ error: 'El parámetro "title" es obligatorio.' });
        }

        // 1. Obtener datos básicos de CheapShark (precios y steamAppID)
        const gameData = await gameService.getCheapSharkData(title);

        if (!gameData) {
            return res.status(404).json({ error: 'Juego no encontrado en la base de datos de precios.' });
        }

        // 2. Obtener requisitos de PC desde Steam (si tenemos el ID de Steam)
        let pcRequirements = null;
        if (gameData.steamAppID) {
            pcRequirements = await gameService.getSteamRequirements(gameData.steamAppID);
        }

        // 3. Obtener tiempo de juego desde HowLongToBeat (principal y 100%)
        const playtimeData = await gameService.getHowLongToBeatData(title);

        // 4. Construir la respuesta unificada
        const responseData = {
            title: gameData.title,
            retailPrice: gameData.retailPrice,
            currentPrice: gameData.currentPrice,
            cheapestStore: gameData.cheapestStore,
            lowestPriceEver: gameData.lowestPriceEver,
            mainStoryTimeHours: playtimeData.main,
            completionistTimeHours: playtimeData.completionist,
            pcRequirements: pcRequirements || "No disponibles"
        };

        // Devolver el JSON final
        return res.json(responseData);

    } catch (error) {
        console.error('Error en el controlador searchGame:', error);
        return res.status(500).json({ error: 'Ocurrió un error interno en el servidor.' });
    }
};

module.exports = {
    searchGame
};
