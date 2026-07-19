import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_states.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';
import 'cabinet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  // Pre-initialize SharedPreferences for synchronous provider access
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E), // MedSafe primary teal
          brightness: Brightness.light, // Using light mode with high-contrast neutral grays
        ),
        fontFamily: 'Inter',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthStateWrapper(),
      },
    );
  }
}

class AuthStateWrapper extends ConsumerWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If connection is waiting, show a custom loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0F766E),
              ),
            ),
          );
        }
        
        // 1. FIRST: If NOT logged in, show AuthScreen (Login/Signup)
        if (!snapshot.hasData || snapshot.data == null) {
          return const AuthScreen();
        }
        
        // 2. NEXT: If logged in, check if onboarding is completed
        final prefs = ref.watch(sharedPreferencesProvider);
        final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
        
        if (!onboardingCompleted) {
          return const OnboardingScreen();
        }
        
        // 3. FINALLY: If logged in and onboarding completed, show CabinetScreen
        return const CabinetScreen();
      },
    );
  }
}
