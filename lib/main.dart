import 'package:flutter/material.dart';
import 'package:nutrition_calculator_app/app/nutrition_calc/presentation/pages/nutrition_calculator_widget.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';

void main() {
  runApp(const NutritionCalculatorApp());
}

class NutritionCalculatorApp extends StatelessWidget {
  const NutritionCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition Calculator',
      theme: blackyellowTheme,
      home: const NutritionCalculator(),
      debugShowCheckedModeBanner: false,
    );
  }
}
