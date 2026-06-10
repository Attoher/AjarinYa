import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ajarin_ya/config/supabase_config.dart';
import 'package:ajarin_ya/firebase_options.dart';
import 'package:ajarin_ya/viewmodels/auth_view_model.dart';
import 'package:ajarin_ya/viewmodels/barter_view_model.dart';
import 'package:ajarin_ya/viewmodels/notes_view_model.dart';
import 'package:ajarin_ya/viewmodels/question_view_model.dart';
import 'package:ajarin_ya/viewmodels/study_spot_view_model.dart';
import 'package:ajarin_ya/viewmodels/chat_view_model.dart';
import 'package:ajarin_ya/repositories/chat_repository.dart';
import 'package:ajarin_ya/views/main_navigation_shell.dart';
import 'package:ajarin_ya/services/notification_service.dart';
import 'package:ajarin_ya/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — database utama (Firestore, Auth, Crashlytics, Messaging)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await NotificationService().initFirebaseMessaging();

  // Supabase — dipakai hanya untuk Storage (foto profil, soal, jawaban, notes)
  await Supabase.initialize(
    url: SupabaseConfig.projectUrl,
    publishableKey: SupabaseConfig.anonKey,
  );

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
        ChangeNotifierProvider<ChatViewModel>(
          create: (_) => ChatViewModel(repository: ChatRepositoryImpl()),
        ),
      ],
      child: MaterialApp(
        title: 'AjarinYa!',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationShell(),
      ),
    );
  }
}
