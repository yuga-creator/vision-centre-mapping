import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('eyecare.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Create the Table
    await db.execute('''
      CREATE TABLE centers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        partner_name TEXT,
        centre_type TEXT,
        base_hospital TEXT,
        latitude REAL,
        longitude REAL,
        address TEXT,
        pin_code TEXT,
        contact_number TEXT,
        phone_num TEXT
      )
    ''');

    // 2. Insert Initial Data
    final List<Map<String, dynamic>> initialData = [
      {
        "name": "Aragandanallur",
        "partner_name": "Aravind Eye Hospital",
        "centre_type": "Vision Center",
        "base_hospital": "Pondicherry",
        "latitude": 11.9766872,
        "longitude": 79.22298361,
        "address": "3/378, Kamarajar road, lakshmi Vidhyalaya, Near Bsnl Office, Arakandanallur - 605 752",
        "pin_code": "605752",
        "contact_number": "04153-294160"
      },
      {
        "name": "Buvanagiri",
        "partner_name": "Aravind Eye Hospital",
        "centre_type": "Vision Center",
        "base_hospital": "Pondicherry",
        "latitude": 11.4424202,
        "longitude": 79.64765165,
        "address": "Near Ragavendira koil, 68-B, Virudhachalam main road, Melbhuvanagiri-Bhuvanagiri. Cuddalore-608601",
        "pin_code": "608601",
        "contact_number": "04144-241000"
      },
      {
        "name": "Gingee",
        "partner_name": "Aravind Eye Hospital",
        "centre_type": "Vision Center",
        "base_hospital": "Pondicherry",
        "latitude": 12.25822458,
        "longitude": 79.42111422,
        "address": "No. 9, Selva Vinayagar kovil street, Govt.girls higher secondary school near, Gingee - 604202",
        "pin_code": "604202",
        "contact_number": "04145-222600"
      },
      {
        "name": "Kilpennathur",
        "partner_name": "Aravind Eye Hospital",
        "centre_type": "Vision Center",
        "base_hospital": "Pondicherry",
        "latitude": 12.2422, 
        "longitude": 79.6524, 
        "address": "Kilpennathur, Tamil Nadu - 604601", 
        "pin_code": "604601",
        "contact_number": "04175-242200" 
      },
      {
        "name": "Kurinchipadi",
        "partner_name": "Aravind Eye Hospital",
        "centre_type": "Vision Center",
        "base_hospital": "Pondicherry",
        "latitude": 11.5618,
        "longitude": 79.6022, 
        "address": "71/26, Ellaikkal street, M.L.A.office (Opp),Kurinjipadi, Cuddalore 607302",
        "pin_code": "607302",
        "contact_number": "04142-258111" 
      },
      {
        "name": "Manalurpet",
        "partner_name": "Aravind Eye Hospital",
        "centre_type": "Vision Center",
        "base_hospital": "Pondicherry",
        "latitude": 12.0084735, 
        "longitude": 79.090000, 
        "address": "No. 16/A, Kammalar street, near post office ,Manalurpet-605754.Kallakurichi", 
        "pin_code": "605754",
        "contact_number": "04153-232440" 
      },
      {
        "name": "Marakanam",
        "partner_name": "Aravind Eye Hospital",
        "centre_type": "Vision Center",
        "base_hospital": "Pondicherry",
        "latitude": 12.1945810, 
        "longitude": 79.9439780, 
        "address": "25,Pondy road, old post office opp,Marakkanam,Villuppuram dt.",
        "pin_code": "604303", 
        "contact_number": "04147-239066" 
      },  
    ];

    for (var center in initialData) {
      await db.insert('centers', center);
    }
  }

  // --- CRUD METHODS ---

  // NOTE: Changed name from addCenter to insertCenter to match main.dart call
  Future<int> insertCenter(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('centers', row);
  }

  Future<List<Map<String, dynamic>>> getAllCenters() async {
    final db = await instance.database;
    return await db.query('centers');
  }
}