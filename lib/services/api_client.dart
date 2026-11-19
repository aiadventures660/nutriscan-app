import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _initTokenFromStorage();
  }

  String? _sessionToken;
  TokenProvider? _tokenProvider;

  void setTokenProvider(TokenProvider? provider) {
    _tokenProvider = provider;
  }

  Future<void> _initTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('clerk_session_token');
      if (savedToken != null && savedToken.isNotEmpty) {
        _sessionToken = savedToken;
      }
    } catch (_) {}
  }

  /// Update the active Clerk session JWT
  void setSessionToken(String? token) {
    _sessionToken = token;
    if (kDebugMode) {
      debugPrint('🔑 ApiClient: Session token updated (length: ${token?.length ?? 0})');
    }
    SharedPreferences.getInstance().then((prefs) {
      if (token != null && token.isNotEmpty) {
        prefs.setString('clerk_session_token', token);
      } else {
        prefs.remove('clerk_session_token');
      }
    }).catchError((_) {});
  }

  String? get sessionToken => _sessionToken;

  Future<Map<String, String>> _ensureHeaders() async {
    String? token = _sessionToken;
    if (_tokenProvider != null) {
      try {
        final fresh = await _tokenProvider!();
        if (fresh != null && fresh.isNotEmpty) {
          _sessionToken = fresh;
          token = fresh;
        }
      } catch (e) {
        debugPrint('ApiClient TokenProvider error: $e');
      }
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  String get _baseUrl => ApiConfig.backendBaseUrl;

  /// Check server health
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse(_baseUrl.replaceFirst('/api/v1', '/health'));
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // Profile Endpoints
  // ===========================================================================

  Future<Map<String, dynamic>?> getProfile() async {
    return _get('/profile');
  }

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> data) async {
    return _put('/profile', data);
  }

  Future<Map<String, dynamic>?> syncOnboardingProfile(Map<String, dynamic> data) async {
    return _post('/profile/sync', data);
  }

  Future<Map<String, dynamic>?> getPreferences() async {
    return _get('/profile/preferences');
  }

  Future<Map<String, dynamic>?> updatePreferences(Map<String, dynamic> data) async {
    return _put('/profile/preferences', data);
  }

  // ===========================================================================
  // Meals Endpoints
  // ===========================================================================

  Future<List<dynamic>?> getMeals({
    int page = 1,
    int limit = 50,
    String? mealType,
    String? search,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (mealType != null) 'mealType': mealType,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$_baseUrl/meals').replace(queryParameters: queryParams);
    final res = await _getUri(uri);
    return res != null && res['data'] is List ? res['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> getMealById(String id) async {
    return _get('/meals/$id');
  }

  Future<Map<String, dynamic>?> createMeal(Map<String, dynamic> mealData) async {
    return _post('/meals', mealData);
  }

  Future<Map<String, dynamic>?> updateMeal(String id, Map<String, dynamic> mealData) async {
    return _put('/meals/$id', mealData);
  }

  Future<bool> deleteMeal(String id) async {
    try {
      final headers = await _ensureHeaders();
      final uri = Uri.parse('$_baseUrl/meals/$id');
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiClient deleteMeal error: $e');
      return false;
    }
  }

  // ===========================================================================
  // Dashboard & Hydration Endpoints
  // ===========================================================================

  Future<Map<String, dynamic>?> getDailySummary(String dateStr) async {
    return _get('/dashboard/daily?date=$dateStr');
  }

  Future<List<dynamic>?> getWeeklySummary(String endDateStr) async {
    final res = await _get('/dashboard/weekly?endDate=$endDateStr');
    return res != null && res['data'] is List ? res['data'] as List<dynamic> : null;
  }

  Future<Map<String, dynamic>?> logHydration(int amountMl) async {
    return _post('/dashboard/hydration', {'amountMl': amountMl});
  }

  // ===========================================================================
  // AI Vision & Text Endpoints
  // ===========================================================================

  Future<Map<String, dynamic>?> analyzeFoodImage(
    File imageFile, {
    String? foodHint,
  }) async {
    try {
      final headers = await _ensureHeaders();
      final uri = Uri.parse('$_baseUrl/ai/analyze-image');
      final request = http.MultipartRequest('POST', uri);

      if (headers.containsKey('Authorization')) {
        request.headers['Authorization'] = headers['Authorization']!;
      }

      if (foodHint != null && foodHint.isNotEmpty) {
        request.fields['hint'] = foodHint;
      }

      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        return decoded['data'] as Map<String, dynamic>?;
      } else {
        debugPrint('ApiClient analyzeFoodImage error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ApiClient analyzeFoodImage exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeFoodText(String query) async {
    return _post('/ai/analyze-text', {'query': query});
  }

  // ===========================================================================
  // User & GDPR Endpoints
  // ===========================================================================

  Future<Map<String, dynamic>?> exportUserData() async {
    return _get('/user/export');
  }

  Future<bool> deleteAccount() async {
    try {
      final headers = await _ensureHeaders();
      final uri = Uri.parse('$_baseUrl/user/account');
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiClient deleteAccount error: $e');
      return false;
    }
  }

  // ===========================================================================
  // Internal HTTP Helpers
  // ===========================================================================

  Future<Map<String, dynamic>?> _get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _getUri(uri);
  }

  Future<Map<String, dynamic>?> _getUri(Uri uri) async {
    try {
      final headers = await _ensureHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('ApiClient GET ${uri.path} error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ApiClient GET ${uri.path} exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      final headers = await _ensureHeaders();
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http
          .post(uri, headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('ApiClient POST $path error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ApiClient POST $path exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _put(String path, Map<String, dynamic> body) async {
    try {
      final headers = await _ensureHeaders();
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http
          .put(uri, headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('ApiClient PUT $path error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ApiClient PUT $path exception: $e');
      return null;
    }
  }
}

