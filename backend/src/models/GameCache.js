const mongoose = require('mongoose');

const gameCacheSchema = new mongoose.Schema({
    steamAppID: {
        type: String,
        default: null
    },
    title: {
        type: String,
        required: true,
        index: true
    },
    imageUrl: {
        type: String,
        default: ''
    },
    requirements: {
        min_ram: { type: Number, default: null }, // en GB
        min_gpu: { type: String, default: null },
        recommended_ram: { type: Number, default: null } // en GB
    },
    hltb: {
        mainStory: { type: Number, default: null },
        completionist: { type: Number, default: null }
    },
    lastPriceUpdate: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('GameCache', gameCacheSchema);
