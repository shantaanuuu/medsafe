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
import 'services/api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  // Pre-initialize SharedPreferences for synchronous provider access
  final sharedPrefs = await SharedPreferences.getInstance();

  // Initialize Local Notifications and request permissions
  try {
    final notifService = NotificationService();
    await notifService.initialize();
    await notifService.requestPermissions();
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

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

  void _showChangeIpDialog(BuildContext context, WidgetRef ref) {
    final currentUrl = ref.read(backendBaseUrlProvider);
    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Backend Server IP',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter or select your running Flask backend address:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'http://10.230.141.96:5000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.link, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quick Select Presets:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ActionChip(
                    label: const Text('10.230.141.96:5000 (Current Wi-Fi)'),
                    onPressed: () {
                      setState(() {
                        controller.text = 'http://10.230.141.96:5000';
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('127.0.0.1:5000 (USB adb)'),
                    onPressed: () {
                      setState(() {
                        controller.text = 'http://127.0.0.1:5000';
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('10.0.2.2:5000 (Emulator)'),
                    onPressed: () {
                      setState(() {
                        controller.text = 'http://10.0.2.2:5000';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final val = controller.text.trim();
                if (val.isNotEmpty) {
                  await ref.read(backendBaseUrlProvider.notifier).setUrl(val);
                  ref.invalidate(apiServiceProvider);
                  ref.invalidate(onboardingRepositoryProvider);
                  ref.invalidate(onboardingProfileProvider);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save & Reconnect'),
            ),
          ],
        ),
      ),
    );
  }

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
          loading: () => Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Connecting to MedSafe Backend...',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer(
                        builder: (context, ref, _) {
                          final url = ref.watch(backendBaseUrlProvider);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              url,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF334155),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showChangeIpDialog(context, ref),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Change IP'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await ref.read(backendBaseUrlProvider.notifier).resetToDefault();
                              ref.invalidate(apiServiceProvider);
                              ref.invalidate(onboardingRepositoryProvider);
                              ref.invalidate(onboardingProfileProvider);
                            },
                            icon: const Icon(Icons.restore, size: 16),
                            label: const Text('Reset IP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        icon: const Icon(Icons.logout, size: 16, color: Color(0xFF64748B)),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          error: (err, stack) => Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Unable to Connect to Server',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Consumer(
                        builder: (context, ref, _) {
                          final currentUrl = ref.watch(backendBaseUrlProvider);
                          return Text(
                            'Could not reach MedSafe backend at:\n' +
                            currentUrl +
                            '\n\nEnsure your Flask server is running and accessible.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.invalidate(onboardingProfileProvider);
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showChangeIpDialog(context, ref),
                            icon: const Icon(Icons.settings_ethernet, size: 18),
                            label: const Text('Change Server IP'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        icon: const Icon(Icons.logout, size: 16, color: Color(0xFF64748B)),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
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
