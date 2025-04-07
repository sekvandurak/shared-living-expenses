import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ortak/core/database/database_helper.dart';
import 'package:ortak/features/auth/providers/auth_provider.dart';
import 'package:ortak/shared/models/activity_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

part 'group_activities_provider.g.dart';

@Riverpod(keepAlive: false)
class GroupActivities extends _$GroupActivities {
  final _uuid = const Uuid();

  @override
  Future<List<ActivityModel>> build(String groupId) async {
    final userId = ref.watch(authProvider).value?.id;
    if (userId == null) return [];

    final db = await DatabaseHelper.instance.database;
    final activities = await db.rawQuery('''
      SELECT a.*, u.name as actorName, t.name as targetName
      FROM activities a
      INNER JOIN users u ON a.actorId = u.id
      LEFT JOIN users t ON a.targetId = t.id
      WHERE a.groupId = ?
      ORDER BY a.timestamp DESC
    ''', [groupId]);

    return activities.map((a) {
      // Parse data if available
      Map<String, dynamic>? data;
      if (a['data'] != null) {
        try {
          data = json.decode(a['data'] as String) as Map<String, dynamic>;
        } catch (_) {
          data = null;
        }
      }
      
      return ActivityModel.fromMap({
        ...a,
        'data': data,
      });
    }).toList();
  }

  Future<void> addActivity({
    required String groupId,
    required String type,
    required String description,
    String? targetId,
    Map<String, dynamic>? data,
  }) async {
    final userId = ref.read(authProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final db = await DatabaseHelper.instance.database;
    final activityId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.insert('activities', {
      'id': activityId,
      'groupId': groupId,
      'type': type,
      'actorId': userId,
      'targetId': targetId,
      'description': description,
      'timestamp': now,
      'data': data != null ? json.encode(data) : null,
    });

    ref.invalidateSelf();
  }

  // Method to record expense creation
  Future<void> recordExpenseAdded({
    required String groupId,
    required String expenseId,
    required String description,
    required double amount,
    required String payerId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final payerResult = await db.query(
      'users',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [payerId],
    );
    
    final payerName = payerResult.isNotEmpty ? payerResult.first['name'] as String : 'Unknown';
    
    await addActivity(
      groupId: groupId,
      type: 'expense_added',
      description: '$payerName added expense "$description" for \$${amount.toStringAsFixed(2)}',
      targetId: null,
      data: {
        'expenseId': expenseId,
        'amount': amount,
        'description': description,
      },
    );
  }

  // Method to record settlement
  Future<void> recordSettlement({
    required String groupId,
    required String debtorId,
    required String creditorId,
    required double amount,
  }) async {
    final db = await DatabaseHelper.instance.database;
    
    // Get user names for the activity record
    final debtorResult = await db.query(
      'users',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [debtorId],
    );
    
    final creditorResult = await db.query(
      'users',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [creditorId],
    );
    
    final debtorName = debtorResult.isNotEmpty ? debtorResult.first['name'] as String : 'Unknown';
    final creditorName = creditorResult.isNotEmpty ? creditorResult.first['name'] as String : 'Unknown';
    
    // Update the debt in the database
    await db.transaction((txn) async {
      // Get existing debt
      final existingDebt = await txn.query(
        'group_debts',
        where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
        whereArgs: [groupId, debtorId, creditorId],
      );
      
      if (existingDebt.isNotEmpty) {
        final currentAmount = existingDebt.first['amount'] as double;
        final newAmount = currentAmount - amount;
        
        // If there's still debt remaining, update the record
        if (newAmount > 0.01) { // Small threshold for floating point errors
          await txn.update(
            'group_debts',
            {'amount': newAmount},
            where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
            whereArgs: [groupId, debtorId, creditorId],
          );
        } else {
          // Otherwise, delete the debt record
          await txn.delete(
            'group_debts',
            where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
            whereArgs: [groupId, debtorId, creditorId],
          );
        }
      }
    });
    
    // Record the settlement activity
    await addActivity(
      groupId: groupId,
      type: 'settlement',
      description: '$debtorName paid $creditorName \$${amount.toStringAsFixed(2)}',
      targetId: creditorId,
      data: {
        'amount': amount,
      },
    );
  }

  // Method to record member addition
  Future<void> recordMemberAdded({
    required String groupId,
    required String newMemberId,
    required String newMemberName,
  }) async {
    await addActivity(
      groupId: groupId,
      type: 'member_added',
      description: '$newMemberName joined the group',
      targetId: newMemberId,
    );
  }
} 