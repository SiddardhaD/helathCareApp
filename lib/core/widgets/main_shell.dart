import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../../features/documents/presentation/screens/documents_screen.dart';
import '../../../features/home/presentation/screens/home_screen.dart';
import '../../../features/medications/presentation/screens/medications_screen.dart';
import '../../../features/reminders/presentation/screens/reminders_screen.dart';

/// Root shell for authenticated users: a persistent bottom navigation bar
/// across the four MVP feature tabs. Kept as simple IndexedStack-based
/// navigation rather than nested go_router shells for the MVP — this keeps
/// state alive per tab (e.g. scroll position) without extra complexity.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    MedicationsScreen(),
    RemindersScreen(),
    DocumentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication_rounded),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder_rounded),
            label: 'Documents',
          ),
        ],
      ),
    );
  }
}
