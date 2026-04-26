import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InsightBoardApp());
}

class InsightBoardApp extends StatelessWidget {
  const InsightBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initAuth(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'InsightBoard',
            debugShowCheckedModeBanner: false,
            themeMode: provider.themeMode,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            home: provider.currentUser != null
                ? const MainShell()
                : const AuthScreen(),
            routes: {
              '/auth': (_) => const AuthScreen(),
              '/onboarding': (_) => const OnboardingScreen(),
              '/home': (_) => const MainShell(),
            },
          );
        },
      ),
    );
  }
}
