import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ortak/core/database/database_helper.dart';
import 'package:ortak/shared/models/user_model.dart';

part 'group_members_provider.g.dart';

/// Provider for fetching group members with auto-refresh capability
@Riverpod(keepAlive: false)
Future<List<UserModel>> groupMembers(GroupMembersRef ref, String groupId) async {
  final db = await DatabaseHelper.instance.database;
  final members = await db.rawQuery('''
    SELECT u.* FROM users u
    INNER JOIN group_members gm ON u.id = gm.userId
    WHERE gm.groupId = ?
    ORDER BY CASE WHEN u.id = (SELECT createdBy FROM groups WHERE id = ?) THEN 0 ELSE 1 END, u.name
  ''', [groupId, groupId]);

  return members.map((m) => UserModel.fromMap(m)).toList();
} 