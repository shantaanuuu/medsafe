import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../models/medication_schedule.dart';
import '../models/medication_log.dart';

import '../shared_states.dart';

const String kDefaultBackendBaseUrl = 'http://10.230.141.96:5000';
const String kBackendBaseUrlKey = 'backend_base_url';
const Duration kApiTimeout = Duration(seconds: 15);

class BackendUrlNotifier extends Notifier<String> {
  @override
  String build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final saved = prefs.getString(kBackendBaseUrlKey);
      if (saved != null && saved.trim().isNotEmpty) {
        final trimmed = saved.trim();
        // Automatically overwrite stale/unreachable IPs from old test configs
        if (trimmed.contains('192.168.1.100') || trimmed.contains('192.168.0.207') || trimmed.contains('192.168.0.165') || trimmed.contains('10.10.178.186')) {
          prefs.setString(kBackendBaseUrlKey, kDefaultBackendBaseUrl);
          return kDefaultBackendBaseUrl;
        }
        return trimmed;
      }
    } catch (_) {}
    return const String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: kDefaultBackendBaseUrl,
    );
  }

  Future<void> setUrl(String newUrl) async {
    final cleanUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(kBackendBaseUrlKey, cleanUrl);
    } catch (_) {}
    state = cleanUrl;
  }

  Future<void> resetToDefault() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(kBackendBaseUrlKey, kDefaultBackendBaseUrl);
    } catch (_) {}
    state = kDefaultBackendBaseUrl;
  }
}

final backendBaseUrlProvider = NotifierProvider<BackendUrlNotifier, String>(() {
  return BackendUrlNotifier();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final baseUrl = ref.watch(backendBaseUrlProvider);
  return ApiService(baseUrl: baseUrl);
});

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  /// Sync user profile data to SQL backend
  Future<void> syncUser(
    String uid, {
    String? email,
    String? role,
    String? username,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/user/sync');
      debugPrint('API_SERVICE: POST $uri');
      final response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'uid': uid,
          if (email != null) 'email': email,
          if (role != null) 'role': role,
          if (username != null) 'username': username,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('User sync failed with status: ${response.statusCode}');
      }
      debugPrint('API_SERVICE: syncUser SUCCESS');
    } catch (e) {
      debugPrint('API_SERVICE: syncUser ERROR: $e');
      rethrow;
    }
  }

  /// Retrieve the user's SQLite-backed cabinet list
  Future<List<MedicineModel>> getCabinet(
    String uid, {
    String? dependentId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/cabinet?uid=$uid' +
            (dependentId != null ? '&dependent_id=$dependentId' : ''),
      );
      debugPrint('API_SERVICE: GET $uri');
      final response = await http.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Get cabinet failed with status: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        throw Exception('Invalid get cabinet response format');
      }

      final data = decoded['data'];
      if (data is! List) {
        return [];
      }

      return data.map((item) => MedicineModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('API_SERVICE: getCabinet ERROR: $e');
      rethrow;
    }
  }

  /// Add/Save medicine to the user's SQL cabinet
  Future<void> addMedicineToCabinet(
    String uid,
    MedicineModel medicine, {
    String? dependentId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/cabinet');
      debugPrint('API_SERVICE: POST $uri');
      final response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'uid': uid,
          'medicine': {
            ...medicine.toJson(),
            if (dependentId != null) 'dependent_id': dependentId,
          },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Add medicine to SQL failed with status: ${response.statusCode}',
        );
      }
      debugPrint('API_SERVICE: addMedicineToCabinet SUCCESS');
    } catch (e) {
      debugPrint('API_SERVICE: addMedicineToCabinet ERROR: $e');
      rethrow;
    }
  }

  /// Remove/Delete medicine from user's SQL cabinet
  Future<void> removeMedicineFromCabinet(
    String uid,
    String medicineId, {
    String? dependentId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/cabinet/$medicineId?uid=$uid' +
            (dependentId != null ? '&dependent_id=$dependentId' : ''),
      );
      debugPrint('API_SERVICE: DELETE $uri');
      final response = await http.delete(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Delete medicine from SQL failed with status: ${response.statusCode}',
        );
      }
      debugPrint('API_SERVICE: removeMedicineFromCabinet SUCCESS');
    } catch (e) {
      debugPrint('API_SERVICE: removeMedicineFromCabinet ERROR: $e');
      rethrow;
    }
  }

  /// Upload captured raw image file to backend scan API
  Future<MedicineModel> scanImage(File imageFile) async {
    try {
      debugPrint('API_SERVICE: scanImage START path=${imageFile.path}');
      final uri = Uri.parse('$baseUrl/scan');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('API_SERVICE: response status=${response.statusCode}');

      final dynamic decodedBody;
      try {
        decodedBody = jsonDecode(response.body);
      } on FormatException {
        throw Exception('Backend returned a non-JSON response.');
      }

      if (decodedBody is! Map<String, dynamic>) {
        throw Exception('Backend returned an invalid response.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final String message =
            decodedBody['message']?.toString() ?? 'Image scan request failed.';
        throw Exception(message);
      }

      final String? status = decodedBody['status']?.toString();
      if (status != 'success') {
        final String message =
            decodedBody['message']?.toString() ?? 'Image scan request failed.';
        throw Exception(message);
      }

      final dynamic data = decodedBody['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Backend response is missing medicine data.');
      }

      final MedicineModel medicine = MedicineModel.fromJson(data);
      debugPrint('API_SERVICE: scanImage SUCCESS');
      return medicine;
    } catch (error) {
      debugPrint('API_SERVICE: scanImage ERROR: $error');
      rethrow;
    }
  }

  Future<PrescriptionScanResult> scanPrescription(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/prescriptions/scan'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    final response = await http.Response.fromStream(await request.send());
    return PrescriptionScanResult.fromJson(_responseData(response) as Map);
  }

  Future<ReportAnalysis> analyseReport(File report) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/reports/analyse'),
    );
    request.files.add(await http.MultipartFile.fromPath('report', report.path));
    final response = await http.Response.fromStream(await request.send());
    return ReportAnalysis.fromJson(_responseData(response) as Map);
  }

  Future<MedicineModel> scanText(String ocrText) async {
    try {
      debugPrint('API_SERVICE: scanText START textLength=${ocrText.length}');
      final Uri uri = Uri.parse('$baseUrl/scan');
      debugPrint('API_SERVICE: POST $uri');
      final http.Response response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'ocr_text': ocrText}),
      );
      debugPrint('API_SERVICE: response status=${response.statusCode}');

      final dynamic decodedBody;
      try {
        decodedBody = jsonDecode(response.body);
      } on FormatException {
        throw Exception('Backend returned a non-JSON response.');
      }

      if (decodedBody is! Map<String, dynamic>) {
        throw Exception('Backend returned an invalid response.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final String message =
            decodedBody['message']?.toString() ?? 'Scan request failed.';
        throw Exception(message);
      }

      final String? status = decodedBody['status']?.toString();
      if (status != 'success') {
        final String message =
            decodedBody['message']?.toString() ?? 'Scan request failed.';
        throw Exception(message);
      }

      final dynamic data = decodedBody['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Backend response is missing medicine data.');
      }

      final MedicineModel medicine = MedicineModel.fromJson(data);
      debugPrint('API_SERVICE: scanText done');
      return medicine;
    } catch (error) {
      debugPrint('API_SERVICE: scanText ERROR: $error');
      rethrow;
    } finally {
      debugPrint('API_SERVICE: scanText FINALLY');
    }
  }

  Future<List<SearchedMedicine>> searchMedicines(String query) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/medicines/search?q=${Uri.encodeComponent(query)}',
      );
      debugPrint('API_SERVICE: GET $uri');
      final response = await http.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Search failed with status: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        throw Exception('Invalid search response format');
      }

      final data = decoded['data'];
      if (data is! List) {
        return [];
      }

      return data.map((item) => SearchedMedicine.fromJson(item)).toList();
    } catch (e) {
      debugPrint('API_SERVICE: searchMedicines ERROR: $e');
      rethrow;
    }
  }

  /// Retrieve medication schedules for a user or dependent
  Future<List<MedicationSchedule>> getSchedules(
    String uid, {
    String? dependentId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/schedules?uid=$uid' +
            (dependentId != null ? '&dependent_id=$dependentId' : ''),
      );
      debugPrint('API_SERVICE: GET $uri');
      final response = await http.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Get schedules failed with status: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        throw Exception('Invalid get schedules response format');
      }

      final data = decoded['data'];
      if (data is! List) {
        return [];
      }

      return data.map((item) => MedicationSchedule.fromJson(item)).toList();
    } catch (e) {
      debugPrint('API_SERVICE: getSchedules ERROR: $e');
      rethrow;
    }
  }

  /// Save or update a medication schedule
  Future<void> saveSchedule(MedicationSchedule schedule) async {
    try {
      final uri = Uri.parse('$baseUrl/api/schedules');
      debugPrint('API_SERVICE: POST $uri');
      final response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(schedule.toJson()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Save schedule failed with status: ${response.statusCode}',
        );
      }
      debugPrint('API_SERVICE: saveSchedule SUCCESS');
    } catch (e) {
      debugPrint('API_SERVICE: saveSchedule ERROR: $e');
      rethrow;
    }
  }

  /// Delete a medication schedule
  Future<void> deleteSchedule(String uid, String scheduleId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/schedules/$scheduleId?uid=$uid');
      debugPrint('API_SERVICE: DELETE $uri');
      final response = await http.delete(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Delete schedule failed with status: ${response.statusCode}',
        );
      }
      debugPrint('API_SERVICE: deleteSchedule SUCCESS');
    } catch (e) {
      debugPrint('API_SERVICE: deleteSchedule ERROR: $e');
      rethrow;
    }
  }

  /// Retrieve daily logs for a given user and date
  Future<List<MedicationLog>> getLogs(
    String uid,
    String date, {
    String? dependentId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/logs?uid=$uid&date=$date' +
            (dependentId != null ? '&dependent_id=$dependentId' : ''),
      );
      debugPrint('API_SERVICE: GET $uri');
      final response = await http.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Get logs failed with status: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        throw Exception('Invalid get logs response format');
      }

      final data = decoded['data'];
      if (data is! List) {
        return [];
      }

      return data.map((item) => MedicationLog.fromJson(item)).toList();
    } catch (e) {
      debugPrint('API_SERVICE: getLogs ERROR: $e');
      rethrow;
    }
  }

  /// Save daily medication log status
  Future<void> saveLog(MedicationLog log) async {
    try {
      final uri = Uri.parse('$baseUrl/api/logs');
      debugPrint('API_SERVICE: POST $uri');
      final response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(log.toJson()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Save log failed with status: ${response.statusCode}');
      }
      debugPrint('API_SERVICE: saveLog SUCCESS');
    } catch (e) {
      debugPrint('API_SERVICE: saveLog ERROR: $e');
      rethrow;
    }
  }

  Future<SymptomAnalysisResult> analyzeSymptoms({
    required int age,
    required String sex,
    required String description,
  }) async {
    final uri = Uri.parse('$baseUrl/api/symptoms/analyze');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'age': age, 'sex': sex, 'description': description}),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('The symptom service returned an invalid response.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('The symptom service returned an invalid response.');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['status'] != 'success') {
      throw Exception(
        decoded['message']?.toString() ?? 'Symptom analysis failed.',
      );
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('The symptom service returned no analysis.');
    }
    return SymptomAnalysisResult.fromJson(data);
  }

  Future<AllergyAnalysis> analyzeAllergy(String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/allergies/analyze'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'description': description}),
    );
    return AllergyAnalysis.fromResponse(response);
  }

  Future<List<AllergyRecord>> getAllergyRecords(String uid) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/allergies?uid=$uid'),
    );
    final body = _responseData(response);
    return (body as List? ?? const [])
        .whereType<Map>()
        .map((item) => AllergyRecord.fromJson(item))
        .toList();
  }

  Future<AllergyRecord> saveAllergyRecord(AllergyRecord record) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/allergies'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(record.toJson()),
    );
    return AllergyRecord.fromJson(_responseData(response) as Map);
  }

  Future<void> deleteAllergyRecord(String uid, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/allergies/$id?uid=$uid'),
    );
    _responseData(response);
  }

  Future<AllergyMedicineCheck> checkMedicineAllergy({
    required List<String> allergies,
    required String medicineName,
    String? genericName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/allergies/check-medicine'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'allergies': allergies,
        'medicine_name': medicineName,
        'generic_name': genericName ?? '',
      }),
    );
    return AllergyMedicineCheck.fromJson(_responseData(response) as Map);
  }

  Future<InteractionAnalysis> analyzeInteractions(
    List<Map<String, dynamic>> medicines,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/interactions/analyze'),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'medicines': medicines}),
    );
    return InteractionAnalysis.fromJson(_responseData(response) as Map);
  }

  Future<List<NearbyPlace>> nearbyHealthcare({
    required double latitude,
    required double longitude,
    required String category,
    required int radius,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/nearby-healthcare'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'radius': radius,
      }),
    );
    final data = _responseData(response) as Map;
    return (data['places'] as List? ?? const [])
        .whereType<Map>()
        .map(NearbyPlace.fromJson)
        .toList();
  }


dynamic _responseData(http.Response response) {
  dynamic decoded;

  try {
    decoded = jsonDecode(response.body);
  } catch (e) {
    debugPrint('API RESPONSE: Invalid JSON');
    debugPrint('HTTP STATUS: ${response.statusCode}');
    debugPrint('RESPONSE BODY: ${response.body}');

    throw Exception('The server returned an invalid response.');
  }

  debugPrint('API HTTP STATUS: ${response.statusCode}');
  debugPrint('API RESPONSE BODY: ${response.body}');

  if (decoded is! Map<String, dynamic> ||
      response.statusCode < 200 ||
      response.statusCode >= 300 ||
      decoded['status'] != 'success') {
    final message = decoded is Map
        ? decoded['message']?.toString() ?? 'Request failed.'
        : 'Request failed.';

    debugPrint('API REQUEST ERROR: $message');

    throw Exception(message);
  }

  return decoded['data'];
}

}

class InteractionAnalysis {
  const InteractionAnalysis({
    required this.links,
    required this.coverageNote,
    required this.coveredMedicines,
  });
  final List<InteractionRuleLink> links;
  final String coverageNote;
  final int coveredMedicines;

  factory InteractionAnalysis.fromJson(Map json) {
    final coverage = json['coverage'] as Map? ?? const {};
    return InteractionAnalysis(
      links: (json['links'] as List? ?? const [])
          .whereType<Map>()
          .map(InteractionRuleLink.fromJson)
          .toList(),
      coverageNote:
          coverage['note']?.toString() ?? 'No result is a safety guarantee.',
      coveredMedicines:
          int.tryParse(
            coverage['medicines_with_database_rules']?.toString() ?? '',
          ) ??
          0,
    );
  }
}

class InteractionRuleLink {
  const InteractionRuleLink({
    required this.medicineAId,
    required this.medicineBId,
    required this.severity,
    required this.sourceEffect,
    required this.matchedTerm,
    required this.description,
  });
  final String medicineAId;
  final String medicineBId;
  final String severity;
  final String sourceEffect;
  final String matchedTerm;
  final String description;

  factory InteractionRuleLink.fromJson(Map json) => InteractionRuleLink(
    medicineAId: json['medicine_a_id']?.toString() ?? '',
    medicineBId: json['medicine_b_id']?.toString() ?? '',
    severity: json['severity']?.toString() ?? 'monitor',
    sourceEffect: json['source_effect']?.toString() ?? 'Documented interaction',
    matchedTerm: json['matched_term']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
  );
}

class NearbyPlace {
  const NearbyPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.openNow,
  });
  final String id, name, address;
  final double latitude, longitude;
  final String? phone;
  final bool? openNow;
  factory NearbyPlace.fromJson(Map json) => NearbyPlace(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Healthcare provider',
    address: json['address']?.toString() ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    phone: json['phone']?.toString(),
    openNow: json['open_now'] as bool?,
  );
}

class PrescriptionScanResult {
  const PrescriptionScanResult({required this.medicines, required this.notes});
  final List<MedicineModel> medicines;
  final String notes;
  factory PrescriptionScanResult.fromJson(Map json) => PrescriptionScanResult(
    medicines: (json['medicines'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => MedicineModel.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
    notes:
        json['notes']?.toString() ?? 'Review each medicine before adding it.',
  );
}

class ReportAnalysis {
  const ReportAnalysis({
    required this.type,
    required this.summary,
    required this.highlights,
    required this.questions,
    required this.urgent,
    required this.urgentReason,
  });
  final String type, summary, urgentReason;
  final List<Map<String, dynamic>> highlights;
  final List<String> questions;
  final bool urgent;
  factory ReportAnalysis.fromJson(Map json) {
    final a = json['analysis'] as Map? ?? const {};
    final hs = a['highlights'] is List ? a['highlights'] as List : const [];
    final qs = a['questions_for_doctor'] is List
        ? a['questions_for_doctor'] as List
        : const [];
    return ReportAnalysis(
      type: a['report_type']?.toString() ?? 'Medical report',
      summary: a['plain_summary']?.toString() ?? '',
      highlights: hs
          .whereType<Map>()
          .map((x) => Map<String, dynamic>.from(x))
          .toList(),
      questions: qs.map((x) => x.toString()).toList(),
      urgent: a['urgent'] == true,
      urgentReason: a['urgent_reason']?.toString() ?? '',
    );
  }
}

class AllergyAnalysis {
  const AllergyAnalysis({
    required this.trigger,
    this.allergenCategory = 'General Compound / Allergen',
    required this.reactions,
    required this.severity,
    this.triageLevel = 'Level 3 - Routine Observational',
    required this.summary,
    required this.guidance,
    required this.emergency,
    this.emergencyReason,
    required this.disclaimer,
  });
  final String trigger;
  final String allergenCategory;
  final List<String> reactions;
  final String severity;
  final String triageLevel;
  final String summary;
  final List<String> guidance;
  final bool emergency;
  final String? emergencyReason;
  final String disclaimer;

  factory AllergyAnalysis.fromResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['status'] != 'success' ||
        decoded['data'] is! Map) {
      throw Exception(
        decoded is Map
            ? decoded['message']?.toString() ?? 'Reaction check failed.'
            : 'Reaction check failed.',
      );
    }
    final data = decoded['data'] as Map;
    return AllergyAnalysis(
      trigger: data['trigger']?.toString() ?? 'Unknown',
      allergenCategory:
          data['allergen_category']?.toString() ??
          'Pharmaceutical / General Compound',
      reactions: (data['reactions'] as List? ?? const [])
          .map((x) => x.toString())
          .toList(),
      severity: data['severity']?.toString() ?? 'unknown',
      triageLevel:
          data['triage_level']?.toString() ?? 'Level 2 - Clinical Review',
      summary: data['summary']?.toString() ?? '',
      guidance: (data['guidance'] as List? ?? const [])
          .map((x) => x.toString())
          .toList(),
      emergency: data['emergency'] == true,
      emergencyReason: data['emergency_reason']?.toString(),
      disclaimer: data['disclaimer']?.toString() ?? '',
    );
  }
}

class AllergyRecord {
  const AllergyRecord({
    this.id,
    required this.userUid,
    required this.triggerName,
    required this.reactions,
    required this.severity,
    this.notes = '',
    this.createdAt,
  });
  final String? id;
  final String userUid;
  final String triggerName;
  final List<String> reactions;
  final String severity;
  final String notes;
  final String? createdAt;
  Map<String, dynamic> toJson() => {
    'user_uid': userUid,
    'trigger_name': triggerName,
    'reactions': reactions,
    'severity': severity,
    'notes': notes,
  };
  factory AllergyRecord.fromJson(Map json) => AllergyRecord(
    id: json['id']?.toString(),
    userUid: json['user_uid']?.toString() ?? '',
    triggerName: json['trigger_name']?.toString() ?? '',
    reactions: (json['reactions'] as List? ?? const [])
        .map((x) => x.toString())
        .toList(),
    severity: json['severity']?.toString() ?? 'unknown',
    notes: json['notes']?.toString() ?? '',
    createdAt: json['created_at']?.toString(),
  );
}


class AllergyMedicineCheck {
  const AllergyMedicineCheck({
    required this.potentialConflict,
    required this.matchedAllergies,
    required this.message,
    this.status = 'inconclusive',
  });

  final bool potentialConflict;
  final List<String> matchedAllergies;
  final String message;
  final String status;

  factory AllergyMedicineCheck.fromJson(Map json) {
    final potentialConflict = json['potential_conflict'] == true;
    final responseStatus = json['status']?.toString();

    return AllergyMedicineCheck(
      potentialConflict: potentialConflict,
      matchedAllergies: (json['matched_allergies'] as List? ?? const [])
          .map((x) => x.toString())
          .toList(),
      message: json['message']?.toString() ?? 'No result available.',
      status: responseStatus ??
          (potentialConflict ? 'potential_conflict' : 'inconclusive'),
    );
  }
}

class SymptomAnalysisResult {
  const SymptomAnalysisResult({
    required this.symptoms,
    required this.summary,
    this.conditions = const [],
    this.triageLevel = 'Moderate / Outpatient Evaluation',
    this.triageCode = 'TRIAGE-CAT-3',
    this.affectedSystems = const [],
    required this.advice,
    required this.emergency,
    this.emergencyReason,
    required this.disclaimer,
  });

  final List<SymptomRecognition> symptoms;
  final String summary;
  final List<PossibleCondition> conditions;
  final String triageLevel;
  final String triageCode;
  final List<String> affectedSystems;
  final List<String> advice;
  final bool emergency;
  final String? emergencyReason;
  final String disclaimer;

  factory SymptomAnalysisResult.fromJson(Map<String, dynamic> json) {
    final symptoms = (json['recognized_symptoms'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => SymptomRecognition(
            phrase: item['user_phrase']?.toString() ?? '',
            normalised: item['normalised']?.toString() ?? '',
          ),
        )
        .toList();
    final conditions = (json['possible_conditions'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => PossibleCondition(
            name: item['name']?.toString() ?? 'Unknown',
            confidence: (item['confidence'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
    final systems = (json['affected_systems'] as List? ?? const [])
        .map((item) => item.toString())
        .toList();
    return SymptomAnalysisResult(
      symptoms: symptoms,
      summary: json['summary']?.toString() ?? '',
      conditions: conditions,
      triageLevel:
          json['triage_level']?.toString() ??
          'Moderate / Outpatient Evaluation',
      triageCode: json['triage_code']?.toString() ?? 'TRIAGE-CAT-3',
      affectedSystems: systems,
      advice: (json['advice'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      emergency: json['emergency'] == true,
      emergencyReason: json['emergency_reason']?.toString(),
      disclaimer: json['disclaimer']?.toString() ?? '',
    );
  }
}

class SymptomRecognition {
  const SymptomRecognition({required this.phrase, required this.normalised});
  final String phrase;
  final String normalised;
}

class PossibleCondition {
  const PossibleCondition({required this.name, required this.confidence});
  final String name;
  final double confidence;
}

class SearchedMedicine {
  final String id;
  final String brandName;
  final String genericName;
  final String? price;
  final String? manufacturer;
  final String? substitutes;
  final String? sideEffects;

  SearchedMedicine({
    required this.id,
    required this.brandName,
    required this.genericName,
    this.price,
    this.manufacturer,
    this.substitutes,
    this.sideEffects,
  });

  factory SearchedMedicine.fromJson(Map<String, dynamic> json) {
    return SearchedMedicine(
      id: json['id'] as String? ?? '',
      brandName:
          json['brand_name'] as String? ?? json['brandName'] as String? ?? '',
      genericName:
          json['generic_name'] as String? ??
          json['genericName'] as String? ??
          '',
      price: json['price'] as String?,
      manufacturer: json['manufacturer'] as String?,
      substitutes: json['substitutes'] as String?,
      sideEffects:
          json['side_effects'] as String? ?? json['sideEffects'] as String?,
    );
  }
}
