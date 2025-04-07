import 'package:flutter/material.dart';
import 'package:ortak/shared/models/expense_model.dart';
import 'package:ortak/shared/models/user_model.dart';
import 'package:intl/intl.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final ExpenseModel expense;
  final List<UserModel> members;

  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final payer = members.firstWhere(
      (m) => m.id == expense.payerId,
      orElse: () => UserModel(
        id: 'unknown',
        name: 'Unknown',
        email: '',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, payer),
          const SizedBox(height: 24),
          _buildDetailsCard(context),
          const SizedBox(height: 24),
          _buildSplitCard(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel payer) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(
            _getCategoryIcon(expense.category),
            size: 32,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          expense.description,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '\$${expense.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final payer = members.firstWhere(
      (m) => m.id == expense.payerId,
      orElse: () => UserModel(
        id: 'unknown',
        name: 'Unknown',
        email: '',
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Category',
              expense.category,
              _getCategoryIcon(expense.category),
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Paid by',
              payer.name,
              Icons.person,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Date',
              DateFormat.yMMMd().format(expense.date),
              Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...members.map((member) {
              final amount = expense.splits[member.id] ?? 0.0;
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: member.avatar != null
                          ? NetworkImage(member.avatar!)
                          : null,
                      child: member.avatar == null
                          ? Text(member.name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(member.name),
                    subtitle: Text(member.email),
                    trailing: Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: amount > 0
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (member != members.last) const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
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
} 