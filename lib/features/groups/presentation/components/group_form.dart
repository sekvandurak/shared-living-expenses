import 'package:flutter/material.dart';

/// A reusable form component for creating and editing groups
class GroupForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final String submitButtonText;
  final VoidCallback? onCancel;

  const GroupForm({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.isLoading,
    required this.onSubmit,
    this.submitButtonText = 'Save',
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (onCancel != null) ...[
              TextButton(
                onPressed: isLoading ? null : onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
            ],
            FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(submitButtonText),
            ),
          ],
        ),
      ],
    );
  }
}

/// A dialog that contains a GroupForm
class GroupFormDialog extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final String title;
  final String submitButtonText;

  const GroupFormDialog({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.isLoading,
    required this.onSubmit,
    required this.title,
    this.submitButtonText = 'Save',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: GroupForm(
        nameController: nameController,
        descriptionController: descriptionController,
        isLoading: isLoading,
        onSubmit: onSubmit,
        submitButtonText: submitButtonText,
        onCancel: () => Navigator.pop(context, false),
      ),
    );
  }
} 