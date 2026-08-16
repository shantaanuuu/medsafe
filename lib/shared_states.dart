import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_service.dart';
import 'models/medicine_model.dart';
import 'models/user_health_profile.dart';
import 'models/medication_schedule.dart';
import 'models/medication_log.dart';
import 'services/onboarding_repository.dart';
import 'main.dart';
import 'package:flutter/foundation.dart';

// --- DATA MODELS ---

enum VerifiedSource { barcode, ocr, manual }

class Medicine {
  final String id;
  final String name;
  final String genericName;
  final String? ndcCode;
  final String? barcode;
  final String? batchNumber;
  final DateTime expiryDate;
  final DateTime addedDate;
  final String dosageForm;
  final String? linkedPrescriptionId;
  final VerifiedSource verifiedSource;
  
  // Database enriched fields
  final double? price;
  final String? manufacturer;
  final String? sideEffects;
  final String? drugInteractions;
  final String? medicineDesc;
  final String? substitutes;
  final String? chemicalClass;
  final String? therapeuticClass;
  final String? habitForming;
  
  // Custom user parameters
  final String? nickname;
  final double? quantity;
  final String? dosageSchedule;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    this.ndcCode,
    this.barcode,
    this.batchNumber,
    required this.expiryDate,
    required this.addedDate,
    required this.dosageForm,
    this.linkedPrescriptionId,
    required this.verifiedSource,
    this.price,
    this.manufacturer,
    this.sideEffects,
    this.drugInteractions,
    this.medicineDesc,
    this.substitutes,
    this.chemicalClass,
    this.therapeuticClass,
    this.habitForming,
    this.nickname,
    this.quantity,
    this.dosageSchedule,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'genericName': genericName,
        'ndcCode': ndcCode,
        'barcode': barcode,
        'batchNumber': batchNumber,
        'expiryDate': expiryDate.toIso8601String(),
        'addedDate': addedDate.toIso8601String(),
        'dosageForm': dosageForm,
        'linkedPrescriptionId': linkedPrescriptionId,
        'verifiedSource': verifiedSource.index,
        'price': price,
        'manufacturer': manufacturer,
        'sideEffects': sideEffects,
        'drugInteractions': drugInteractions,
        'medicineDesc': medicineDesc,
        'substitutes': substitutes,
        'chemicalClass': chemicalClass,
        'therapeuticClass': therapeuticClass,
        'habitForming': habitForming,
        'nickname': nickname,
        'quantity': quantity,
        'dosage_schedule': dosageSchedule,
        'dosageSchedule': dosageSchedule,
      };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        genericName: json['genericName']?.toString() ?? '',
        ndcCode: json['ndcCode']?.toString(),
        barcode: json['barcode']?.toString(),
        batchNumber: json['batchNumber']?.toString(),
        expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : DateTime.now(),
        addedDate: json['addedDate'] != null ? DateTime.parse(json['addedDate']) : DateTime.now(),
        dosageForm: json['dosageForm']?.toString() ?? '',
        linkedPrescriptionId: json['linkedPrescriptionId']?.toString(),
        verifiedSource: VerifiedSource.values[json['verifiedSource'] ?? 2],
        price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
        manufacturer: json['manufacturer']?.toString(),
        sideEffects: json['sideEffects']?.toString(),
        drugInteractions: json['drugInteractions']?.toString(),
        medicineDesc: json['medicineDesc']?.toString(),
        substitutes: json['substitutes']?.toString(),
        chemicalClass: json['chemicalClass']?.toString(),
        therapeuticClass: json['therapeuticClass']?.toString(),
        habitForming: json['habitForming']?.toString(),
        nickname: json['nickname']?.toString(),
        quantity: json['quantity'] != null ? double.tryParse(json['quantity'].toString()) : null,
        dosageSchedule: json['dosage_schedule']?.toString() ?? json['dosageSchedule']?.toString(),
      );

  Medicine copyWith({
    String? id,
    String? name,
    String? genericName,
    String? ndcCode,
    String? barcode,
    String? batchNumber,
    DateTime? expiryDate,
    DateTime? addedDate,
    String? dosageForm,
    String? linkedPrescriptionId,
    VerifiedSource? verifiedSource,
    double? price,
    String? manufacturer,
    String? sideEffects,
    String? drugInteractions,
    String? medicineDesc,
    String? substitutes,
    String? chemicalClass,
    String? therapeuticClass,
    String? habitForming,
    String? nickname,
    double? quantity,
    String? dosageSchedule,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      ndcCode: ndcCode ?? this.ndcCode,
      barcode: barcode ?? this.barcode,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      addedDate: addedDate ?? this.addedDate,
      dosageForm: dosageForm ?? this.dosageForm,
      linkedPrescriptionId: linkedPrescriptionId ?? this.linkedPrescriptionId,
      verifiedSource: verifiedSource ?? this.verifiedSource,
      price: price ?? this.price,
      manufacturer: manufacturer ?? this.manufacturer,
      sideEffects: sideEffects ?? this.sideEffects,
      drugInteractions: drugInteractions ?? this.drugInteractions,
      medicineDesc: medicineDesc ?? this.medicineDesc,
      substitutes: substitutes ?? this.substitutes,
      chemicalClass: chemicalClass ?? this.chemicalClass,
      therapeuticClass: therapeuticClass ?? this.therapeuticClass,
      habitForming: habitForming ?? this.habitForming,
      nickname: nickname ?? this.nickname,
      quantity: quantity ?? this.quantity,
      dosageSchedule: dosageSchedule ?? this.dosageSchedule,
    );
  }
}

class SyncState {
  final bool isOffline;
  final DateTime? lastSynced;

  SyncState({required this.isOffline, this.lastSynced});
}

// --- PROVIDERS ---

// SharedPreferences Provider initialized in main()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main() first');
});

// Elderly Mode Provider using modern Riverpod Notifier
class ElderlyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('elderlyMode') ?? false;
  }

  void toggle() {
    state = !state;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool('elderlyMode', state);
  }
}

final elderlyModeProvider = NotifierProvider<ElderlyModeNotifier, bool>(() {
  return ElderlyModeNotifier();
});

// Cabinet Notifier using modern Riverpod Notifier
class CabinetNotifier extends Notifier<List<Medicine>> {
  @override
  List<Medicine> build() {
    final activeProfile = ref.watch(activeProfileProvider);
    final key = 'medicine_cabinet_${activeProfile?.id ?? 'self'}';

    final prefs = ref.watch(sharedPreferencesProvider);
    final cached = prefs.getString(key);
    List<Medicine> localList = [];
    if (cached != null) {
      try {
        final List decoded = jsonDecode(cached);
        localList = decoded.map((item) => Medicine.fromJson(item)).toList();
      } catch (_) {
        localList = [];
      }
    } else {
      localList = [];
    }

    // Trigger async SQL backend pull if user is logged in
    Future.microtask(() => _syncFromBackend());

    return localList;
  }

  Future<void> _syncFromBackend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final activeProfile = ref.read(activeProfileProvider);
    final caregiverProfile = ref.read(onboardingProfileProvider).value;
    final String? dependentId = (activeProfile != null && caregiverProfile != null && activeProfile.id != caregiverProfile.id)
        ? activeProfile.id
        : null;

    try {
      final apiService = ref.read(apiServiceProvider);
      final List<MedicineModel> dbList = await apiService.getCabinet(user.uid, dependentId: dependentId);

      final List<Medicine> localList = dbList.map((m) {
        return Medicine(
          id: m.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: m.brandName ?? '',
          genericName: m.genericName ?? '',
          batchNumber: m.batchNumber,
          expiryDate: m.expiryDate != null ? DateTime.parse(m.expiryDate!) : DateTime.now(),
          addedDate: m.manufacturingDate != null ? DateTime.parse(m.manufacturingDate!) : DateTime.now(),
          dosageForm: m.strength ?? 'Tablet',
          verifiedSource: m.verifiedSource != null ? VerifiedSource.values[m.verifiedSource!] : VerifiedSource.ocr,
          price: m.mrp != null ? double.tryParse(m.mrp!) : null,
          manufacturer: m.manufacturer,
          sideEffects: m.sideEffects,
          drugInteractions: m.drugInteractions,
          medicineDesc: m.medicineDesc,
          substitutes: m.substitutes,
          chemicalClass: m.chemicalClass,
          therapeuticClass: m.therapeuticClass,
          habitForming: m.habitForming,
          nickname: m.nickname,
          quantity: m.quantity,
          dosageSchedule: m.dosageSchedule,
        );
      }).toList();

      state = localList;
      _saveToPrefs();
    } catch (e) {
      print("SQL CABINET SYNC ERROR: $e");
    }
  }

  Future<void> addMedicine(Medicine med) async {
    final index = state.indexWhere((m) => m.id == med.id);
    if (index != -1) {
      final list = List<Medicine>.from(state);
      list[index] = med;
      state = list;
    } else {
      state = [...state, med];
    }
    _saveToPrefs();
    
    // Sync to backend SQLite
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final activeProfile = ref.read(activeProfileProvider);
      final caregiverProfile = ref.read(onboardingProfileProvider).value;
      final String? dependentId = (activeProfile != null && caregiverProfile != null && activeProfile.id != caregiverProfile.id)
          ? activeProfile.id
          : null;

      try {
        final apiService = ref.read(apiServiceProvider);
        final model = MedicineModel(
          id: med.id,
          brandName: med.name,
          genericName: med.genericName,
          strength: med.dosageForm,
          expiryDate: med.expiryDate.toIso8601String(),
          manufacturingDate: med.addedDate.toIso8601String(),
          batchNumber: med.batchNumber,
          mrp: med.price?.toString(),
          manufacturer: med.manufacturer,
          sideEffects: med.sideEffects,
          drugInteractions: med.drugInteractions,
          medicineDesc: med.medicineDesc,
          substitutes: med.substitutes,
          chemicalClass: med.chemicalClass,
          therapeuticClass: med.therapeuticClass,
          nickname: med.nickname,
          quantity: med.quantity,
          dosageSchedule: med.dosageSchedule,
        );
        await apiService.addMedicineToCabinet(user.uid, model, dependentId: dependentId);
      } catch (e) {
        print("SQL CABINET ADD ERROR: $e");
      }
    }
  }

  void removeMedicine(String id) async {
    state = state.where((m) => m.id != id).toList();
    _saveToPrefs();

    // Sync to backend SQLite
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final activeProfile = ref.read(activeProfileProvider);
      final caregiverProfile = ref.read(onboardingProfileProvider).value;
      final String? dependentId = (activeProfile != null && caregiverProfile != null && activeProfile.id != caregiverProfile.id)
          ? activeProfile.id
          : null;

      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.removeMedicineFromCabinet(user.uid, id, dependentId: dependentId);
        ref.invalidate(schedulesProvider);
      } catch (e) {
        print("SQL CABINET DELETE ERROR: $e");
      }
    }
  }

  void _saveToPrefs() {
    final activeProfile = ref.read(activeProfileProvider);
    final key = 'medicine_cabinet_${activeProfile?.id ?? 'self'}';
    final prefs = ref.read(sharedPreferencesProvider);
    final encoded = jsonEncode(state.map((m) => m.toJson()).toList());
    prefs.setString(key, encoded);
  }
}

// Medication Schedules Provider
final schedulesProvider = FutureProvider.autoDispose<List<MedicationSchedule>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final activeProfile = ref.watch(activeProfileProvider);
  final caregiverProfile = ref.watch(onboardingProfileProvider).value;
  final String? dependentId = (activeProfile != null && caregiverProfile != null && activeProfile.id != caregiverProfile.id)
      ? activeProfile.id
      : null;

  final api = ref.watch(apiServiceProvider);
  try {
    return await api.getSchedules(user.uid, dependentId: dependentId);
  } catch (e) {
    debugPrint("FETCH SCHEDULES ERROR: $e");
    return [];
  }
});

// Medication Daily Logs Provider
final logsProvider = FutureProvider.autoDispose.family<List<MedicationLog>, String>((ref, dateStr) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final activeProfile = ref.watch(activeProfileProvider);
  final caregiverProfile = ref.watch(onboardingProfileProvider).value;
  final String? dependentId = (activeProfile != null && caregiverProfile != null && activeProfile.id != caregiverProfile.id)
      ? activeProfile.id
      : null;

  final api = ref.watch(apiServiceProvider);
  try {
    return await api.getLogs(user.uid, dateStr, dependentId: dependentId);
  } catch (e) {
    debugPrint("FETCH LOGS ERROR: $e");
    return [];
  }
});

final cabinetProvider = NotifierProvider<CabinetNotifier, List<Medicine>>(() {
  return CabinetNotifier();
});

class ActiveProfileNotifier extends Notifier<UserHealthProfile?> {
  @override
  UserHealthProfile? build() {
    final caregiverProfileAsync = ref.watch(onboardingProfileProvider);
    return caregiverProfileAsync.value;
  }

  void setActiveProfile(UserHealthProfile? profile) {
    state = profile;
  }
}

final activeProfileProvider = NotifierProvider<ActiveProfileNotifier, UserHealthProfile?>(() {
  return ActiveProfileNotifier();
});

// All Profiles Provider: caregiver self-profile + all dependents
final allProfilesProvider = FutureProvider<List<UserHealthProfile>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final repo = ref.watch(onboardingRepositoryProvider);
  final caregiverProfile = await repo.fetchProfile(user.uid);
  final List<UserHealthProfile> profiles = [];
  if (caregiverProfile != null) {
    profiles.add(caregiverProfile);
    if (caregiverProfile.role == 'Caregiver') {
      try {
        final deps = await repo.fetchDependents(user.uid);
        profiles.addAll(deps);
      } catch (e) {
        debugPrint("ONBOARDING_PROVIDER: fetchDependents failed: $e");
      }
    }
  }
  return profiles;
});

// Sync and Connection State Provider using modern Riverpod Notifier
class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    return SyncState(isOffline: false, lastSynced: DateTime.now());
  }

  void toggleConnectivity(bool isOffline) {
    state = SyncState(
      isOffline: isOffline,
      lastSynced: isOffline ? state.lastSynced : DateTime.now(),
    );
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});

// --- CAREGIVER & DEPENDENT MODELS ---

class AdherenceLog {
  final String medicineName;
  final String timeString; // e.g. "8:00 AM"
  final bool isTaken;
  final DateTime? takenTime;

  AdherenceLog({
    required this.medicineName,
    required this.timeString,
    required this.isTaken,
    this.takenTime,
  });
}

class Dependent {
  final String id;
  final String name;
  final int age;
  final double weight;
  final List<String> allergies;
  final List<String> conditions;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final int streakDays;
  final double adherenceRate; // e.g. 0.85 (85%)
  final List<AdherenceLog> adherenceLog;

  Dependent({
    required this.id,
    required this.name,
    required this.age,
    required this.weight,
    required this.allergies,
    required this.conditions,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.streakDays,
    required this.adherenceRate,
    required this.adherenceLog,
  });
}

class DependentNotifier extends Notifier<List<Dependent>> {
  @override
  List<Dependent> build() {
    final allProfilesAsync = ref.watch(allProfilesProvider);
    final caregiverProfile = ref.watch(onboardingProfileProvider).value;

    return allProfilesAsync.maybeWhen(
      data: (profiles) {
        final List<Dependent> list = [];
        for (var profile in profiles) {
          if (caregiverProfile != null && profile.id == caregiverProfile.id) {
            continue;
          }
          list.add(
            Dependent(
              id: profile.id,
              name: profile.nickname ?? 'Dependent',
              age: profile.age ?? 0,
              weight: profile.weightKg ?? 0.0,
              allergies: profile.allergies,
              conditions: profile.chronicConditions,
              emergencyContactName: 'Primary Caregiver',
              emergencyContactPhone: '+91 99999 99999',
              streakDays: 4,
              adherenceRate: 0.85,
              adherenceLog: profile.currentMedications.map((m) {
                return AdherenceLog(
                  medicineName: m.medicineName,
                  timeString: '09:00 AM',
                  isTaken: false,
                );
              }).toList(),
            ),
          );
        }
        return list;
      },
      orElse: () => [],
    );
  }

  void recordAdherence(String dependentId, String medicineName, String timeString, bool isTaken) {
    state = state.map((dep) {
      if (dep.id == dependentId) {
        final updatedLogs = dep.adherenceLog.map((log) {
          if (log.medicineName == medicineName && log.timeString == timeString) {
            return AdherenceLog(
              medicineName: log.medicineName,
              timeString: log.timeString,
              isTaken: isTaken,
              takenTime: isTaken ? DateTime.now() : null,
            );
          }
          return log;
        }).toList();
        return Dependent(
          id: dep.id,
          name: dep.name,
          age: dep.age,
          weight: dep.weight,
          allergies: dep.allergies,
          conditions: dep.conditions,
          emergencyContactName: dep.emergencyContactName,
          emergencyContactPhone: dep.emergencyContactPhone,
          streakDays: isTaken ? dep.streakDays + 1 : dep.streakDays,
          adherenceRate: dep.adherenceRate,
          adherenceLog: updatedLogs,
        );
      }
      return dep;
    }).toList();
  }
}

final dependentProvider = NotifierProvider<DependentNotifier, List<Dependent>>(() {
  return DependentNotifier();
});
