import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ortak/core/database/database_helper.dart';
import 'package:ortak/features/auth/providers/auth_provider.dart';
import 'package:ortak/shared/models/user_model.dart';
import 'dart:collection';

part 'group_balances_provider.g.dart';

/// Represents a debt between two users
class DebtModel {
  final UserModel creditor;
  final UserModel debtor;
  final double amount;

  DebtModel({
    required this.creditor,
    required this.debtor,
    required this.amount,
  });
}

@Riverpod(keepAlive: false)
Future<List<DebtModel>> groupBalances(GroupBalancesRef ref, String groupId) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return [];

  final db = await DatabaseHelper.instance.database;
  
  // Get all members in the group
  final membersResult = await db.rawQuery('''
    SELECT u.*
    FROM group_members gm
    JOIN users u ON gm.userId = u.id
    WHERE gm.groupId = ?
  ''', [groupId]);
  
  final members = membersResult.map((m) => UserModel.fromMap(m)).toList();
  
  // Map to store the net balance for each user
  final Map<String, double> balances = {};
  // Initialize with zero balances
  for (final member in members) {
    balances[member.id] = 0.0;
  }
  
  // Get all debts from the database
  final debtsResult = await db.rawQuery('''
    SELECT gd.*, 
           c.name as creditorName, c.email as creditorEmail,
           d.name as debtorName, d.email as debtorEmail
    FROM group_debts gd
    JOIN users c ON gd.creditorId = c.id
    JOIN users d ON gd.debtorId = d.id
    WHERE gd.groupId = ?
  ''', [groupId]);
  
  // Map of users by ID for quick lookup
  final Map<String, UserModel> usersById = {};
  for (final member in members) {
    usersById[member.id] = member;
  }
  
  // Calculate net balance for each user
  for (final debt in debtsResult) {
    final creditorId = debt['creditorId'] as String;
    final debtorId = debt['debtorId'] as String;
    final amount = debt['amount'] as double;
    
    // Update balances: positive means "is owed money", negative means "owes money"
    balances[creditorId] = (balances[creditorId] ?? 0) + amount;
    balances[debtorId] = (balances[debtorId] ?? 0) - amount;
    
    // Store user info for later
    if (!usersById.containsKey(creditorId)) {
      usersById[creditorId] = UserModel(
        id: creditorId,
        name: debt['creditorName'] as String,
        email: debt['creditorEmail'] as String,
      );
    }
    
    if (!usersById.containsKey(debtorId)) {
      usersById[debtorId] = UserModel(
        id: debtorId,
        name: debt['debtorName'] as String,
        email: debt['debtorEmail'] as String,
      );
    }
  }
  
  // Separate positive (creditors) and negative (debtors) balances
  final List<MapEntry<String, double>> creditors = [];
  final List<MapEntry<String, double>> debtors = [];
  
  for (final entry in balances.entries) {
    final amount = entry.value;
    if (amount > 0.01) { // Small threshold to account for floating point errors
      creditors.add(MapEntry(entry.key, amount));
    } else if (amount < -0.01) {
      debtors.add(MapEntry(entry.key, amount.abs()));
    }
  }
  
  // Sort by amount (largest first)
  creditors.sort((a, b) => b.value.compareTo(a.value));
  debtors.sort((a, b) => b.value.compareTo(a.value));
  
  // Calculate simplified settlements
  final List<DebtModel> simplifiedDebts = [];
  
  // Use greedy algorithm to minimize number of transactions
  final Queue<MapEntry<String, double>> creditorsQueue = Queue.from(creditors);
  final Queue<MapEntry<String, double>> debtorsQueue = Queue.from(debtors);
  
  while (creditorsQueue.isNotEmpty && debtorsQueue.isNotEmpty) {
    final creditor = creditorsQueue.first;
    final debtor = debtorsQueue.first;
    
    final payAmount = creditor.value < debtor.value ? creditor.value : debtor.value;
    
    // Round to 2 decimal places
    final roundedAmount = (payAmount * 100).round() / 100;
    
    if (roundedAmount > 0) {
      simplifiedDebts.add(DebtModel(
        creditor: usersById[creditor.key]!,
        debtor: usersById[debtor.key]!,
        amount: roundedAmount,
      ));
    }
    
    if ((creditor.value - payAmount).abs() < 0.01) {
      creditorsQueue.removeFirst();
    } else {
      creditorsQueue.removeFirst();
      creditorsQueue.addFirst(MapEntry(creditor.key, creditor.value - payAmount));
    }
    
    if ((debtor.value - payAmount).abs() < 0.01) {
      debtorsQueue.removeFirst();
    } else {
      debtorsQueue.removeFirst();
      debtorsQueue.addFirst(MapEntry(debtor.key, debtor.value - payAmount));
    }
  }
  
  return simplifiedDebts;
} 