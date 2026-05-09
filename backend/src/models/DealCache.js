const mongoose = require('mongoose');

const dealCacheSchema = new mongoose.Schema({
    gameId: { type: String, required: true },
    title: { type: String, required: true },
    originalPrice: { type: Number, required: true },
    salePrice: { type: Number, required: true },
    storeID: { type: String, required: true },
    thumb: { type: String },
    category: {
        type: String,
        enum: ['DEAL', 'FREE', 'UPCOMING'],
        required: true
    },
    // Campos extra para retrocompatibilidad con el frontend
    storeName: { type: String },
    discountPercent: { type: Number, default: 0 },
    dealUrl: { type: String },
    steamAppID: { type: String },
    isFree: { type: Boolean, default: false },

    // Índice TTL: los documentos se eliminarán automáticamente tras 12 horas (43200 segundos)
    createdAt: { 
        type: Date, 
        default: Date.now,
        expires: 43200
    }
});

module.exports = mongoose.model('DealCache', dealCacheSchema);
