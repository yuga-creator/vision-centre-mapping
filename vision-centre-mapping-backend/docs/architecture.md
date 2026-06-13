# System Architecture Overview

This document describes the architectural layout and component interactions of the **Vision 2020: Eye Care Centre Locator** application suite.

---

## 🏗️ Architectural Layout

The system follows a lightweight, serverless mobile architecture pattern. It consists of a mobile client frontend, a serverless NoSQL cloud database backend, and a standalone web administration tool.

```
                  ┌──────────────────────┐
                  │   uploader.html      │
                  │   (Bulk Upload)      │
                  └──────────┬───────────┘
                             │ (Write)
                             ▼
 ┌───────────────┐  (Read) ┌──────────────────────┐
 │   Flutter     ├────────►│  Firebase Firestore  │
 │  Mobile App   │         │  ("centers" Coll)    │
 └──────┬───┬────┘         └──────────────────────┘
        │   │
        │   └───────────────────────┐
        ▼ (Route request)           ▼ (Tile request)
┌────────────────┐          ┌────────────────┐
│   OSRM API     │          │  CartoDB Maps  │
│  (Routing)     │          │  (Tile Server) │
└────────────────┘          └────────────────┘
```

---

## 🧩 Key Components

### 1. Mobile Client Frontend (`vision-centre-mapping-frontend`)
A cross-platform Flutter application providing the main UI for users:
*   **Locating Module**: Employs the `geolocator` and `geocoding` libraries to acquire the user's current latitude/longitude coordinates or resolve physical coordinates from manually typed PIN codes.
*   **Map Renderer**: Uses `flutter_map` together with `flutter_map_cancellable_tile_provider` to query raster tiles from CartoDB Voyager servers and construct the map workspace.
*   **Routing Manager**: Connects to the public OSRM (Open Source Routing Machine) engine to download geoJSON driving paths between the user and target coordinates, displaying them as customized animated lines on the map.
*   **Local Caching (Legacy)**: Includes `sqflite` implementation (pre-seeded with 7 fallback locations) prepared for offline-first replication.

### 2. NoSQL Database Backend (`vision-centre-mapping-backend`)
Implemented as a serverless database using **Google Cloud Firestore**:
*   Stores coordinates, addresses, contacts, and metadata of all registered centers.
*   Directly accessed by the client app via the Firebase Flutter SDK, eliminating the need for custom API middleware.

### 3. CSV Bulk Uploader (`vision-centre-mapping-backend`)
A static web utility designed for administrative staff:
*   Uses `PapaParse` to parse localized CSV data files containing hundreds of centers.
*   Uploads parsed rows directly to Firestore using Firebase Compat client modules.

---

## 🔄 Interaction Scenarios

### Nearby Center Retrieval Flow
1.  User opens the mobile app.
2.  App checks GPS permissions and pulls local coordinates, or parses the manually submitted Indian PIN code.
3.  App queries *all* documents from the Firestore `centers` collection.
4.  App calculates the straight-line distance (using `latlong2` ellipsoidal math) between the user's coordinate and each center.
5.  App filters out centers beyond the chosen search radius (e.g. 50km) and sorts the remaining items in ascending order of proximity.

### Routing Execution Flow
1.  User taps a center card in the list view.
2.  App opens the map details page, passing the center's location and user's GPS position.
3.  App queries the OSRM route server: `https://router.project-osrm.org/route/v1/driving/...`
4.  OSRM replies with driving route geometry coordinates.
5.  App animates a polyline layer over the map representing the driving track.
