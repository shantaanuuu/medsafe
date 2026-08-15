import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/user_health_profile.dart';
import 'api_service.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return OnboardingRepository(baseUrl: apiService.baseUrl);
});

class OnboardingRepository {
  final String baseUrl;

  OnboardingRepository({required this.baseUrl});

  Future<UserHealthProfile?> fetchProfile(String uid) async {
    try {
      final uri = Uri.parse('$baseUrl/api/user/profile?uid=$uid');
      debugPrint('ONBOARDING_REPO: GET $uri');
      final response = await http.get(uri);

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Fetch profile failed with status: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        throw Exception('Invalid profile response format');
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Missing profile data block');
      }

      return UserHealthProfile.fromJson(data);
    } catch (e) {
      debugPrint('ONBOARDING_REPO: fetchProfile ERROR: $e');
      rethrow;
    }
  }

  Future<UserHealthProfile> createDraftProfile(String uid, {String? email, String? username}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/user/profile/create');
      debugPrint('ONBOARDING_REPO: POST $uri');
      final response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'firebase_uid': uid,
          if (email != null) 'email': email,
          if (username != null) 'username': username,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Create draft profile failed with status: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        throw Exception('Invalid profile response format');
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Missing profile data block');
      }

      return UserHealthProfile.fromJson(data);
    } catch (e) {
      debugPrint('ONBOARDING_REPO: createDraftProfile ERROR: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(UserHealthProfile profile) async {
    try {
      final uri = Uri.parse('$baseUrl/api/user/profile/update');
      debugPrint('ONBOARDING_REPO: POST $uri');
      final response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(profile.toJson()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Update profile failed with status: ${response.statusCode}');
      }
      debugPrint('ONBOARDING_REPO: updateProfile SUCCESS');
    } catch (e) {
      debugPrint('ONBOARDING_REPO: updateProfile ERROR: $e');
      rethrow;
    }
  }

  Future<List<UserHealthProfile>> fetchDependents(String caregiverUid) async {
    try {
      final uri = Uri.parse('$baseUrl/api/dependents?caregiver_uid=$caregiverUid');
      debugPrint('ONBOARDING_REPO: GET $uri');
      final response = await http.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Fetch dependents failed with status: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        throw Exception('Invalid dependents response format');
      }

      final data = decoded['data'];
      if (data is! List) {
        return [];
      }

      return data.map((item) => UserHealthProfile.fromJson(item)).toList();
    } catch (e) {
      debugPrint('ONBOARDING_REPO: fetchDependents ERROR: $e');
      rethrow;
    }
  }

  Future<void> saveDependent(UserHealthProfile dependent) async {
    try {
      final uri = Uri.parse('$baseUrl/api/dependents');
      debugPrint('ONBOARDING_REPO: POST $uri');
      final response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(dependent.toJson()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Save dependent failed with status: ${response.statusCode}');
      }
      debugPrint('ONBOARDING_REPO: saveDependent SUCCESS');
    } catch (e) {
      debugPrint('ONBOARDING_REPO: saveDependent ERROR: $e');
      rethrow;
    }
  }

  Future<void> deleteDependent(String dependentId, String caregiverUid) async {
    try {
      final uri = Uri.parse('$baseUrl/api/dependents/$dependentId?caregiver_uid=$caregiverUid');
      debugPrint('ONBOARDING_REPO: DELETE $uri');
      final response = await http.delete(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Delete dependent failed with status: ${response.statusCode}');
      }
      debugPrint('ONBOARDING_REPO: deleteDependent SUCCESS');
    } catch (e) {
      debugPrint('ONBOARDING_REPO: deleteDependent ERROR: $e');
      rethrow;
    }
  }
}
