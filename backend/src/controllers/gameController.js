const gameService = require('../services/gameService');
const GameCache = require('../models/GameCache');

/**
 * Orquesta la búsqueda de información de un juego en múltiples APIs
 * y devuelve un JSON unificado, utilizando MongoDB como caché.
 */
const searchGame = async (req, res) => {
    try {
        const { title } = req.query;

        if (!title) {
            return res.status(400).json({ error: 'El parámetro "title" es obligatorio.' });
        }

        // --- 1. BUSCAR EN CACHÉ (MONGODB) ---
        // Usamos una expresión regular para buscar sin importar mayúsculas/minúsculas
        const cachedGame = await GameCache.findOne({ title: { $regex: new RegExp(`^${title}$`, "i") } });

        if (cachedGame) {
            console.log(`⚡ Devolviendo '${cachedGame.title}' desde la caché de MongoDB`);
            return res.json(cachedGame);
        }

        console.log(`🌐 Buscando '${title}' en APIs externas...`);

        // --- 2. SI NO EXISTE EN CACHÉ, BUSCAR EN APIS EXTERNAS ---
        const gameData = await gameService.getCheapSharkData(title);

        if (!gameData) {
            return res.status(404).json({ error: 'Juego no encontrado en la base de datos de precios.' });
        }

        let pcRequirements = null;
        if (gameData.steamAppID) {
            pcRequirements = await gameService.getSteamRequirements(gameData.steamAppID);
        }

        const playtimeData = await gameService.getHowLongToBeatData(title);

        // --- 3. CONSTRUIR EL OBJETO A GUARDAR ---
        const newGameData = {
            title: gameData.title,
            steamAppID: gameData.steamAppID || null,
            retailPrice: gameData.retailPrice,
            currentPrice: gameData.currentPrice,
            cheapestStore: gameData.cheapestStore,
            lowestPriceEver: gameData.lowestPriceEver,
            hltb: {
                mainStory: playtimeData.main,
                completionist: playtimeData.completionist
            },
            pcRequirements: pcRequirements || "No disponibles",
            lastPriceUpdate: new Date()
        };

        // --- 4. GUARDAR EN MONGODB Y DEVOLVER ---
        const newGame = new GameCache(newGameData);
        await newGame.save();

        console.log(`💾 Juego '${newGame.title}' guardado en la caché de MongoDB`);
        return res.json(newGame);

    } catch (error) {
        console.error('Error en el controlador searchGame:', error);
        return res.status(500).json({ error: 'Ocurrió un error interno en el servidor.' });
    }
};

module.exports = {
    searchGame
};
