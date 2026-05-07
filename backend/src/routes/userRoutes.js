const express = require('express');
const router = express.Router();
const userController    = require('../controllers/userController');
const libraryController = require('../controllers/libraryController');

// ── Autenticación ─────────────────────────────────────────────────────────────
// POST /api/users/register
router.post('/register', userController.registerUser);

// POST /api/users/login
router.post('/login', userController.loginUser);

// ── Biblioteca del usuario ─────────────────────────────────────────────────────
// GET    /api/users/:userId/library          → obtener todos los juegos
// POST   /api/users/:userId/library          → añadir juego
// PATCH  /api/users/:userId/library/:entryId → actualizar estado/nota
// DELETE /api/users/:userId/library/:entryId → eliminar entrada
// GET    /api/users/:userId/stats            → estadísticas resumidas

router.get   ('/:userId/library',             libraryController.getLibrary);
router.post  ('/:userId/library',             libraryController.addGame);
router.patch ('/:userId/library/:entryId',    libraryController.updateEntry);
router.delete('/:userId/library/:entryId',    libraryController.removeGame);
router.get   ('/:userId/stats',               libraryController.getStats);

module.exports = router;
