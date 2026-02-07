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

// LORE: Secretos de los municipios (Lo que el usuario quiere desbloquear)
const muniLore = {
  "SANTA CRUZ DE TENERIFE": "Aquí se libró la batalla contra Nelson en 1797. ¿Sabías que perdió un brazo intentando conquistarnos?",
  "SAN CRISTÓBAL DE LA LAGUNA": "Es la primera ciudad de paz sin murallas del mundo. Su trazado sirvió de modelo para las ciudades de América.",
  "OROTAVA (LA)": "Conserva la mayor altura de España. Desde el mar hasta el pico del Teide, todo es un mismo municipio.",
  "ADEJE": "Hogar del Barranco del Infierno, un lugar donde el agua fluye incluso en los veranos más secos.",
  "VILAFLOR": "El pueblo más alto de España. Aquí los árboles tocan las nubes y el aire es puro.",
  "ARONA": "Guarda el secreto de los Cristianos, donde los barcos piratas solían esconderse tras las montañas de Guaza."
};

function cleanName(name) {
  if (!name) return "TENERIFE";
  let n = name.toString().toUpperCase().trim();
  if (n.includes("SANTA CRUZ")) return "SANTA CRUZ DE TENERIFE";
  if (n.includes("LAGUNA")) return "SAN CRISTÓBAL DE LA LAGUNA";
  if (n.includes("OROTAVA")) return "OROTAVA (LA)";
  return n;
}

// ... Resto de funciones load (POIs, BICs, Borders, Itinerarios) ...
// (Mantenemos la lógica de normalización que ya funciona)

function loadPOIs() {
  try {
    if (fs.existsSync(path.join(__dirname, 'puntos-de-interes.geojson'))) {
      const geojson = JSON.parse(fs.readFileSync(path.join(__dirname, 'puntos-de-interes.geojson'), 'utf8').replace(/^\uFEFF/, ''));
      pois = geojson.features.map((feature, index) => {
        const enp = feature.properties.enp || "";
        let muni = "TENERIFE";
        if (enp.includes("Anaga")) muni = "SANTA CRUZ DE TENERIFE";
        else if (enp.includes("Teide")) muni = "OROTAVA (LA)";
        else if (enp.includes("Corona Forestal")) muni = "VILAFLOR";
        else if (enp.includes("Teno")) muni = "BUENAVISTA DEL NORTE";
        const muniKey = cleanName(muni);
        return {
          id: index + 1,
          name: feature.properties.nombre || "Sitio",
          lat: feature.geometry.coordinates[1],
          lng: feature.geometry.coordinates[0],
          type: feature.properties.tipo || "Interés",
          description: feature.properties.descripcion || "",
          municipio: muniKey
        };
      });
    }
  } catch (err) {}
}

function loadBICs() {
  try {
    if (fs.existsSync(path.join(__dirname, 'bic_inmuebles.geojson'))) {
      const geojson = JSON.parse(fs.readFileSync(path.join(__dirname, 'bic_inmuebles.geojson'), 'utf8').replace(/^\uFEFF/, ''));
      bics = geojson.features.map((f, index) => ({
        id: index + 10000,
        name: f.properties.bic_nombre,
        category: f.properties.bic_categoria,
        municipio: cleanName(f.properties.municipio_nombre),
        description: f.properties.bic_descripcion,
        lat: f.geometry.type === 'Point' ? f.geometry.coordinates[1] : f.geometry.coordinates[0][0][0][1],
        lng: f.geometry.type === 'Point' ? f.geometry.coordinates[0] : f.geometry.coordinates[0][0][0][0]
      }));
    }
  } catch (e) {}
}

function loadMuniBorders() {
  try {
    if (fs.existsSync(path.join(__dirname, 'geo_canarias_municipios.geojson'))) {
      const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'geo_canarias_municipios.geojson'), 'utf8'));
      muniBorders = data.features
        .filter(f => f.properties.gcd_isla === "ES709" || f.properties.geocode.startsWith("38"))
        .map(f => ({
          name: cleanName(f.properties.etiqueta),
          geometry: f.geometry
        }));
    }
  } catch (e) {}
}

function loadItinerarios() {
  try {
    if (fs.existsSync(path.join(__dirname, 'itinerarios.geojson'))) {
      const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'itinerarios.geojson'), 'utf8').replace(/^\uFEFF/, ''));
      itinerarios = data.features.map((f, index) => ({
        id: index + 1,
        name: f.properties.itinerario_nombre || "Ruta",
        matricula: f.properties.itinerario_matricula || "S/N",
        distancia: f.properties.itinerario_distancia || 0,
        paths: f.geometry.type === 'LineString' ? [f.geometry.coordinates] : f.geometry.coordinates,
        startPoint: f.geometry.type === 'LineString' ? f.geometry.coordinates[0] : f.geometry.coordinates[0][0]
      }));
    }
  } catch (e) {}
}

loadPOIs(); loadBICs(); loadMuniBorders(); loadItinerarios();

app.get('/api/pois', (req, res) => res.json(pois));
app.get('/api/itinerarios', (req, res) => res.json(itinerarios));
app.get('/api/bics', (req, res) => res.json(bics));
app.get('/api/borders', (req, res) => res.json(muniBorders));
app.get('/api/lore', (req, res) => res.json(muniLore)); // NUEVO ENDPOINT

app.listen(port, '0.0.0.0', () => {
  console.log(`TENERIFE QUEST API v5.0 - Narrative Engine Active`);
});