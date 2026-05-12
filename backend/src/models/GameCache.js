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
    // Precio y tienda
    currentPrice:    { type: String, default: null },
    retailPrice:     { type: String, default: null },
    cheapestStore:   { type: String, default: null },
    lowestPriceEver: { type: String, default: null },
    // Requisitos
    requirements: {
        min_ram:         { type: Number, default: null },
        min_gpu:         { type: String, default: null },
        recommended_ram: { type: Number, default: null }
    },
    pcRequirements: { type: String, default: null },
    // Plataformas detectadas por RAWG (ej: ['pc', 'nintendo-switch', 'playstation-4'])
    rawgPlatforms: { type: [String], default: [] },
    // Metadatos de RAWG
    releaseYear:  { type: Number, default: null },
    genres:       { type: [String], default: [] },
    metacritic:   { type: Number, default: null },
    esrbRating:   { type: String, default: null },
    // HowLongToBeat
    hltb: {
        mainStory:     { type: Number, default: null },
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

