import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  const baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
  return ApiService(baseUrl: baseUrl);
});

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  /// Sync user profile data to SQL backend
  Future<void> syncUser(String uid, {String? email, String? role, String? username}) async {
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
  Future<List<MedicineModel>> getCabinet(String uid) async {
    try {
      final uri = Uri.parse('$baseUrl/api/cabinet?uid=$uid');
      debugPrint('API_SERVICE: GET $uri');
      final response = await http.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Get cabinet failed with status: ${response.statusCode}');
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
  Future<void> addMedicineToCabinet(String uid, MedicineModel medicine) async {
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
          'medicine': medicine.toJson(),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Add medicine to SQL failed with status: ${response.statusCode}');
      }
      debugPrint('API_SERVICE: addMedicineToCabinet SUCCESS');
    } catch (e) {
      debugPrint('API_SERVICE: addMedicineToCabinet ERROR: $e');
      rethrow;
    }
  }

  /// Remove/Delete medicine from user's SQL cabinet
  Future<void> removeMedicineFromCabinet(String uid, String medicineId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/cabinet/$medicineId?uid=$uid');
      debugPrint('API_SERVICE: DELETE $uri');
      final response = await http.delete(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Delete medicine from SQL failed with status: ${response.statusCode}');
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
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
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
        final String message = decodedBody['message']?.toString() ?? 'Image scan request failed.';
        throw Exception(message);
      }

      final String? status = decodedBody['status']?.toString();
      if (status != 'success') {
        final String message = decodedBody['message']?.toString() ?? 'Image scan request failed.';
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
        body: jsonEncode(<String, String>{
          'ocr_text': ocrText,
        }),
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
}
