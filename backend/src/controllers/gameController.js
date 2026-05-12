const gameService = require('../services/gameService');
const GameCache = require('../models/GameCache');
const axios = require('axios');

// ──────────────────────────────────────────────────────────────────────────────
// Fallback 1: Steam Store Search (sin rate limit, solo juegos de PC/Steam)
// ──────────────────────────────────────────────────────────────────────────────
const searchSteamFallback = async (title) => {
    try {
        const url = `https://store.steampowered.com/api/storesearch/?term=${encodeURIComponent(title)}&l=english&cc=US`;
        const resp = await axios.get(url, { timeout: 8000 });
        const items = resp.data?.items;
        if (!items || items.length === 0) return null;

        const exact = items.find(i => i.name.toLowerCase() === title.toLowerCase());
        const best = exact || items[0];

        return {
            title: best.name,
            steamAppID: best.id?.toString(),
            retailPrice: best.price?.final ? (best.price.final / 100).toFixed(2) : '0',
            currentPrice: best.price?.final ? (best.price.final / 100).toFixed(2) : '0',
            cheapestStore: 'Steam',
            lowestPriceEver: '0',
            imageUrl: best.tiny_image || `https://cdn.akamai.steamstatic.com/steam/apps/${best.id}/header.jpg`,
        };
    } catch (e) {
        console.error('Steam fallback failed:', e.message);
        return null;
    }
};

// ──────────────────────────────────────────────────────────────────────────────
// Fallback 2: OpenCritic — cubre TODAS las plataformas (Nintendo, PS, Xbox…)
// No requiere API key. Devuelve título + portada.
// ──────────────────────────────────────────────────────────────────────────────
const searchOpenCriticFallback = async (title) => {
    try {
        const url = `https://api.opencritic.com/api/game/search?criteria=${encodeURIComponent(title)}`;
        const resp = await axios.get(url, {
            timeout: 8000,
            headers: { 'User-Agent': 'Bound2Game/1.0 (game tracker app)' }
        });
        if (!Array.isArray(resp.data) || resp.data.length === 0) return null;

        const exact = resp.data.find(g => g.name.toLowerCase() === title.toLowerCase());
        const best = exact || resp.data[0];

        const imgBase = 'https://img.opencritic.com/';
        let imageUrl = '';
        if (best.images?.box?.sm) imageUrl = imgBase + best.images.box.sm;
        else if (best.images?.box?.og) imageUrl = imgBase + best.images.box.og;

        return {
            title: best.name,
            steamAppID: null,
            imageUrl,
            currentPrice: '0',
            retailPrice: '0',
            cheapestStore: 'N/A',
            lowestPriceEver: '0',
        };
    } catch (e) {
        console.error('OpenCritic fallback failed:', e.message);
        return null;
    }
};

/**
 * Orquesta la búsqueda de información de un juego en múltiples APIs
 * y devuelve un JSON unificado, utilizando MongoDB como caché.
 * Cadena: MongoDB caché → CheapShark → Steam → OpenCritic
 */
const searchGame = async (req, res) => {
    try {
        const { title } = req.query;

        if (!title) {
            return res.status(400).json({ error: 'El parámetro "title" es obligatorio.' });
        }

        console.log(`🌐 Buscando '${title}' en APIs externas...`);

        // --- 1. Obtener hasta 5 resultados básicos de RAWG ---
        const rawgResults = await gameService.getRawgData(title);
        
        // Si RAWG no devuelve nada, intentamos buscar en caché al menos
        if (!rawgResults || rawgResults.length === 0) {
            const cachedGames = await GameCache.find({ title: { $regex: new RegExp(title, 'i') } }).limit(5);
            if (cachedGames.length > 0) return res.json(cachedGames);
            return res.status(404).json({ error: 'Juego no encontrado.' });
        }

        const finalResults = [];

        // --- 2. Procesar los resultados de RAWG (en paralelo para mayor velocidad) ---
        await Promise.all(rawgResults.map(async (baseData) => {
            // Comprobar si ya está en caché por título exacto
            let cachedGame = await GameCache.findOne({ title: baseData.title });
            
            if (cachedGame) {
                // Parche: actualizar plataformas si faltan
                if (!cachedGame.rawgPlatforms || cachedGame.rawgPlatforms.length === 0) {
                    cachedGame.rawgPlatforms = baseData.rawgPlatforms;
                    await cachedGame.save();
                }
                finalResults.push(cachedGame);
                return;
            }

            // Si no está en caché, buscamos datos adicionales (CheapShark, Steam, HLTB)
            const searchTitle = baseData.title;
            let gameData = await gameService.getCheapSharkData(searchTitle);
            
            if (!gameData) {
                gameData = await searchSteamFallback(searchTitle);
            }
            if (!gameData) {
                gameData = await searchOpenCriticFallback(searchTitle);
            }
            
            if (!gameData) {
                gameData = {
                    title: baseData.title,
                    steamAppID: null,
                    imageUrl: baseData.imageUrl,
                    currentPrice: '0',
                    retailPrice: '0',
                    cheapestStore: 'N/A',
                    lowestPriceEver: '0',
                };
            } else {
                gameData.title = baseData.title; // Forzar el título bonito de RAWG
                if (baseData.imageUrl) {
                    gameData.imageUrl = baseData.imageUrl;
                }
            }

            let pcRequirements = null;
            if (gameData.steamAppID) {
                pcRequirements = await gameService.getSteamRequirements(gameData.steamAppID);
            }

            const playtimeData = await gameService.getHowLongToBeatData(gameData.title);

            // Construir el objeto a guardar
            const newGameData = {
                title: gameData.title,
                steamAppID: gameData.steamAppID || null,
                imageUrl: gameData.imageUrl || (gameData.steamAppID
                    ? `https://cdn.akamai.steamstatic.com/steam/apps/${gameData.steamAppID}/header.jpg`
                    : ''),
                retailPrice: gameData.retailPrice,
                currentPrice: gameData.currentPrice,
                cheapestStore: gameData.cheapestStore,
                lowestPriceEver: gameData.lowestPriceEver,
                hltb: {
                    mainStory: playtimeData.main,
                    completionist: playtimeData.completionist
                },
                pcRequirements: pcRequirements || 'No disponibles',
                rawgPlatforms: baseData.rawgPlatforms || [],
                lastPriceUpdate: new Date()
            };

            const newGame = new GameCache(newGameData);
            await newGame.save();
            console.log(`✅ Juego '${newGame.title}' guardado en la caché de MongoDB`);
            finalResults.push(newGame);
        }));

        // Mantener el orden original de RAWG tanto como sea posible
        finalResults.sort((a, b) => {
            const indexA = rawgResults.findIndex(r => r.title === a.title);
            const indexB = rawgResults.findIndex(r => r.title === b.title);
            return indexA - indexB;
        });

        return res.json(finalResults);

    } catch (error) {
        console.error('Error en el controlador searchGame:', error);
        return res.status(500).json({ error: 'Ocurrió un error interno en el servidor.' });
    }
};

module.exports = {
    searchGame
};
