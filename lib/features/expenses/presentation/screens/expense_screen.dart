import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/features/expenses/providers/expense_provider.dart';
import 'package:ortak/features/groups/providers/group_members_provider.dart';
import 'package:ortak/shared/widgets/error_widget.dart';
import 'package:ortak/shared/widgets/loading_widget.dart';
import 'package:ortak/features/auth/providers/auth_provider.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ExpenseScreen({super.key, required this.groupId});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  Map<String, double> _splits = {};
  String? _selectedPayerId;

  final _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showAddExpenseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Expense',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
                  
                  return membersAsync.when(
                    data: (members) {
                      // Initialize payer if not selected
                      if (_selectedPayerId == null) {
                        final currentUser = ref.read(authProvider).value;
                        if (currentUser != null) {
                          _selectedPayerId = currentUser.id;
                        }
                      }

                      if (_splits.isEmpty) {
                        // Initialize splits equally
                        final perPersonAmount = 
                            double.tryParse(_amountController.text) ?? 0.0;
                        if (perPersonAmount > 0) {
                          final splitAmount = perPersonAmount / members.length;
                          _splits = {
                            for (var member in members)
                              member.id: splitAmount
                          };
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedPayerId,
                            decoration: const InputDecoration(
                              labelText: 'Paid by',
                              border: OutlineInputBorder(),
                            ),
                            items: members.map((member) => DropdownMenuItem(
                              value: member.id,
                              child: Text(member.name),
                            )).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select who paid';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPayerId = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Split',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...members.map((member) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(member.name),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      initialValue: _splits[member.id]?.toString() ?? '0',
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        prefixText: '\$',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          _splits[member.id] = double.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                    loading: () => const LoadingWidget(),
                    error: (error, stack) => AppErrorWidget(
                      message: error.toString(),
                      onRetry: () => ref.refresh(groupMembersProvider(widget.groupId)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await ref.read(groupExpensesProvider(widget.groupId).notifier)
                          .addExpense(
                        groupId: widget.groupId,
                        description: _descriptionController.text,
                        amount: double.parse(_amountController.text),
                        category: _selectedCategory,
                        splits: _splits,
                        payerId: _selectedPayerId!,
                      );
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expense added successfully')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Add Expense'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final expensesAsync = ref.watch(groupExpensesProvider(widget.groupId));

          return expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No expenses yet'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddExpenseDialog,
                        child: const Text('Add Expense'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Dismissible(
                    key: Key(expense.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Expense'),
                          content: const Text(
                            'Are you sure you want to delete this expense?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) async {
                      try {
                        await ref.read(groupExpensesProvider(widget.groupId).notifier)
                            .deleteExpense(expense.id);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Expense deleted successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', '')
                              ),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    child: ListTile(
                      title: Text(expense.description),
                      subtitle: Text(
                        '${expense.category} • Paid by ${expense.payerName}'
                      ),
                      trailing: Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const LoadingWidget(),
            error: (error, stack) => AppErrorWidget(
              message: error.toString(),
              onRetry: () => ref.refresh(groupExpensesProvider(widget.groupId)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 