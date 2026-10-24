
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared_states.dart';
import '../../../main.dart';
import '../models/child_profile.dart';

final pediatricsChildrenProvider =
    FutureProvider<List<ChildProfile>>((ref) async {
  final profiles = await ref.watch(allProfilesProvider.future);
  final caregiverProfile =
      await ref.watch(onboardingProfileProvider.future);

  final children = <ChildProfile>[];

  for (final profile in profiles) {
    // Exclude the caregiver's own profile.
    if (caregiverProfile != null &&
        profile.id == caregiverProfile.id) {
      continue;
    }

    // Pediatrics requires a valid date of birth.
    final dob = profile.dateOfBirth?.trim();
    if (dob == null || dob.isEmpty) continue;

    try {
      children.add(
        ChildProfile.fromUserHealthProfile(profile),
      );
    } on ArgumentError {
      continue;
    } on FormatException {
      continue;
    }
  }

  return children;
});
