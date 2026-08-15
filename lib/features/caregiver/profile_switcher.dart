import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../accessibility_config.dart';
import '../../shared_states.dart';
import '../../models/user_health_profile.dart';
import '../onboarding/onboarding_flow_screen.dart';
import '../../main.dart';

class ProfileSwitcher extends ConsumerWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final caregiverProfileAsync = ref.watch(onboardingProfileProvider);
    
    final caregiverProfile = caregiverProfileAsync.value;
    if (caregiverProfile == null || caregiverProfile.role != 'Caregiver') {
      return const SizedBox.shrink();
    }

    final allProfilesAsync = ref.watch(allProfilesProvider);
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    return Container(
      height: access.scaleSpacing(64.0),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: allProfilesAsync.when(
        data: (profiles) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: profiles.length + 1,
            itemBuilder: (context, index) {
              if (index == profiles.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingFlowScreen(isAddingDependent: true),
                        ),
                      );
                    },
                    icon: Icon(Icons.add_rounded, size: 18, color: access.primaryTeal),
                    label: Text(
                      'Add Dependent',
                      style: access.getTextStyle(
                        baseSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: access.primaryTeal,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: access.primaryTeal, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                );
              }

              final profile = profiles[index];
              final isSelected = activeProfile?.id == profile.id;
              final isCaregiverSelf = profile.id == caregiverProfile.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                child: ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: isSelected ? Colors.white : access.primaryTeal.withOpacity(0.1),
                    child: Icon(
                      isCaregiverSelf ? Icons.admin_panel_settings_rounded : Icons.face_rounded,
                      size: 16,
                      color: access.primaryTeal,
                    ),
                  ),
                  label: Text(
                    isCaregiverSelf ? 'Self' : (profile.nickname ?? 'Dependent'),
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : access.textColor,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: access.primaryTeal,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? access.primaryTeal : access.textColor.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(activeProfileProvider.notifier).setActiveProfile(profile);
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
          ),
        ),
        error: (err, stack) => const SizedBox.shrink(),
      ),
    );
  }
}
