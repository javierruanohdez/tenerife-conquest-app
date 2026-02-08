# Memoria Técnica: Tenerife Eco-Explora
## II Concurso Datos Abiertos: Desarrollo de APP - Cabildo de Tenerife

### 1. Resumen Ejecutivo
"Tenerife Eco-Explora" es una solución móvil multiplataforma orientada a la sostenibilidad turística. Utiliza la gamificación para resolver el problema de la saturación en puntos de interés (POIs) icónicos de Tenerife, redirigiendo el flujo de visitantes hacia zonas menos concurridas y promoviendo el patrimonio cultural (BICs) y natural de la isla.

### 2. Arquitectura de Datos e Integración (ETL)
Como proyecto de ingeniería de datos, se ha implementado un flujo de procesamiento que garantiza la integridad y eficiencia de la información proveniente de `datos.tenerife.es`:

*   **Extracción y Normalización:** Se han integrado cuatro datasets principales:
    1.  **Puntos de Interés (GeoJSON):** Fuente primaria para la ubicación de áreas recreativas y miradores.
    2.  **Itinerarios de la Isla (CSV):** Datos sobre senderos oficiales, incluyendo dificultad, distancia y tipo de ruta.
    3.  **Bienes de Interés Cultural - BIC (CSV):** Información sobre el patrimonio histórico.
    4.  **Límites Municipales (GeoJSON):** Utilizados para el filtrado espacial y la asignación de contextos administrativos a los POIs.
*   **Procesamiento Backend (Node.js):** Se ha desarrollado un middleware que actúa como capa de limpieza. Dado que algunos datasets originales carecen de coordenadas precisas (como los BICs), el backend realiza un cruce de datos basado en el nombre del municipio y la proximidad a senderos conocidos para enriquecer la experiencia del usuario.
*   **Algoritmo de Saturación Dinámica:** Para la demo, se ha implementado un generador de estados de saturación que simula la carga turística en tiempo real, permitiendo al sistema de recompensas (Eco-Puntos) asignar mayores incentivos a las zonas con "Baja" ocupación.

### 3. Innovación y Gamificación
La aplicación introduce dos conceptos disruptivos:
*   **Niebla de Guerra (Fog of War):** Inspirado en videojuegos, el mapa de Tenerife aparece inicialmente oculto por una capa de niebla. Los usuarios "desbloquean" la geografía de la isla realizando visitas físicas reales (validación mediante GPS a menos de 500m).
*   **Eco-Puntos:** Un sistema de fidelización donde el usuario sube de nivel (de "Eco-Viajero" a "Guardián de la Isla"). Los puntos son inversamente proporcionales a la saturación del sitio visitado, incentivando el descubrimiento de "joyas ocultas" de la isla.

### 4. Accesibilidad Universal (Cumplimiento RD 1112/2018)
Este es el pilar central del desarrollo, garantizando que cualquier ciudadano pueda usar la app:
*   **Semántica Completa:** Todos los elementos interactivos cuentan con `Semantics` de Flutter, proporcionando descripciones claras para TalkBack y VoiceOver.
*   **Contraste y Color:** Se ha utilizado una paleta basada en Material Design 3 con ratios de contraste superiores a 4.5:1 para texto normal, cumpliendo con WCAG 2.1 AA.
*   **Navegación Adaptativa:** La interfaz permite el escalado de fuentes sin romper el diseño (text scaling support) y ofrece áreas de pulsación mínimas de 48x48dp.
*   **Jerarquía de Información:** Uso de encabezados semánticos para que los usuarios de lectores de pantalla puedan saltar rápidamente entre secciones de la app.

### 5. Sostenibilidad y Tecnologías Abiertas
*   **Tecnología:** Flutter 3.10+ para garantizar un código base único para APK (Android) e IPA (iOS).
*   **Licenciamiento:** El código se entrega bajo **EUPL v1.2**, promoviendo la soberanía tecnológica y la reutilización por parte del Cabildo.
*   **Mantenibilidad:** Arquitectura basada en el patrón de diseño "Provider", separando la lógica de negocio (servicios y proveedores) de la capa de presentación (screens).

### 6. Manual de Instalación y Ejecución
Para compilar los entregables obligatorios:
1.  **Android:** `flutter build apk --release` (Genera el APK).
2.  **iOS:** `flutter build ipa` (Requiere macOS para generar el fichero IPA).
3.  **Servidor:** `cd backend && npm install && node index.js`.

---
**Autor:** Estudiante de Ciencia e Ingeniería de Datos, ULPGC.
**Licencia:** European Union Public Licence v1.2.
**Datasets:** Portal de Datos Abiertos del Cabildo de Tenerife.
