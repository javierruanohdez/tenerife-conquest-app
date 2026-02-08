const fs = require('fs');
const path = require('path');

const itPath = path.join(__dirname, 'itinerarios.geojson');

console.log("--- DIAGNOSTICO ---");

if (!fs.existsSync(itPath)) {
    console.error("Archivo no encontrado");
    process.exit(1);
}

try {
    const rawData = fs.readFileSync(itPath, 'utf8').replace(/^\uFEFF/, '');
    const geojson = JSON.parse(rawData);
    
    console.log("Features:", geojson.features.length);
    
    if (geojson.features.length > 0) {
        const f = geojson.features[0];
        console.log("Nombre:", f.properties.itinerario_nombre);
        console.log("Tipo:", f.geometry.type);
        
        let p = f.geometry.type === 'LineString' ? f.geometry.coordinates[0] : f.geometry.coordinates[0][0];
        console.log("Coord Lng:", p[0]);
        console.log("Coord Lat:", p[1]);
        
        if (p[1] > 27 && p[1] < 29) {
            console.log("UBICACION OK (Tenerife)");
        } else {
            console.log("UBICACION FUERA DE TENERIFE");
        }
    }
} catch (e) {
    console.log("Error:", e.message);
}