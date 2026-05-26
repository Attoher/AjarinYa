import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/views/dashboard_screen.dart';
import 'package:ajarin_ya/views/study_spot_screen.dart';
import 'package:ajarin_ya/views/notes_collection_screen.dart';
import 'package:ajarin_ya/views/question_forum_screen.dart';
import 'package:ajarin_ya/views/pomodoro_screen.dart';
import 'package:ajarin_ya/views/login_screen.dart';
import 'package:ajarin_ya/views/group_gate_screen.dart';
import 'package:ajarin_ya/views/barter_request_screen.dart';
import 'package:ajarin_ya/views/answer_question_screen.dart';

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
    const BarterRequestScreen(),
    const PomodoroScreen(),
    const NotesCollectionScreen(),
    const QuestionForumScreen(),
    const AnswerQuestionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (!authViewModel.isAuthenticated) {
      return const LoginScreen();
    }

    if (authViewModel.user?.groupIds.isEmpty ?? true) {
      return const GroupGateScreen(isFromProfile: false);
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFF0D47A1).withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
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
          elevation: 2,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF0D47A1)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: Color(0xFF0D47A1)),
              label: 'Study spot',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horizontal_circle_outlined),
              selectedIcon: Icon(Icons.swap_horizontal_circle, color: Color(0xFF0D47A1)),
              label: 'Request Barter Skill',
            ),
            NavigationDestination(
              icon: Icon(Icons.hourglass_empty_rounded),
              selectedIcon: Icon(Icons.hourglass_full_rounded, color: Color(0xFF0D47A1)),
              label: 'Sesi Pomodoro',
            ),
            NavigationDestination(
              icon: Icon(Icons.collections_bookmark_outlined),
              selectedIcon: Icon(Icons.collections_bookmark_rounded, color: Color(0xFF0D47A1)),
              label: 'Notes / Collection',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded, color: Color(0xFF0D47A1)),
              label: 'Question Forum',
            ),
            NavigationDestination(
              icon: Icon(Icons.rate_review_outlined),
              selectedIcon: Icon(Icons.rate_review_rounded, color: Color(0xFF0D47A1)),
              label: 'Answer Question',
            ),
          ],
        ),
      ),
    );
  }
}
