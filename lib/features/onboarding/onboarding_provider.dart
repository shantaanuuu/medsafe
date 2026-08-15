import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_health_profile.dart';
import '../../services/onboarding_repository.dart';
import 'onboarding_state.dart';

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});

class OnboardingNotifier extends Notifier<OnboardingState> {
  late final OnboardingRepository _repository;

  @override
  OnboardingState build() {
    _repository = ref.watch(onboardingRepositoryProvider);
    return OnboardingState.initial();
  }

  void initializeProfile(UserHealthProfile profile) {
    state = state.copyWith(status: OnboardingStatus.loaded, profile: profile);
  }

  Future<void> loadProfile(String uid, {String? email, String? username}) async {
    state = state.copyWith(status: OnboardingStatus.loading);
    try {
      var profile = await _repository.fetchProfile(uid);
      if (profile == null) {
        // If profile doesn't exist on SQL backend, create a draft profile
        profile = await _repository.createDraftProfile(uid, email: email, username: username);
      }
      state = state.copyWith(status: OnboardingStatus.loaded, profile: profile);
    } catch (e) {
      state = state.copyWith(status: OnboardingStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> updateStep(int step, {
    String? role,
    List<String>? chronicConditions,
    List<MedicationEntry>? currentMedications,
    List<String>? allergies,
    int? age,
    double? weightKg,
    String? sex,
    bool completed = false,
    String? nickname,
  }) async {
    final currentProfile = state.profile;
    if (currentProfile == null) return;

    state = state.copyWith(status: OnboardingStatus.submitting);
    try {
      final updatedProfile = currentProfile.copyWith(
        role: role,
        chronicConditions: chronicConditions,
        currentMedications: currentMedications,
        allergies: allergies,
        age: age,
        weightKg: weightKg,
        sex: sex,
        onboardingStep: step,
        onboardingCompleted: completed,
        nickname: nickname,
      );

      await _repository.updateProfile(updatedProfile);
      state = state.copyWith(
        status: completed ? OnboardingStatus.completed : OnboardingStatus.loaded,
        profile: updatedProfile,
      );
    } catch (e) {
      state = state.copyWith(status: OnboardingStatus.error, errorMessage: e.toString());
    }
  }
}
