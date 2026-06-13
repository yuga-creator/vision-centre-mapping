# Vision Centre Mapping - Frontend

This repository contains the mobile client application for the **Vision 2020: Eye Care Centre Locator** project. It is built using **Flutter** and provides an interactive map interface to search, filter, and navigate to the nearest eye care centers.

---

## 🚀 Features

*   **Nearby Search**: Automatically locates nearby centers based on the user's GPS coordinates or manually typed Indian PIN codes.
*   **Distance Filtering**: Users can filter centers within a custom radius (5km, 10km, 20km, 50km, or 100km).
*   **Interactive Maps**: High-performance mapping using CartoDB Voyager tiles and a cancellable tile provider.
*   **Animated Routing**: Connects to the Open Source Routing Machine (OSRM) driving route API and dynamically animates the travel path.
*   **One-Click Navigation**: Direct links to call centers or navigate to them via native external GPS apps (Google Maps / Apple Maps).
*   **Administrative Access**: Passcode-protected mode to add or remove centers inside the mobile interface.

---

## 🛠️ Prerequisites & Setup

Ensure you have the Flutter SDK installed on your system.

### 1. Environment Setup
*   **Flutter SDK**: `sdk: '>=3.10.1 <4.0.0'` (Dart 3.x)
*   For setup guidelines, visit the [Official Flutter Documentation](https://docs.flutter.dev/get-started/install).

### 2. Dependency Installation
Run the following command in the project root:
```bash
flutter pub get
```

---

## ⚙️ Configuration & Secrets

This project depends on Firebase Firestore. The configuration files contain private keys and are **excluded** from version control.

### Firebase Configuration
To connect the app to your Firebase project, obtain configuration files from your Firebase Console and place them in the following directories:

1.  **Android Configuration**:
    *   Download your `google-services.json` from the Firebase Console.
    *   Place it in: `android/app/google-services.json`
2.  **iOS Configuration**:
    *   Download your `GoogleService-Info.plist` from the Firebase Console.
    *   Place it in: `ios/Runner/GoogleService-Info.plist`

### Environment Variables
Copy `.env.example` to `.env` and fill in any customized environment configurations:
```bash
cp .env.example .env
```

---

## 🏃 Running the Application

To run the application locally on an emulator or a connected device:

```bash
# List available devices
flutter devices

# Run in debug mode
flutter run
```

To build a release binary:

```bash
# Android APK
flutter build apk --release

# iOS App Bundle
flutter build ipa --release
```

---

## 📁 Folder Structure

```
├── assets/             # Images and graphic assets
│   ├── splash.gif      # Splash loading animation
│   └── icon.png        # App launcher icon
├── lib/                # Dart source code
│   ├── main.dart       # App UI and routing logic
│   ├── firestore_helper.dart  # Cloud database helper
│   └── database_helper.dart   # Legacy SQLite database manager
├── test/               # Unit and integration tests
└── pubspec.yaml        # Package management and assets configuration
```

---

## 🤝 Handover & Customization

This project was prepared for **Appasamy Associates**. To customize branding, replace `assets/icon.png` and update references in `pubspec.yaml` under `flutter_launcher_icons`, then regenerate launcher icons:

```bash
flutter pub run flutter_launcher_icons
```

---

## 📄 License

This repository is distributed under the MIT License. See [LICENSE](LICENSE) for more details.
