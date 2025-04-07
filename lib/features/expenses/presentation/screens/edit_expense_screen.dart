import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/features/expenses/providers/expense_provider.dart';
import 'package:ortak/shared/models/user_model.dart';
import 'package:ortak/shared/models/expense_model.dart';


class EditExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<UserModel> members;
  final ExpenseModel expense;

  const EditExpenseScreen({
    super.key,
    required this.groupId,
    required this.members,
    required this.expense,
  });

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late String _selectedCategory;
  late Map<String, double> _splits = {};
  late bool _isEqualSplit = false;
  bool _isLoading = false;
  late String? _selectedPayerId;

  final List<String> _categories = [
    'Food',
    'Rent',
    'Utilities',
    'Groceries',
    'Entertainment',
    'Transportation',
    'Shopping',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.expense.description);
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _selectedCategory = widget.expense.category;
    _selectedPayerId = widget.expense.payerId;
    
    // Initialize splits from expense
    _initializeSplits();
    
    // Determine if it was an equal split originally
    _determineIfEqualSplit();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _initializeSplits() {
    // Initialize with actual splits from the expense
    _splits = Map.from(widget.expense.splits);
  }

  void _determineIfEqualSplit() {
    // Check if all split values are equal
    if (widget.expense.splits.isEmpty) return;
    
    final values = widget.expense.splits.values.toList();
    final firstValue = values.first;
    
    _isEqualSplit = values.every((value) => (value - firstValue).abs() < 0.01);
  }

  void _updateSplits() {
    if (_amountController.text.isEmpty) return;

    final amount = double.parse(_amountController.text);
    if (_isEqualSplit) {
      final splitAmount = (amount / widget.members.length * 100).round() / 100;
      var totalSplit = 0.0;
      for (int i = 0; i < widget.members.length; i++) {
        final member = widget.members[i];
        if (i == widget.members.length - 1) {
          _splits[member.id] = (amount - totalSplit);
        } else {
          _splits[member.id] = splitAmount;
          totalSplit += splitAmount;
        }
      }
    }
    setState(() {});
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final totalSplit = _splits.values.fold<double>(0, (a, b) => a + b);

    if ((totalSplit - amount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Split amounts must equal the total amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(groupExpensesProvider(widget.groupId).notifier).updateExpense(
            expenseId: widget.expense.id,
            groupId: widget.groupId,
            description: _descriptionController.text.trim(),
            amount: amount,
            category: _selectedCategory,
            splits: _splits,
            payerId: _selectedPayerId!,
          );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onChanged: (_) => _updateSplits(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPayerId,
              decoration: const InputDecoration(
                labelText: 'Paid by',
                border: OutlineInputBorder(),
              ),
              items: widget.members.map((member) => DropdownMenuItem(
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
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Split Type'),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Equal'),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Custom'),
                    ),
                  ],
                  selected: {_isEqualSplit},
                  onSelectionChanged: (value) {
                    setState(() {
                      _isEqualSplit = value.first;
                      _updateSplits();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildSplitAmountInputs(),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _saveExpense,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update Expense'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSplitAmountInputs() {
    if (_isEqualSplit) {
      return [];
    }

    return [
      const Text(
        'Custom Split Amounts',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      ...widget.members.map((member) {
        final controller = TextEditingController(
          text: (_splits[member.id] ?? 0).toString(),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(member.name),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    if (value.isEmpty) {
                      _splits[member.id] = 0;
                    } else {
                      _splits[member.id] = double.parse(value);
                    }
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('Total:'),
          const Spacer(),
          Text(
            '\$${_splits.values.fold<double>(0, (a, b) => a + b).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _amountController.text.isNotEmpty &&
                      (double.parse(_amountController.text) -
                              _splits.values.fold<double>(0, (a, b) => a + b))
                          .abs() >
                      0.01
                  ? Colors.red
                  : null,
            ),
          ),
        ],
      ),
      if (_amountController.text.isNotEmpty &&
          (double.parse(_amountController.text) -
                  _splits.values.fold<double>(0, (a, b) => a + b))
              .abs() >
              0.01)
        const Text(
          'Total split amounts must equal the total expense amount',
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
    ];
  }
} 