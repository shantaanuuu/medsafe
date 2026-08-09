import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _selectedRole = 'Patient';
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi (हिन्दी)'},
    {'code': 'ta', 'name': 'Tamil (தமிழ்)'},
    {'code': 'te', 'name': 'Telugu (తెలుగు)'},
    {'code': 'bn', 'name': 'Bengali (বাংলা)'},
  ];

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('user_role', _selectedRole);
    await prefs.setString('user_lang', _selectedLanguage);
    await prefs.setBool('onboarding_completed', true);

    // Sync to SQLite Backend using ApiService
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.syncUser(
          user.uid,
          email: user.email,
          role: _selectedRole,
          username: user.displayName ?? '',
        );
      } catch (e) {
        debugPrint("ONBOARDING SYNC ERROR: $e");
      }
    }

    if (mounted) {
      // Re-trigger the auth wrapper or push direct cabinet
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    return Scaffold(
      backgroundColor: access.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Disclaimer Banner at top
            DisclaimerBanner(access: access),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: access.scaleSpacing(24.0),
                  vertical: access.scaleSpacing(20.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // App Logo Mockup
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: access.primaryTeal.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.health_and_safety_rounded,
                          color: access.primaryTeal,
                          size: access.scaleText(48.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to MedSafe',
                      textAlign: TextAlign.center,
                      style: access.getTextStyle(
                        baseSize: 26.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your clinical companion for medicine safety.',
                      textAlign: TextAlign.center,
                      style: access.getTextStyle(
                        baseSize: 15.0,
                        color: access.textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // 1. SELECT ROLE
                    Text(
                      '1. Select Your Profile Role',
                      style: access.getTextStyle(
                        baseSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRoleCard(
                      role: 'Patient',
                      title: 'Patient Profile',
                      description: 'Manage your own cabinet, track expiries, and verify interactions.',
                      icon: Icons.person_rounded,
                      access: access,
                    ),
                    const SizedBox(height: 12),
                    _buildRoleCard(
                      role: 'Caregiver',
                      title: 'Caregiver Profile',
                      description: 'Monitor medicine schedules and safety for dependents/family.',
                      icon: Icons.people_rounded,
                      access: access,
                    ),
                    
                    const SizedBox(height: 28),

                    // 2. SELECT LANGUAGE
                    Text(
                      '2. Select Preferred Language',
                      style: access.getTextStyle(
                        baseSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageDropdown(access),

                    const SizedBox(height: 40),

                    // CONTINUE BUTTON
                    ElevatedButton(
                      onPressed: _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: access.primaryTeal,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, access.minTapTargetSize),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Get Started',
                        style: access.getTextStyle(
                          baseSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required AccessibilityConfig access,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: EdgeInsets.all(access.scaleSpacing(16.0)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? access.primaryTeal : access.textColor.withOpacity(0.08),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: access.primaryTeal.withOpacity(0.06),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? access.primaryTeal.withOpacity(0.08) : access.textColor.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? access.primaryTeal : access.textColor.withOpacity(0.6),
                size: access.scaleText(24.0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: access.getTextStyle(
                      baseSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      color: access.textColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: role,
              groupValue: _selectedRole,
              activeColor: access.primaryTeal,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedRole = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(AccessibilityConfig access) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.textColor.withOpacity(0.08), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: access.primaryTeal),
          style: access.getTextStyle(baseSize: 15.0),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedLanguage = val;
              });
            }
          },
          items: _languages.map((lang) {
            return DropdownMenuItem<String>(
              value: lang['code'],
              child: Text(
                lang['name']!,
                style: access.getTextStyle(baseSize: 15.0),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
