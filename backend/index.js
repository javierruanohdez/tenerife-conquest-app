const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');
const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

let pois = [];
let itinerarios = [];
let bics = [];

const geojsonPath = path.join(__dirname, 'puntos-de-interes.geojson');
const itPath = path.join(__dirname, 'itinerarios.csv');
const bicGeojsonPath = path.join(__dirname, 'bic_inmuebles.geojson');

// Load POIs
function loadPOIs() {
  try {
    if (fs.existsSync(geojsonPath)) {
      let data = fs.readFileSync(geojsonPath, 'utf8');
      if (data.charCodeAt(0) === 0xFEFF) data = data.slice(1);
      const geojson = JSON.parse(data);
      pois = geojson.features.map((feature, index) => {
        const enp = feature.properties.enp || "";
        let muni = "Tenerife";
        
        if (enp.includes("Anaga")) muni = "Santa Cruz de Tenerife";
        else if (enp.includes("Teide")) muni = "La Orotava";
        else if (enp.includes("Corona Forestal")) muni = "Vilaflor";
        else if (enp.includes("Teno")) muni = "Buenavista del Norte";
        
        return {
          id: index + 1,
          name: feature.properties.nombre || "Sin nombre",
          lat: feature.geometry.coordinates[1],
          lng: feature.geometry.coordinates[0],
          type: feature.properties.tipo || "Interés",
          description: feature.properties.descripcion || "Sin descripción.",
          enp: enp,
          municipio: muni,
          saturation: "none"
        };
      });
      console.log(`[SUCCESS] Loaded ${pois.length} POIs`);
    }
  } catch (err) { console.error("[ERROR] POIs:", err.message); }
}

// Load Itinerarios
function loadItinerarios() {
  const results = [];
  if (fs.existsSync(itPath)) {
    fs.createReadStream(itPath)
      .pipe(csv())
      .on('data', (data) => results.push(data))
      .on('end', () => {
        itinerarios = results.map((it, index) => ({
          id: index + 1,
          name: it.itinerario_nombre,
          matricula: it.itinerario_matricula,
          distancia: it.itinerario_distancia,
          municipios: it.municipios_nombres,
          espacios: it.espacios_naturales,
          inicio: it.itinerario_inicio,
          fin: it.itinerario_fin
        }));
        console.log(`[SUCCESS] Loaded ${itinerarios.length} Itinerarios`);
      });
  }
}

// Load BICs from GeoJSON
function loadBICs() {
  try {
    if (fs.existsSync(bicGeojsonPath)) {
      let data = fs.readFileSync(bicGeojsonPath, 'utf8');
      if (data.charCodeAt(0) === 0xFEFF) data = data.slice(1);
      const geojson = JSON.parse(data);
      
      bics = geojson.features.map((feature, index) => {
        let lat = 28.2916;
        let lng = -16.6291;

        if (feature.geometry && feature.geometry.coordinates) {
          let firstPoint;
          if (feature.geometry.type === 'Point') {
            firstPoint = feature.geometry.coordinates;
          } else if (feature.geometry.type === 'Polygon') {
            firstPoint = feature.geometry.coordinates[0][0];
          } else if (feature.geometry.type === 'MultiPolygon') {
            firstPoint = feature.geometry.coordinates[0][0][0];
          }
          
          if (firstPoint && Array.isArray(firstPoint)) {
            lng = firstPoint[0];
            lat = firstPoint[1];
          }
        }

        return {
          id: index + 10000,
          name: feature.properties.bic_nombre || "Patrimonio",
          category: feature.properties.bic_categoria || "BIC",
          municipio: feature.properties.municipio_nombre || "Tenerife",
          description: feature.properties.bic_descripcion || "",
          url: feature.properties.boletin1_url || "",
          lat: lat,
          lng: lng
        };
      });
      console.log(`[SUCCESS] Loaded ${bics.length} BICs from GeoJSON`);
    }
  } catch (err) { console.error("[ERROR] BICs:", err.message); }
}

loadPOIs();
loadItinerarios();
loadBICs();

app.get('/api/pois', (req, res) => {
  res.json(pois);
});

app.get('/api/recommendation', (req, res) => {
  if (pois.length > 0) {
    const randomPoi = pois[Math.floor(Math.random() * pois.length)];
    const relatedBics = bics.filter(b => randomPoi.enp.includes(b.municipio) || b.municipio.includes(randomPoi.name));
    res.json({
      poi: randomPoi,
      bics: relatedBics.slice(0, 2),
      reason: "¡Lugar recomendado para visitar hoy!"
    });
  } else {
    res.json(null);
  }
});

app.post('/api/report', (req, res) => {
  const { poiId, type, comment } = req.body;
  console.log(`[CIENCIA CIUDADANA] Reporte recibido para POI ${poiId}: ${type} - ${comment}`);
  res.json({ success: true, message: "Reporte registrado. ¡Gracias por cuidar la isla!" });
});

app.get('/api/itinerarios', (req, res) => {
  res.json(itinerarios);
});

app.get('/api/bics', (req, res) => {
  res.json(bics);
});

app.get('/api/borders', (req, res) => {
  try {
    const data = fs.readFileSync(path.join(__dirname, 'municipios_borders.json'), 'utf8');
    res.json(JSON.parse(data));
  } catch (e) {
    res.json([]);
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Backend running at http://0.0.0.0:${port}`);
});