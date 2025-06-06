import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/house.dart';
import '../models/vehicle.dart';
import '../models/visit.dart';
import '../models/pricing_config.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('parqueadero.db');
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

  Future _createDB(Database db, int version) async {
    // Houses table
    await db.execute('''
      CREATE TABLE houses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        house_number TEXT NOT NULL UNIQUE,
        owner_name TEXT NOT NULL,
        owner_phone TEXT,
        owner_email TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Vehicles table
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        license_plate TEXT NOT NULL UNIQUE,
        brand TEXT,
        model TEXT,
        color TEXT,
        vehicle_type TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Visits table
    await db.execute('''
      CREATE TABLE visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        house_id INTEGER NOT NULL,
        entry_time TEXT NOT NULL,
        exit_time TEXT,
        photo_path TEXT,
        amount REAL,
        is_paid INTEGER DEFAULT 0,
        notes TEXT,
        agent_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id),
        FOREIGN KEY (house_id) REFERENCES houses (id)
      )
    ''');

    // Pricing config table
    await db.execute('''
      CREATE TABLE pricing_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hourly_rate REAL NOT NULL,
        free_minutes INTEGER DEFAULT 15,
        minimum_charge REAL NOT NULL,
        maximum_charge REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert default pricing config
    final now = DateTime.now().toIso8601String();
    await db.insert('pricing_config', {
      'hourly_rate': 2000.0,
      'free_minutes': 15,
      'minimum_charge': 1000.0,
      'maximum_charge': 10000.0,
      'created_at': now,
      'updated_at': now,
    });
  }

  // House operations
  Future<int> insertHouse(House house) async {
    final db = await instance.database;
    return await db.insert('houses', house.toMap());
  }

  Future<List<House>> getAllHouses() async {
    final db = await instance.database;
    final result = await db.query('houses', orderBy: 'house_number');
    return result.map((map) => House.fromMap(map)).toList();
  }

  Future<House?> getHouseById(int id) async {
    final db = await instance.database;
    final result = await db.query('houses', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return House.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateHouse(House house) async {
    final db = await instance.database;
    return await db.update(
      'houses',
      house.toMap(),
      where: 'id = ?',
      whereArgs: [house.id],
    );
  }

  Future<int> deleteHouse(int id) async {
    final db = await instance.database;
    return await db.delete('houses', where: 'id = ?', whereArgs: [id]);
  }

  // Vehicle operations
  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final db = await instance.database;
    final result = await db.query('vehicles', orderBy: 'license_plate');
    return result.map((map) => Vehicle.fromMap(map)).toList();
  }

  Future<Vehicle?> getVehicleByPlate(String licensePlate) async {
    final db = await instance.database;
    final result = await db.query(
      'vehicles',
      where: 'license_plate = ?',
      whereArgs: [licensePlate],
    );
    if (result.isNotEmpty) {
      return Vehicle.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    return await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // Visit operations
  Future<int> insertVisit(Visit visit) async {
    final db = await instance.database;
    return await db.insert('visits', visit.toMap());
  }

  Future<List<Map<String, dynamic>>> getAllVisitsWithDetails() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        v.*,
        ve.license_plate,
        ve.brand,
        ve.model,
        ve.color,
        h.house_number,
        h.owner_name
      FROM visits v
      JOIN vehicles ve ON v.vehicle_id = ve.id
      JOIN houses h ON v.house_id = h.id
      ORDER BY v.entry_time DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getActiveVisits() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        v.*,
        ve.license_plate,
        ve.brand,
        ve.model,
        ve.color,
        h.house_number,
        h.owner_name
      FROM visits v
      JOIN vehicles ve ON v.vehicle_id = ve.id
      JOIN houses h ON v.house_id = h.id
      WHERE v.exit_time IS NULL
      ORDER BY v.entry_time DESC
    ''');
  }

  Future<int> updateVisit(Visit visit) async {
    final db = await instance.database;
    return await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> deleteVisit(int id) async {
    final db = await instance.database;
    return await db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }

  // Pricing config operations
  Future<PricingConfig?> getPricingConfig() async {
    final db = await instance.database;
    final result = await db.query('pricing_config', limit: 1);
    if (result.isNotEmpty) {
      return PricingConfig.fromMap(result.first);
    }
    return null;
  }

  Future<int> updatePricingConfig(PricingConfig config) async {
    final db = await instance.database;
    return await db.update(
      'pricing_config',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
