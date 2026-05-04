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

module.exports = {
    registerUser,
    loginUser
};
