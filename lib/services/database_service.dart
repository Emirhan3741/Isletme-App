import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'locapo.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> initializeDatabase() async {
    if (!kIsWeb &&
        (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))) {
      await database;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        displayName TEXT,
        photoURL TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers(
        id TEXT PRIMARY KEY,
        ad TEXT NOT NULL,
        soyad TEXT NOT NULL,
        telefon TEXT,
        eposta TEXT,
        not TEXT,
        olusturulmaTarihi INTEGER NOT NULL,
        ekleyenKullaniciId TEXT NOT NULL,
        FOREIGN KEY (ekleyenKullaniciId) REFERENCES users (id)
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        miktar REAL NOT NULL,
        aciklama TEXT NOT NULL,
        kategori TEXT NOT NULL,
        tarih INTEGER NOT NULL,
        tip TEXT NOT NULL,
        musteriId TEXT,
        kullaniciId TEXT NOT NULL,
        olusturulmaTarihi INTEGER NOT NULL,
        FOREIGN KEY (musteriId) REFERENCES customers (id),
        FOREIGN KEY (kullaniciId) REFERENCES users (id)
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        baslik TEXT NOT NULL,
        icerik TEXT NOT NULL,
        kategori TEXT NOT NULL,
        oncelik TEXT NOT NULL,
        tamamlandi INTEGER NOT NULL DEFAULT 0,
        hatirlatmaTarihi INTEGER,
        etiketler TEXT,
        musteriId TEXT,
        kullaniciId TEXT NOT NULL,
        olusturulmaTarihi INTEGER NOT NULL,
        FOREIGN KEY (musteriId) REFERENCES customers (id),
        FOREIGN KEY (kullaniciId) REFERENCES users (id)
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses(
        id TEXT PRIMARY KEY,
        miktar REAL NOT NULL,
        kategori TEXT NOT NULL,
        aciklama TEXT NOT NULL,
        tarih INTEGER NOT NULL,
        fatura_no TEXT,
        tedarikci TEXT,
        odeme_yontemi TEXT,
        kullaniciId TEXT NOT NULL,
        olusturulmaTarihi INTEGER NOT NULL,
        FOREIGN KEY (kullaniciId) REFERENCES users (id)
      )
    ''');

    // Reports table (cache için)
    await db.execute('''
      CREATE TABLE reports(
        id TEXT PRIMARY KEY,
        rapor_tipi TEXT NOT NULL,
        veri TEXT NOT NULL,
        kullaniciId TEXT NOT NULL,
        olusturulmaTarihi INTEGER NOT NULL,
        son_guncelleme INTEGER NOT NULL,
        FOREIGN KEY (kullaniciId) REFERENCES users (id)
      )
    ''');
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
