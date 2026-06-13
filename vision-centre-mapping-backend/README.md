# Vision Centre Mapping - Backend & Administration

This repository contains the backend database configuration, security rules, schemas, and administrative bulk upload tools for the **Vision 2020: Eye Care Centre Locator** application.

---

## 📁 Repository Structure

```
├── uploader.html               # CSV Web bulk upload interface
├── docs/                       # Project documentation
│   ├── architecture.md         # Database & component interactions
│   ├── database_schema.md      # Firestore field definitions
│   ├── deployment.md           # Deployment manual
│   └── csv_upload_guide.md     # CSV schema and uploader guidelines
├── firebase/                   # Firebase configuration scripts
│   ├── firestore.rules         # Security access rules
│   └── firestore.indexes.json  # Query index configuration
├── samples/                    # Test assets
│   └── centers_sample.csv      # CSV data template
└── .env.example                # Project environment variable placeholders
```

---

## 🏥 Bulk Data Uploader

The `uploader.html` file is a standalone web page that allows administrators to parse CSV files containing center listings and push them directly to Cloud Firestore.

### Setup & Launch
1.  **Configure API Credentials**: Open `uploader.html` in an editor and replace the `firebaseConfig` object (lines 40–48) with the credentials obtained from your Firebase Console.
2.  **Run the Uploader**: Open `uploader.html` directly in any web browser.
3.  **Upload CSV**: Select a CSV file conforming to the sample schema and click **Upload Data**.

---

## 🔒 Firebase Firestore Security Rules

To apply database security policies to your Firestore database:
1.  Navigate to **Firestore Database** in the Firebase Console.
2.  Select the **Rules** tab.
3.  Copy and paste the contents of `firebase/firestore.rules`.
4.  Click **Publish**.

*Note: In production, it is highly recommended to enforce authentication (`request.auth != null`) for all mutation calls (write, delete).*

---

## ⚙️ Environment Configuration

Copy `.env.example` to `.env` to define environment configurations for local CLI deployment tools:
```bash
cp .env.example .env
```

---

## 🤝 Handover & Deployment

This backend package is structured for deployment and ownership by **Appasamy Associates**. For step-by-step production setup, configuration, and maintenance instructions, refer to [docs/deployment.md](docs/deployment.md).

---

## 📄 License

This repository is distributed under the MIT License. See [LICENSE](LICENSE) for details.
