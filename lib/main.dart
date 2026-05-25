import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:ajarin_ya/firebase_options.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/barter_view_model.dart';
import 'package:ajarin_ya/viewmodels/notes_view_model.dart';
import 'package:ajarin_ya/viewmodels/question_view_model.dart';
import 'package:ajarin_ya/viewmodels/study_spot_view_model.dart';
import 'package:ajarin_ya/views/main_navigation_shell.dart';
import 'package:ajarin_ya/services/notification_service.dart';

void main() async {
  // Memastikan binding Flutter terinisialisasi secara aman
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase Core agar Firestore aktif untuk fitur Study Spot & Barter Skill
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Konfigurasi Firebase Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Setup Firebase Messaging
  await NotificationService().initFirebaseMessaging();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(),
        ),
        ChangeNotifierProvider<BarterViewModel>(
          create: (_) => BarterViewModel(),
        ),
        ChangeNotifierProvider<StudySpotViewModel>(
          create: (_) => StudySpotViewModel(),
        ),
        ChangeNotifierProvider<NotesViewModel>(
          create: (_) => NotesViewModel(),
        ),
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
            seedColor: const Color(0xFF0D47A1),
            primary: const Color(0xFF0D47A1),
            secondary: const Color(0xFF00796B),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const MainNavigationShell(),
      ),
    );
  }
}

