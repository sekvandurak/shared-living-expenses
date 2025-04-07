import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ortak/features/auth/repositories/auth_repository.dart';
import 'package:ortak/shared/models/user_model.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  late final AuthRepository _repository;

  @override
  Future<UserModel?> build() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = AuthRepository(prefs);
    return _repository.getCurrentUser();
  }

  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _repository.signUp(
        name: name,
        email: email,
        password: password,
      );
      state = AsyncData(user);
      return user;
    } catch (e) {
      // Don't update state for auth errors
      rethrow;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      state = AsyncData(user);
      return user;
    } catch (e) {
      // Don't update state for auth errors
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(null);
  }

  Future<void> updateProfile({
    String? name,
    String? avatar,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      await _repository.updateProfile(
        userId: currentUser.id,
        name: name,
        avatar: avatar,
      );
      state = await AsyncValue.guard(() => _repository.getCurrentUser());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) {
      throw Exception('Not authenticated');
    }

    try {
      await _repository.changePassword(
        userId: currentUser.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String> resetPassword(String email) async {
    try {
      return await _repository.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }
} 