import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "ortak.db";
  static const _databaseVersion = 2;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      print('Attempting to open database at path: $path');

      // Ensure the directory exists
      await Directory(documentsDirectory.path).create(recursive: true);

      // REMOVED: Database deletion code that was causing data loss
      // We'll use proper migrations in the future instead of deleting the database

      print('Opening or creating database');
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          print('Database opened successfully');
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        avatar TEXT
      )
    ''');

    // Groups table
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        avatar TEXT,
        createdAt TEXT NOT NULL,
        createdBy TEXT NOT NULL,
        FOREIGN KEY (createdBy) REFERENCES users (id)
      )
    ''');

    // Group members table
    await db.execute('''
      CREATE TABLE group_members (
        groupId TEXT NOT NULL,
        userId TEXT NOT NULL,
        role TEXT NOT NULL,
        joinedAt TEXT NOT NULL,
        PRIMARY KEY (groupId, userId),
        FOREIGN KEY (groupId) REFERENCES groups (id),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groupId TEXT NOT NULL,
        fromUserId TEXT NOT NULL,
        toUserId TEXT NOT NULL,
        type TEXT NOT NULL,
        read INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (groupId) REFERENCES groups (id),
        FOREIGN KEY (fromUserId) REFERENCES users (id),
        FOREIGN KEY (toUserId) REFERENCES users (id)
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        payerId TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (groupId) REFERENCES groups (id),
        FOREIGN KEY (payerId) REFERENCES users (id)
      )
    ''');

    // Expense splits table
    await db.execute('''
      CREATE TABLE expense_splits (
        expenseId TEXT NOT NULL,
        userId TEXT NOT NULL,
        amount REAL NOT NULL,
        PRIMARY KEY (expenseId, userId),
        FOREIGN KEY (expenseId) REFERENCES expenses (id),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Group debts table
    await db.execute('''
      CREATE TABLE group_debts (
        groupId TEXT NOT NULL,
        debtorId TEXT NOT NULL,
        creditorId TEXT NOT NULL,
        amount REAL NOT NULL,
        PRIMARY KEY (groupId, debtorId, creditorId),
        FOREIGN KEY (groupId) REFERENCES groups (id),
        FOREIGN KEY (debtorId) REFERENCES users (id),
        FOREIGN KEY (creditorId) REFERENCES users (id)
      )
    ''');
    
    // Activities table
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        type TEXT NOT NULL,
        actorId TEXT NOT NULL,
        targetId TEXT,
        description TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        data TEXT,
        FOREIGN KEY (groupId) REFERENCES groups (id),
        FOREIGN KEY (actorId) REFERENCES users (id),
        FOREIGN KEY (targetId) REFERENCES users (id)
      )
    ''');
  }
  
  // Handle database migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add activities table if upgrading to version 2
      await db.execute('''
        CREATE TABLE activities (
          id TEXT PRIMARY KEY,
          groupId TEXT NOT NULL,
          type TEXT NOT NULL,
          actorId TEXT NOT NULL,
          targetId TEXT,
          description TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          data TEXT,
          FOREIGN KEY (groupId) REFERENCES groups (id),
          FOREIGN KEY (actorId) REFERENCES users (id),
          FOREIGN KEY (targetId) REFERENCES users (id)
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 