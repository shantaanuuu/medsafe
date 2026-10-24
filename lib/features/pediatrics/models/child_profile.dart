
import '../../../models/user_health_profile.dart';

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.caregiverUid,
    required this.name,
    required this.dateOfBirth,
    this.age,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.currentMedications = const [],
  });

  final String id;
  final String caregiverUid;
  final String name;
  final DateTime dateOfBirth;
  final int? age;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> currentMedications;

  /// Calculates the child's current age from their date of birth.
  int get ageInYears {
    final today = DateTime.now();
    var calculatedAge = today.year - dateOfBirth.year;

    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month &&
            today.day < dateOfBirth.day)) {
      calculatedAge--;
    }

    return calculatedAge;
  }

  /// Creates a Pediatrics profile from an existing MedSafe dependent.
  factory ChildProfile.fromUserHealthProfile(
    UserHealthProfile profile,
  ) {
    final dobString = profile.dateOfBirth?.trim();

    if (dobString == null || dobString.isEmpty) {
      throw ArgumentError(
        'A date of birth is required for the Pediatrics profile.',
      );
    }

    final parsedDob = DateTime.tryParse(dobString);

    if (parsedDob == null || parsedDob.isAfter(DateTime.now())) {
      throw ArgumentError(
        'The dependent must have a valid date of birth.',
      );
    }

    return ChildProfile(
      id: profile.id,
      caregiverUid: profile.firebaseUid,
      name: profile.nickname?.trim().isNotEmpty == true
          ? profile.nickname!.trim()
          : 'Child',
      dateOfBirth: parsedDob,
      age: profile.age,
      allergies: List<String>.from(profile.allergies),
      medicalConditions: List<String>.from(profile.chronicConditions),
      currentMedications: profile.currentMedications
          .map((medication) => medication.medicineName)
          .toList(),
    );
  }
}
