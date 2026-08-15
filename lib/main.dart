import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_states.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';
import 'cabinet_screen.dart';
import 'main_dashboard.dart';
import 'features/onboarding/onboarding_flow_screen.dart';
import 'features/onboarding/onboarding_provider.dart';
import 'models/user_health_profile.dart';
import 'services/onboarding_repository.dart';

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
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // MedSafe primary medical blue
          primary: const Color(0xFF2563EB),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF111827)),
          titleTextStyle: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthStateWrapper(),
      },
    );
  }
}

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final onboardingProfileProvider = FutureProvider<UserHealthProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;

  final repository = ref.watch(onboardingRepositoryProvider);
  var profile = await repository.fetchProfile(user.uid);
  if (profile == null) {
    profile = await repository.createDraftProfile(
      user.uid,
      email: user.email,
      username: user.displayName ?? '',
    );
  }

  return profile;
});

class AuthStateWrapper extends ConsumerWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Text('Authentication error: $err'),
        ),
      ),
      data: (user) {
        if (user == null) {
          return const AuthScreen();
        }

        final profileAsync = ref.watch(onboardingProfileProvider);

        return profileAsync.when(
          loading: () => const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          error: (err, stack) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading health profile: $err'),
              ),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const AuthScreen();
            }

            if (profile.onboardingCompleted) {
              return const MainDashboard();
            }

            return const OnboardingFlowScreen();
          },
        );
      },
    );
  }
}
