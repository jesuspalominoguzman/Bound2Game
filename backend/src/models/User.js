const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true,
        unique: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        lowercase: true
    },
    password: {
        type: String,
        required: true
    },
    avatarUrl: {
        type: String,
        default: ''
    },
    bio: {
        type: String,
        default: ''
    },
    karma: {
        type: Number,
        default: 0
    },
    steamId: {
        type: String,
        default: ''
    },
    epicId: {
        type: String,
        default: ''
    },
    xboxId: {
        type: String,
        default: ''
    },
    discordId: {
        type: String,
        default: ''
    },
    reputation: {
        karma: {
            type: Number,
            default: 0
        },
        tags: [{
            type: String
        }]
    },
    hardwareSpecs: {
        cpu: { type: String, default: '' },
        gpu: { type: String, default: '' },
        ram: { type: Number, default: 0 },
        vram: { type: Number, default: 0 }
    },
    pcComponents: {
        cpu: { type: String, default: '' },
        gpu: { type: String, default: '' },
        ram: { type: Number, default: 0 },
        storage: { type: String, default: '' }
    },
    preferences: {
        playSchedule: [{
            type: String
        }],
        favoriteGenres: [{
            type: String
        }]
    },
    friends: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    // IDs de usuarios que han enviado una solicitud de amistad y aún no ha sido aceptada
    pendingRequests: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    // Estado de presencia en tiempo real — true mientras la app está en primer plano
    isOnline: {
        type: Boolean,
        default: false
    },
    fcmToken: {
        type: String,
        default: ''
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('User', userSchema);
