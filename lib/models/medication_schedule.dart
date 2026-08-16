class MedicationSchedule {
  final String id;
  final String cabinetItemId;
  final String? dependentId;
  final String userUid;
  final int frequencyPerDay;
  final List<String> scheduledTimes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MedicationSchedule({
    required this.id,
    required this.cabinetItemId,
    this.dependentId,
    required this.userUid,
    required this.frequencyPerDay,
    required this.scheduledTimes,
    this.createdAt,
    this.updatedAt,
  });

  MedicationSchedule copyWith({
    String? id,
    String? cabinetItemId,
    String? dependentId,
    String? userUid,
    int? frequencyPerDay,
    List<String>? scheduledTimes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      cabinetItemId: cabinetItemId ?? this.cabinetItemId,
      dependentId: dependentId ?? this.dependentId,
      userUid: userUid ?? this.userUid,
      frequencyPerDay: frequencyPerDay ?? this.frequencyPerDay,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    var rawTimes = json['scheduled_times'] ?? json['scheduledTimes'] ?? [];
    List<String> parsedTimes = [];
    if (rawTimes is List) {
      parsedTimes = rawTimes.map((e) => e.toString()).toList();
    }
    
    return MedicationSchedule(
      id: json['id']?.toString() ?? '',
      cabinetItemId: json['cabinet_item_id']?.toString() ?? json['cabinetItemId']?.toString() ?? '',
      dependentId: json['dependent_id']?.toString() ?? json['dependentId']?.toString(),
      userUid: json['user_uid']?.toString() ?? json['userUid']?.toString() ?? '',
      frequencyPerDay: json['frequency_per_day'] as int? ?? json['frequencyPerDay'] as int? ?? 1,
      scheduledTimes: parsedTimes,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cabinet_item_id': cabinetItemId,
      'dependent_id': dependentId,
      'user_uid': userUid,
      'frequency_per_day': frequencyPerDay,
      'scheduled_times': scheduledTimes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
