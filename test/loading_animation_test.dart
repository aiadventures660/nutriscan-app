import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:nutriscan/widgets/nutri_loading_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('NutriLoadingIndicator renders Lottie animation widget correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: NutriLoadingIndicator(
              size: 120,
              message: 'Analyzing nutrition facts with AI...',
              showBackground: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(NutriLoadingIndicator), findsOneWidget);
    expect(find.byType(Lottie), findsOneWidget);
    expect(find.text('Analyzing nutrition facts with AI...'), findsOneWidget);
  });
}
