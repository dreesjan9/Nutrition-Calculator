import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';
import 'package:nutrition_calculator_app/app/nutrition_calc/presentation/widgets/triathlon_nutrition_calculator.dart';

class NutritionCalculator extends StatefulWidget {
  const NutritionCalculator({super.key});

  @override
  _NutritionCalculatorState createState() => _NutritionCalculatorState();
}

enum GlucoseFructoseRatio {
  ratio1to08('1:0.8'),
  ratio2to1('2:1');
  
  const GlucoseFructoseRatio(this.displayName);
  final String displayName;
}

class _NutritionCalculatorState extends State<NutritionCalculator> {
  double maltoRatio = 1.8;
  double amountWaterRatio = 9.375;
  GlucoseFructoseRatio selectedRatio = GlucoseFructoseRatio.ratio1to08;
  TextEditingController carbAmount = TextEditingController();
  String resultMalto = '';
  String resultFructose = '';
  String resultAmountWater = '';

  void calculateCarbAmount() {
    final _carbAmount = double.tryParse(carbAmount.text);
    if (_carbAmount != null) {
      double malto, fructose;
      
      if (selectedRatio == GlucoseFructoseRatio.ratio1to08) {
        // 1:0.8 ratio
        malto = _carbAmount / maltoRatio;
        fructose = _carbAmount / maltoRatio * 0.8;
      } else {
        // 2:1 ratio
        malto = _carbAmount * (2.0 / 3.0); // 2/3 of total carbs
        fructose = _carbAmount * (1.0 / 3.0); // 1/3 of total carbs
      }
      
      var amountWater = amountWaterRatio * _carbAmount;
      setState(() {
        resultMalto =
            '${malto.toStringAsFixed(1)} g'; // Display the result with 2 decimal places
        resultFructose = '${fructose.toStringAsFixed(1)} g';
        resultAmountWater = '${amountWater.toStringAsFixed(1)} ml';
      });
    } else {
      setState(() {
        if (carbAmount.text.isEmpty) {
          resultMalto = '';
          resultFructose = '';
          resultAmountWater = '';
          return;
        } else {
          resultMalto = 'Invalid input';
          resultFructose = 'Invalid input';
          resultAmountWater = 'Invalid input';
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, SizingInformation) {
        return Scaffold(
          appBar: SizingInformation.deviceScreenType != DeviceScreenType.mobile ? AppBar(
            title: const Text('Nutrition Calculator'),
            backgroundColor: blackyellowTheme.colorScheme.secondary,
          ) : null,
          body: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black,
            ),
          
            child: ListView(
              padding: const EdgeInsets.all(0),
                children: [
                  Container(
                          padding: const EdgeInsets.all(15), 
                    height: carbAmount.text.isEmpty ? 220 : 300,
                    decoration: BoxDecoration(
                      color: blackyellowTheme.colorScheme.secondary,
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                    child: Column(
                      children: [
                        Text('Glucose-Fructose Ratio Calculator',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          'Enter the amount of carbs in g',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        
                        // Glucose-Fructose Ratio Dropdown
                        Row(
                          children: [
                            Text('Verhältnis: ', style: TextStyle(color: Colors.white, fontSize: 14)),
                            SizedBox(width: 10),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<GlucoseFructoseRatio>(
                                value: selectedRatio,
                                underline: SizedBox.shrink(),
                                isDense: true,
                                style: TextStyle(color: Colors.black, fontSize: 14),
                                items: GlucoseFructoseRatio.values.map((ratio) {
                                  return DropdownMenuItem(
                                    value: ratio,
                                    child: Text(ratio.displayName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedRatio = value;
                                    });
                                    calculateCarbAmount(); // Recalculate when ratio changes
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          maxLength: 6,
                          controller: carbAmount,
                          style: TextStyle(color: Colors.black),
                          cursorColor: Colors.black,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calculate, color: Colors.black),
                            suffixText: 'g',
                            labelText: 'Carb amount in g',
                            filled: true,
                            fillColor: Colors.white,
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            labelStyle: TextStyle(color: Colors.black, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            calculateCarbAmount();
                          },
                        ),
                        /*ElevatedButton(
                          onPressed: calculateCarbAmount,
                          child: const Text('Calculate'),
                        ),*/
                        // This section will expand and take the remaining space
                        resultMalto.isNotEmpty && resultFructose.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.only(top: 0),
                                alignment: Alignment.topLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Amount of Maltodextrin: $resultMalto',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Amount of Fructose: $resultFructose',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'You should mix it with: $resultAmountWater water',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  // Triathlon Nutrition Calculator
                  Container(
                    padding: const EdgeInsets.all(15), 
                    decoration: BoxDecoration(
                      color: blackyellowTheme.colorScheme.secondary,
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                    child: TriathlonNutritionCalculator(),
                  ),
                ],
              ),
          ),
        );
      }
    );
  }
}
