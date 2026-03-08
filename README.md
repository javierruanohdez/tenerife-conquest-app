# Memoria Técnica: Conquista Tenerife
## II Concurso Datos Abiertos: Desarrollo de APP - Cabildo de Tenerife

### 1. Resumen Ejecutivo
**Conquista Tenerife** es una solución móvil multiplataforma diseñada para revolucionar la forma en que ciudadanos y turistas exploran la isla de Tenerife. Mediante técnicas de gamificación (como la "Niebla de Guerra" y un sistema de "Conquistas"), la aplicación incentiva el descubrimiento del patrimonio cultural y natural, utilizando exclusivamente conjuntos de datos abiertos del Cabildo de Tenerife. El objetivo es promover un turismo sostenible, responsable y tecnológicamente avanzado.

### 2. Arquitectura de Datos e Integración (ETL)
Como proyecto de ingeniería de datos, se ha implementado un flujo de procesamiento que garantiza la integridad y eficiencia de la información proveniente de `datos.tenerife.es`:

*   **Fuentes de Datos:** Se han integrado y normalizado cuatro datasets principales:
    1.  **Puntos de Interés (GeoJSON):** Localización y detalles de áreas recreativas, miradores y patrimonio.
    2.  **Itinerarios de la Isla (CSV):** Información técnica sobre senderos (distancia, dificultad, municipios).
    3.  **Bienes de Interés Cultural - BIC (CSV):** Catálogo del patrimonio histórico insular.
    4.  **Límites Municipales (GeoJSON):** Para la zonificación y el geofencing del mapa.
*   **Procesamiento Backend (Node.js):** Se ha desarrollado una API REST que actúa como capa de enriquecimiento. El backend realiza cruces espaciales para vincular BICs con senderos cercanos, permitiendo un motor de recomendación que sugiere rutas basadas en la riqueza patrimonial y la baja saturación.

### 3. Innovación y Experiencia de Usuario (UX)
*   **Niebla de Guerra:** El mapa de Tenerife se descubre dinámicamente a medida que el usuario visita físicamente los lugares, fomentando la exploración real.
*   **Sistema de Conquistas:** Cada visita se registra en un historial personal con fecha y soporte visual, permitiendo generar tarjetas de compartir personalizadas (**Captura Tenerife**) para redes sociales.
*   **Dashboard Estadístico:** Integración de análisis de datos mediante gráficos dinámicos que muestran la distribución de la exploración del usuario por categorías de patrimonio.

### 4. Accesibilidad Universal (Cumplimiento RD 1112/2018)
La aplicación garantiza la inclusión total:
*   **Semántica Completa:** Uso de etiquetas `Semantics` de Flutter para compatibilidad total con TalkBack (Android) y VoiceOver (iOS).
*   **Contraste y Diseño:** Paleta de colores validada para alta legibilidad y soporte para escalado de texto dinámico.
*   **Navegación Intuitiva:** Interfaz moderna basada en menús inferiores, optimizada para el uso con una sola mano.

### 5. Sostenibilidad y Tecnologías Abiertas
*   **Tecnología:** Flutter para un despliegue nativo multiplataforma.
*   **Licenciamiento:** El código se entrega bajo la **European Union Public Licence (EUPL) v1.2**.
*   **Ciencia Ciudadana:** Módulo integrado para que los usuarios reporten incidencias en tiempo real, devolviendo datos valiosos al Cabildo para el mantenimiento del entorno.

### 6. Manual de Instalación y Ejecución
1.  **Servidor:** `cd backend && npm install && node index.js`
2.  **App:** `cd frontend && flutter pub get && flutter build apk --debug`

---
**Autores:** Yone Suárez, Lucas Mendoza y Javier Ruano.
**Institución:** Estudiantes de Ciencia e Ingeniería de Datos, ULPGC.
**Licencia:** EUPL v1.2.
