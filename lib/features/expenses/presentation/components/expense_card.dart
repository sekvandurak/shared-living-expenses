import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ortak/core/utils/expense_utils.dart';
import 'package:ortak/shared/models/expense_model.dart';
import 'package:ortak/shared/models/user_model.dart';

/// A reusable card widget for displaying expense information
class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final UserModel payer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Function(DismissDirection)? onDismiss;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.payer,
    required this.onTap,
    required this.onEdit,
    this.onDismiss,
    this.confirmDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final content = ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          ExpenseUtils.getCategoryIcon(expense.category),
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      title: Text(expense.description),
      subtitle: Text(
        '${payer.name} • ${DateFormat.yMMMd().format(expense.date)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\$${expense.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
        ],
      ),
      onTap: onTap,
    );

    // If no dismiss functionality is provided, return just the ListTile
    if (onDismiss == null) {
      return Card(child: content);
    }

    // Otherwise, wrap it in a Dismissible
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: confirmDismiss,
      onDismissed: onDismiss,
      child: Card(child: content),
    );
  }
} 