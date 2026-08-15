class MedicationEntry {
  final String medicineId;
  final String medicineName;

  MedicationEntry({
    required this.medicineId,
    required this.medicineName,
  });

  factory MedicationEntry.fromJson(Map<String, dynamic> json) {
    return MedicationEntry(
      medicineId: json['medicine_id'] as String? ?? json['medicineId'] as String? ?? '',
      medicineName: json['medicine_name'] as String? ?? json['medicineName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine_id': medicineId,
      'medicine_name': medicineName,
    };
  }
}

class UserHealthProfile {
  final String id;
  final String firebaseUid;
  final String role;
  final int? age;
  final double? weightKg;
  final String? sex;
  final List<String> chronicConditions;
  final List<MedicationEntry> currentMedications;
  final List<String> allergies;
  final int onboardingStep;
  final bool onboardingCompleted;
  final String? createdAt;
  final String? updatedAt;
  final String? nickname;

  UserHealthProfile({
    required this.id,
    required this.firebaseUid,
    required this.role,
    this.age,
    this.weightKg,
    this.sex,
    required this.chronicConditions,
    required this.currentMedications,
    required this.allergies,
    required this.onboardingStep,
    required this.onboardingCompleted,
    this.createdAt,
    this.updatedAt,
    this.nickname,
  });

  UserHealthProfile copyWith({
    String? id,
    String? firebaseUid,
    String? role,
    int? age,
    double? weightKg,
    String? sex,
    List<String>? chronicConditions,
    List<MedicationEntry>? currentMedications,
    List<String>? allergies,
    int? onboardingStep,
    bool? onboardingCompleted,
    String? createdAt,
    String? updatedAt,
    String? nickname,
  }) {
    return UserHealthProfile(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      role: role ?? this.role,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      sex: sex ?? this.sex,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      allergies: allergies ?? this.allergies,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nickname: nickname ?? this.nickname,
    );
  }

  factory UserHealthProfile.fromJson(Map<String, dynamic> json) {
    var rawMedications = json['current_medications'] as List? ?? json['currentMedications'] as List? ?? [];
    List<MedicationEntry> meds = rawMedications
        .map((e) => MedicationEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return UserHealthProfile(
      id: json['id'] as String? ?? '',
      firebaseUid: json['firebase_uid'] as String? ?? json['firebaseUid'] as String? ?? '',
      role: json['role'] as String? ?? 'Patient',
      age: json['age'] as int?,
      weightKg: (json['weight_kg'] ?? json['weightKg'])?.toDouble(),
      sex: json['sex'] as String?,
      chronicConditions: List<String>.from(json['chronic_conditions'] ?? json['chronicConditions'] ?? []),
      currentMedications: meds,
      allergies: List<String>.from(json['allergies'] ?? []),
      onboardingStep: json['onboarding_step'] as int? ?? json['onboardingStep'] as int? ?? 1,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? json['onboardingCompleted'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
      updatedAt: json['updated_at'] as String? ?? json['updatedAt'] as String?,
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'role': role,
      'age': age,
      'weight_kg': weightKg,
      'sex': sex,
      'chronic_conditions': chronicConditions,
      'current_medications': currentMedications.map((e) => e.toJson()).toList(),
      'allergies': allergies,
      'onboarding_step': onboardingStep,
      'onboarding_completed': onboardingCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (nickname != null) 'nickname': nickname,
    };
  }
}
