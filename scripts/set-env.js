const os = require('os');
const fs = require('fs');
const path = require('path');

console.log('🔍 Detectando tu IP local para configurar Flutter...');

function getLocalIp() {
    const interfaces = os.networkInterfaces();
    let fallbackIp = '10.0.2.2'; // Fallback por defecto (Emulador Android)
    let possibleIps = [];

    for (const name of Object.keys(interfaces)) {
        if (name.toLowerCase().includes('veth') || name.toLowerCase().includes('wsl') || name.toLowerCase().includes('docker')) {
            continue;
        }
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                possibleIps.push(iface.address);
            }
        }
    }

    // Priorizamos IPs típicas de routers domésticos (192.168.x.x)
    const wifiIp = possibleIps.find(ip => ip.startsWith('192.168.'));
    if (wifiIp) return wifiIp;

    // Si no hay 192.168, devolvemos la primera que encontremos
    return possibleIps.length > 0 ? possibleIps[0] : fallbackIp;
}

const localIp = getLocalIp();
const envContent = `API_URL=http://${localIp}:3000\n`;
const envPath = path.join(__dirname, '..', 'frontend', '.env');

fs.writeFileSync(envPath, envContent);

console.log(`✅ ¡Éxito! Archivo frontend/.env configurado con la IP: ${localIp}`);
