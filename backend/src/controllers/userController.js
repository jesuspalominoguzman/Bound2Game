const mongoose = require('mongoose');
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// El secreto para firmar los tokens. Debe estar en .env idealmente.
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_key_for_bound2game_tfg';

/**
 * Registro de nuevo usuario
 */
const registerUser = async (req, res) => {
    try {
        const { username, email, password } = req.body;

        // 1. Validaciones básicas
        if (!username || !email || !password) {
            return res.status(400).json({ error: 'Todos los campos son obligatorios' });
        }

        // 2. Comprobar si el usuario ya existe
        const userExists = await User.findOne({ $or: [{ email }, { username }] });
        if (userExists) {
            return res.status(400).json({ error: 'El email o el nombre de usuario ya están en uso' });
        }

        // 3. Encriptar la contraseña (hashing)
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 4. Crear el usuario en MongoDB
        const newUser = new User({
            username,
            email,
            password: hashedPassword
        });

        await newUser.save();

        // 5. Responder con éxito (sin devolver la contraseña)
        res.status(201).json({
            message: 'Usuario registrado correctamente',
            user: {
                id: newUser._id,
                username: newUser.username,
                email: newUser.email
            }
        });
    } catch (error) {
        console.error('Error en registerUser:', error);
        res.status(500).json({ error: 'Error interno del servidor al registrar usuario' });
    }
};

/**
 * Login de usuario existente
 */
const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;

        // 1. Validar campos
        if (!email || !password) {
            return res.status(400).json({ error: 'Por favor, proporciona email y contraseña' });
        }

        // 2. Buscar al usuario
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }

        // 3. Comparar contraseñas
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }

        // 4. Generar Token JWT
        const token = jwt.sign(
            { id: user._id, username: user.username },
            JWT_SECRET,
            { expiresIn: '30d' } // El token expira en 30 días
        );

        // 5. Devolver datos y token
        res.json({
            message: 'Login exitoso',
            token,
            user: {
                id: user._id,
                username: user.username,
                email: user.email,
                avatarUrl: user.avatarUrl,
                reputation: user.reputation,
                hardwareSpecs: user.hardwareSpecs
            }
        });
    } catch (error) {
        console.error('Error en loginUser:', error);
        res.status(500).json({ error: 'Error interno del servidor al hacer login' });
    }
};

/**
 * Obtener perfil del usuario autenticado
 */
const getProfile = async (req, res) => {
    try {
        // req.user contiene el id y el username que metimos en el token (ver authMiddleware)
        const userId = req.user.id;

        // Buscamos el usuario en la BD excluyendo la contraseña (-password)
        const user = await User.findById(userId).select('-password');

        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        return res.status(200).json({
            message: 'Perfil recuperado con éxito',
            user: user
        });
    } catch (error) {
        console.error('Error en getProfile:', error);
        return res.status(500).json({ error: 'Error interno al recuperar el perfil' });
    }
};

/**
 * Actualizar los componentes de PC del usuario
 */
const updatePcComponents = async (req, res) => {
    try {
        const userId = req.user.id;
        const { cpu, gpu, ram, storage } = req.body;

        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Asegurarse de que existe el objeto
        if (!user.pcComponents) {
            user.pcComponents = {};
        }

        // Actualizar campos si se envían en el body
        if (cpu !== undefined) user.pcComponents.cpu = cpu;
        if (gpu !== undefined) user.pcComponents.gpu = gpu;
        if (ram !== undefined) user.pcComponents.ram = Number(ram);
        if (storage !== undefined) user.pcComponents.storage = String(storage);

        await user.save();

        return res.status(200).json({
            message: 'Componentes de PC actualizados con éxito',
            pcComponents: user.pcComponents
        });
    } catch (error) {
        console.error('Error en updatePcComponents:', error);
        return res.status(500).json({ error: 'Error interno al actualizar los componentes de PC' });
    }
};

/**
 * Actualizar las plataformas (Steam, Epic, Xbox, Discord) del usuario autenticado.
 */
const updatePlatforms = async (req, res) => {
    try {
        const userId = req.user.id;
        const { steamId, epicId, xboxId, discordId } = req.body;

        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        if (steamId !== undefined) user.steamId = steamId;
        if (epicId !== undefined) user.epicId = epicId;
        if (xboxId !== undefined) user.xboxId = xboxId;
        if (discordId !== undefined) user.discordId = discordId;

        await user.save();

        return res.status(200).json({
            message: 'Plataformas actualizadas con éxito',
            platforms: {
                steamId: user.steamId,
                epicId: user.epicId,
                xboxId: user.xboxId,
                discordId: user.discordId
            }
        });
    } catch (error) {
        console.error('Error en updatePlatforms:', error);
        return res.status(500).json({ error: 'Error interno al actualizar las plataformas' });
    }
};

/**
 * Obtener la lista de amigos del usuario autenticado.
 * Incluye populate anidado con los juegos recientes de cada amigo
 * (hasta 5 títulos de su UserLibrary) para mostrarlos en la pantalla Social.
 */
const getUserFriends = async (req, res) => {
    try {
        const userId = req.user.id;
        const UserLibrary = require('../models/UserLibrary');

        // 1. Traer el usuario con sus amigos populados (datos básicos)
        const user = await User.findById(userId)
            .populate('friends', 'username avatarUrl karma reputation bio isOnline');

        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // 2. Para cada amigo, traer sus juegos recientes (populate anidado manual,
        //    más eficiente que virtual populate para este caso)
        const friendsWithGames = await Promise.all(
            user.friends.map(async (friend) => {
                const libraryEntries = await UserLibrary.find({ userId: friend._id })
                    .populate('gameId', 'title imageUrl steamAppID')
                    .sort({ addedAt: -1 })
                    .limit(5)
                    .lean();

                // Extraer títulos reales
                const recentGames = libraryEntries.map((entry) => {
                    return entry.gameId?.title
                        ?? entry.gameDetails?.name
                        ?? 'Juego desconocido';
                });

                // Extraer URLs de portada reales
                const recentGameCovers = libraryEntries.map((entry) => {
                    if (entry.gameId?.imageUrl) return entry.gameId.imageUrl;
                    if (entry.gameId?.steamAppID) {
                        return `https://cdn.cloudflare.steamstatic.com/steam/apps/${entry.gameId.steamAppID}/library_600x900.jpg`;
                    }
                    return '';
                }).filter(url => url !== '');

                return {
                    _id:              friend._id,
                    username:         friend.username,
                    avatarUrl:        friend.avatarUrl,
                    karma:            friend.karma,
                    reputation:       friend.reputation,
                    bio:              friend.bio,
                    isOnline:         friend.isOnline ?? false,
                    recentGames,
                    recentGameCovers
                };
            })
        );

        return res.status(200).json({
            message: 'Amigos recuperados con éxito',
            friends: friendsWithGames
        });
    } catch (error) {
        console.error('Error en getUserFriends:', error);
        return res.status(500).json({ error: 'Error interno al recuperar amigos' });
    }
};

/**
 * Buscar usuarios por nombre de usuario
 */
const searchUsers = async (req, res) => {
    try {
        const { q } = req.query;
        if (!q) {
            return res.status(400).json({ error: 'Debes proporcionar un término de búsqueda' });
        }

        // Buscar usuarios ignorando mayúsculas/minúsculas usando expresión regular
        const users = await User.find({ username: { $regex: q, $options: 'i' } })
                                .select('username avatarUrl karma bio isOnline')
                                .limit(20);

        return res.status(200).json({
            message: 'Búsqueda exitosa',
            users
        });
    } catch (error) {
        console.error('Error en searchUsers:', error);
        return res.status(500).json({ error: 'Error interno al buscar usuarios' });
    }
};

/**
 * Enviar o aceptar una solicitud de amistad.
 *
 * Lógica:
 *   - Si el emisor (req.user.id) ya está en pendingRequests del receptor → ACEPTAR
 *     (mover ambos a friends[], limpiar pendingRequests).
 *   - Si ya son amigos → 409 Conflict.
 *   - En otro caso → ENVIAR (añadir emisor al pendingRequests del receptor).
 */
const manageFriendRequest = async (req, res) => {
    try {
        const senderId     = req.user.id;
        const { targetId } = req.body;

        // ── Validación temprana ────────────────────────────────────────────────
        if (!targetId || typeof targetId !== 'string' || targetId.trim() === '') {
            return res.status(400).json({ error: 'Debes proporcionar targetId' });
        }
        if (!mongoose.Types.ObjectId.isValid(targetId)) {
            return res.status(400).json({ error: 'El targetId no es un ObjectId válido' });
        }
        if (senderId === targetId) {
            return res.status(400).json({ error: 'No puedes enviarte una solicitud a ti mismo' });
        }

        const [sender, receiver] = await Promise.all([
            User.findById(senderId),
            User.findById(targetId)
        ]);

        if (!sender || !receiver) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // ── ¿Ya son amigos? ─────────────────────────────────────────────────
        const alreadyFriends = sender.friends.map(id => id.toString()).includes(targetId);
        if (alreadyFriends) {
            return res.status(409).json({ error: 'Ya sois amigos', status: 'friends' });
        }

        // ── ¿El TARGET está en los pendingRequests del EMISOR? → ACEPTAR ────
        // Esto significa: el target nos envió una solicitud y ahora la aceptamos.
        // Ejemplo: A envió a B (B.pending=[A]). B acepta: sender=B,target=A.
        // Check: ¿está A en B.pendingRequests? Sí → aceptar.
        const hasPendingFromTarget = sender.pendingRequests
            .map(id => id.toString()).includes(targetId);

        if (hasPendingFromTarget) {
            // Mover a friends[], limpiar pendingRequests del emisor (que estaba esperando)
            sender.friends.push(targetId);
            receiver.friends.push(senderId);
            sender.pendingRequests = sender.pendingRequests.filter(
                id => id.toString() !== targetId
            );
            await Promise.all([sender.save(), receiver.save()]);

            // Emitir evento de socket si el receptor está conectado
            const io = req.app.get('io');
            if (io) {
                io.of('/chat').to(`user_${targetId}`).emit('friendRequest', {
                    username: sender.username,
                    userId: senderId,
                    type: 'accepted'
                });
            }

            return res.status(200).json({
                message: '¡Solicitud aceptada! Ahora sois amigos.',
                status: 'accepted'
            });
        }

        // ── ¿El emisor ya envió una solicitud antes? (está en pending del receptor) ─
        const alreadySent = receiver.pendingRequests
            .map(id => id.toString()).includes(senderId);
        if (alreadySent) {
            return res.status(409).json({ error: 'Solicitud ya enviada', status: 'pending' });
        }

        // ── ENVIAR: añadir senderId a los pendingRequests del receiver ────────
        receiver.pendingRequests.push(senderId);
        await receiver.save();

        // Emitir evento de socket si el receptor está conectado
        const io = req.app.get('io');
        if (io) {
            io.of('/chat').to(`user_${targetId}`).emit('friendRequest', {
                username: sender.username,
                userId: senderId,
                type: 'request'
            });
        }

        return res.status(200).json({
            message: 'Solicitud de amistad enviada correctamente.',
            status: 'pending'
        });
    } catch (error) {
        console.error('Error en manageFriendRequest:', error);
        return res.status(500).json({ error: 'Error interno al gestionar la solicitud de amistad' });
    }
};

/**
 * Obtener la biblioteca pública de un amigo.
 * Requiere que el usuario autenticado y el dueño de la biblioteca sean amigos.
 */
const getFriendLibrary = async (req, res) => {
    try {
        const requesterId = req.user.id;
        const { userId }  = req.params;

        // Verificar que son amigos antes de mostrar la biblioteca
        const requester = await User.findById(requesterId).select('friends');
        if (!requester) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const areFriends = requester.friends.map(id => id.toString()).includes(userId);
        if (!areFriends) {
            return res.status(403).json({ error: 'Solo puedes ver la biblioteca de tus amigos' });
        }

        // Importar UserLibrary aquí para no crear dependencia circular en el módulo
        const UserLibrary = require('../models/UserLibrary');
        const entries = await UserLibrary.find({ userId })
            .populate('gameId', 'title imageUrl steamAppID hltb')
            .sort({ addedAt: -1 });

        return res.status(200).json({
            message: 'Biblioteca recuperada con éxito',
            library: entries
        });
    } catch (error) {
        console.error('Error en getFriendLibrary:', error);
        return res.status(500).json({ error: 'Error interno al recuperar la biblioteca del amigo' });
    }
};

/**
 * Vista previa de la biblioteca de cualquier usuario.
 * NO requiere amistad — permite ver los juegos de alguien antes de añadirlo.
 * Solo devuelve datos no sensibles (títulos e imagen de portada).
 */
const getUserLibraryPreview = async (req, res) => {
    try {
        const { userId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({ error: 'userId no válido' });
        }

        const UserLibrary = require('../models/UserLibrary');
        const entries = await UserLibrary.find({ userId })
            .populate('gameId', 'title imageUrl steamAppID hltb')
            .sort({ addedAt: -1 })
            .limit(8);

        return res.status(200).json({
            message: 'Vista previa de biblioteca',
            library: entries
        });
    } catch (error) {
        console.error('Error en getUserLibraryPreview:', error);
        return res.status(500).json({ error: 'Error interno al recuperar la vista previa' });
    }
};

/**
 * GET /api/users/pending-requests
 * Devuelve la lista de usuarios que han enviado una solicitud al usuario autenticado.
 * (i.e., usuarios cuyos IDs están en req.user.pendingRequests)
 */
const getPendingRequests = async (req, res) => {
    try {
        const user = await User.findById(req.user.id)
            .populate('pendingRequests', 'username avatarUrl karma bio');

        if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });

        return res.status(200).json({
            message: 'Solicitudes pendientes',
            pendingRequests: user.pendingRequests
        });
    } catch (error) {
        console.error('Error en getPendingRequests:', error);
        return res.status(500).json({ error: 'Error interno al obtener solicitudes' });
    }
};

/**
 * GET /api/users/:userId/profile-public
 * Devuelve la información pública de un usuario (para mostrar en su pantalla de perfil).
 */
const getUserProfilePublic = async (req, res) => {
    try {
        const { userId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(userId)) {
            return res.status(400).json({ error: 'userId no válido' });
        }

        const targetUser = await User.findById(userId)
            .select('username avatarUrl bio karma reputation steamId epicId xboxId discordId pcComponents isOnline friends')
            .lean();

        if (!targetUser) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        const friendsCount = targetUser.friends ? targetUser.friends.length : 0;

        return res.status(200).json({
            message: 'Perfil público recuperado con éxito',
            profile: {
                id: targetUser._id,
                username: targetUser.username,
                avatarUrl: targetUser.avatarUrl,
                bio: targetUser.bio,
                karma: targetUser.karma,
                reputation: targetUser.reputation,
                steamId: targetUser.steamId,
                epicId: targetUser.epicId,
                xboxId: targetUser.xboxId,
                discordId: targetUser.discordId,
                pcComponents: targetUser.pcComponents,
                isOnline: targetUser.isOnline,
                friendsCount: friendsCount
            }
        });
    } catch (error) {
        console.error('Error en getUserProfilePublic:', error);
        return res.status(500).json({ error: 'Error interno al recuperar el perfil público' });
    }
};

/**
 * PUT /api/users/me/fcm-token
 * Actualiza el token de Firebase Cloud Messaging del usuario actual.
 */
const updateFcmToken = async (req, res) => {
    try {
        const { fcmToken } = req.body;

        if (!fcmToken) {
            return res.status(400).json({ error: 'Token FCM no proporcionado' });
        }

        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });

        user.fcmToken = fcmToken;
        await user.save();

        return res.status(200).json({ message: 'Token FCM actualizado correctamente' });
    } catch (error) {
        console.error('Error en updateFcmToken:', error);
        return res.status(500).json({ error: 'Error interno al actualizar el token' });
    }
};

module.exports = {
    registerUser,
    loginUser,
    getProfile,
    updatePcComponents,
    getUserFriends,
    searchUsers,
    manageFriendRequest,
    getFriendLibrary,
    getUserLibraryPreview,
    getPendingRequests,
    getUserProfilePublic,
    updatePlatforms,
    updateFcmToken
};
