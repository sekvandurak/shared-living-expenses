import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/features/groups/presentation/screens/groups_screen.dart';
import 'package:ortak/features/friends/presentation/screens/friends_screen.dart';
import 'package:ortak/features/auth/presentation/screens/profile_screen.dart';
import 'package:ortak/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:ortak/features/groups/presentation/screens/add_group_screen.dart';
import 'package:ortak/features/groups/providers/selected_group_provider.dart';
import 'package:ortak/features/groups/providers/group_members_provider.dart';
import 'package:ortak/shared/widgets/bottom_nav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FriendsScreen(),
    const GroupsScreen(),
    const Center(child: Text('Add')), // Placeholder for FAB action
    const ProfileScreen(),
  ];

  void _addExpense() {
    final selectedGroup = ref.read(selectedGroupProvider);
    if (selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a group first'),
        ),
      );
      return;
    }

    final membersAsync = ref.read(groupMembersProvider(selectedGroup.id));
    membersAsync.whenData((members) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(
            groupId: selectedGroup.id,
            members: members,
          ),
        ),
      );
    });
  }

  void _addGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddGroupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ortak'),
        actions: [
          // Logout button removed
        ],
      ),
      body: _getScreenForIndex(_currentIndex),
      floatingActionButton: null,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Middle button - Create a New Group
            _addGroup();
          } else {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }
  
  Widget _getScreenForIndex(int index) {
    // Handle "Add" button which doesn't have a screen
    if (index == 2) {
      return _screens[0]; // Default to Friends screen
    }
    return _screens[index];
  }
} 