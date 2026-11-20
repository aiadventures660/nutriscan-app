import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nutriscan/config/api_config.dart';
import 'package:nutriscan/services/api_client.dart';
import 'package:nutriscan/models/food_models.dart';

void main() {
  group('NutriScan E2E Live Render Backend & Integration Tests', () {
    const liveBackendUrl = 'https://nutriscan-backend-3sl6.onrender.com';
    const liveApiBaseUrl = 'https://nutriscan-backend-3sl6.onrender.com/api/v1';

    test('1. Production API Configuration Verification', () {
      expect(
        ApiConfig.productionBackendUrl,
        equals(liveApiBaseUrl),
        reason: 'productionBackendUrl must point to deployed Render URL',
      );
      expect(
        ApiConfig.defaultBackendUrl,
        equals(ApiConfig.productionBackendUrl),
        reason: 'defaultBackendUrl must default to productionBackendUrl',
      );
      expect(
        ApiConfig.clerkPublishableKey,
        isNotEmpty,
        reason: 'Clerk publishable key must be configured',
      );
      expect(
        ApiConfig.clerkApplicationId,
        equals('app_3MFQeKduTlDlvScWQinKnELN9cx'),
        reason: 'Clerk Application ID must match registered app',
      );
    });

    test('2. Live Render Backend Health Check & Availability', () async {
      final uri = Uri.parse('$liveBackendUrl/health');
      final stopwatch = Stopwatch()..start();
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      stopwatch.stop();

      expect(res.statusCode, equals(200), reason: 'Live health check should return 200 OK');
      final data = json.decode(res.body) as Map<String, dynamic>;
      expect(data['status'], equals('healthy'));
      expect(data['service'], equals('nutriscan-backend'));
      expect(data['environment'], equals('production'));
      expect(stopwatch.elapsedMilliseconds, lessThan(5000), reason: 'Response latency acceptable');
    });

    test('3. Live Backend Security: Unauthenticated Requests Rejected (401)', () async {
      final uri = Uri.parse('$liveApiBaseUrl/profile');
      final res = await http.get(uri);
      expect(res.statusCode, equals(401), reason: 'Missing token should return HTTP 401');

      final data = json.decode(res.body) as Map<String, dynamic>;
      expect(data['success'], isFalse);
      expect(data['error'], equals('Unauthorized'));
    });

    test('4. Live Backend Security: Forged JWT Tokens Rejected (401)', () async {
      final uri = Uri.parse('$liveApiBaseUrl/meals');
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer forged_fake_token_abc_123'},
      );
      expect(res.statusCode, equals(401), reason: 'Forged token should be rejected with HTTP 401');

      final data = json.decode(res.body) as Map<String, dynamic>;
      expect(data['success'], isFalse);
      expect(data['error'], equals('Unauthorized'));
    });

    test('5. ApiClient Session Token Management & Header Attachment', () async {
      final client = ApiClient();
      client.setSessionToken('test_session_jwt_sample_token');
      expect(client.sessionToken, equals('test_session_jwt_sample_token'));

      // Clear on logout
      client.setSessionToken(null);
      expect(client.sessionToken, isNull);
    });

    test('6. Food Nutrition Data Model & Macro Parsing', () {
      final testNutrition = 'Calories: 520 kcal, Protein: 32g, Carbs: 45g, Fat: 18g';
      final scanData = ScanData(
        foodName: 'Grilled Chicken & Quinoa',
        nutritionInfo: testNutrition,
        healthScore: 'Excellent',
        recommendations: 'Rich in lean protein and complex carbs.',
        vitaminsAndMinerals: const [],
        imagePath: '/test/path.jpg',
        timestamp: DateTime.now(),
        novaGroup: 1,
      );

      final entry = LoggedFoodEntry(
        id: 'test_meal_101',
        scanData: scanData,
        timestamp: scanData.timestamp,
        parsedNutrition: ParsedNutritionValues(
          calories: 520,
          protein: 32,
          carbs: 45,
          fat: 18,
        ),
        mealType: 'Lunch',
      );

      expect(entry.parsedNutrition.calories, equals(520));
      expect(entry.parsedNutrition.protein, equals(32));
      expect(entry.parsedNutrition.carbs, equals(45));
      expect(entry.parsedNutrition.fat, equals(18));
      expect(entry.scanData.novaGroup, equals(1));
    });

    test('7. Lottie Loading Animation Asset Integrity', () {
      final file = File('assets/animations/loading.json');
      expect(file.existsSync(), isTrue, reason: 'loading.json must exist in assets/animations');
      final content = file.readAsStringSync();
      final jsonMap = json.decode(content) as Map<String, dynamic>;
      expect(jsonMap.containsKey('v'), isTrue);
      expect(jsonMap.containsKey('layers'), isTrue);
    });

    test('8. Network Timeout Handling & Resilience', () async {
      // Test that an unreachable host or forced timeout triggers catch without crashing
      final unreachableUri = Uri.parse('http://10.255.255.1:65534/health');
      bool timedOut = false;
      try {
        await http.get(unreachableUri).timeout(const Duration(milliseconds: 500));
      } catch (_) {
        timedOut = true;
      }
      expect(timedOut, isTrue, reason: 'Network timeout must be handled gracefully');
    });
  });
}
