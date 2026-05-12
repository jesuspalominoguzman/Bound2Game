const express = require('express');
const router = express.Router();
const userController    = require('../controllers/userController');
const libraryController = require('../controllers/libraryController');
const authMiddleware    = require('../middlewares/authMiddleware');

// Middleware para verificar que el usuario autenticado solo modifica SU propia biblioteca
const verifyOwnership = (req, res, next) => {
    if (req.user.id !== req.params.userId) {
        return res.status(403).json({ error: 'Acceso denegado. No puedes acceder a la biblioteca de otro usuario.' });
    }
    next();
};

// ── Autenticación ─────────────────────────────────────────────────────────────
// POST /api/users/register
router.post('/register', userController.registerUser);

// POST /api/users/login
router.post('/login', userController.loginUser);

// GET /api/users/profile (Ruta Protegida)
// También mapeamos /me por conveniencia según petición
router.get('/profile', authMiddleware, userController.getProfile);
router.get('/me', authMiddleware, userController.getProfile);

// GET /api/users/friends (Lista de amigos)
router.get('/friends', authMiddleware, userController.getUserFriends);

// GET /api/users/pending-requests (Solicitudes de amistad recibidas)
router.get('/pending-requests', authMiddleware, userController.getPendingRequests);

// GET /api/users/search?q=name (Buscar nuevos amigos)
router.get('/search', authMiddleware, userController.searchUsers);

// POST /api/users/friend-request (Enviar o aceptar solicitud de amistad)
router.post('/friend-request', authMiddleware, userController.manageFriendRequest);

// PUT /api/users/me/pc-components (Ruta Protegida)
router.put('/me/pc-components', authMiddleware, userController.updatePcComponents);

// PUT /api/users/me/platforms (Ruta Protegida)
router.put('/me/platforms', authMiddleware, userController.updatePlatforms);

// PUT /api/users/me/fcm-token (Ruta Protegida)
router.put('/me/fcm-token', authMiddleware, userController.updateFcmToken);

// ── Biblioteca del usuario ─────────────────────────────────────────────────────
// GET    /api/users/:userId/library          → obtener todos los juegos
// POST   /api/users/:userId/library          → añadir juego
// GET    /api/users/:userId/library/:entryId → detalles de juego y compatibilidad
// PATCH  /api/users/:userId/library/:entryId → actualizar estado/nota
// DELETE /api/users/:userId/library/:entryId → eliminar entrada
// GET    /api/users/:userId/stats            → estadísticas resumidas

router.get   ('/:userId/library',             authMiddleware, verifyOwnership, libraryController.getUserLibrary);
router.post  ('/:userId/library',             authMiddleware, verifyOwnership, libraryController.addGameToLibrary);
router.get   ('/:userId/library/:entryId',    authMiddleware, verifyOwnership, libraryController.getGameDetails);
router.patch ('/:userId/library/:entryId',    authMiddleware, verifyOwnership, libraryController.updateEntry);
router.delete('/:userId/library/:entryId',    authMiddleware, verifyOwnership, libraryController.removeGame);
router.get   ('/:userId/stats',               authMiddleware, verifyOwnership, libraryController.getStats);

// GET /api/users/:userId/library-public — Biblioteca visible para amigos del usuario
// Sin verifyOwnership: el controlador verifica internamente la relación de amistad
router.get   ('/:userId/library-public',      authMiddleware, userController.getFriendLibrary);

// GET /api/users/:userId/library-preview — Vista previa pública (sin requerir amistad)
// Permite ver los juegos de un usuario antes de añadirlo como amigo
router.get   ('/:userId/library-preview',     authMiddleware, userController.getUserLibraryPreview);

// GET /api/users/:userId/profile-public — Info pública del perfil
router.get   ('/:userId/profile-public',      authMiddleware, userController.getUserProfilePublic);

module.exports = router;
