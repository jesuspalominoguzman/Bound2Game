const mongoose    = require('mongoose');
const UserLibrary = require('../models/UserLibrary');
const GameCache   = require('../models/GameCache');
const gameService = require('../services/gameService');
const User        = require('../models/User');

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/users/:userId/library
// Devuelve todas las entradas de la biblioteca del usuario con datos del juego
// ─────────────────────────────────────────────────────────────────────────────
const getUserLibrary = async (req, res) => {
    try {
        const { userId } = req.params;

        const entries = await UserLibrary.find({ userId })
            .populate('gameId')
            .sort({ addedAt: -1 });

        return res.json({ library: entries });
    } catch (error) {
        console.error('Error en getUserLibrary:', error);
        return res.status(500).json({ error: 'Error interno al obtener la biblioteca' });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/users/:userId/library
// Añade un juego a la biblioteca del usuario buscando por API
// Body: { gameName, platform?, status? }
// ─────────────────────────────────────────────────────────────────────────────
const addGameToLibrary = async (req, res) => {
    try {
        const { userId } = req.params;
        const { gameName: rawGameName, gameTitle, platform = 'PC', status = 'Backlog' } = req.body;
        const gameName = rawGameName || gameTitle;

        if (!gameName) {
            return res.status(400).json({ error: 'gameName es obligatorio' });
        }

        // 1. Buscar primero en la caché de MongoDB (evita rate limits de APIs externas)
        let gameCache = await GameCache.findOne({ title: { $regex: new RegExp(gameName, 'i') } });

        // 2. Si no está en caché, buscar en APIs externas y guardar
        if (!gameCache) {
            console.log(`📡 Buscando '${gameName}' en APIs externas para añadir a biblioteca...`);
            const gameData = await gameService.searchGame(gameName);

            if (!gameData) {
                return res.status(404).json({ error: 'Juego no encontrado. Prueba con el nombre exacto en inglés.' });
            }

            const steamId = gameData.steamAppID || gameData.id || null;
            const imageUrl = gameData.imageUrl || gameData.image ||
                (steamId ? `https://cdn.akamai.steamstatic.com/steam/apps/${steamId}/header.jpg` : '');

            gameCache = new GameCache({
                title:        gameData.title || gameData.name,
                steamAppID:   steamId,
                imageUrl,
                currentPrice:    gameData.currentPrice || gameData.price || '0',
                retailPrice:     gameData.retailPrice || '0',
                cheapestStore:   gameData.cheapestStore || 'N/A',
                lowestPriceEver: gameData.lowestPriceEver || '0',
                hltb: {
                    mainStory:     gameData.mainTime || null,
                    completionist: null
                },
                lastPriceUpdate: Date.now()
            });
            await gameCache.save();
        }

        // 3. Comprobar si ya existe en la biblioteca
        const existing = await UserLibrary.findOne({ userId, gameId: gameCache._id });
        if (existing) {
            return res.status(409).json({ error: 'El juego ya está en tu biblioteca' });
        }

        // 4. Añadir a la biblioteca del usuario
        const entry = new UserLibrary({
            userId,
            gameId:   gameCache._id,
            // Rellenamos gameDetails para retrocompatibilidad con código antiguo
            gameDetails: {
                name:        gameCache.title,
                id:          gameCache.steamAppID || '',
                image:       gameCache.imageUrl || '',
                mainTime:    gameCache.hltb?.mainStory || null,
                price:       parseFloat(gameCache.currentPrice) || 0,
                rentability: 0,
            },
            platform,
            status
        });
        await entry.save();

        return res.status(201).json({
            message: 'Juego añadido a la biblioteca',
            entry
        });
    } catch (error) {
        console.error('Error en addGameToLibrary:', error);
        return res.status(500).json({ error: 'Error interno al añadir el juego' });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/users/:userId/library/:entryId
// Devuelve los detalles de un juego y evalúa la compatibilidad
// ─────────────────────────────────────────────────────────────────────────────
const getGameDetails = async (req, res) => {
    try {
        const { userId, entryId } = req.params;

        const entry = await UserLibrary.findOne({ _id: entryId, userId }).populate('gameId');
        if (!entry) {
            return res.status(404).json({ error: 'Entrada no encontrada' });
        }

        // Obtener usuario para comparar componentes
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Parche: Si es un juego antiguo en la biblioteca que tiene SteamID pero no requisitos HTML, actualizamos
        if (entry.gameId && entry.gameId.steamAppID && (!entry.gameId.pcRequirements || entry.gameId.pcRequirements === 'No disponibles')) {
            const steamReq = await gameService.getSteamRequirements(entry.gameId.steamAppID);
            if (steamReq) {
                entry.gameId.pcRequirements = steamReq;
                await entry.gameId.save();
            }
        }

        const requirements = entry.gameId ? entry.gameId.requirements : null;
        const compatibility = gameService.compareRequirements(user.pcComponents, requirements);

        return res.status(200).json({
            entry,
            compatibility
        });
    } catch (error) {
        console.error('Error en getGameDetails:', error);
        return res.status(500).json({ error: 'Error interno al obtener los detalles del juego' });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/users/:userId/library/:entryId
// Actualiza el estado y/o nota personal de una entrada
// Body: { status?, personalNote? }
// ─────────────────────────────────────────────────────────────────────────────
const updateEntry = async (req, res) => {
    try {
        const { userId, entryId } = req.params;
        const { status, personalNote } = req.body;

        const update = {};
        if (status       !== undefined) update.status       = status;
        if (personalNote !== undefined) update.personalNote = personalNote;

        const entry = await UserLibrary.findOneAndUpdate(
            { _id: entryId, userId },
            { $set: update },
            { new: true },
        );

        if (!entry) {
            return res.status(404).json({ error: 'Entrada no encontrada' });
        }

        return res.json({ message: 'Entrada actualizada', entry });
    } catch (error) {
        console.error('Error en updateEntry:', error);
        return res.status(500).json({ error: 'Error interno al actualizar la entrada' });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/users/:userId/library/:entryId
// Elimina un juego de la biblioteca
// ─────────────────────────────────────────────────────────────────────────────
const removeGame = async (req, res) => {
    try {
        const { userId, entryId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(entryId)) {
            return res.status(400).json({ error: 'ID de entrada inválido' });
        }

        const deleted = await UserLibrary.findOneAndDelete({ _id: entryId, userId });

        if (!deleted) {
            return res.status(404).json({ error: 'Entrada no encontrada' });
        }

        return res.json({ message: 'Juego eliminado de la biblioteca' });
    } catch (error) {
        console.error('Error en removeGame:', error);
        return res.status(500).json({ error: 'Error interno al eliminar el juego' });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/users/:userId/stats
// Estadísticas resumidas de la biblioteca del usuario
// ─────────────────────────────────────────────────────────────────────────────
const getStats = async (req, res) => {
    try {
        const { userId } = req.params;

        const entries = await UserLibrary.find({ userId }).populate('gameId');

        const total       = entries.length;
        const completed   = entries.filter(e => e.status === 'Completed').length;
        const playing     = entries.filter(e => e.status === 'Playing').length;
        const backlog     = entries.filter(e => e.status === 'Backlog').length;
        const abandoned   = entries.filter(e => e.status === 'Abandoned').length;

        // Sumar horas HLTB (mainStory) como estimación de horas jugadas
        const estimatedHours = entries.reduce((acc, e) => {
            const h = e.gameId?.hltb?.mainStory;
            return acc + (typeof h === 'number' ? h : 0);
        }, 0);

        return res.json({
            total,
            completed,
            playing,
            backlog,
            abandoned,
            estimatedHours: Math.round(estimatedHours),
        });
    } catch (error) {
        console.error('Error en getStats:', error);
        return res.status(500).json({ error: 'Error interno al calcular estadísticas' });
    }
};

module.exports = {
    getUserLibrary,
    addGameToLibrary,
    getGameDetails,
    updateEntry,
    removeGame,
    getStats,
};
