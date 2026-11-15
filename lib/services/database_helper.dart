import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthDuplicateException implements Exception {
  final String message;
  AuthDuplicateException(this.message);

  @override
  String toString() => message;
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  DatabaseHelper.withDatabase(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final factory = isDesktop ? databaseFactoryFfi : databaseFactory;
    final dbPath = await factory.getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.databaseVersion,
        onCreate: _createDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.userTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await database;
    final results = await db.query(
      AppConstants.userTable,
      where: 'LOWER(username) = LOWER(?)',
      whereArgs: [username.trim()],
    );

    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  Future<int> registerUser(UserModel user) async {
    final db = await database;

    final existingUser = await getUserByUsername(user.username);
    if (existingUser != null) {
      throw AuthDuplicateException('Username sudah digunakan! Gunakan username lain.');
    }

    return await db.insert(
      AppConstants.userTable,
      {
        'username': user.username.trim(),
        'password': user.password,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<UserModel?> loginUser(String username, String password) async {
    final db = await database;
    final results = await db.query(
      AppConstants.userTable,
      where: 'LOWER(username) = LOWER(?) AND password = ?',
      whereArgs: [username.trim(), password],
    );

    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

