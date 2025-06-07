import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/house.dart';
import '../models/vehicle.dart';
import '../models/visit.dart';
import '../models/pricing_config.dart';
import '../models/user.dart';
import '../models/parking_zone.dart';
import '../models/house_vehicle.dart';

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
      version: 3, // Incrementamos la versión para las nuevas tablas
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE pricing_config ADD COLUMN daily_rate REAL DEFAULT 10.0');
    }
    
    if (oldVersion < 3) {
      // Crear nuevas tablas
      await _createNewTables(db);
      // Actualizar tabla visits
      await db.execute('ALTER TABLE visits ADD COLUMN zone_id INTEGER');
      await db.execute('ALTER TABLE visits ADD COLUMN is_weekend_parking INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE visits ADD COLUMN is_communal_parking INTEGER DEFAULT 0');
    }
  }

  Future _createNewTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Parking zones table
    await db.execute('''
      CREATE TABLE parking_zones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zone_number INTEGER NOT NULL UNIQUE,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // House vehicles table
    await db.execute('''
      CREATE TABLE house_vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        house_id INTEGER NOT NULL,
        vehicle_id INTEGER NOT NULL,
        is_owner_vehicle INTEGER DEFAULT 0,
        registered_at TEXT NOT NULL,
        removed_at TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (house_id) REFERENCES houses (id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
      )
    ''');

    // Insertar zonas por defecto
    await _insertDefaultZones(db);
    
    // Insertar usuario administrador por defecto
    await _insertDefaultAdmin(db);
  }

  Future _insertDefaultZones(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Zonas de visitas (1-9)
    for (int i = 1; i <= 9; i++) {
      await db.insert('parking_zones', {
        'zone_number': i,
        'type': 'visitor',
        'name': 'Zona de Visitas $i',
        'description': 'Zona para vehículos de visitas',
        'created_at': now,
        'updated_at': now,
      });
    }
    
    // Zona 10 (overflow)
    await db.insert('parking_zones', {
      'zone_number': 10,
      'type': 'overflow',
      'name': 'Zona 10 - Vehículos Adicionales',
      'description': 'Zona obligatoria para casas con más de 2 vehículos',
      'created_at': now,
      'updated_at': now,
    });
    
    // Zona comunal
    await db.insert('parking_zones', {
      'zone_number': 11,
      'type': 'communal',
      'name': 'Casa Comunal',
      'description': 'Parqueadero de la casa comunal (\$1 de ingreso)',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future _insertDefaultAdmin(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'name': 'Administrador',
      'email': 'admin@parqueadero.com',
      'role': 'administrator',
      'created_at': now,
      'updated_at': now,
    });
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
        zone_id INTEGER,
        entry_time TEXT NOT NULL,
        exit_time TEXT,
        photo_path TEXT,
        amount REAL,
        is_paid INTEGER DEFAULT 0,
        notes TEXT,
        agent_name TEXT NOT NULL,
        is_weekend_parking INTEGER DEFAULT 0,
        is_communal_parking INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id),
        FOREIGN KEY (house_id) REFERENCES houses (id),
        FOREIGN KEY (zone_id) REFERENCES parking_zones (id)
      )
    ''');

    // Pricing config table
    await db.execute('''
      CREATE TABLE pricing_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hourly_rate REAL NOT NULL,
        daily_rate REAL NOT NULL,
        free_minutes INTEGER DEFAULT 15,
        minimum_charge REAL NOT NULL,
        maximum_charge REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await _createNewTables(db);

    // Insert default pricing config
    final now = DateTime.now().toIso8601String();
    await db.insert('pricing_config', {
      'hourly_rate': 1000.0,
      'daily_rate': 10000.0,
      'free_minutes': 15,
      'minimum_charge': 500.0,
      'maximum_charge': 50000.0,
      'created_at': now,
      'updated_at': now,
    });
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateUserRole(String email, UserRole role) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'role': role.name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // Parking zones operations
  Future<List<ParkingZone>> getAllParkingZones() async {
    final db = await instance.database;
    final result = await db.query('parking_zones', orderBy: 'zone_number');
    return result.map((map) => ParkingZone.fromMap(map)).toList();
  }

  Future<List<ParkingZone>> getVisitorZones() async {
    final db = await instance.database;
    final result = await db.query(
      'parking_zones', 
      where: 'type = ? AND is_active = 1', 
      whereArgs: ['visitor'],
      orderBy: 'zone_number'
    );
    return result.map((map) => ParkingZone.fromMap(map)).toList();
  }

  // House vehicles operations
  Future<int> insertHouseVehicle(HouseVehicle houseVehicle) async {
    final db = await instance.database;
    return await db.insert('house_vehicles', houseVehicle.toMap());
  }

  Future<List<Map<String, dynamic>>> getVehiclesByHouse(int houseId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        hv.*,
        v.license_plate,
        v.brand,
        v.model,
        v.color,
        v.vehicle_type
      FROM house_vehicles hv
      JOIN vehicles v ON hv.vehicle_id = v.id
      WHERE hv.house_id = ? AND hv.is_active = 1
      ORDER BY hv.is_owner_vehicle DESC, hv.registered_at ASC
    ''', [houseId]);
  }

  Future<Map<String, dynamic>> getHouseDebtSummary(int houseId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_visits,
        SUM(CASE WHEN amount IS NOT NULL THEN amount ELSE 0 END) as total_amount,
        SUM(CASE WHEN is_paid = 0 AND amount IS NOT NULL THEN amount ELSE 0 END) as pending_amount,
        SUM(CASE WHEN is_paid = 1 AND amount IS NOT NULL THEN amount ELSE 0 END) as paid_amount
      FROM visits 
      WHERE house_id = ?
    ''', [houseId]);
    
    return result.first;
  }

  // House operations (existing methods remain the same)
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

  // Vehicle operations (existing methods remain the same)
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

  // Visit operations (updated methods)
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
        h.owner_name,
        pz.name as zone_name,
        pz.zone_number
      FROM visits v
      JOIN vehicles ve ON v.vehicle_id = ve.id
      JOIN houses h ON v.house_id = h.id
      LEFT JOIN parking_zones pz ON v.zone_id = pz.id
      ORDER BY v.entry_time DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getActiveVisits() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        v.*,
        ve.license_plate,
        h.house_number,
        h.owner_name,
        pz.name as zone_name,
        pz.zone_number
      FROM visits v
      JOIN vehicles ve ON v.vehicle_id = ve.id
      JOIN houses h ON v.house_id = h.id
      LEFT JOIN parking_zones pz ON v.zone_id = pz.id
      WHERE v.exit_time IS NULL
      ORDER BY v.entry_time DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getVisitsNeedingAlert() async {
    final db = await instance.database;
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
    
    return await db.rawQuery('''
      SELECT 
        v.*,
        ve.license_plate,
        h.house_number,
        h.owner_name,
        pz.zone_number
      FROM visits v
      JOIN vehicles ve ON v.vehicle_id = ve.id
      JOIN houses h ON v.house_id = h.id
      LEFT JOIN parking_zones pz ON v.zone_id = pz.id
      WHERE v.exit_time IS NULL 
        AND v.entry_time < ?
        AND v.is_weekend_parking = 0
        AND (pz.type = 'visitor' OR pz.type IS NULL)
      ORDER BY v.entry_time ASC
    ''', [twoDaysAgo]);
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

  // Pricing config operations (existing methods remain the same)
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
