const axios = require('axios');
const DealCache = require('../models/DealCache');

const STORE_MAP = {
    '1':  'steam',
    '25': 'epic',
    '23': 'nintendo',
    '15': 'psStore',
    '24': 'xbox',
};

// Caché en memoria para los nombres de tiendas
let storeNamesCache = null;

const getStoreNames = async () => {
    if (storeNamesCache) return storeNamesCache;
    try {
        const storesResp = await axios.get('https://www.cheapshark.com/api/1.0/stores');
        storeNamesCache = {};
        storesResp.data.forEach(s => { storeNamesCache[s.storeID] = s.storeName; });
        return storeNamesCache;
    } catch (e) {
        console.error("Error al obtener nombres de tiendas:", e.message);
        return {};
    }
};

/**
 * Obtiene ofertas desde la caché o desde CheapShark
 */
const getDeals = async (limit = 20) => {
    // 1. Buscar en caché (forzar expiración)
    const twelveHoursAgo = new Date(Date.now());
    const cachedDeals = await DealCache.find({ 
        category: 'DEAL',
        updatedAt: { $gte: twelveHoursAgo }
    }).limit(limit);
    if (cachedDeals && cachedDeals.length > 0) {
        console.log(`⚡ Devolviendo ${cachedDeals.length} ofertas desde la caché de MongoDB`);
        return cachedDeals;
    }

    console.log(`🌐 Buscando ofertas en CheapShark API...`);
    
    // 2. Si no hay caché, buscar SIEMPRE el máximo (200) para tener una buena base
    const response = await axios.get(
        `https://www.cheapshark.com/api/1.0/deals?sortBy=DealRating&pageSize=200&onSale=1`
    );
    console.log(`📡 Recibidas ${response.data.length} ofertas de CheapShark`);

    const storeNames = await getStoreNames();

    const newDeals = [];
    for (const deal of response.data) {
        const storeKey = STORE_MAP[deal.storeID] || 'other';

        const storeName = storeNames[deal.storeID] || 'Store';
        
        newDeals.push({
            gameId: deal.gameID || deal.dealID || String(Math.random()),
            title: deal.title || deal.external || 'Unknown',
            originalPrice: parseFloat(deal.normalPrice || deal.retailPrice || '0'),
            salePrice: parseFloat(deal.salePrice || deal.price || '0'),
            storeID: storeKey,
            storeName: storeName,
            thumb: deal.thumb || null,
            category: 'DEAL',
            discountPercent: parseInt(deal.savings || '0', 10),
            isFree: parseFloat(deal.salePrice || deal.price || '1') === 0,
            dealUrl: deal.dealID ? `https://www.cheapshark.com/redirect?dealID=${deal.dealID}` : null,
            steamAppID: deal.steamAppID || null
        });
    }

    // 3. Guardar en caché y devolver
    if (newDeals.length > 0) {
        // Limpiamos la caché anterior de esta categoría por si acaso para no acumular basura si se vuelve a pedir
        await DealCache.deleteMany({ category: 'DEAL' });
        await DealCache.insertMany(newDeals);
        console.log(`💾 Guardadas ${newDeals.length} ofertas en la caché de MongoDB`);
    }

    return newDeals.slice(0, limit);
};

/**
 * Obtiene juegos gratuitos desde la caché o desde CheapShark
 */
const getFreeGames = async () => {
    // 1. Buscar en caché (forzar expiración)
    const twelveHoursAgo = new Date(Date.now());
    const cachedFreeGames = await DealCache.find({ 
        category: 'FREE',
        updatedAt: { $gte: twelveHoursAgo }
    });
    if (cachedFreeGames && cachedFreeGames.length > 0) {
        console.log(`⚡ Devolviendo ${cachedFreeGames.length} juegos gratis desde la caché de MongoDB`);
        return cachedFreeGames;
    }

    console.log(`🌐 Buscando juegos gratuitos en CheapShark API...`);

    // 2. Si no hay caché, buscar en API
    const response = await axios.get(
        'https://www.cheapshark.com/api/1.0/deals?upperPrice=0&pageSize=20'
    );

    const storeNames = await getStoreNames();

    const newFreeGames = [];
    for (const deal of response.data) {
        const storeKey = STORE_MAP[deal.storeID] || 'other';

        const storeName = storeNames[deal.storeID] || 'Store';
        
        newFreeGames.push({
            gameId: deal.gameID || deal.dealID || String(Math.random()),
            title: deal.title || deal.external || 'Unknown',
            originalPrice: parseFloat(deal.normalPrice || deal.retailPrice || '0'),
            salePrice: 0,
            storeID: storeKey,
            storeName: storeName,
            thumb: deal.thumb || null,
            category: 'FREE',
            discountPercent: 100,
            isFree: true,
            dealUrl: deal.dealID ? `https://www.cheapshark.com/redirect?dealID=${deal.dealID}` : null,
            steamAppID: deal.steamAppID || null
        });
    }

    // 3. Guardar en caché y devolver
    if (newFreeGames.length > 0) {
        await DealCache.deleteMany({ category: 'FREE' });
        await DealCache.insertMany(newFreeGames);
        console.log(`💾 Guardados ${newFreeGames.length} juegos gratis en la caché de MongoDB`);
    }

    return newFreeGames;
};

/**
 * Obtiene próximos lanzamientos desde RAWG (juegos con fecha de lanzamiento próxima)
 */
const getUpcomingGames = async () => {
    // 1. Buscar en caché (forzar expiración)
    const twelveHoursAgo = new Date(Date.now());
    const cachedUpcoming = await DealCache.find({ 
        category: 'UPCOMING',
        updatedAt: { $gte: twelveHoursAgo }
    });
    if (cachedUpcoming && cachedUpcoming.length > 0) {
        console.log(`⚡ Devolviendo ${cachedUpcoming.length} próximos lanzamientos desde la caché`);
        return cachedUpcoming;
    }

    console.log(`🌐 Buscando próximos lanzamientos en RAWG...`);

    try {
        const apiKey = process.env.RAWG_API_KEY;
        if (!apiKey) throw new Error('RAWG_API_KEY no configurada');

        const today = new Date().toISOString().split('T')[0];
        const threeMonthsLater = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

        const url = `https://api.rawg.io/api/games?key=${apiKey}&dates=${today},${threeMonthsLater}&ordering=released&page_size=10`;
        const response = await axios.get(url, { timeout: 8000 });

        const upcomingGames = (response.data?.results || []).map(game => ({
            gameId: `rawg_${game.id}`,
            title: game.name,
            originalPrice: 59.99,
            salePrice: 59.99,
            storeID: 'steam',
            storeName: 'Steam',
            thumb: game.background_image || '',
            category: 'UPCOMING',
            discountPercent: 0,
            isFree: false,
            dealUrl: null,
            steamAppID: null,
            releaseDate: game.released || null,
        }));

        if (upcomingGames.length > 0) {
            await DealCache.deleteMany({ category: 'UPCOMING' });
            await DealCache.insertMany(upcomingGames);
            console.log(`💾 Guardados ${upcomingGames.length} próximos lanzamientos de RAWG`);
        }

        return upcomingGames;
    } catch (e) {
        console.error('Error al obtener próximos lanzamientos de RAWG:', e.message);
        // Fallback: devolver los de la caché aunque sean viejos
        const oldCache = await DealCache.find({ category: 'UPCOMING' });
        return oldCache;
    }
};

/**
 * Obtiene las ofertas de un juego específico por título
 */
const getDealsByGame = async (title) => {
    try {
        const searchResponse = await axios.get(`https://www.cheapshark.com/api/1.0/games?title=${encodeURIComponent(title)}`);
        if (!searchResponse.data || searchResponse.data.length === 0) return [];
        
        let bestMatch = searchResponse.data.find(g => g.external.toLowerCase() === title.toLowerCase());
        if (!bestMatch) {
            bestMatch = searchResponse.data.find(g => {
                const name = g.external.toLowerCase();
                return !name.includes('sfx') && !name.includes('soundtrack') && !name.includes('dlc') && !name.includes('pack');
            });
        }
        if (!bestMatch) return [];

        const detailsResponse = await axios.get(`https://www.cheapshark.com/api/1.0/games?id=${bestMatch.gameID}`);
        if (!detailsResponse.data || !detailsResponse.data.deals) return [];

        const storeNames = await getStoreNames();
        
        const mappedDeals = [];
        for (const deal of detailsResponse.data.deals) {
            const storeKey = STORE_MAP[deal.storeID] || 'other';
            const storeName = storeNames[deal.storeID] || 'Store';
            mappedDeals.push({
                gameId: bestMatch.gameID,
                title: bestMatch.external,
                originalPrice: parseFloat(deal.retailPrice || '0'),
                salePrice: parseFloat(deal.price || '0'),
                storeID: storeKey,
                storeName: storeName,
                thumb: detailsResponse.data.info.thumb || null,
                category: 'DEAL',
                discountPercent: parseInt(deal.savings || '0', 10),
                isFree: parseFloat(deal.price || '1') === 0,
                dealUrl: deal.dealID ? `https://www.cheapshark.com/redirect?dealID=${deal.dealID}` : null,
                steamAppID: null
            });
        }
        return mappedDeals;
    } catch (e) {
        console.error('Error al obtener deals por juego:', e.message);
        return [];
    }
};

module.exports = {
    getDeals,
    getFreeGames,
    getUpcomingGames,
    getDealsByGame
};
