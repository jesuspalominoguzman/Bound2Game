const authService = require('../services/authService');
const User = require('../models/User'); // Importamos el modelo User para la ruta de perfil

/**
 * POST /api/auth/register
 */
const register = async (req, res) => {
    try {
        const { username, email, password } = req.body;

        if (!username || !email || !password) {
            return res.status(400).json({ error: 'Todos los campos (username, email, password) son obligatorios' });
        }

        const authData = await authService.registerUser({ username, email, password });
        
        return res.status(201).json({
            message: 'Usuario registrado correctamente',
            ...authData // Incluye token y datos del usuario
        });

    } catch (error) {
        if (error.message === 'El email o nombre de usuario ya está en uso') {
            return res.status(400).json({ error: error.message });
        }
        console.error('Error en register:', error);
        return res.status(500).json({ error: 'Error interno del servidor al registrar' });
    }
};

/**
 * POST /api/auth/login
 */
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Por favor, proporciona email y contraseña' });
        }

        const authData = await authService.loginUser({ email, password });

        return res.status(200).json({
            message: 'Login exitoso',
            ...authData // Incluye token y datos del usuario
        });

    } catch (error) {
        if (error.message === 'Credenciales inválidas') {
            return res.status(401).json({ error: error.message });
        }
        console.error('Error en login:', error);
        return res.status(500).json({ error: 'Error interno del servidor al hacer login' });
    }
};

/**
 * GET /api/auth/profile
 * Ruta protegida. Requiere que el usuario esté autenticado.
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

module.exports = {
    register,
    login,
    getProfile
};
