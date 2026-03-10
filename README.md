# Memoria Técnica: Conquista Tenerife
## II Concurso Datos Abiertos: Desarrollo de APP - Cabildo de Tenerife

### 1. Resumen Ejecutivo
**Conquista Tenerife** es una solución móvil multiplataforma diseñada para revolucionar la forma en que ciudadanos y turistas exploran la isla de Tenerife. Mediante técnicas de gamificación (como la "Niebla de Guerra" y un sistema de "Conquistas"), la aplicación incentiva el descubrimiento del patrimonio cultural y natural, utilizando exclusivamente conjuntos de datos abiertos del Cabildo de Tenerife. El objetivo es promover un turismo sostenible, responsable y tecnológicamente avanzado.

**Conquista Tenerife** es una aplicación móvil multiplataforma que transforma la exploración de la isla en una experiencia interactiva y gamificada. Utilizando **datos abiertos del Cabildo de Tenerife**, la app invita a ciudadanos y turistas a descubrir el patrimonio cultural y natural mediante mecánicas de juego como **Niebla de Guerra**, **Conquistas** y **exploración geolocalizada**.

Este proyecto ha sido desarrollado para el **II Concurso de Datos Abiertos – Desarrollo de APP del Cabildo de Tenerife**, combinando **ingeniería de datos, desarrollo móvil y diseño centrado en el usuario**.

---

# ✨ Características principales

## 🌫️ Niebla de Guerra

Inspirado en los videojuegos de exploración.

El mapa de Tenerife comienza cubierto por una **niebla digital** que se va despejando a medida que el usuario visita lugares reales de la isla.

Esto fomenta:

* turismo activo
* exploración fuera de rutas saturadas
* descubrimiento progresivo del territorio

---

## 🏆 Sistema de Conquistas

Cada lugar visitado se convierte en una **conquista personal**.

La aplicación registra automáticamente:

* 📍 ubicación visitada
* 📅 fecha de exploración
* 🖼️ soporte visual del logro

Los usuarios pueden generar **tarjetas personalizadas para compartir en redes sociales** mediante la función **Captura Tenerife**.

---

## 📊 Dashboard de Exploración

La app incluye un panel estadístico que permite al usuario visualizar su actividad:

* distribución de visitas por tipo de patrimonio
* progreso de exploración de la isla
* evolución de conquistas a lo largo del tiempo

Todo representado mediante **gráficos dinámicos e intuitivos**.

---

# 🗺️ Datos Abiertos Utilizados

La aplicación se construye **exclusivamente con datasets públicos** disponibles en:

👉 [https://datos.tenerife.es](https://datos.tenerife.es)

Datasets integrados:

| Dataset                          | Formato | Uso                                       |
| -------------------------------- | ------- | ----------------------------------------- |
| Puntos de Interés                | GeoJSON | Áreas recreativas, miradores y patrimonio |
| Itinerarios de la Isla           | CSV     | Información técnica de senderos           |
| Bienes de Interés Cultural (BIC) | CSV     | Patrimonio histórico de Tenerife          |
| Límites Municipales              | GeoJSON | Zonificación y geofencing                 |

---

# ⚙️ Arquitectura del Proyecto

El sistema sigue una arquitectura **cliente–servidor** con una capa de enriquecimiento de datos.

```
datos.tenerife.es
        │
        ▼
   Procesamiento ETL
        │
        ▼
   Backend API REST (Node.js)
        │
        ▼
 App móvil Flutter
```

### Backend

El backend actúa como **motor de inteligencia geográfica**.

Funciones principales:

* normalización de datasets
* cruces espaciales entre senderos y patrimonio
* generación de recomendaciones de rutas
* filtrado de zonas con baja saturación turística

---

# ♿ Accesibilidad

La aplicación ha sido diseñada siguiendo las directrices del **Real Decreto 1112/2018** para garantizar accesibilidad universal.

Características implementadas:

* soporte completo para **TalkBack (Android)** y **VoiceOver (iOS)**
* uso extensivo de **Semantics en Flutter**
* **alto contraste visual**
* **escalado dinámico de texto**
* interfaz optimizada para **uso con una sola mano**

---

# 🌱 Sostenibilidad y Ciencia Ciudadana

Conquista Tenerife no solo promueve la exploración, sino también el **cuidado del territorio**.

Incluye un módulo de **reporte ciudadano** que permite a los usuarios comunicar:

* incidencias en senderos
* problemas en puntos de interés
* necesidades de mantenimiento

Estos datos pueden ayudar a las administraciones públicas a **mejorar la gestión del entorno natural**.

---

# 🛠️ Tecnologías

**Frontend**

* Flutter
* Dart
* Geolocalización
* Mapas interactivos

**Backend**

* Node.js
* API REST
* Procesamiento de datos geoespaciales

**Datos**

* GeoJSON
* CSV
* Open Data del Cabildo de Tenerife

---

# 🚀 Instalación y ejecución

## 1️⃣ Backend

```bash
cd backend
npm install
node index.js
```

---

## 2️⃣ Aplicación móvil

```bash
cd frontend
flutter pub get
flutter build apk --debug
```

---

# 👨‍💻 Equipo

**Autores**

* Yone Suárez
* Lucas Mendoza
* Javier Ruano

🎓 Estudiantes de **Ciencia e Ingeniería de Datos**
📍 Universidad de Las Palmas de Gran Canaria (ULPGC)

---

# 📄 Licencia

Este proyecto se distribuye bajo la licencia:

**European Union Public Licence (EUPL) v1.2**

---

⭐ Si te interesa el proyecto, ¡no olvides darle una estrella al repositorio!
