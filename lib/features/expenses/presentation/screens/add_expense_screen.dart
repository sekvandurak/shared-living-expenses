import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/features/expenses/providers/expense_provider.dart';
import 'package:ortak/shared/models/user_model.dart';
import 'package:ortak/features/auth/providers/auth_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<UserModel> members;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.members,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Other';
  Map<String, double> _splits = {};
  Map<String, bool> _includedInSplit = {};
  bool _isEqualSplit = true;
  bool _isLoading = false;
  String? _selectedPayerId;

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
    _initializeSplits();
    _initializeIncludedMembers();
    _initializeSelectedPayer();
  }

  void _initializeSplits() {
    for (final member in widget.members) {
      _splits[member.id] = 0;
    }
  }

  void _initializeIncludedMembers() {
    for (final member in widget.members) {
      _includedInSplit[member.id] = true;
    }
  }

  void _initializeSelectedPayer() {
    // Default to first member if list is not empty
    if (widget.members.isNotEmpty) {
      _selectedPayerId = widget.members.first.id;
      
      // Try to set it to current user if they are a member
      final currentUser = ref.read(authProvider).value;
      if (currentUser != null) {
        final isMember = widget.members.any((m) => m.id == currentUser.id);
        if (isMember) {
          _selectedPayerId = currentUser.id;
        }
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateSplits() {
    if (_amountController.text.isEmpty) return;

    final amount = double.parse(_amountController.text);
    
    // Reset all splits first
    for (final member in widget.members) {
      _splits[member.id] = 0;
    }
    
    if (_isEqualSplit) {
      // Count how many members are included in the split
      final includedMembersCount = _includedInSplit.values.where((included) => included).length;
      
      if (includedMembersCount == 0) return;
      
      final splitAmount = (amount / includedMembersCount * 100).round() / 100;
      var totalSplit = 0.0;
      var index = 0;
      
      for (final member in widget.members) {
        if (!_includedInSplit[member.id]!) continue;
        
        index++;
        if (index == includedMembersCount) {
          // Last included member gets the remainder to avoid rounding issues
          _splits[member.id] = (amount - totalSplit);
        } else {
          _splits[member.id] = splitAmount;
          totalSplit += splitAmount;
        }
      }
    }
    setState(() {});
  }

  void _redistributeCustomSplits() {
    if (_amountController.text.isEmpty) return;
    
    final amount = double.parse(_amountController.text);
    final includedMembers = _includedInSplit.entries.where((entry) => entry.value).map((e) => e.key).toList();
    
    if (includedMembers.isEmpty) return;
    
    // First, capture the existing total of custom splits among included members
    final currentTotalSplit = includedMembers.fold<double>(
      0, (sum, memberId) => sum + (_splits[memberId] ?? 0)
    );
    
    // If the total is close to the target amount, we don't need to recalculate
    if ((currentTotalSplit - amount).abs() < 0.01) return;
    
    // Calculate an equal split for all included members
    final perPersonAmount = amount / includedMembers.length;
    
    // Distribute the amount equally among included members
    for (final memberId in includedMembers) {
      if (includedMembers.indexOf(memberId) == includedMembers.length - 1) {
        // Last person gets any remainder to avoid rounding issues
        final sumSoFar = includedMembers.sublist(0, includedMembers.length - 1)
            .fold<double>(0, (sum, id) => sum + (_splits[id] ?? 0));
        _splits[memberId] = amount - sumSoFar;
      } else {
        _splits[memberId] = perPersonAmount;
      }
    }
  }
  
  void _toggleMemberInclusion(String memberId) {
    setState(() {
      // Toggle the inclusion state
      _includedInSplit[memberId] = !_includedInSplit[memberId]!;
      
      // Set the split to 0 for excluded members
      if (!_includedInSplit[memberId]!) {
        _splits[memberId] = 0;
      }
      
      // Update splits based on the current mode
      if (_isEqualSplit) {
        _updateSplits();
      } else {
        _redistributeCustomSplits();
      }
    });
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
    
    // Check if at least one member is included
    if (!_includedInSplit.values.any((included) => included)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one member must be included in the split'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(groupExpensesProvider(widget.groupId).notifier).addExpense(
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
            content: Text('Error adding expense: $e'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Safety check - if somehow there are no members, show an error
    if (widget.members.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Expense'),
          elevation: 0,
        ),
        body: const Center(
          child: Text('This group has no members. Add members to create expenses.'),
        ),
      );
    }

    // Ensure the selected payer is valid
    if (_selectedPayerId == null || !widget.members.any((m) => m.id == _selectedPayerId)) {
      _selectedPayerId = widget.members.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // Form Fields Section
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                prefixIcon: Icon(Icons.description_outlined, color: colorScheme.primary),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                prefixIcon: Icon(Icons.attach_money, color: colorScheme.primary),
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
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                prefixIcon: Icon(Icons.category_outlined, color: colorScheme.primary),
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
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedPayerId,
              decoration: InputDecoration(
                labelText: 'Paid by',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
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
            
            // Split Type Section
            Container(
              margin: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Split Type',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Equal'),
                          ),
                          icon: const Icon(Icons.balance),
                        ),
                        ButtonSegment(
                          value: false,
                          label: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Custom'),
                          ),
                          icon: const Icon(Icons.tune),
                        ),
                      ],
                      selected: {_isEqualSplit},
                      onSelectionChanged: (value) {
                        final oldValue = _isEqualSplit;
                        final newValue = value.first;
                        
                        setState(() {
                          _isEqualSplit = newValue;
                          
                          // If switching from Equal to Custom, preserve the equal split values
                          // to use as starting point for custom mode
                          if (oldValue == true && newValue == false && _amountController.text.isNotEmpty) {
                            // No need to reset the splits here, we want to keep the equal values
                            // as a starting point for custom edits
                          } else {
                            _updateSplits();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Split Details Section
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Split Details',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...widget.members.map((member) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _includedInSplit[member.id]! 
                          ? colorScheme.outline.withOpacity(0.2)
                          : colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _toggleMemberInclusion(member.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _includedInSplit[member.id]!
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceVariant,
                            backgroundImage: member.avatar != null
                                ? NetworkImage(member.avatar!)
                                : null,
                            child: member.avatar == null
                                ? Text(
                                    member.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: _includedInSplit[member.id]!
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: _includedInSplit[member.id]!
                                      ? textTheme.titleMedium
                                      : textTheme.titleMedium?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.5),
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                ),
                                Text(
                                  member.email,
                                  style: _includedInSplit[member.id]!
                                      ? textTheme.bodySmall
                                      : textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: _includedInSplit[member.id],
                            onChanged: (_) => _toggleMemberInclusion(member.id),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!_isEqualSplit && _includedInSplit[member.id]!)
                            Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                key: ValueKey('split-${member.id}-${_includedInSplit.values.where((v) => v).length}'),
                                initialValue: (_splits[member.id] ?? 0) > 0
                                    ? (_splits[member.id] ?? 0).toString()
                                    : _amountController.text.isNotEmpty
                                        ? (double.parse(_amountController.text) /
                                            _includedInSplit.values.where((v) => v).length).toStringAsFixed(2)
                                        : '0',
                                decoration: InputDecoration(
                                  prefixText: '\$',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _splits[member.id] = double.tryParse(value) ?? 0;
                                  });
                                },
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            )
                          else if (_includedInSplit[member.id]!)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$${_splits[member.id]?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 60),
                        ],
                      ),
                    ),
                  ),
                )),
            
            // Save Button
            Container(
              margin: const EdgeInsets.only(top: 24),
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save Expense',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 