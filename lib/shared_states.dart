import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_service.dart';
import 'models/medicine_model.dart';

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
      );
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
    final prefs = ref.watch(sharedPreferencesProvider);
    final cached = prefs.getString('medicine_cabinet');
    List<Medicine> localList = [];
    if (cached != null) {
      try {
        final List decoded = jsonDecode(cached);
        localList = decoded.map((item) => Medicine.fromJson(item)).toList();
      } catch (_) {
        localList = _getMockData();
      }
    } else {
      localList = _getMockData();
    }

    // Trigger async SQL backend pull if user is logged in
    _syncFromBackend();

    return localList;
  }

  Future<void> _syncFromBackend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      final List<MedicineModel> dbList = await apiService.getCabinet(user.uid);

      if (dbList.isNotEmpty) {
        final List<Medicine> localList = dbList.map((m) {
          return Medicine(
            id: m.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: m.brandName ?? '',
            genericName: m.genericName ?? '',
            batchNumber: m.batchNumber,
            expiryDate: m.expiryDate != null ? DateTime.parse(m.expiryDate!) : DateTime.now(),
            addedDate: m.manufacturingDate != null ? DateTime.parse(m.manufacturingDate!) : DateTime.now(),
            dosageForm: m.strength ?? 'Tablet',
            verifiedSource: VerifiedSource.ocr,
            price: m.mrp != null ? double.tryParse(m.mrp!) : null,
            manufacturer: m.manufacturer,
            sideEffects: m.sideEffects,
            drugInteractions: m.drugInteractions,
            medicineDesc: m.medicineDesc,
            substitutes: m.substitutes,
            chemicalClass: m.chemicalClass,
            therapeuticClass: m.therapeuticClass,
            habitForming: m.habitForming,
          );
        }).toList();

        state = localList;
        _saveToPrefs();
      }
    } catch (e) {
      print("SQL CABINET SYNC ERROR: $e");
    }
  }

  List<Medicine> _getMockData() {
    final mockData = [
      Medicine(
        id: '1',
        name: 'Paracetamol 500mg',
        genericName: 'Acetaminophen',
        barcode: '8901043001815',
        batchNumber: 'BT-88992',
        expiryDate: DateTime.now().add(const Duration(days: 3)), // Expiring in 3 days (Urgent Red Alert)
        addedDate: DateTime.now().subtract(const Duration(days: 10)),
        dosageForm: 'Tablet',
        verifiedSource: VerifiedSource.barcode,
      ),
      Medicine(
        id: '2',
        name: 'Metformin 500mg',
        genericName: 'Metformin Hydrochloride',
        barcode: '8901043003422',
        batchNumber: 'MF-22119',
        expiryDate: DateTime.now().add(const Duration(days: 20)), // Expiring in 20 days (Amber warning)
        addedDate: DateTime.now().subtract(const Duration(days: 30)),
        dosageForm: 'Extended Release Tablet',
        verifiedSource: VerifiedSource.ocr,
      ),
      Medicine(
        id: '3',
        name: 'Amoxicillin 250mg Capsules',
        genericName: 'Amoxicillin Trihydrate',
        barcode: '8901043015467',
        batchNumber: 'AX-0034',
        expiryDate: DateTime.now().add(const Duration(days: 120)), // Safe (>90 days)
        addedDate: DateTime.now().subtract(const Duration(days: 5)),
        dosageForm: 'Capsule',
        verifiedSource: VerifiedSource.barcode,
      ),
    ];
    
    return mockData;
  }

  void addMedicine(Medicine med) async {
    state = [...state, med];
    _saveToPrefs();
    
    // Sync to backend SQLite
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
          habitForming: med.habitForming,
          verifiedSource: med.verifiedSource.index,
        );
        await apiService.addMedicineToCabinet(user.uid, model);
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
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.removeMedicineFromCabinet(user.uid, id);
      } catch (e) {
        print("SQL CABINET DELETE ERROR: $e");
      }
    }
  }

  void _saveToPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    final encoded = jsonEncode(state.map((m) => m.toJson()).toList());
    prefs.setString('medicine_cabinet', encoded);
  }
}

final cabinetProvider = NotifierProvider<CabinetNotifier, List<Medicine>>(() {
  return CabinetNotifier();
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
    return [
      Dependent(
        id: 'dep_1',
        name: 'Priya Sharma',
        age: 8,
        weight: 22.5,
        allergies: ['Penicillin'],
        conditions: ['Asthma'],
        emergencyContactName: 'Ramesh Sharma (Father)',
        emergencyContactPhone: '+91 98765 43210',
        streakDays: 5,
        adherenceRate: 0.92,
        adherenceLog: [
          AdherenceLog(medicineName: 'Amoxicillin 250mg', timeString: '09:00 AM', isTaken: true, takenTime: DateTime.now().subtract(const Duration(hours: 8))),
          AdherenceLog(medicineName: 'Amoxicillin 250mg', timeString: '09:00 PM', isTaken: false),
        ],
      ),
      Dependent(
        id: 'dep_2',
        name: 'Ramesh Gupta',
        age: 68,
        weight: 72.0,
        allergies: ['Sulfa Drugs'],
        conditions: ['Diabetes Type 2', 'Hypertension'],
        emergencyContactName: 'Ananya Gupta (Daughter)',
        emergencyContactPhone: '+91 91234 56789',
        streakDays: 12,
        adherenceRate: 0.88,
        adherenceLog: [
          AdherenceLog(medicineName: 'Metformin 500mg', timeString: '08:00 AM', isTaken: true, takenTime: DateTime.now().subtract(const Duration(hours: 9))),
          AdherenceLog(medicineName: 'Metformin 500mg', timeString: '08:00 PM', isTaken: true, takenTime: DateTime.now().subtract(const Duration(minutes: 10))),
        ],
      ),
    ];
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
