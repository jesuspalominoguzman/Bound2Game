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

        // --- 1. BUSCAR EN CACHÉ (MONGODB) ---
        const cachedGame = await GameCache.findOne({ title: { $regex: new RegExp(title, 'i') } });

        if (cachedGame) {
            console.log(`⚡ Devolviendo '${cachedGame.title}' desde la caché de MongoDB`);
            // Parche: Si es un juego antiguo en caché que tiene SteamID pero no requisitos, actualizamos
            if (cachedGame.steamAppID && (!cachedGame.pcRequirements || cachedGame.pcRequirements === 'No disponibles')) {
                const steamReq = await gameService.getSteamRequirements(cachedGame.steamAppID);
                if (steamReq) {
                    cachedGame.pcRequirements = steamReq;
                    await cachedGame.save();
                }
            }
            return res.json(cachedGame);
        }

        console.log(`🌐 Buscando '${title}' en APIs externas...`);

        // --- 2. CADENA DE BÚSQUEDA: RAWG → CheapShark → Steam → OpenCritic ---
        let baseData = await gameService.getRawgData(title);
        
        // Si RAWG devuelve algo, usamos ese nombre limpio para las demás tiendas
        const searchTitle = baseData ? baseData.title : title;

        let gameData = await gameService.getCheapSharkData(searchTitle);

        if (!gameData) {
            console.log(`⚠️  CheapShark falló para '${searchTitle}', probando Steam...`);
            gameData = await searchSteamFallback(searchTitle);
        }

        if (!gameData) {
            console.log(`⚠️  Steam falló para '${searchTitle}', probando OpenCritic...`);
            gameData = await searchOpenCriticFallback(searchTitle);
        }

        // --- Combinar resultados ---
        if (!gameData && baseData) {
            // Solo se encontró en RAWG (ej. Smash Bros)
            gameData = {
                title: baseData.title,
                steamAppID: null,
                imageUrl: baseData.imageUrl,
                currentPrice: '0',
                retailPrice: '0',
                cheapestStore: 'N/A',
                lowestPriceEver: '0',
            };
        } else if (gameData && baseData) {
            // Combinar ambos: RAWG tiene mejor título y fondo
            gameData.title = baseData.title;
            if (baseData.imageUrl) {
                gameData.imageUrl = baseData.imageUrl;
            }
        }

        if (!gameData) {
            return res.status(404).json({ error: 'Juego no encontrado.' });
        }

        let pcRequirements = null;
        if (gameData.steamAppID) {
            pcRequirements = await gameService.getSteamRequirements(gameData.steamAppID);
        }

        const playtimeData = await gameService.getHowLongToBeatData(gameData.title);

        // --- 3. CONSTRUIR EL OBJETO A GUARDAR ---
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
            lastPriceUpdate: new Date()
        };

        // --- 4. GUARDAR EN MONGODB Y DEVOLVER ---
        const newGame = new GameCache(newGameData);
        await newGame.save();

        console.log(`✅ Juego '${newGame.title}' guardado en la caché de MongoDB`);
        return res.json(newGame);

    } catch (error) {
        console.error('Error en el controlador searchGame:', error);
        return res.status(500).json({ error: 'Ocurrió un error interno en el servidor.' });
    }
};

module.exports = {
    searchGame
};
