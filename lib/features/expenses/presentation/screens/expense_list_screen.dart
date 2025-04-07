import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/features/expenses/providers/expense_provider.dart';
import 'package:ortak/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:ortak/features/expenses/presentation/screens/expense_details_screen.dart';
import 'package:ortak/features/expenses/presentation/screens/edit_expense_screen.dart';
import 'package:ortak/shared/models/user_model.dart';
import 'package:ortak/shared/models/expense_model.dart';
import 'package:intl/intl.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<UserModel> members;

  const ExpenseListScreen({
    super.key,
    required this.groupId,
    required this.members,
  });

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(groupExpensesProvider(widget.groupId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        elevation: 0,
      ),
      body: expensesAsync.when(
        loading: () {
          // If we have previous data while loading, show it instead of spinner
          if (expensesAsync.hasValue) {
            return _buildExpenseList(context, expensesAsync.value!);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (expenses) => _buildExpenseList(context, expenses),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expense_list_fab',
        onPressed: () => _addExpense(context, ref),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, List<ExpenseModel> expenses) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No expenses yet',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Add your first expense by tapping the + button',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _addExpense(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final payer = widget.members.firstWhere(
          (m) => m.id == expense.payerId,
          orElse: () => UserModel(
            id: 'unknown',
            name: 'Unknown',
            email: '',
          ),
        );
        
        // Get category color based on category
        final categoryColor = _getCategoryColor(expense.category, colorScheme);
        final formattedDate = DateFormat.yMMMd().format(expense.date);

        return Dismissible(
          key: Key(expense.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.delete_outlined,
              color: colorScheme.onError,
              size: 28,
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Expense'),
                content: const Text(
                  'Are you sure you want to delete this expense?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            ref
                .read(groupExpensesProvider(widget.groupId).notifier)
                .deleteExpense(expense.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Expense deleted'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () {
                    // Ideally implement undo functionality here
                  },
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpenseDetailsScreen(
                      expense: expense,
                      members: widget.members,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(expense.category),
                        color: categoryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.description,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                payer.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  formattedDate,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              expense.category,
                              style: textTheme.labelSmall?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${expense.amount.toStringAsFixed(2)}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: colorScheme.primary,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                            padding: const EdgeInsets.all(8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          constraints: const BoxConstraints(
                            minHeight: 36,
                            minWidth: 36,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _editExpense(context, ref, expense, widget.members);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category, ColorScheme colorScheme) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'rent':
        return Colors.blue;
      case 'utilities':
        return Colors.amber;
      case 'groceries':
        return Colors.green;
      case 'entertainment':
        return Colors.purple;
      case 'transportation':
        return Colors.teal;
      case 'shopping':
        return Colors.pink;
      default:
        return colorScheme.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_outlined;
      case 'rent':
        return Icons.home_outlined;
      case 'utilities':
        return Icons.power_outlined;
      case 'groceries':
        return Icons.shopping_cart_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'transportation':
        return Icons.directions_car_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  void _addExpense(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupId: widget.groupId,
          members: widget.members,
        ),
      ),
    );
    
    // If we returned from the add screen, refresh the expenses
    if (result == true) {
      // Explicitly refresh the expenses list
      ref.invalidate(groupExpensesProvider(widget.groupId));
    }
  }

  void _editExpense(BuildContext context, WidgetRef ref, ExpenseModel expense, List<UserModel> members) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(
          groupId: widget.groupId,
          members: widget.members,
          expense: expense,
        ),
      ),
    );
    
    // If we returned from the edit screen, refresh the expenses
    if (result == true) {
      // Explicitly refresh the expenses list
      ref.invalidate(groupExpensesProvider(widget.groupId));
    }
  }
} 