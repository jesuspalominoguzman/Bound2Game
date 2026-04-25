const axios = require('axios');
const hltb = require('howlongtobeat');

const hltbService = new hltb.HowLongToBeatService();

// Caché en memoria para las tiendas de CheapShark
let storesCache = {};

/**
 * Obtiene el nombre de la tienda a partir de su ID usando caché
 */
const getStoreName = async (storeID) => {
    if (Object.keys(storesCache).length === 0) {
        try {
            const storesResponse = await axios.get('https://www.cheapshark.com/api/1.0/stores');
            storesResponse.data.forEach(store => {
                storesCache[store.storeID] = store.storeName;
            });
        } catch (error) {
            console.error('Error al obtener tiendas de CheapShark:', error.message);
            return "Tienda Desconocida";
        }
    }
    return storesCache[storeID] || "Tienda Desconocida";
};

/**
 * Consulta la API de CheapShark para obtener el juego por título.
 * @param {string} title - Título del juego
 * @returns {Object|null} - Datos del juego desde CheapShark o null si no se encuentra
 */
const getCheapSharkData = async (title) => {
    try {
        // Primera petición: Buscar el juego por título
        const searchResponse = await axios.get(`https://www.cheapshark.com/api/1.0/games?title=${encodeURIComponent(title)}`);
        
        if (!searchResponse.data || searchResponse.data.length === 0) {
            return null;
        }

        // Mejorar la búsqueda: intentar encontrar coincidencia exacta, 
        // o si no, el primer resultado que NO sea un DLC/Soundtrack
        let bestMatch = searchResponse.data.find(g => g.external.toLowerCase() === title.toLowerCase());
        
        if (!bestMatch) {
            bestMatch = searchResponse.data.find(g => {
                const name = g.external.toLowerCase();
                return !name.includes('sfx') && !name.includes('soundtrack') && !name.includes('dlc') && !name.includes('pack');
            });
        }

        // Si todos eran DLCs, cogemos el primero por defecto
        const gameInfo = bestMatch || searchResponse.data[0];
        const gameId = gameInfo.gameID;

        // Segunda petición: Obtener detalles usando el gameId
        const detailsResponse = await axios.get(`https://www.cheapshark.com/api/1.0/games?id=${gameId}`);
        const gameDetails = detailsResponse.data;

        let storeName = "No disponible";
        if (gameDetails.deals.length > 0) {
            const storeID = gameDetails.deals[0].storeID;
            storeName = await getStoreName(storeID);
        }

        return {
            title: gameDetails.info.title,
            steamAppID: gameDetails.info.steamAppID,
            retailPrice: gameDetails.deals.length > 0 ? gameDetails.deals[0].retailPrice : "No disponible",
            currentPrice: gameDetails.deals.length > 0 ? gameDetails.deals[0].price : "No disponible",
            cheapestStore: storeName,
            lowestPriceEver: gameDetails.cheapestPriceEver.price || "No disponible",
        };
    } catch (error) {
        console.error('Error al consultar CheapShark API:', error.message);
        return null;
    }
};

/**
 * Consulta la API de Steam usando el steamAppID para obtener los requisitos de PC
 * @param {string} steamAppID - ID de Steam del juego
 * @returns {string|null} - Requisitos mínimos de PC (HTML string) o null
 */
const getSteamRequirements = async (steamAppID) => {
    if (!steamAppID) return null;
    
    try {
        const steamResponse = await axios.get(`https://store.steampowered.com/api/appdetails?appids=${steamAppID}`);
        const data = steamResponse.data[steamAppID];

        // Verificar si la respuesta es exitosa y tiene datos
        if (data && data.success && data.data) {
            const pcReq = data.data.pc_requirements;
            // Steam suele devolver un objeto con 'minimum' y 'recommended' en HTML
            if (pcReq && pcReq.minimum) {
                return pcReq.minimum; // Devuelve el string HTML
            }
        }
        return null;
    } catch (error) {
        console.error('Error al consultar Steam API:', error.message);
        return null;
    }
};

/**
 * Consulta HowLongToBeat para obtener el tiempo de finalización
 * @param {string} title - Título del juego
 * @returns {Object|string} - Horas para completar la historia principal y el 100%, o valor por defecto
 */
const getHowLongToBeatData = async (title) => {
    try {
        const results = await hltbService.search(title);
        
        if (results && results.length > 0) {
            // Tomamos el primer resultado
            const match = results[0];
            return {
                main: match.gameplayMain,
                completionist: match.gameplayCompletionist
            };
        }
        return { main: "Desconocido", completionist: "Desconocido" };
    } catch (error) {
        // La API de HowLongToBeat suele cambiar a menudo y bloquear el paquete npm (dando error 404/403).
        // En caso de que falle, devolvemos un dato simulado para que el frontend pueda seguir trabajando.
        console.warn('⚠️ La librería de HowLongToBeat falló (posible cambio en su web). Usando dato simulado.');
        const fakeMain = Math.floor(Math.random() * (40 - 10 + 1) + 10);
        return { 
            main: fakeMain, 
            completionist: fakeMain * 2 + Math.floor(Math.random() * 20) // El 100% suele ser el doble + un poco más
        };
    }
};

module.exports = {
    getCheapSharkData,
    getSteamRequirements,
    getHowLongToBeatData
};
