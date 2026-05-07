const UserLibrary = require('../models/UserLibrary');
const GameCache   = require('../models/GameCache');

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/users/:userId/library
// Devuelve todas las entradas de la biblioteca del usuario con datos del juego
// ─────────────────────────────────────────────────────────────────────────────
const getLibrary = async (req, res) => {
    try {
        const { userId } = req.params;

        const entries = await UserLibrary.find({ userId })
            .populate('gameId')
            .sort({ addedAt: -1 });

        // Transformar al formato que el frontend espera
        const library = entries.map(entry => {
            const game = entry.gameId; // GameCache poblado
            return {
                entryId:      entry._id,
                userId:       entry.userId,
                platform:     entry.platform,
                status:       entry.status,
                personalNote: entry.personalNote,
                addedAt:      entry.addedAt,
                game: game ? {
                    _id:             game._id,
                    title:           game.title,
                    steamAppID:      game.steamAppID,
                    imageUrl:        game.imageUrl || '',
                    hltb:            game.hltb,
                    requirements:    game.requirements,
                    lastPriceUpdate: game.lastPriceUpdate,
                    createdAt:       game.createdAt,
                } : null,
            };
        });

        return res.json({ library });
    } catch (error) {
        console.error('Error en getLibrary:', error);
        return res.status(500).json({ error: 'Error interno al obtener la biblioteca' });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/users/:userId/library
// Añade un juego a la biblioteca del usuario
// Body: { gameTitle, platform?, status? }
// ─────────────────────────────────────────────────────────────────────────────
const addGame = async (req, res) => {
    try {
        const { userId }   = req.params;
        const { gameTitle, platform = 'Steam', status = 'Backlog' } = req.body;

        if (!gameTitle) {
            return res.status(400).json({ error: 'gameTitle es obligatorio' });
        }

        // 1. Buscar o crear el juego en GameCache
        let game = await GameCache.findOne({
            title: { $regex: new RegExp(`^${gameTitle}$`, 'i') },
        });

        if (!game) {
            // Crear un registro mínimo; el scraping completo se hace al buscar
            game = new GameCache({ title: gameTitle });
            await game.save();
        }

        // 2. Comprobar si ya existe la entrada
        const existing = await UserLibrary.findOne({ userId, gameId: game._id });
        if (existing) {
            return res.status(409).json({ error: 'El juego ya está en tu biblioteca' });
        }

        // 3. Crear la entrada
        const entry = new UserLibrary({
            userId,
            gameId:   game._id,
            platform,
            status,
        });
        await entry.save();

        return res.status(201).json({
            message: 'Juego añadido a la biblioteca',
            entryId: entry._id,
            gameId:  game._id,
            title:   game.title,
        });
    } catch (error) {
        console.error('Error en addGame:', error);
        return res.status(500).json({ error: 'Error interno al añadir el juego' });
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
    getLibrary,
    addGame,
    updateEntry,
    removeGame,
    getStats,
};
