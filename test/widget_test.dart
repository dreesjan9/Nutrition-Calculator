// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:nutrition_calculator_app/main.dart';

void main() {
  testWidgets('Nutrition calculator app test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NutritionCalculatorApp());

    // Verify that the nutrition calculator loads
    expect(find.text('Glucose-Fructose Ratio Calculator'), findsOneWidget);
    expect(find.text('Enter the amount of carbs in g'), findsOneWidget);
  });
}
