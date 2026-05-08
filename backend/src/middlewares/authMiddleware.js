const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_key_for_bound2game_tfg';

const authMiddleware = (req, res, next) => {
    // 1. Obtener el encabezado de autorización
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Acceso denegado. No se proporcionó un token válido.' });
    }

    // 2. Extraer el token (quitando la palabra "Bearer ")
    const token = authHeader.split(' ')[1];

    try {
        // 3. Verificar el token usando la clave secreta
        const decoded = jwt.verify(token, JWT_SECRET);

        // 4. Inyectar los datos del usuario en la request (req.user)
        // 'decoded' contiene lo que guardamos al hacer el login: { id, username }
        req.user = decoded;

        // 5. Pasar al siguiente controlador
        next();
    } catch (error) {
        console.error('Error al verificar el token:', error.message);
        return res.status(401).json({ error: 'Token inválido o expirado.' });
    }
};

module.exports = authMiddleware;
