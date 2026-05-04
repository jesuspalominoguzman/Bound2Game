const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_key_for_bound2game_tfg';

/**
 * Registra un nuevo usuario en la base de datos
 */
const registerUser = async (userData) => {
    const { username, email, password } = userData;

    // Verificar si ya existe el usuario
    const existingUser = await User.findOne({ $or: [{ email }, { username }] });
    if (existingUser) {
        throw new Error('El email o nombre de usuario ya está en uso');
    }

    // Encriptar la contraseña
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Crear el usuario
    const newUser = new User({
        username,
        email,
        password: hashedPassword
    });

    await newUser.save();

    // Generar JWT
    const token = jwt.sign(
        { id: newUser._id, username: newUser.username },
        JWT_SECRET,
        { expiresIn: '30d' }
    );

    return {
        token,
        user: {
            id: newUser._id,
            username: newUser.username,
            email: newUser.email,
            avatarUrl: newUser.avatarUrl,
            reputation: newUser.reputation
        }
    };
};

/**
 * Realiza el login validando credenciales
 */
const loginUser = async (credentials) => {
    const { email, password } = credentials;

    // Buscar usuario
    const user = await User.findOne({ email });
    if (!user) {
        throw new Error('Credenciales inválidas');
    }

    // Comprobar contraseña
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
        throw new Error('Credenciales inválidas');
    }

    // Generar JWT
    const token = jwt.sign(
        { id: user._id, username: user.username },
        JWT_SECRET,
        { expiresIn: '30d' }
    );

    return {
        token,
        user: {
            id: user._id,
            username: user.username,
            email: user.email,
            avatarUrl: user.avatarUrl,
            reputation: user.reputation,
            hardwareSpecs: user.hardwareSpecs
        }
    };
};

module.exports = {
    registerUser,
    loginUser
};
