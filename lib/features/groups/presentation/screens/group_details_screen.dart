import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/features/expenses/providers/expense_provider.dart';
import 'package:ortak/features/groups/providers/group_provider.dart';
import 'package:ortak/features/groups/providers/group_members_provider.dart';
import 'package:ortak/shared/models/group_model.dart';
import 'package:ortak/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:ortak/features/expenses/presentation/screens/expense_list_screen.dart';
import 'package:ortak/features/auth/providers/auth_provider.dart';
import 'package:ortak/features/groups/presentation/components/balance_list.dart';
import 'package:ortak/features/groups/presentation/components/activity_list.dart';
import 'package:ortak/features/groups/presentation/components/add_member_dialog.dart';
import 'package:intl/intl.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupDetailsScreen({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(groupExpensesProvider(widget.group.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          padding: const EdgeInsets.only(left: 4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Members'),
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(group: widget.group),
          _MembersTab(group: widget.group),
          _buildExpensesTab(ref),
          BalanceList(groupId: widget.group.id),
          ActivityList(groupId: widget.group.id),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildExpensesTab(WidgetRef ref) {
    // Use auto-refresh for better reactivity
    final membersAsync = ref.watch(groupMembersProvider(widget.group.id));
    // Watch expenses to react to changes
    final expensesAsync = ref.watch(groupExpensesProvider(widget.group.id));
    
    // If either is loading but not for the first time, show content
    if ((membersAsync is AsyncLoading && membersAsync.hasValue) ||
        (expensesAsync is AsyncLoading && expensesAsync.hasValue)) {
      // We have previous data, so use that while refreshing in background
      return ExpenseListScreen(
        groupId: widget.group.id,
        members: membersAsync.value ?? [],
      );
    }
    
    // Normal handling of state
    return membersAsync.when(
      data: (members) {
        return ExpenseListScreen(
          groupId: widget.group.id, 
          members: members,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  void _addExpense(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(widget.group.id));
    
    membersAsync.when(
      data: (members) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddExpenseScreen(
              groupId: widget.group.id,
              members: members,
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading members: $error'),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show different FABs based on the selected tab
    switch (_tabController.index) {
      case 1: // Members tab
        return FloatingActionButton(
          heroTag: 'add_member_fab',
          onPressed: () => AddMemberDialog.show(context, ref, widget.group.id),
          child: const Icon(Icons.person_add),
        );
      default:
        return null;
    }
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    AddMemberDialog.show(context, ref, widget.group.id);
  }
}

class _OverviewTab extends ConsumerWidget {
  final GroupModel group;

  const _OverviewTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Format the date for better readability
    final createdAt = DateTime.parse(group.createdAt.toString());
    final formatter = DateFormat('MMM d, yyyy');
    final formattedDate = formatter.format(createdAt);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group avatar and name
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                      style: textTheme.displayMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  group.name,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Description section
          _buildSectionTitle(context, 'Description'),
          Card(
            margin: const EdgeInsets.only(top: 8, bottom: 24),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.description.isEmpty ? 'No description provided' : group.description,
                      style: textTheme.bodyLarge?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Created date section
          _buildSectionTitle(context, 'Created'),
          Card(
            margin: const EdgeInsets.only(top: 8, bottom: 24),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formattedDate,
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          
          // Statistics section
          _buildSectionTitle(context, 'Statistics'),
          const SizedBox(height: 8),
          _buildStatsCards(context, ref),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget _buildStatsCards(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Watch the member count
    final membersAsync = ref.watch(groupMembersProvider(group.id));
    final expensesAsync = ref.watch(groupExpensesProvider(group.id));
    
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Members',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    membersAsync.when(
                      data: (members) => members.length.toString(),
                      loading: () => '...',
                      error: (_, __) => '?',
                    ),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expenses',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expensesAsync.when(
                      data: (expenses) => expenses.length.toString(),
                      loading: () => '...',
                      error: (_, __) => '?',
                    ),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final GroupModel group;

  const _MembersTab({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider with keepAlive: false to ensure frequent refreshes
    final membersAsync = ref.watch(groupMembersProvider(group.id));
    final currentUserId = ref.watch(authProvider).value?.id;
    final isCreator = group.createdBy == currentUserId;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Add a manual refresh mechanism for the UI
    ref.listen<AsyncValue<List<GroupModel>>>(
      groupsProvider, 
      (_, __) {
        // This will automatically refresh groupMembersProvider
        ref.invalidate(groupMembersProvider(group.id));
      }
    );

    return membersAsync.when(
      data: (members) {
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
                const SizedBox(height: 40),
                AddMemberDialog(groupId: group.id),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Invalidate both providers to force refresh
            ref.invalidate(groupsProvider);
            ref.invalidate(groupMembersProvider(group.id));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isGroupCreator = member.id == group.createdBy;
              
              // Create a card for both creator and regular members
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
                        backgroundColor: isGroupCreator 
                            ? colorScheme.primary 
                            : colorScheme.surfaceVariant,
                        foregroundColor: isGroupCreator 
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
                                if (isGroupCreator)
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
                      if (isCreator && !isGroupCreator)
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
              
              // For the creator or if current user isn't the creator, return simple card
              if (isGroupCreator || !isCreator) {
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
                  if (!isCreator) {
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
                onDismissed: (direction) async {
                  try {
                    await ref.read(groupsProvider.notifier).removeMember(
                      groupId: group.id,
                      userId: member.id,
                    );
                    
                    // Refresh the members list
                    ref.invalidate(groupMembersProvider(group.id));
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${member.name} has been removed from the group'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: colorScheme.error,
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
  
  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    AddMemberDialog.show(context, ref, group.id);
  }
} 