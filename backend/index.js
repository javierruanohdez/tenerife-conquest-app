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
let muniBorders = []; 

function cleanName(name) {
  if (!name) return "TENERIFE";
  return name.toString().toUpperCase().trim();
}

function normalizeKey(key) {
  if (!key) return "";
  return key.toString().toUpperCase().replace(/[^A-Z0-9]/g, '').trim();
}

async function loadItinerarios() {
  const csvData = [];
  const csvPath = path.join(__dirname, 'itinerarios.csv');
  const geojsonPath = path.join(__dirname, 'itinerarios.geojson');

  // 1. Cargamos el CSV en memoria para cruzar datos
  if (fs.existsSync(csvPath)) {
    await new Promise((resolve) => {
      fs.createReadStream(csvPath).pipe(csv()).on('data', (d) => csvData.push(dataClean(d))).on('end', resolve);
    });
  }

  function dataClean(d) {
    return d; // Simplificado
  }

  // 2. Cargamos el GeoJSON (Nuestra fuente de verdad para el MAPA)
  try {
    if (fs.existsSync(geojsonPath)) {
      const geojson = JSON.parse(fs.readFileSync(geojsonPath, 'utf8').replace(/^\uFEFF/, ''));
      
      itinerarios = geojson.features.map((f, index) => {
        const gp = f.properties;
        const geoMatricula = gp.itinerario_matricula || "";
        
        // BUSCAMOS LOS DATOS TÉCNICOS EN EL CSV
        const csvMatch = csvData.find(c => normalizeKey(c.itinerario_matricula) === normalizeKey(geoMatricula));

        const dist = parseFloat(csvMatch ? csvMatch.itinerario_distancia : gp.itinerario_distancia) || 0;
        const desnivel = parseFloat(csvMatch ? csvMatch.itinerario_desnivel_positivo : 0) || 0;

        let difficulty = "Baja";
        let color = "#4CAF50"; 
        if (dist > 12000 || desnivel > 700) { difficulty = "Alta"; color = "#F44336"; }
        else if (dist > 6000 || desnivel > 350) { difficulty = "Media"; color = "#FFC107"; }

        return {
          id: index + 1,
          matricula: geoMatricula || "S/N",
          name: gp.itinerario_nombre || "Sendero",
          description: csvMatch ? `Ruta por ${csvMatch.municipios_nombres}.` : "Ruta oficial de Tenerife.",
          distancia: Math.round(dist), // NÚMERO
          desnivelPos: Math.round(desnivel), // NÚMERO
          difficulty: difficulty,
          difficultyColor: color,
          isCircular: (gp.itinerario_modalidad || "").toUpperCase().includes("CIRCULAR"),
          municipios: csvMatch ? csvMatch.municipios_nombres : "Tenerife",
          paths: f.geometry.type === 'LineString' ? [f.geometry.coordinates] : f.geometry.coordinates,
          startPoint: f.geometry.type === 'LineString' ? f.geometry.coordinates[0] : f.geometry.coordinates[0][0]
        };
      });
      console.log(`[SUCCESS] ${itinerarios.length} Itinerarios con geometría listos.`);
    }
  } catch (err) { console.error("Error en motor espacial:", err); }
}

function loadPOIs() {
  try {
    const pPath = path.join(__dirname, 'puntos-de-interes.geojson');
    const data = JSON.parse(fs.readFileSync(pPath, 'utf8').replace(/^\uFEFF/, ''));
    pois = data.features.map((f, i) => ({
      id: i + 1,
      name: f.properties.nombre || "Sitio",
      lat: f.geometry.coordinates[1],
      lng: f.geometry.coordinates[0],
      type: f.properties.tipo || "Interés",
      description: f.properties.descripcion || "",
      municipio: cleanName(f.properties.municipio_nombre || "TENERIFE")
    }));
  } catch (e) {}
}

function loadBICs() {
  try {
    const bPath = path.join(__dirname, 'bic_inmuebles.geojson');
    const data = JSON.parse(fs.readFileSync(bPath, 'utf8').replace(/^\uFEFF/, ''));
    bics = data.features.map((f, i) => {
      let p = f.geometry.type === 'Point' ? f.geometry.coordinates : f.geometry.coordinates[0][0][0];
      return {
        id: i + 10000,
        name: f.properties.bic_nombre,
        category: f.properties.bic_categoria,
        municipio: cleanName(f.properties.municipio_nombre),
        description: f.properties.bic_descripcion,
        lat: p[1], lng: p[0]
      };
    });
  } catch (e) {}
}

function loadMuniBorders() {
  try {
    const mPath = path.join(__dirname, 'geo_canarias_municipios.geojson');
    const data = JSON.parse(fs.readFileSync(mPath, 'utf8'));
    muniBorders = data.features
      .filter(f => f.properties.gcd_isla === "ES709" || f.properties.geocode.startsWith("38"))
      .map(f => ({
        name: cleanName(f.properties.etiqueta),
        geometry: f.geometry
      }));
  } catch (e) {}
}

async function init() {
  loadPOIs(); loadBICs(); loadMuniBorders(); await loadItinerarios();
  app.listen(port, '0.0.0.0', () => console.log(`TENERIFE QUEST API v5.0 - Ready`));
}
init();

app.get('/api/pois', (req, res) => res.json(pois));
app.get('/api/itinerarios', (req, res) => res.json(itinerarios));
app.get('/api/bics', (req, res) => res.json(bics));
app.get('/api/borders', (req, res) => res.json(muniBorders));
