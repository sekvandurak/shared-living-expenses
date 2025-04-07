import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ortak/core/database/database_helper.dart';
import 'package:ortak/features/auth/providers/auth_provider.dart';
import 'package:ortak/shared/models/user_model.dart';
import 'dart:collection';

part 'friends_provider.g.dart';

// Model to represent a friend with their overall balance
class FriendBalanceModel {
  final UserModel user;
  final double balance; // Positive means they owe you, negative means you owe them

  FriendBalanceModel({
    required this.user,
    required this.balance,
  });
}

@Riverpod(keepAlive: false)
Future<List<FriendBalanceModel>> friends(FriendsRef ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return [];

  final db = await DatabaseHelper.instance.database;
  
  // Get all unique members from all groups the current user is in
  final membersResult = await db.rawQuery('''
    SELECT DISTINCT u.*
    FROM group_members gm1
    JOIN group_members gm2 ON gm1.groupId = gm2.groupId
    JOIN users u ON gm2.userId = u.id
    WHERE gm1.userId = ? AND u.id != ?
  ''', [userId, userId]);
  
  final members = membersResult.map((m) => UserModel.fromMap(m)).toList();
  
  // Map of users by ID for quick lookup
  final Map<String, UserModel> usersById = {};
  for (final member in members) {
    usersById[member.id] = member;
  }
  
  // Calculate net balance for each user across all groups
  final Map<String, double> totalBalances = {};
  
  // Initialize balances for all members
  for (final member in members) {
    totalBalances[member.id] = 0.0;
  }
  
  // Get all debts for the current user across all groups
  final debtsResult = await db.rawQuery('''
    SELECT gd.*, 
           c.name as creditorName, c.email as creditorEmail,
           d.name as debtorName, d.email as debtorEmail,
           g.name as groupName
    FROM group_debts gd
    JOIN users c ON gd.creditorId = c.id
    JOIN users d ON gd.debtorId = d.id
    JOIN groups g ON gd.groupId = g.id
    JOIN group_members gm ON gd.groupId = gm.groupId
    WHERE gm.userId = ? AND (gd.creditorId = ? OR gd.debtorId = ?)
  ''', [userId, userId, userId]);
  
  // Calculate net balance for each user across all groups
  for (final debt in debtsResult) {
    final creditorId = debt['creditorId'] as String;
    final debtorId = debt['debtorId'] as String;
    final amount = debt['amount'] as double;
    
    if (creditorId == userId) {
      // Current user is the creditor, so the friend owes them
      totalBalances[debtorId] = (totalBalances[debtorId] ?? 0) + amount;
      
      // Make sure we have user info
      if (!usersById.containsKey(debtorId)) {
        usersById[debtorId] = UserModel(
          id: debtorId,
          name: debt['debtorName'] as String,
          email: debt['debtorEmail'] as String,
        );
      }
    } else if (debtorId == userId) {
      // Current user is the debtor, so they owe the friend
      totalBalances[creditorId] = (totalBalances[creditorId] ?? 0) - amount;
      
      // Make sure we have user info
      if (!usersById.containsKey(creditorId)) {
        usersById[creditorId] = UserModel(
          id: creditorId,
          name: debt['creditorName'] as String,
          email: debt['creditorEmail'] as String,
        );
      }
    }
  }
  
  // Separate positive (creditors) and negative (debtors) balances
  final List<MapEntry<String, double>> creditors = [];
  final List<MapEntry<String, double>> debtors = [];
  
  for (final entry in totalBalances.entries) {
    final amount = entry.value;
    if (amount > 0.01) { // Small threshold to account for floating point errors
      creditors.add(MapEntry(entry.key, amount));
    } else if (amount < -0.01) {
      debtors.add(MapEntry(entry.key, -amount)); // Negate to get positive value
    }
  }
  
  // Sort by amount (largest first)
  creditors.sort((a, b) => b.value.compareTo(a.value));
  debtors.sort((a, b) => b.value.compareTo(a.value));
  
  // Simplify balances for display
  final List<FriendBalanceModel> friendBalances = [];
  
  // Add creditors (people who owe the current user)
  for (final entry in creditors) {
    if (usersById.containsKey(entry.key)) {
      friendBalances.add(FriendBalanceModel(
        user: usersById[entry.key]!,
        balance: entry.value, // Positive balance (they owe user)
      ));
    }
  }
  
  // Add debtors (people the current user owes)
  for (final entry in debtors) {
    if (usersById.containsKey(entry.key)) {
      friendBalances.add(FriendBalanceModel(
        user: usersById[entry.key]!,
        balance: -entry.value, // Negative balance (user owes them)
      ));
    }
  }
  
  // Add friends with zero balance
  for (final member in members) {
    if (!creditors.any((e) => e.key == member.id) && 
        !debtors.any((e) => e.key == member.id)) {
      friendBalances.add(FriendBalanceModel(
        user: member,
        balance: 0.0,
      ));
    }
  }
  
  // Sort: first by non-zero balances, then by balance amount (highest absolute value first)
  friendBalances.sort((a, b) {
    // First prioritize non-zero balances
    if (a.balance.abs() > 0.01 && b.balance.abs() <= 0.01) return -1;
    if (a.balance.abs() <= 0.01 && b.balance.abs() > 0.01) return 1;
    // Then sort by absolute value of balance
    return b.balance.abs().compareTo(a.balance.abs());
  });
  
  return friendBalances;
} 