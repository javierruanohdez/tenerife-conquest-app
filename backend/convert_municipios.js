const fs = require('fs');
const path = require('path');

const csvPath = path.join(__dirname, 'municipios.csv');
const outputPath = path.join(__dirname, 'municipios_borders.json');

try {
    const content = fs.readFileSync(csvPath, 'utf8');
    const lines = content.split(/\r?\n/);
    const borders = [];

    for (let i = 1; i < lines.length; i++) {
        let line = lines[i].trim();
        if (!line) continue;

        // WKT is in quotes sometimes
        if (line.startsWith('"')) {
            // Find closing quote
            const endQuote = line.lastIndexOf('"');
            line = line.substring(1, endQuote);
        }

        if (line.includes('MULTILINESTRING')) {
            const coordsMatch = line.match(/\(\((.*)\)\)/);
            if (coordsMatch) {
                const coordsPart = coordsMatch[1];
                const points = coordsPart.split(',').map(p => {
                    const parts = p.trim().split(/\s+/);
                    if (parts.length >= 2) {
                        return [parseFloat(parts[1]), parseFloat(parts[0])]; // [lat, lng]
                    }
                    return null;
                }).filter(p => p !== null);
                
                if (points.length > 0) {
                    borders.push(points);
                }
            }
        }
    }

    fs.writeFileSync(outputPath, JSON.stringify(borders));
    console.log(`Converted ${borders.length} border segments.`);
} catch (err) {
    console.error("Error converting municipios:", err);
}