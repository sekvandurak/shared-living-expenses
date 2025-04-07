import 'package:flutter/material.dart';

/// Utility functions for expense-related operations
class ExpenseUtils {
  /// Gets the appropriate icon for a given expense category
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'rent':
        return Icons.home;
      case 'utilities':
        return Icons.power;
      case 'groceries':
        return Icons.shopping_cart;
      case 'entertainment':
        return Icons.movie;
      case 'transportation':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt;
    }
  }

  /// Gets a list of standard expense categories
  static List<String> getStandardCategories() {
    return [
      'Food',
      'Rent',
      'Utilities',
      'Groceries',
      'Entertainment',
      'Transportation',
      'Shopping',
      'Other',
    ];
  }

  /// Calculate equal splits for an expense amount among members
  static Map<String, double> calculateEqualSplits(double amount, List<String> memberIds) {
    final splits = <String, double>{};
    final splitAmount = (amount / memberIds.length * 100).round() / 100;
    
    var totalSplit = 0.0;
    for (int i = 0; i < memberIds.length; i++) {
      final memberId = memberIds[i];
      if (i == memberIds.length - 1) {
        // For the last member, assign the remaining amount to account for rounding errors
        splits[memberId] = (amount - totalSplit);
      } else {
        splits[memberId] = splitAmount;
        totalSplit += splitAmount;
      }
    }
    
    return splits;
  }

  /// Validates if all splits add up to the total amount
  static bool validateSplits(Map<String, double> splits, double totalAmount) {
    final sum = splits.values.fold<double>(0, (a, b) => a + b);
    return (sum - totalAmount).abs() <= 0.01; // Allow for small rounding errors
  }
} 