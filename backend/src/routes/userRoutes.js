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
router.get('/profile', authMiddleware, userController.getProfile);

// ── Biblioteca del usuario ─────────────────────────────────────────────────────
// GET    /api/users/:userId/library          → obtener todos los juegos
// POST   /api/users/:userId/library          → añadir juego
// PATCH  /api/users/:userId/library/:entryId → actualizar estado/nota
// DELETE /api/users/:userId/library/:entryId → eliminar entrada
// GET    /api/users/:userId/stats            → estadísticas resumidas

router.get   ('/:userId/library',             authMiddleware, verifyOwnership, libraryController.getLibrary);
router.post  ('/:userId/library',             authMiddleware, verifyOwnership, libraryController.addGame);
router.patch ('/:userId/library/:entryId',    authMiddleware, verifyOwnership, libraryController.updateEntry);
router.delete('/:userId/library/:entryId',    authMiddleware, verifyOwnership, libraryController.removeGame);
router.get   ('/:userId/stats',               authMiddleware, verifyOwnership, libraryController.getStats);

module.exports = router;
