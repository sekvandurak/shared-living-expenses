import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ortak/core/database/database_helper.dart';
import 'package:ortak/features/auth/providers/auth_provider.dart';
import 'package:ortak/shared/models/group_model.dart';
import 'package:ortak/shared/models/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/features/groups/providers/group_activities_provider.dart';

part 'group_provider.g.dart';

@riverpod
class Groups extends _$Groups {
  final _uuid = const Uuid();

  @override
  FutureOr<List<GroupModel>> build() async {
    return _loadGroups();
  }

  Future<List<GroupModel>> _loadGroups() async {
    final authState = await ref.read(authProvider.future);
    if (authState == null) return [];

    final db = await DatabaseHelper.instance.database;
    
    // Get groups where the user is a member
    final results = await db.rawQuery('''
      SELECT g.*, u.name as creatorName 
      FROM groups g
      INNER JOIN group_members gm ON g.id = gm.groupId
      INNER JOIN users u ON g.createdBy = u.id
      WHERE gm.userId = ?
      ORDER BY g.createdAt DESC
    ''', [authState.id]);

    return results.map((row) => GroupModel.fromMap(row)).toList();
  }

  Future<void> addGroup(GroupModel group) async {
    state = const AsyncValue.loading();
    try {
      // TODO: Implement adding group to backend
      final currentGroups = state.value ?? [];
      state = AsyncValue.data([...currentGroups, group]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createGroup({
    required String name,
    required String description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authState = await ref.read(authProvider.future);
      if (authState == null) throw Exception('User not authenticated');

      final db = await DatabaseHelper.instance.database;
      final groupId = _uuid.v4();

      await db.transaction((txn) async {
        // Create group
        await txn.insert('groups', {
          'id': groupId,
          'name': name,
          'description': description,
          'createdAt': DateTime.now().toIso8601String(),
          'createdBy': authState.id,
        });

        // Add creator as a member with admin role
        await txn.insert('group_members', {
          'groupId': groupId,
          'userId': authState.id,
          'joinedAt': DateTime.now().toIso8601String(),
          'role': 'admin',
        });
      });

      // Reload groups
      final updatedGroups = await _loadGroups();
      state = AsyncValue.data(updatedGroups);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    final userId = ref.read(authProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final db = await DatabaseHelper.instance.database;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    await db.update(
      'groups',
      updates,
      where: 'id = ? AND createdBy = ?',
      whereArgs: [groupId, userId],
    );

    ref.invalidateSelf();
  }

  Future<void> deleteGroup(String groupId) async {
    final userId = ref.read(authProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Delete group members
      await txn.delete(
        'group_members',
        where: 'groupId = ?',
        whereArgs: [groupId],
      );

      // Delete group expenses
      await txn.delete(
        'expenses',
        where: 'groupId = ?',
        whereArgs: [groupId],
      );

      // Delete expense splits
      await txn.delete(
        'expense_splits',
        where: 'expenseId IN (SELECT id FROM expenses WHERE groupId = ?)',
        whereArgs: [groupId],
      );

      // Delete group debts
      await txn.delete(
        'group_debts',
        where: 'groupId = ?',
        whereArgs: [groupId],
      );

      // Delete group
      await txn.delete(
        'groups',
        where: 'id = ? AND createdBy = ?',
        whereArgs: [groupId, userId],
      );
    });

    ref.invalidateSelf();
  }

  Future<void> addMember({
    required String groupId,
    required String email,
  }) async {
    final userId = ref.read(authProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final db = await DatabaseHelper.instance.database;
    
    // Check if user exists
    final userResult = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (userResult.isEmpty) {
      throw Exception('User not found');
    }

    final targetUserId = userResult.first['id'] as String;
    final targetUserName = userResult.first['name'] as String;

    // Check if user is already a member
    final memberResult = await db.query(
      'group_members',
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, targetUserId],
    );

    if (memberResult.isNotEmpty) {
      throw Exception('User is already a member of this group');
    }

    // Add user to group
    await db.insert('group_members', {
      'groupId': groupId,
      'userId': targetUserId,
      'role': 'member',
      'joinedAt': DateTime.now().toIso8601String(),
    });

    // Record member addition in activity
    await ref.read(groupActivitiesProvider(groupId).notifier).recordMemberAdded(
      groupId: groupId,
      newMemberId: targetUserId,
      newMemberName: targetUserName,
    );

    ref.invalidateSelf();
  }

  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    final currentUserId = ref.read(authProvider).value?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final db = await DatabaseHelper.instance.database;
    
    // Check if the current user is the creator of the group
    final creatorCheck = await db.query(
      'groups',
      where: 'id = ? AND createdBy = ?',
      whereArgs: [groupId, currentUserId],
    );
    
    if (creatorCheck.isEmpty) {
      throw Exception('Only the group creator can remove members');
    }

    await db.delete(
      'group_members',
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, userId],
    );

    ref.invalidateSelf();
  }

  Future<List<UserModel>> getMembers(String groupId) async {
    final db = await DatabaseHelper.instance.database;
    final members = await db.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN group_members gm ON u.id = gm.userId
      WHERE gm.groupId = ?
    ''', [groupId]);

    return members.map((m) => UserModel.fromMap(m)).toList();
  }
} 