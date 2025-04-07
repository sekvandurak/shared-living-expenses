import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/shared/models/user_model.dart';

/// A reusable widget for displaying a list of group members
/// with optional swipe-to-delete functionality
class MemberList extends ConsumerWidget {
  final List<UserModel> members;
  final String creatorId;
  final bool isUserCreator;
  final Function(String)? onRemoveMember;
  final Widget Function(UserModel)? itemBuilder;

  const MemberList({
    super.key,
    required this.members,
    required this.creatorId,
    required this.isUserCreator,
    this.onRemoveMember,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No members yet',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Invite friends to join this group',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        
        // Use custom item builder if provided
        if (itemBuilder != null) {
          return itemBuilder!(member);
        }
        
        final isCreator = member.id == creatorId;
        final canRemove = isUserCreator && onRemoveMember != null && !isCreator;
        
        // Build the member card
        Widget memberCard = Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar with proper styling
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isCreator 
                      ? colorScheme.primary 
                      : colorScheme.surfaceVariant,
                  foregroundColor: isCreator 
                      ? colorScheme.onPrimary 
                      : colorScheme.primary,
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Member info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCreator)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Creator',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.email,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Swipe indicator for removable members
                if (canRemove)
                  Tooltip(
                    message: 'Swipe left to remove',
                    child: Icon(
                      Icons.swipe_left,
                      color: colorScheme.outline,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        );
        
        // For creator or when removal is not allowed, return simple card
        if (!canRemove) {
          return memberCard;
        }
        
        // For removable members, wrap in dismissible
        return Dismissible(
          key: Key(member.id),
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
            if (!canRemove) {
              // Show permission error message if not the creator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Only the group creator can remove members'),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              return false;
            }
            
            // Show confirmation dialog
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove Member'),
                content: Text('Are you sure you want to remove ${member.name} from this group?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            if (onRemoveMember != null) {
              onRemoveMember!(member.id);
              
              // Show confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} was removed from the group'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          child: memberCard,
        );
      },
    );
  }
} 