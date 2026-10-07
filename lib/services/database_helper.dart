import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:filetrack/models/dossier.dart';
import 'package:filetrack/models/service_model.dart';
import 'package:filetrack/models/transmission.dart';
import 'package:filetrack/models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('filetrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE dossiers ADD COLUMN is_synced INTEGER DEFAULT 0');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE transmissions ADD COLUMN is_synced INTEGER DEFAULT 0');
        } catch (_) {}
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    // Table Services
    await db.execute('''
      CREATE TABLE services (
        id $textType PRIMARY KEY,
        name $textType,
        description $textType
      )
    ''');

    // Table Users
    await db.execute('''
      CREATE TABLE users (
        id $textType PRIMARY KEY,
        name $textType,
        service_id $textType,
        pin_hash $textType,
        role $textType,
        must_change_pin $integerType
      )
    ''');

    // Table Dossiers
    await db.execute('''
      CREATE TABLE dossiers (
        id $textType PRIMARY KEY,
        title $textType,
        created_at $textType,
        creator_service_id $textType,
        current_status $textType,
        is_synced $integerType DEFAULT 0
      )
    ''');

    // Table Transmissions
    await db.execute('''
      CREATE TABLE transmissions (
        id $textType PRIMARY KEY,
        dossier_id $textType,
        sender_service_id $textType,
        sender_user_id $textType,
        receiver_service_id $textType,
        receiver_user_id $textNullable,
        date_time $textType,
        observation $textType,
        type $textType,
        external_organization $textNullable,
        attachment_path $textNullable,
        status $textType,
        is_synced $integerType DEFAULT 0
      )
    ''');

    // Seeding initial data
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // 1. Initial Services
    final initialServices = [
      ServiceModel(
        id: 'SERV_SDCAF',
        name: 'SDCAF',
        description: 'Sous-Direction des Affaires Financières',
      ),
      ServiceModel(
        id: 'SERV_DG',
        name: 'Direction Générale',
        description: 'Direction Générale Hydro-Mekin',
      ),
      ServiceModel(
        id: 'SERV_ST',
        name: 'Service Technique',
        description: 'Service Technique & Exploitation',
      ),
    ];

    for (var service in initialServices) {
      await db.insert('services', service.toMap());
    }

    // 2. Default Admin User (PIN: 1234, hash SHA256)
    final initialPinHash = sha256.convert(utf8.encode('1234')).toString();
    final adminUser = User(
      id: 'ADMIN001',
      name: 'Admin SDCAF',
      serviceId: 'SERV_SDCAF',
      pinHash: initialPinHash,
      role: 'admin',
      mustChangePin: true,
    );

    await db.insert('users', adminUser.toMap());

    // 3. Sample initial Dossier
    final sampleDossier = Dossier(
      id: 'DOS-2026-001',
      title: 'Dossier d\'achat d\'équipements de maintenance Hydro-Mekin',
      createdAt: DateTime.now().toIso8601String(),
      creatorServiceId: 'SERV_SDCAF',
      currentStatus: 'Créé',
    );

    await db.insert('dossiers', sampleDossier.toMap());
  }

  // --- CRUD Services ---
  Future<int> insertService(ServiceModel service) async {
    final db = await instance.database;
    return await db.insert('services', service.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ServiceModel>> getAllServices() async {
    final db = await instance.database;
    final result = await db.query('services');
    return result.map((map) => ServiceModel.fromMap(map)).toList();
  }

  Future<ServiceModel?> getServiceById(String id) async {
    final db = await instance.database;
    final result =
        await db.query('services', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return ServiceModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateService(ServiceModel service) async {
    final db = await instance.database;
    return await db.update(
      'services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(String id) async {
    final db = await instance.database;
    return await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Users ---
  Future<int> insertUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUserById(String id) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(String id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Dossiers ---
  Future<int> insertDossier(Dossier dossier) async {
    final db = await instance.database;
    return await db.insert('dossiers', dossier.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Dossier>> getAllDossiers() async {
    final db = await instance.database;
    final result = await db.query('dossiers', orderBy: 'created_at DESC');
    return result.map((map) => Dossier.fromMap(map)).toList();
  }

  Future<Dossier?> getDossierById(String id) async {
    final db = await instance.database;
    final result =
        await db.query('dossiers', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Dossier.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateDossierStatus(String dossierId, String newStatus) async {
    final db = await instance.database;
    return await db.update(
      'dossiers',
      {'current_status': newStatus},
      where: 'id = ?',
      whereArgs: [dossierId],
    );
  }

  // --- CRUD Transmissions ---
  Future<int> insertTransmission(Transmission transmission) async {
    final db = await instance.database;
    return await db.insert('transmissions', transmission.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Transmission>> getAllTransmissions() async {
    final db = await instance.database;
    final result = await db.query('transmissions', orderBy: 'date_time DESC');
    return result.map((map) => Transmission.fromMap(map)).toList();
  }

  Future<List<Transmission>> getTransmissionsByDossier(String dossierId) async {
    final db = await instance.database;
    final result = await db.query(
      'transmissions',
      where: 'dossier_id = ?',
      whereArgs: [dossierId],
      orderBy: 'date_time ASC',
    );
    return result.map((map) => Transmission.fromMap(map)).toList();
  }

  Future<Transmission?> getLatestTransmissionForDossier(String dossierId) async {
    final db = await instance.database;
    final result = await db.query(
      'transmissions',
      where: 'dossier_id = ?',
      whereArgs: [dossierId],
      orderBy: 'date_time DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Transmission.fromMap(result.first);
    }
    return null;
  }

  Future<List<Transmission>> getPendingTransmissionsForService(String serviceId) async {
    final db = await instance.database;
    final result = await db.query(
      'transmissions',
      where: 'receiver_service_id = ? AND status = ?',
      whereArgs: [serviceId, 'émis'],
      orderBy: 'date_time DESC',
    );
    return result.map((map) => Transmission.fromMap(map)).toList();
  }

  // --- SYNC Helpers ---
  Future<List<Dossier>> getUnsyncedDossiers() async {
    final db = await instance.database;
    final result = await db.query('dossiers', where: 'is_synced = 0 OR is_synced IS NULL');
    return result.map((m) => Dossier.fromMap(m)).toList();
  }

  Future<List<Transmission>> getUnsyncedTransmissions() async {
    final db = await instance.database;
    final result = await db.query('transmissions', where: 'is_synced = 0 OR is_synced IS NULL');
    return result.map((m) => Transmission.fromMap(m)).toList();
  }

  Future<int> markDossiersAsSynced(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final db = await instance.database;
    return await db.update('dossiers', {'is_synced': 1},
        where: 'id IN (${ids.map((_) => '?').join(',')})', whereArgs: ids);
  }

  Future<int> markTransmissionsAsSynced(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final db = await instance.database;
    return await db.update('transmissions', {'is_synced': 1},
        where: 'id IN (${ids.map((_) => '?').join(',')})', whereArgs: ids);
  }
}
