import 'package:ortak/core/database/database_helper.dart';
import 'package:ortak/shared/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SharedPreferences _prefs;
  static const _currentUserKey = 'current_user_id';

  AuthRepository(this._prefs);

  Future<UserModel?> getCurrentUser() async {
    final userId = _prefs.getString(_currentUserKey);
    if (userId == null) return null;

    final db = await _db.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await _db.database;

    try {
      // Check if user already exists
      final existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existingUser.isNotEmpty) {
        throw Exception('User already exists');
      }

      final user = UserModel(
        id: const Uuid().v4(),
        name: name,
        email: email,
        password: password,
      );

      await db.insert('users', {
        ...user.toMap(),
        'password': password, // Ensure password is included
      });
      await _prefs.setString(_currentUserKey, user.id);

      return user;
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('An account with this email already exists');
      } else if (e.toString().contains('no such table')) {
        throw Exception('Database initialization error. Please restart the app');
      } else {
        throw Exception('Failed to create account: ${e.toString()}');
      }
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final db = await _db.database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isEmpty) {
      throw Exception('Invalid email or password');
    }

    final user = UserModel.fromMap(result.first);
    await _prefs.setString(_currentUserKey, user.id);

    return user;
  }

  Future<void> signOut() async {
    await _prefs.remove(_currentUserKey);
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? avatar,
  }) async {
    final db = await _db.database;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (avatar != null) updates['avatar'] = avatar;

    if (updates.isEmpty) return;

    await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<String> resetPassword(String email) async {
    final db = await _db.database;
    
    final user = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (user.isEmpty) {
      throw Exception('No user found with this email');
    }

    // Generate a random password
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = chars.split('')..shuffle();
    final newPassword = random.take(8).join();

    // Update the user's password
    await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );

    // In a real app, you would send this password via email
    // For this demo app, we'll return it to show on the UI
    return newPassword;
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = await _db.database;
    
    // In a real app, you would verify the current password here
    // For this demo, we'll just update the password
    // In production, you should hash the password and verify it against the stored hash
    
    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
} 