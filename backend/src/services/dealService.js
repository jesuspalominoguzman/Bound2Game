const axios = require('axios');
const DealCache = require('../models/DealCache');

const STORE_MAP = {
    '1':  'steam',
    '25': 'epic',
    '23': 'nintendo',
    '15': 'psStore',
    '24': 'xbox',
    '27': 'instantGaming',
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
    // 1. Buscar en caché
    const cachedDeals = await DealCache.find({ category: 'DEAL' }).limit(limit);
    if (cachedDeals && cachedDeals.length > 0) {
        console.log(`⚡ Devolviendo ${cachedDeals.length} ofertas desde la caché de MongoDB`);
        return cachedDeals;
    }

    console.log(`🌐 Buscando ofertas en CheapShark API...`);
    
    // 2. Si no hay caché, buscar en API
    const response = await axios.get(
        `https://www.cheapshark.com/api/1.0/deals?sortBy=DealRating&pageSize=${limit}&onSale=1`
    );

    const storeNames = await getStoreNames();

    const newDeals = response.data.map(deal => {
        const storeKey = STORE_MAP[deal.storeID] || 'steam';
        const storeName = storeNames[deal.storeID] || 'Steam';
        
        return {
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
        };
    });

    // 3. Guardar en caché y devolver
    if (newDeals.length > 0) {
        // Limpiamos la caché anterior de esta categoría por si acaso para no acumular basura si se vuelve a pedir
        await DealCache.deleteMany({ category: 'DEAL' });
        await DealCache.insertMany(newDeals);
        console.log(`💾 Guardadas ${newDeals.length} ofertas en la caché de MongoDB`);
    }

    return newDeals;
};

/**
 * Obtiene juegos gratuitos desde la caché o desde CheapShark
 */
const getFreeGames = async () => {
    // 1. Buscar en caché
    const cachedFreeGames = await DealCache.find({ category: 'FREE' });
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

    const newFreeGames = response.data.map(deal => {
        const storeKey = STORE_MAP[deal.storeID] || 'steam';
        const storeName = storeNames[deal.storeID] || 'Steam';
        
        return {
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
        };
    });

    // 3. Guardar en caché y devolver
    if (newFreeGames.length > 0) {
        await DealCache.deleteMany({ category: 'FREE' });
        await DealCache.insertMany(newFreeGames);
        console.log(`💾 Guardados ${newFreeGames.length} juegos gratis en la caché de MongoDB`);
    }

    return newFreeGames;
};

/**
 * Obtiene próximos lanzamientos desde la caché o usa datos simulados
 */
const getUpcomingGames = async () => {
    // 1. Buscar en caché
    const cachedUpcoming = await DealCache.find({ category: 'UPCOMING' });
    if (cachedUpcoming && cachedUpcoming.length > 0) {
        console.log(`⚡ Devolviendo ${cachedUpcoming.length} próximos lanzamientos desde la caché de MongoDB`);
        return cachedUpcoming;
    }

    console.log(`🌐 Generando próximos lanzamientos simulados...`);

    // 2. Generar datos simulados ya que CheapShark no tiene endpoint directo para 'Upcoming'
    const upcomingMockData = [
        {
            gameId: 'upc1',
            title: 'Grand Theft Auto VI',
            originalPrice: 69.99,
            salePrice: 69.99,
            storeID: 'steam',
            storeName: 'Steam',
            thumb: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co6mnc.png',
            category: 'UPCOMING',
            discountPercent: 0,
            isFree: false,
            dealUrl: null,
            steamAppID: null
        },
        {
            gameId: 'upc2',
            title: 'Hollow Knight: Silksong',
            originalPrice: 29.99,
            salePrice: 29.99,
            storeID: 'steam',
            storeName: 'Steam',
            thumb: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x7e.png',
            category: 'UPCOMING',
            discountPercent: 0,
            isFree: false,
            dealUrl: null,
            steamAppID: null
        },
        {
            gameId: 'upc3',
            title: 'Fable',
            originalPrice: 59.99,
            salePrice: 59.99,
            storeID: 'xbox',
            storeName: 'Xbox',
            thumb: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co2l0q.png',
            category: 'UPCOMING',
            discountPercent: 0,
            isFree: false,
            dealUrl: null,
            steamAppID: null
        }
    ];

    // 3. Guardar en caché y devolver
    if (upcomingMockData.length > 0) {
        await DealCache.deleteMany({ category: 'UPCOMING' });
        await DealCache.insertMany(upcomingMockData);
        console.log(`💾 Guardados ${upcomingMockData.length} próximos lanzamientos en la caché de MongoDB`);
    }

    return upcomingMockData;
};

module.exports = {
    getDeals,
    getFreeGames,
    getUpcomingGames
};
