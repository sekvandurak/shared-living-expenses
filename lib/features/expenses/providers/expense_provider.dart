import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ortak/core/database/database_helper.dart';
import 'package:ortak/features/auth/providers/auth_provider.dart';
import 'package:ortak/shared/models/expense_model.dart';
import 'package:ortak/features/groups/providers/group_activities_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

part 'expense_provider.g.dart';

@riverpod
class GroupExpenses extends _$GroupExpenses {
  final _uuid = const Uuid();

  @override
  Future<List<ExpenseModel>> build(String groupId) async {
    final userId = ref.watch(authProvider).value?.id;
    if (userId == null) return [];

    final db = await DatabaseHelper.instance.database;
    final expenses = await db.rawQuery('''
      SELECT e.*, u.name as payerName, 
        COALESCE(
          (
            SELECT json_group_object(userId, amount)
            FROM expense_splits
            WHERE expenseId = e.id
          ),
          '{}'
        ) as splits
      FROM expenses e
      INNER JOIN users u ON e.payerId = u.id
      WHERE e.groupId = ?
      ORDER BY e.date DESC
    ''', [groupId]);

    return expenses.map((e) {
      // Ensure splits is properly parsed as Map<String, double>
      final splitsStr = e['splits'] as String;
      final splitsMap = Map<String, dynamic>.from(
        splitsStr == '{}' ? {} : json.decode(splitsStr)
      );
      final splits = splitsMap.map((key, value) => 
        MapEntry(key, (value as num).toDouble())
      );
      
      return ExpenseModel.fromMap({
        ...e,
        'splits': splits,
      });
    }).toList();
  }

  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String category,
    required Map<String, double> splits,
    required String payerId,
  }) async {
    // Set to loading immediately to prevent UI lag
    state = const AsyncValue.loading();
    
    final userId = ref.read(authProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final db = await DatabaseHelper.instance.database;
    final expenseId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    try {
      await db.transaction((txn) async {
        // Insert expense
        await txn.insert('expenses', {
          'id': expenseId,
          'groupId': groupId,
          'description': description,
          'amount': amount,
          'category': category,
          'payerId': payerId,
          'date': now,
        });

        // Insert splits
        for (final entry in splits.entries) {
          await txn.insert('expense_splits', {
            'expenseId': expenseId,
            'userId': entry.key,
            'amount': entry.value,
          });
        }

        // Update group debts
        for (final entry in splits.entries) {
          if (entry.key == payerId) continue; // Skip payer's own split

          // Get existing debt
          final existingDebt = await txn.query(
            'group_debts',
            where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
            whereArgs: [groupId, entry.key, payerId],
          );

          if (existingDebt.isEmpty) {
            // Create new debt
            await txn.insert('group_debts', {
              'groupId': groupId,
              'debtorId': entry.key,
              'creditorId': payerId,
              'amount': entry.value,
            });
          } else {
            // Update existing debt
            final currentAmount = existingDebt.first['amount'] as double;
            await txn.update(
              'group_debts',
              {'amount': currentAmount + entry.value},
              where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
              whereArgs: [groupId, entry.key, payerId],
            );
          }
        }
      });

      // Record activity
      await ref.read(groupActivitiesProvider(groupId).notifier).recordExpenseAdded(
        groupId: groupId,
        expenseId: expenseId,
        description: description,
        amount: amount,
        payerId: payerId,
      );

      // Fetch the updated data immediately after the transaction
      final updatedData = await build(groupId);
      // Update state with the new data
      state = AsyncValue.data(updatedData);
    } catch (e, stack) {
      // On error, update state with error
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final userId = ref.read(authProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final db = await DatabaseHelper.instance.database;
    
    // Get expense details before deleting
    final expense = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [expenseId],
    );

    if (expense.isEmpty) {
      throw Exception('Expense not found');
    }

    final groupId = expense.first['groupId'] as String;
    final description = expense.first['description'] as String;
    final amount = expense.first['amount'] as double;
    final payerId = expense.first['payerId'] as String;

    await db.transaction((txn) async {
      // Get splits before deleting
      final splits = await txn.query(
        'expense_splits',
        where: 'expenseId = ?',
        whereArgs: [expenseId],
      );

      // Update group debts
      for (final split in splits) {
        final debtorId = split['userId'] as String;
        if (debtorId == payerId) continue; // Skip payer's own split

        final splitAmount = split['amount'] as double;

        // Update existing debt
        final existingDebt = await txn.query(
          'group_debts',
          where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
          whereArgs: [groupId, debtorId, payerId],
        );

        if (existingDebt.isNotEmpty) {
          final currentAmount = existingDebt.first['amount'] as double;
          final newAmount = currentAmount - splitAmount;

          if (newAmount > 0) {
            await txn.update(
              'group_debts',
              {'amount': newAmount},
              where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
              whereArgs: [groupId, debtorId, payerId],
            );
          } else {
            await txn.delete(
              'group_debts',
              where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
              whereArgs: [groupId, debtorId, payerId],
            );
          }
        }
      }

      // Delete splits
      await txn.delete(
        'expense_splits',
        where: 'expenseId = ?',
        whereArgs: [expenseId],
      );

      // Delete expense
      await txn.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [expenseId],
      );
    });

    // Record activity
    await ref.read(groupActivitiesProvider(groupId).notifier).addActivity(
      groupId: groupId,
      type: 'expense_deleted',
      description: 'Expense "$description" for \$${amount.toStringAsFixed(2)} was deleted',
      data: {
        'amount': amount,
        'description': description,
      },
    );

    ref.invalidateSelf();
  }

  Future<void> updateExpense({
    required String expenseId,
    required String groupId,
    required String description,
    required double amount,
    required String category,
    required Map<String, double> splits,
    required String payerId,
  }) async {
    final userId = ref.read(authProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');

    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Get original expense to check permissions and calculate debt changes
      final originalExpense = await txn.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [expenseId],
      );

      if (originalExpense.isEmpty) {
        throw Exception('Expense not found');
      }

      // Get original splits
      final originalSplits = await txn.query(
        'expense_splits',
        where: 'expenseId = ?',
        whereArgs: [expenseId],
      );

      final originalPayerId = originalExpense.first['payerId'] as String;

      // Update expense
      await txn.update('expenses', {
        'description': description,
        'amount': amount,
        'category': category,
        'payerId': payerId,
        'date': now,
      }, 
      where: 'id = ?',
      whereArgs: [expenseId]);

      // Delete old splits
      await txn.delete(
        'expense_splits',
        where: 'expenseId = ?',
        whereArgs: [expenseId],
      );

      // Insert new splits
      for (final entry in splits.entries) {
        await txn.insert('expense_splits', {
          'expenseId': expenseId,
          'userId': entry.key,
          'amount': entry.value,
        });
      }

      // Update group debts - reverse old splits first
      for (final split in originalSplits) {
        final debtorId = split['userId'] as String;
        if (debtorId == originalPayerId) continue;

        final splitAmount = split['amount'] as double;
        
        // Get existing debt from old split
        final existingDebt = await txn.query(
          'group_debts',
          where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
          whereArgs: [groupId, debtorId, originalPayerId],
        );

        if (existingDebt.isNotEmpty) {
          final currentAmount = existingDebt.first['amount'] as double;
          final newAmount = currentAmount - splitAmount;

          if (newAmount > 0) {
            await txn.update(
              'group_debts',
              {'amount': newAmount},
              where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
              whereArgs: [groupId, debtorId, originalPayerId],
            );
          } else {
            await txn.delete(
              'group_debts',
              where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
              whereArgs: [groupId, debtorId, originalPayerId],
            );
          }
        }
      }

      // Add new debts
      for (final entry in splits.entries) {
        if (entry.key == payerId) continue; // Skip payer's own split

        // Get existing debt
        final existingDebt = await txn.query(
          'group_debts',
          where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
          whereArgs: [groupId, entry.key, payerId],
        );

        if (existingDebt.isEmpty) {
          // Create new debt
          await txn.insert('group_debts', {
            'groupId': groupId,
            'debtorId': entry.key,
            'creditorId': payerId,
            'amount': entry.value,
          });
        } else {
          // Update existing debt
          final currentAmount = existingDebt.first['amount'] as double;
          await txn.update(
            'group_debts',
            {'amount': currentAmount + entry.value},
            where: 'groupId = ? AND debtorId = ? AND creditorId = ?',
            whereArgs: [groupId, entry.key, payerId],
          );
        }
      }
    });

    ref.invalidateSelf();
  }
} 