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
    steamId: {
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
    }]
}, {
    timestamps: true
});

module.exports = mongoose.model('User', userSchema);
