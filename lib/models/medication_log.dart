class MedicationLog {
  final String id;
  final String cabinetItemId;
  final String? dependentId;
  final String userUid;
  final String doseTime;
  final String takenDate;
  final bool taken;
  final DateTime? createdAt;

  MedicationLog({
    required this.id,
    required this.cabinetItemId,
    this.dependentId,
    required this.userUid,
    required this.doseTime,
    required this.takenDate,
    required this.taken,
    this.createdAt,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id']?.toString() ?? '',
      cabinetItemId: json['cabinet_item_id']?.toString() ?? json['cabinetItemId']?.toString() ?? '',
      dependentId: json['dependent_id']?.toString() ?? json['dependentId']?.toString(),
      userUid: json['user_uid']?.toString() ?? json['userUid']?.toString() ?? '',
      doseTime: json['dose_time']?.toString() ?? json['doseTime']?.toString() ?? '',
      takenDate: json['taken_date']?.toString() ?? json['takenDate']?.toString() ?? '',
      taken: json['taken'] is bool ? json['taken'] as bool : (json['taken'] == 1 || json['taken'] == 'true' || json['taken'] == true),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cabinet_item_id': cabinetItemId,
      'dependent_id': dependentId,
      'user_uid': userUid,
      'dose_time': doseTime,
      'taken_date': takenDate,
      'taken': taken,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
