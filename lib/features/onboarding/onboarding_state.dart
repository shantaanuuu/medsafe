import '../../models/user_health_profile.dart';

enum OnboardingStatus {
  initial,
  loading,
  loaded,
  submitting,
  completed,
  error,
}

class OnboardingState {
  final OnboardingStatus status;
  final UserHealthProfile? profile;
  final String? errorMessage;

  OnboardingState({
    required this.status,
    this.profile,
    this.errorMessage,
  });

  factory OnboardingState.initial() {
    return OnboardingState(status: OnboardingStatus.initial);
  }

  OnboardingState copyWith({
    OnboardingStatus? status,
    UserHealthProfile? profile,
    String? errorMessage,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
