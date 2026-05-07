const gameService = require('../services/gameService');
const GameCache = require('../models/GameCache');
const axios = require('axios');

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

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/games/deals?limit=20
// Devuelve los mejores deals actuales de CheapShark normalizados para Flutter
// ─────────────────────────────────────────────────────────────────────────────

// Mapa de storeID de CheapShark a nombre interno de Flutter
const STORE_MAP = {
    '1':  'steam',
    '25': 'epic',
    '23': 'nintendo',
    '15': 'psStore',
    '24': 'xbox',
    '27': 'instantGaming',
};

const _normalizeDeal = (deal, storeName, storeKey) => ({
    gameId:          deal.gameID  || deal.dealID || String(Math.random()),
    gameTitle:       deal.title   || deal.external || 'Unknown',
    gameCover:       deal.thumb   || null,
    store:           storeKey,
    storeName:       storeName,
    originalPrice:   parseFloat(deal.normalPrice || deal.retailPrice || '0'),
    salePrice:       parseFloat(deal.salePrice   || deal.price       || '0'),
    discountPercent: parseInt(deal.savings       || '0', 10),
    isFree:          parseFloat(deal.salePrice   || deal.price || '1') === 0,
    dealUrl:         deal.dealID
        ? `https://www.cheapshark.com/redirect?dealID=${deal.dealID}`
        : null,
    steamAppID:      deal.steamAppID || null,
});

const getDeals = async (req, res) => {
    try {
        const limit = Math.min(parseInt(req.query.limit || '20', 10), 60);

        // Pedir deals ordenados por rating (mejor relación calidad/precio)
        const response = await axios.get(
            `https://www.cheapshark.com/api/1.0/deals?sortBy=DealRating&pageSize=${limit}&onSale=1`
        );

        // Obtener nombres de tiendas
        const storesResp = await axios.get('https://www.cheapshark.com/api/1.0/stores');
        const storeNames = {};
        storesResp.data.forEach(s => { storeNames[s.storeID] = s.storeName; });

        const deals = response.data.map(deal => {
            const storeKey  = STORE_MAP[deal.storeID] || 'steam';
            const storeName = storeNames[deal.storeID] || 'Steam';
            return _normalizeDeal(deal, storeName, storeKey);
        });

        return res.json({ deals });
    } catch (error) {
        console.error('Error en getDeals:', error.message);
        return res.status(500).json({ error: 'Error al obtener deals de CheapShark' });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/games/free
// Devuelve ÚNICAMENTE los juegos gratuitos activos (salePrice = 0.00)
// ─────────────────────────────────────────────────────────────────────────────
const getFreeGames = async (req, res) => {
    try {
        // CheapShark filtra por upperPrice=0 para juegos 100% gratis
        const response = await axios.get(
            'https://www.cheapshark.com/api/1.0/deals?upperPrice=0&pageSize=20'
        );

        const storesResp = await axios.get('https://www.cheapshark.com/api/1.0/stores');
        const storeNames = {};
        storesResp.data.forEach(s => { storeNames[s.storeID] = s.storeName; });

        const freeGames = response.data.map(deal => {
            const storeKey  = STORE_MAP[deal.storeID] || 'steam';
            const storeName = storeNames[deal.storeID] || 'Steam';
            return {
                ..._normalizeDeal(deal, storeName, storeKey),
                isFree:          true,
                discountPercent: 100,
                salePrice:       0,
            };
        });

        return res.json({ freeGames });
    } catch (error) {
        console.error('Error en getFreeGames:', error.message);
        return res.status(500).json({ error: 'Error al obtener juegos gratuitos' });
    }
};

module.exports = {
    searchGame,
    getDeals,
    getFreeGames,
};
