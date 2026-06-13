# Backend Deployment and Setup Guide

This document outlines the step-by-step instructions to deploy and configure the Firebase Firestore backend database for the **Vision Centre Mapping** application.

---

## 🚀 Setup Flow

### Step 1: Create a Firebase Project
1.  Navigate to the [Firebase Console](https://console.firebase.google.com/).
2.  Click **Add Project** and assign a name (e.g., `vision-centre-locator`).
3.  Configure Google Analytics preferences and click **Create Project**.

### Step 2: Provision Cloud Firestore
1.  In the Firebase Console sidebar, expand **Build** and select **Firestore Database**.
2.  Click **Create Database**.
3.  Choose your database location (select a regional hub close to your user base, e.g., `asia-south1` for India).
4.  Choose **Start in Test Mode** (which configures default rules) and click **Create**.

### Step 3: Deploy Security Rules and Indexes
To secure the database for public use:
1.  Go to the **Rules** tab in the Firestore Database console workspace.
2.  Open the local file [firebase/firestore.rules](../firebase/firestore.rules).
3.  Copy its contents, paste them into the rule editor, and click **Publish**.
4.  If composite indexing is ever required, deploy index configuration templates from [firebase/firestore.indexes.json](../firebase/firestore.indexes.json) via the Firebase CLI:
    ```bash
    firebase deploy --only firestore:indexes
    ```

### Step 4: Configure the Web Bulk Uploader
To configure the standalone administrative CSV uploader:
1.  In your Firebase Project dashboard home page, click the **Web Icon (</>)** to register a new Web App.
2.  Name the Web App (e.g., `bulk-csv-uploader`) and click **Register App**.
3.  Copy the generated `firebaseConfig` credentials object.
4.  Open the local file [uploader.html](../uploader.html) in an editor.
5.  Locate lines 40–48 and overwrite the placeholder object with your copied credentials:
    ```javascript
    const firebaseConfig = {
      apiKey: "YOUR_PROD_API_KEY",
      authDomain: "YOUR_PROD_AUTH_DOMAIN",
      projectId: "YOUR_PROD_PROJECT_ID",
      storageBucket: "YOUR_PROD_STORAGE_BUCKET",
      messagingSenderId: "YOUR_PROD_MESSAGING_SENDER_ID",
      appId: "YOUR_PROD_APP_ID",
      measurementId: "YOUR_PROD_MEASUREMENT_ID"
    };
    ```
6.  Save the file and double-click to run in your web browser.

### Step 5: Link Frontend Mobile Client
To feed the database to the Flutter application:
1.  In your Firebase Project home page, click **Add App** and select **Android**.
2.  Input your package name (found in `android/app/build.gradle.kts`, e.g., `com.example.eye_app`).
3.  Download the generated `google-services.json` file.
4.  Place this file in the frontend repository directory at: `vision-centre-mapping-frontend/android/app/google-services.json`
5.  Repeat the process for **iOS** if compiling for Apple devices, downloading `GoogleService-Info.plist` and placing it in: `vision-centre-mapping-frontend/ios/Runner/GoogleService-Info.plist`
