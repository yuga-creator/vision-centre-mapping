# CSV Bulk Upload Guide

This document describes how to prepare CSV files and use the bulk uploader tool (`uploader.html`) to populate the Firestore database.

---

## 📋 CSV Format Guidelines

To ensure the CSV data is parsed and uploaded successfully, your input file must follow these criteria:
*   **Encoding**: UTF-8 format.
*   **Header Row**: The first line of the CSV must contain column headers matching the schema fields.
*   **Mandatory Fields**: Every row must have a value for `name`, `latitude`, and `longitude`.

---

## 🗂️ CSV Schema Columns

The uploader matches CSV headers to database attributes. Use the exact spelling below:

| CSV Column Header | Mandatory | Data Constraint | Description |
| :--- | :--- | :--- | :--- |
| **`name`** | Yes | String (trimmed) | Unique name of the center. |
| **`latitude`** | Yes | Numeric Decimal | GPS Latitude (e.g. `11.9766872`). |
| **`longitude`** | Yes | Numeric Decimal | GPS Longitude (e.g. `79.22298361`). |
| **`address`** | No | String | Street address, city, and state. |
| **`contact_number`** | No | String | Phone or local landline number. |
| **`partner_name`** | No | String | Hospital affiliation group. |
| **`base_hospital`** | No | String | Regional base hospital link. |
| **`centre_type`** | No | String | Type (e.g., Vision Center). Defaults to "Eye Centre". |

---

## 📊 CSV Template Example

Open a text editor or Excel and create a file formatted as follows:

```csv
name,latitude,longitude,address,contact_number,partner_name,base_hospital,centre_type
Aragandanallur,11.9766872,79.22298361,"3/378, Kamarajar road, Arakandanallur - 605 752",04153-294160,Aravind Eye Hospital,Pondicherry,Vision Center
Buvanagiri,11.4424202,79.64765165,"68-B, Virudhachalam main road, Bhuvanagiri-608601",04144-241000,Aravind Eye Hospital,Pondicherry,Vision Center
```

---

## 🚀 Upload Step-by-Step Procedure

1.  Open your browser and load the local `uploader.html` file.
2.  Click **Choose File** (or **Browse**) and select your prepared CSV file.
3.  Click **Upload Data**.
4.  The system will parse the CSV rows using PapaParse and display progress in the log viewport.
5.  Check for validation alerts:
    *   ✅ Green log lines indicate successful documents added.
    *   ❌ Red log lines indicate errors or skipped lines (e.g., empty names or missing coordinates).
6.  Upon completion, a summary popup will display the count of successes and failures.
