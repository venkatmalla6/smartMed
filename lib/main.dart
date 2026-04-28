import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/app_theme.dart';
import 'providers/note_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/study_plan_provider.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Hold the splash screen until init is complete
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await HiveService.init();
  await NotificationService().init();
  FlutterNativeSplash.remove(); // Remove splash and show app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NoteProvider()..loadNotes()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => StudyPlanProvider()..loadTasks()),
      ],
      child: MaterialApp(
        title: 'SmartMed',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
