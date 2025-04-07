import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ortak/core/database/database_helper.dart';
import 'package:ortak/features/auth/providers/auth_provider.dart';

part 'notification_provider.g.dart';

@riverpod
class Notifications extends _$Notifications {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final authState = await ref.watch(authProvider.future);
    if (authState == null) return [];

    final db = await DatabaseHelper.instance.database;
    
    // Get all unread notifications for the current user
    final notifications = await db.rawQuery('''
      SELECT n.*, g.name as groupName, u.name as inviterName
      FROM notifications n
      INNER JOIN groups g ON n.groupId = g.id
      INNER JOIN users u ON n.fromUserId = u.id
      WHERE n.toUserId = ? AND n.read = 0
      ORDER BY n.createdAt DESC
    ''', [authState.id]);

    return notifications;
  }

  Future<void> createInvitation({
    required String groupId,
    required String toUserId,
  }) async {
    final authState = await ref.read(authProvider.future);
    if (authState == null) throw Exception('User not authenticated');

    final db = await DatabaseHelper.instance.database;
    
    await db.insert('notifications', {
      'groupId': groupId,
      'fromUserId': authState.id,
      'toUserId': toUserId,
      'type': 'invitation',
      'read': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });

    ref.invalidateSelf();
  }

  Future<void> markAsRead(int notificationId) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.update(
      'notifications',
      {'read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );

    ref.invalidateSelf();
  }
} 