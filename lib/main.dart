import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nutrition_calculator_app/app/nutrition_calc/presentation/pages/nutrition_calculator_widget.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';
import 'package:nutrition_calculator_app/services/storage_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Safety check for crash loops
    await StorageService.checkSafetyMode();
    
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.toString()}');
    };

    runApp(const NutritionCalculatorApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stack');
  });
}

class NutritionCalculatorApp extends StatelessWidget {
  const NutritionCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ratio - Advanced Sports Nutrition Planning',
      theme: blackyellowTheme,
      home: const NutritionCalculator(),
      debugShowCheckedModeBanner: false,
    );
  }
}
