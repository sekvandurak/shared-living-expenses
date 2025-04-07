import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/shared/models/user_model.dart';

/// A reusable form component for creating and editing expenses
class ExpenseForm extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final List<String> categories;
  final String selectedCategory;
  final String? selectedPayerId;
  final List<UserModel> members;
  final Map<String, double> splits;
  final bool isEqualSplit;
  final bool isLoading;
  final Function(String) onCategoryChanged;
  final Function(String) onPayerChanged;
  final Function(bool) onSplitTypeChanged;
  final Function() onSavePressed;
  final Function() onAmountChanged;

  const ExpenseForm({
    super.key,
    required this.formKey,
    required this.descriptionController,
    required this.amountController,
    required this.categories,
    required this.selectedCategory,
    required this.selectedPayerId,
    required this.members,
    required this.splits,
    required this.isEqualSplit,
    required this.isLoading,
    required this.onCategoryChanged,
    required this.onPayerChanged,
    required this.onSplitTypeChanged,
    required this.onSavePressed,
    required this.onAmountChanged,
  });

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: widget.descriptionController,
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
            controller: widget.amountController,
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
            onChanged: (_) => widget.onAmountChanged(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: widget.selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: widget.categories
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                widget.onCategoryChanged(value);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: widget.selectedPayerId,
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
                widget.onPayerChanged(value);
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
                selected: {widget.isEqualSplit},
                onSelectionChanged: (value) {
                  widget.onSplitTypeChanged(value.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildSplitAmountInputs(),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.isLoading ? null : widget.onSavePressed,
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Expense'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSplitAmountInputs() {
    if (widget.isEqualSplit) {
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
          text: (widget.splits[member.id] ?? 0).toString(),
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
                      widget.splits[member.id] = 0;
                    } else {
                      widget.splits[member.id] = double.parse(value);
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
            '\$${widget.splits.values.fold<double>(0, (a, b) => a + b).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.amountController.text.isNotEmpty &&
                      (double.parse(widget.amountController.text) -
                              widget.splits.values.fold<double>(0, (a, b) => a + b))
                          .abs() >
                      0.01
                  ? Colors.red
                  : null,
            ),
          ),
        ],
      ),
      if (widget.amountController.text.isNotEmpty &&
          (double.parse(widget.amountController.text) -
                  widget.splits.values.fold<double>(0, (a, b) => a + b))
              .abs() >
              0.01)
        const Text(
          'Total split amounts must equal the total expense amount',
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
    ];
  }
} 