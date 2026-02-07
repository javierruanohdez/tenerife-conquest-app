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
const bicPath = path.join(__dirname, 'bics.csv');

// Load POIs
function loadPOIs() {
  try {
    if (fs.existsSync(geojsonPath)) {
      let data = fs.readFileSync(geojsonPath, 'utf8');
      if (data.charCodeAt(0) === 0xFEFF) data = data.slice(1);
      const geojson = JSON.parse(data);
      pois = geojson.features.map((feature, index) => ({
        id: index + 1,
        name: feature.properties.nombre || "Sin nombre",
        lat: feature.geometry.coordinates[1],
        lng: feature.geometry.coordinates[0],
        type: feature.properties.tipo || "Interés",
        description: feature.properties.descripcion || "Sin descripción.",
        enp: feature.properties.enp || "",
        municipio: "Tenerife", // Default
        saturation: "none"
      }));
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

// Load BICs
// Since the BIC CSV lacks coordinates, we link them to municipal areas or relevant POIs
function loadBICs() {
  const results = [];
  if (fs.existsSync(bicPath)) {
    fs.createReadStream(bicPath)
      .pipe(csv())
      .on('data', (data) => results.push(data))
      .on('end', () => {
        bics = results.map((b, index) => ({
          id: index + 10000,
          name: b.bic_nombre,
          category: b.bic_categoria,
          municipio: b.municipio_nombre,
          description: b.bic_descripcion,
          url: b.boletin1_url
        }));
        console.log(`[SUCCESS] Loaded ${bics.length} BICs`);
      });
  }
}

loadPOIs();
loadItinerarios();
loadBICs();

const getSaturation = () => {
  const rand = Math.random();
  if (rand < 0.4) return "low"; 
  if (rand < 0.7) return "medium";
  return "high"; 
};

app.get('/api/pois', (req, res) => {
  res.json(pois);
});

// NEW: Smart Recommendation Endpoint
app.get('/api/recommendation', (req, res) => {
  if (pois.length > 0) {
    const randomPoi = pois[Math.floor(Math.random() * pois.length)];
    // Encontrar BICs en el mismo municipio o ENP
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

// NEW: Endpoint de Ciencia Ciudadana (Eco-Reportes)
app.post('/api/report', (req, res) => {
  const { poiId, type, comment } = req.body;
  console.log(`[CIENCIA CIUDADANA] Reporte recibido para POI ${poiId}: ${type} - ${comment}`);
  // Aquí, en un sistema real, guardaríamos esto en una BBDD para el Área de Medio Ambiente
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
