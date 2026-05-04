const mongoose = require('mongoose');

const matchmakingSessionSchema = new mongoose.Schema({
    hostId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    gameId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'GameCache',
        required: true
    },
    description: {
        type: String,
        default: ''
    },
    maxPlayers: {
        type: Number,
        default: 4
    },
    currentPlayers: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    active: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('MatchmakingSession', matchmakingSessionSchema);
