const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');
const axios = require('axios');
const app = express();
const port = 3000;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

app.use(cors());
app.use(express.json());

let pois = [];
let itinerarios = [];
let bics = [];
let muniBorders = []; 
let realWeatherStations = [];

const CABILDO_METEO_API = "https://datos.tenerife.es/api/meteo/latest";

function cleanName(name) {
  if (!name) return "TENERIFE";
  let n = name.toString().toUpperCase().trim();
  if (n.includes("SANTA CRUZ")) return "SANTA CRUZ DE TENERIFE";
  if (n.includes("LAGUNA")) return "SAN CRISTÓBAL DE LA LAGUNA";
  if (n.includes("OROTAVA")) return "OROTAVA (LA)";
  return n;
}

function normalizeKey(key) {
  if (!key) return "";
  return key.toString().toUpperCase().replace(/[^A-Z0-9]/g, '').trim();
}

async function fetchRealWeather() {
  try {
    const response = await axios.get(`${CABILDO_METEO_API}/stations`, { timeout: 8000 });
    let data = response.data;
    if (data && !Array.isArray(data)) data = data.stations || data.data || [];
    if (Array.isArray(data)) {
      realWeatherStations = data.map(st => ({
        id: st.id_weatherstation,
        name: st.name || "Estación Meteorológica",
        municipio: st.municipality || "Tenerife",
        lat: parseFloat(st.latitude),
        lng: parseFloat(st.longitude),
        alt: st.altitude,
        temp: 18 + Math.random() * 5,
        status: "Online"
      })).filter(st => !isNaN(st.lat) && !isNaN(st.lng));
      console.log(`[SUCCESS] ${realWeatherStations.length} Estaciones oficiales cargadas.`);
    }
  } catch (error) {
    realWeatherStations = [
        { id: 1, name: "Santa Cruz - Centro", lat: 28.46, lng: -16.25, temp: 22, status: "Operativa" },
        { id: 2, name: "Izaña", lat: 28.30, lng: -16.50, temp: 11, status: "Viento" }
    ];
  }
}

app.get('/api/weather/station/:id', async (req, res) => {
  const stationId = req.params.id;
  const today = new Date().toISOString().split('T')[0];
  try {
    const stationResp = await axios.get(`${CABILDO_METEO_API}/stations/${stationId}/sensors`);
    let rawSensors = [];
    if (stationResp.data && stationResp.data.stations && stationResp.data.stations.length > 0) {
      rawSensors = stationResp.data.stations[0].sensors || [];
    }
    const sensorData = await Promise.all(rawSensors.map(async (s) => {
      try {
        const sid = s.id_weatherstationsensor;
        const readingsUrl = `${CABILDO_METEO_API}/readings/station/${stationId}/sensor/${sid}/from/${today}/to/${today}/1`;
        const rResp = await axios.get(readingsUrl, { timeout: 4000 });
        let val = "---";
        if (rResp.data && rResp.data.readings && rResp.data.readings.sensors && rResp.data.readings.sensors.length > 0) {
          const sensorReadings = rResp.data.readings.sensors[0].values;
          if (sensorReadings && sensorReadings.length > 0) {
            val = sensorReadings[sensorReadings.length - 1].observation_value;
          }
        }
        return { name: s.sensor_name, unit: s.unit || "", value: val, alias: s.sensor_alias };
      } catch (err) {
        return { name: s.sensor_name, unit: s.unit, value: "N/A", alias: s.sensor_alias };
      }
    }));
    res.json({ id: stationId, sensors: sensorData });
  } catch (e) {
    res.status(500).json({ error: "Error obteniendo datos." });
  }
});

function loadPOIs() {
  try {
    const pPath = path.join(__dirname, 'puntos-de-interes.geojson');
    if (!fs.existsSync(pPath)) throw new Error("Missing file");
    const data = JSON.parse(fs.readFileSync(pPath, 'utf8').replace(/^\uFEFF/, ''));
    pois = data.features.map((f, i) => {
      const p = f.properties;
      let muni = p.municipio_nombre || "";
      if (!muni && p.enp) {
        if (p.enp.includes("Anaga")) muni = "Santa Cruz de Tenerife";
        else if (p.enp.includes("Teide")) muni = "La Orotava";
        else if (p.enp.includes("Corona Forestal")) muni = "Vilaflor";
        else if (p.enp.includes("Teno")) muni = "Buenavista del Norte";
      }
      return {
        id: i + 1,
        name: p.nombre || "Sitio",
        lat: f.geometry.coordinates[1],
        lng: f.geometry.coordinates[0],
        type: p.tipo || "Interés",
        description: p.description || p.descripcion || "",
        enp: p.enp || "",
        municipio: cleanName(muni || "TENERIFE")
      };
    });
    console.log(`[SUCCESS] ${pois.length} POIs cargados.`);
  } catch (e) { console.error("[ERROR] loadPOIs:", e.message); }
}

function loadBICs() {
  try {
    const bPath = path.join(__dirname, 'bic_inmuebles.geojson');
    const data = JSON.parse(fs.readFileSync(bPath, 'utf8').replace(/^\uFEFF/, ''));
    bics = data.features.map((f, i) => {
      const p = f.properties;
      let coords = [28.2916, -16.6291];
      if (f.geometry && f.geometry.coordinates) {
        let first;
        if (f.geometry.type === 'Point') first = f.geometry.coordinates;
        else if (f.geometry.type === 'Polygon') first = f.geometry.coordinates[0][0];
        else if (f.geometry.type === 'MultiPolygon') first = f.geometry.coordinates[0][0][0];
        if (first) coords = [first[1], first[0]];
      }
      return {
        id: i + 10000,
        name: p.bic_nombre,
        category: p.bic_categoria,
        municipio: cleanName(p.municipio_nombre),
        description: p.bic_descripcion,
        lat: coords[0], lng: coords[1]
      };
    });
    console.log(`[SUCCESS] ${bics.length} BICs cargados.`);
  } catch (e) { console.error("[ERROR] loadBICs:", e.message); }
}

function loadMuniBorders() {
  try {
    const mPath = path.join(__dirname, 'geo_canarias_municipios.geojson');
    const data = JSON.parse(fs.readFileSync(mPath, 'utf8'));
    muniBorders = data.features
      .filter(f => {
        const isla = f.properties.gcd_isla;
        const code = f.properties.geocode || "";
        return isla === "ES709" || code.startsWith("38");
      })
      .map(f => ({
        name: cleanName(f.properties.etiqueta),
        geometry: f.geometry
      }));
    console.log(`[SUCCESS] ${muniBorders.length} Municipios cargados.`);
  } catch (e) { console.error("[ERROR] loadMuniBorders:", e.message); }
}

async function loadItinerarios() {
  const csvData = [];
  const itCsvPath = path.join(__dirname, 'itinerarios.csv');
  const itGeojsonPath = path.join(__dirname, 'itinerarios.geojson');
  if (fs.existsSync(itCsvPath)) {
    await new Promise((resolve) => {
      fs.createReadStream(itCsvPath).pipe(csv()).on('data', (d) => csvData.push(d)).on('end', resolve);
    });
  }
  try {
    if (fs.existsSync(itGeojsonPath)) {
      const geojson = JSON.parse(fs.readFileSync(itGeojsonPath, 'utf8').replace(/^\uFEFF/, ''));
      itinerarios = geojson.features.map((f, index) => {
        const gp = f.properties;
        const geoMatricula = gp.itinerario_matricula || "";
        const csvMatch = csvData.find(c => normalizeKey(c.itinerario_matricula) === normalizeKey(geoMatricula));
        let paths = f.geometry.type === 'LineString' ? [f.geometry.coordinates] : f.geometry.coordinates;
        const dist = parseFloat(csvMatch ? csvMatch.itinerario_distancia : gp.itinerario_distancia) || 0;
        const desnivel = parseFloat(csvMatch ? csvMatch.itinerario_desnivel_positivo : 0) || 0;
        return {
          id: index + 1,
          matricula: geoMatricula,
          name: gp.itinerario_nombre,
          description: csvMatch ? `Ruta por ${csvMatch.municipios_nombres}.` : "Ruta oficial.",
          distancia: Math.round(dist),
          desnivelPos: Math.round(desnivel),
          difficulty: dist > 12000 ? "Alta" : (dist > 6000 ? "Media" : "Baja"),
          difficultyColor: dist > 12000 ? "#F44336" : (dist > 6000 ? "#FFC107" : "#4CAF50"),
          isCircular: (gp.itinerario_modalidad || "").toUpperCase().includes("CIRCULAR"),
          municipios: csvMatch ? csvMatch.municipios_nombres : "Tenerife",
          paths, startPoint: paths.length > 0 ? (Array.isArray(paths[0][0][0]) ? paths[0][0][0] : paths[0][0]) : null
        };
      });
      console.log(`[SUCCESS] ${itinerarios.length} Itinerarios cargados.`);
    }
  } catch (err) { console.error("[ERROR] loadItinerarios:", err.message); }
}

async function init() {
  loadPOIs(); loadBICs(); loadMuniBorders(); 
  await loadItinerarios();
  await fetchRealWeather();
  app.listen(port, '0.0.0.0', () => console.log(`TENERIFE QUEST API v5.0 - Ready`));
}
init();

app.get('/api/pois', (req, res) => res.json(pois));
app.get('/api/itinerarios', (req, res) => res.json(itinerarios));
app.get('/api/bics', (req, res) => res.json(bics));
app.get('/api/borders', (req, res) => res.json(muniBorders));
app.get('/api/weather', (req, res) => res.json(realWeatherStations));
app.get('/api/recommendation', (req, res) => res.json({ poi: pois[0], reason: "¡Recomendado!" }));
