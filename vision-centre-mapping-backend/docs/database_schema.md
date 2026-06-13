# Firestore Database Schema Specification

This document specifies the schema structure for documents in the **`centers`** collection of the Cloud Firestore database.

---

## 📂 Collection: `centers`

Each document in this collection represents an individual eye care center. Documents use auto-generated alphanumeric IDs provided by Firestore (e.g., `3sD8KfJslK29Fsl2j3D1`).

### Field Schema

| Field Name | Firestore Data Type | Mandatory | Description | Example Value |
| :--- | :--- | :--- | :--- | :--- |
| **`name`** | `String` | Yes | The name of the eye care or vision center. | `"Aragandanallur"` |
| **`address`** | `String` | Yes | Complete postal address of the center. | `"3/378, Kamarajar road, Arakandanallur - 605 752"` |
| **`contact_number`** | `String` | No | Primary telephone or landline contact number. | `"04153-294160"` |
| **`latitude`** | `Number` (Double) | Yes | Latitude of the center on the map (WSG84). | `11.9766872` |
| **`longitude`** | `Number` (Double) | Yes | Longitude of the center on the map (WSG84). | `79.22298361` |
| **`partner_name`** | `String` | No | Name of the partnering hospital group. | `"Aravind Eye Hospital"` |
| **`base_hospital`** | `String` | No | Reference to the regional base hospital. | `"Pondicherry"` |
| **`centre_type`** | `String` | No | Category of center (e.g., Vision Center, Clinic). Defaults to `"Eye Centre"`. | `"Vision Center"` |

---

## 📝 Document JSON Representation

Here is a sample representation of a complete center record as stored in the Firestore database:

```json
{
  "name": "Gingee",
  "partner_name": "Aravind Eye Hospital",
  "centre_type": "Vision Center",
  "base_hospital": "Pondicherry",
  "latitude": 12.25822458,
  "longitude": 79.42111422,
  "address": "No. 9, Selva Vinayagar kovil street, Govt.girls higher secondary school near, Gingee - 604202",
  "contact_number": "04145-222600"
}
```

---

## 🛠️ Data Type Constraints

*   **Coordinates**: Latitude and Longitude must be stored as **numeric float/double types**, not strings. Storing them as strings will cause calculations inside the mobile client to fail on type-casting.
*   **Strings**: String fields should be trimmed of leading and trailing whitespace characters before database submission.
