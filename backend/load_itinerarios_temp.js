function loadItinerarios() {
  try {
    const itPath = path.join(__dirname, 'itinerarios.geojson');
    if (fs.existsSync(itPath)) {
      const data = JSON.parse(fs.readFileSync(itPath, 'utf8').replace(/^\uFEFF/, ''));
      itinerarios = data.features.map((f, index) => {
        const p = f.properties;
        let paths = f.geometry.type === 'LineString' ? [f.geometry.coordinates] : f.geometry.coordinates;
        
        // LIMPIEZA DE DISTANCIA ROBUSTA
        let rawDist = (p.itinerario_distancia || "0").toString();
        // Cambiamos comas por puntos y eliminamos caracteres no numéricos excepto el punto
        let cleanDist = parseFloat(rawDist.replace(',', '.').replace(/[^0-9.]/g, '')) || 0;
        
        let difficulty = "Baja";
        let color = "#4CAF50"; 

        if (cleanDist > 15000) {
          difficulty = "Alta";
          color = "#F44336"; 
        } else if (cleanDist > 7000) {
          difficulty = "Media";
          color = "#FFC107"; 
        }

        const modalidad = (p.itinerario_modalidad || "").toUpperCase();
        const isCircular = modalidad.includes("CIRCULAR") || p.itinerario_inicio === p.itinerario_fin;

        return {
          id: index + 1,
          name: p.itinerario_nombre || "Ruta",
          matricula: p.itinerario_matricula || "S/N",
          distancia: cleanDist,
          difficulty: difficulty,
          difficultyColor: color,
          isCircular: isCircular,
          municipios: Array.isArray(p.itinerario_altura_maxima) ? p.itinerario_altura_maxima.join(", ") : "Tenerife",
          paths: paths,
          startPoint: f.geometry.type === 'LineString' ? f.geometry.coordinates[0] : f.geometry.coordinates[0][0]
        };
      });
      console.log(`[SUCCESS] Itinerarios clasificados por distancia.`);
    }
  } catch (err) { console.error("Error loadItinerarios:", err); }
}
