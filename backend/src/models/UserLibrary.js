const mongoose = require('mongoose');

const userLibrarySchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    gameId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'GameCache',
        required: true
    },
    platform: {
        type: String,
        default: 'Steam'
    },
    status: {
        type: String,
        enum: ['Backlog', 'Playing', 'Completed', 'Abandoned'],
        default: 'Backlog'
    },
    personalNote: {
        type: String,
        default: ''
    },
    addedAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('UserLibrary', userLibrarySchema);
