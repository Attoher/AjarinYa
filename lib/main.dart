import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ajarin_ya/firebase_options.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/barter_view_model.dart';
import 'package:ajarin_ya/viewmodels/notes_view_model.dart';
import 'package:ajarin_ya/viewmodels/question_view_model.dart';
import 'package:ajarin_ya/viewmodels/study_spot_view_model.dart';
import 'package:ajarin_ya/views/main_navigation_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        ChangeNotifierProvider<BarterViewModel>(
          create: (_) => BarterViewModel(),
        ),
        ChangeNotifierProvider<StudySpotViewModel>(
          create: (_) => StudySpotViewModel(),
        ),
        ChangeNotifierProvider<NotesViewModel>(create: (_) => NotesViewModel()),
        ChangeNotifierProvider<QuestionViewModel>(
          create: (_) => QuestionViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'AjarinYa!',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            primary: Colors.deepPurple,
            secondary: Colors.indigo,
          ),
          appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        ),
        home: const MainNavigationShell(),
      ),
    );
  }
}
