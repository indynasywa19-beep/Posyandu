import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('si_posyandu.db');

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;

      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // =====================================================
  // DATABASE BARU
  // =====================================================

  Future<void> _createDB(Database db, int version) async {
    // TABEL ANAK
    await db.execute('''
      CREATE TABLE anak (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        nik TEXT NOT NULL,
        tanggalLahir TEXT NOT NULL,
        jenisKelamin TEXT NOT NULL
      )
    ''');

    // TABEL PEMERIKSAAN
    await db.execute('''
      CREATE TABLE pemeriksaan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anakId INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        beratBadan REAL NOT NULL,
        tinggiBadan REAL NOT NULL,
        catatan TEXT,
        FOREIGN KEY (anakId) REFERENCES anak (id)
      )
    ''');

    // TABEL IMUNISASI
    await db.execute('''
      CREATE TABLE imunisasi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anakId INTEGER NOT NULL,
        namaVaksin TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        keterangan TEXT,
        FOREIGN KEY (anakId) REFERENCES anak (id)
      )
    ''');
  }

  // =====================================================
  // UPGRADE DATABASE
  // =====================================================

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // VERSION 1 -> 2
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE pemeriksaan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          anakId INTEGER NOT NULL,
          tanggal TEXT NOT NULL,
          beratBadan REAL NOT NULL,
          tinggiBadan REAL NOT NULL,
          catatan TEXT,
          FOREIGN KEY (anakId) REFERENCES anak (id)
        )
      ''');
    }

    // VERSION 2 -> 3
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE imunisasi (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          anakId INTEGER NOT NULL,
          namaVaksin TEXT NOT NULL,
          tanggal TEXT NOT NULL,
          keterangan TEXT,
          FOREIGN KEY (anakId) REFERENCES anak (id)
        )
      ''');
    }
  }

  // =====================================================
  // CRUD ANAK
  // =====================================================

  Future<int> insertAnak(Map<String, dynamic> data) async {
    final db = await instance.database;

    return await db.insert('anak', data);
  }

  Future<List<Map<String, dynamic>>> getAllAnak() async {
    final db = await instance.database;

    return await db.query('anak', orderBy: 'id DESC');
  }

  Future<int> updateAnak(int id, Map<String, dynamic> data) async {
    final db = await instance.database;

    return await db.update('anak', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAnak(int id) async {
    final db = await instance.database;

    return await db.delete('anak', where: 'id = ?', whereArgs: [id]);
  }

  // =====================================================
  // CRUD PEMERIKSAAN
  // =====================================================

  Future<int> insertPemeriksaan(Map<String, dynamic> data) async {
    final db = await instance.database;

    return await db.insert('pemeriksaan', data);
  }

  Future<List<Map<String, dynamic>>> getAllPemeriksaan() async {
    final db = await instance.database;

    return await db.query('pemeriksaan', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getPemeriksaanByAnak(int anakId) async {
    final db = await instance.database;

    return await db.query(
      'pemeriksaan',
      where: 'anakId = ?',
      whereArgs: [anakId],
      orderBy: 'id DESC',
    );
  }

  Future<int> updatePemeriksaan(int id, Map<String, dynamic> data) async {
    final db = await instance.database;

    return await db.update(
      'pemeriksaan',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePemeriksaan(int id) async {
    final db = await instance.database;

    return await db.delete('pemeriksaan', where: 'id = ?', whereArgs: [id]);
  }

  // =====================================================
  // CRUD IMUNISASI
  // =====================================================

  Future<int> insertImunisasi(Map<String, dynamic> data) async {
    final db = await instance.database;

    return await db.insert('imunisasi', data);
  }

  Future<List<Map<String, dynamic>>> getAllImunisasi() async {
    final db = await instance.database;

    return await db.query('imunisasi', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getImunisasiByAnak(int anakId) async {
    final db = await instance.database;

    return await db.query(
      'imunisasi',
      where: 'anakId = ?',
      whereArgs: [anakId],
      orderBy: 'id DESC',
    );
  }

  Future<int> updateImunisasi(int id, Map<String, dynamic> data) async {
    final db = await instance.database;

    return await db.update('imunisasi', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteImunisasi(int id) async {
    final db = await instance.database;

    return await db.delete('imunisasi', where: 'id = ?', whereArgs: [id]);
  }
}
