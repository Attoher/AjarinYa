import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/views/dashboard_screen.dart';
import 'package:ajarin_ya/views/study_spot_screen.dart';
import 'package:ajarin_ya/views/notes_collection_screen.dart';
import 'package:ajarin_ya/views/question_forum_screen.dart';
import 'package:ajarin_ya/views/pomodoro_screen.dart';
import 'package:ajarin_ya/views/login_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const StudySpotScreen(),
    const NotesCollectionScreen(),
    const QuestionForumScreen(),
    const PomodoroScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Jika pengguna belum masuk / terotentikasi, alihkan secara asinkron ke layar Login premium
    if (!authViewModel.isAuthenticated) {
      return const LoginScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.deepPurple.shade100,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade900,
              );
            }
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          elevation: 10,
          backgroundColor: Colors.white,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF312E81)),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: Color(0xFF312E81)),
              label: 'Peta Spot',
            ),
            NavigationDestination(
              icon: Icon(Icons.collections_bookmark_outlined),
              selectedIcon: Icon(Icons.collections_bookmark_rounded, color: Color(0xFF312E81)),
              label: 'Catatan',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded, color: Color(0xFF312E81)),
              label: 'Forum',
            ),
            NavigationDestination(
              icon: Icon(Icons.hourglass_empty_rounded),
              selectedIcon: Icon(Icons.hourglass_full_rounded, color: Color(0xFF312E81)),
              label: 'Pomodoro',
            ),
          ],
        ),
      ),
    );
  }
}
