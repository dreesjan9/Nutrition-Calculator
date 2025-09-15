import 'package:flutter/material.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';

enum NutritionType { gel, caffeineGel, bar, bottle }
enum GelCarbs { g30, g40, g45 }
enum BarCarbs { g20, g25, g30 }
enum SweatRate { low, medium, high }
enum FluidRate { low, medium, high }

class NutritionItem {
  final String id;
  final NutritionType type;
  final GelCarbs? gelCarbs;
  final BarCarbs? barCarbs;
  final double? bottleVolume;
  final double? bottleCarbs;
  final double? bottleSodium;
  final double? caffeine;

  NutritionItem({
    required this.id,
    required this.type,
    this.gelCarbs,
    this.barCarbs,
    this.bottleVolume,
    this.bottleCarbs,
    this.bottleSodium,
    this.caffeine,
  });

  double get carbsAmount {
    switch (type) {
      case NutritionType.gel:
      case NutritionType.caffeineGel:
        switch (gelCarbs) {
          case GelCarbs.g30: return 30.0;
          case GelCarbs.g40: return 40.0;
          case GelCarbs.g45: return 45.0;
          default: return 0.0;
        }
      case NutritionType.bar:
        switch (barCarbs) {
          case BarCarbs.g20: return 20.0;
          case BarCarbs.g25: return 25.0;
          case BarCarbs.g30: return 30.0;
          default: return 0.0;
        }
      case NutritionType.bottle:
        return bottleCarbs ?? 0.0;
    }
  }

  double get sodiumAmount {
    switch (type) {
      case NutritionType.gel:
      case NutritionType.caffeineGel:
        return 50.0; // Standard Gel Sodium
      case NutritionType.bar:
        return 30.0; // Standard Bar Sodium
      case NutritionType.bottle:
        return bottleSodium ?? 0.0;
    }
  }

  double get fluidAmount {
    switch (type) {
      case NutritionType.gel:
      case NutritionType.caffeineGel:
        return 0.0; // Gel has no fluid
      case NutritionType.bar:
        return 0.0; // Bar has no fluid
      case NutritionType.bottle:
        return bottleVolume ?? 0.0;
    }
  }

  double get caffeineAmount => caffeine ?? 0.0;
}

class SportNutrition {
  final String sportName;
  final IconData icon;
  final Color color;
  final TextEditingController durationController;
  final TextEditingController carbTargetController;
  final TextEditingController sodiumTargetController;
  final TextEditingController fluidTargetController;
  final List<NutritionItem> nutritionItems;

  SportNutrition({
    required this.sportName,
    required this.icon,
    required this.color,
  }) : durationController = TextEditingController(),
        carbTargetController = TextEditingController(),
        sodiumTargetController = TextEditingController(),
        fluidTargetController = TextEditingController(),
        nutritionItems = [];

  double get totalCarbs => nutritionItems.fold(0.0, (sum, item) => sum + item.carbsAmount);
  double get totalSodium => nutritionItems.fold(0.0, (sum, item) => sum + item.sodiumAmount);
  double get totalFluid => nutritionItems.fold(0.0, (sum, item) => sum + item.fluidAmount);
  double get totalCaffeine => nutritionItems.fold(0.0, (sum, item) => sum + item.caffeineAmount);

  double get duration {
    final text = durationController.text.trim();
    if (text.isEmpty) return 0.0;
    
    if (text.contains(':')) {
      final parts = text.split(':');
      if (parts.length == 2) {
        final hours = double.tryParse(parts[0]) ?? 0.0;
        final minutes = double.tryParse(parts[1]) ?? 0.0;
        return hours * 60 + minutes; // Convert to minutes
      }
    }
    
    // Fallback: try to parse as minutes directly
    return double.tryParse(text) ?? 0.0;
  }
  double get carbTarget => (double.tryParse(carbTargetController.text) ?? 0.0) * (duration / 60);
  double get sodiumTarget => (double.tryParse(sodiumTargetController.text) ?? 0.0) * (duration / 60);
  double get fluidTarget => (double.tryParse(fluidTargetController.text) ?? 0.0) * (duration / 60);

  double get carbsDifference => totalCarbs - carbTarget;
  double get sodiumDifference => totalSodium - sodiumTarget;
  double get fluidDifference => totalFluid - fluidTarget;
}

class TriathlonNutritionCalculator extends StatefulWidget {
  const TriathlonNutritionCalculator({super.key});

  @override
  State<TriathlonNutritionCalculator> createState() => _TriathlonNutritionCalculatorState();
}

class _TriathlonNutritionCalculatorState extends State<TriathlonNutritionCalculator> {
  late List<SportNutrition> sports;
  final TextEditingController sipVolumeController = TextEditingController(text: '22');
  final TextEditingController drinkingIntervalController = TextEditingController(text: '10');

  SweatRate defaultSweatRate = SweatRate.medium;
  FluidRate defaultFluidRate = FluidRate.medium;

  double getSweatRateValue(SweatRate rate) {
    switch (rate) {
      case SweatRate.low: return 500.0;
      case SweatRate.medium: return 750.0;
      case SweatRate.high: return 1000.0;
    }
  }

  double getFluidRateValue(FluidRate rate) {
    switch (rate) {
      case FluidRate.low: return 500.0;
      case FluidRate.medium: return 750.0;
      case FluidRate.high: return 1000.0;
    }
  }

  String getSweatRateLabel(SweatRate rate) {
    switch (rate) {
      case SweatRate.low: return 'Low (500mg/h)';
      case SweatRate.medium: return 'Medium (750mg/h)';
      case SweatRate.high: return 'High (1000mg/h)';
    }
  }

  String getFluidRateLabel(FluidRate rate) {
    switch (rate) {
      case FluidRate.low: return 'Low (500ml/h)';
      case FluidRate.medium: return 'Medium (750ml/h)';
      case FluidRate.high: return 'High (1000ml/h)';
    }
  }

  void applyDefaultRatesToAllSports() {
    final defaultSodiumTarget = getSweatRateValue(defaultSweatRate);
    final defaultFluidTarget = getFluidRateValue(defaultFluidRate);

    for (final sport in sports) {
      sport.sodiumTargetController.text = defaultSodiumTarget.toString();
      sport.fluidTargetController.text = defaultFluidTarget.toString();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    sports = [
      SportNutrition(
        sportName: 'Pre-Race-Nutrition',
        icon: Icons.pool,
        color: blackyellowTheme.colorScheme.primary,
      ),
      SportNutrition(
        sportName: 'Cycling',
        icon: Icons.directions_bike,
        color: blackyellowTheme.colorScheme.primary,
      ),
      SportNutrition(
        sportName: 'Running',
        icon: Icons.directions_run,
        color: blackyellowTheme.colorScheme.primary,
      ),
    ];

    // Apply default rates to all sports on initialization
    applyDefaultRatesToAllSports();
  }

  @override
  void dispose() {
    for (final sport in sports) {
      sport.durationController.dispose();
      sport.carbTargetController.dispose();
      sport.sodiumTargetController.dispose();
      sport.fluidTargetController.dispose();
    }
    sipVolumeController.dispose();
    drinkingIntervalController.dispose();
    super.dispose();
  }

  double get sipVolume => double.tryParse(sipVolumeController.text) ?? 22.0;
  double get drinkingInterval => double.tryParse(drinkingIntervalController.text) ?? 10.0;

  // Typography Constants
  TextStyle get headingStyle => TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  TextStyle get sectionTitleStyle => TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  TextStyle get labelStyle => TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  TextStyle get bodyStyle => TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  TextStyle get captionStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.8),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Spacing Constants
  static const double spacingXS = 8.0;
  static const double spacingS = 12.0;
  static const double spacingM = 16.0;
  static const double spacingL = 20.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // Consistent button style
  ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: blackyellowTheme.colorScheme.primary,
    foregroundColor: Colors.black,
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
  );

  ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: blackyellowTheme.colorScheme.secondary,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
  );

  void _addNutritionItem(SportNutrition sport, NutritionType type) {
    showDialog(
      context: context,
      builder: (context) => _NutritionDialog(
        type: type,
        onAdd: (item) {
          setState(() {
            sport.nutritionItems.add(item);
          });
        },
      ),
    );
  }

  void _removeNutritionItem(SportNutrition sport, NutritionItem item) {
    setState(() {
      sport.nutritionItems.remove(item);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pool, color: blackyellowTheme.primaryColor, size: 24),
            SizedBox(width: spacingXS),
            Icon(Icons.directions_bike, color: blackyellowTheme.primaryColor, size: 24),
            SizedBox(width: spacingXS),
            Icon(Icons.directions_run, color: blackyellowTheme.primaryColor, size: 24),
            SizedBox(width: spacingM),
            Text(
              'Triathlon Nutrition Calculator',
              style: headingStyle,
            ),
          ],
        ),
        SizedBox(height: spacingXL),
        // Drinking Settings Input
        Container(
          padding: EdgeInsets.all(spacingL),
          margin: EdgeInsets.only(bottom: spacingL),
          decoration: BoxDecoration(
            color: blackyellowTheme.colorScheme.secondary,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Drinking interval:',
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(width: spacingS),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: drinkingIntervalController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        suffixText: 'min',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacingS),
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Default sip volume:',
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(width: spacingS),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: sipVolumeController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        suffixText: 'ml/sip',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(width: spacingXS),
                  GestureDetector(
                    onTap: _showSipVolumeInfoDialog,
                    child: Icon(
                      Icons.info_outline,
                      color: blackyellowTheme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacingS),
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Default sweat rate:',
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(width: spacingS),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<SweatRate>(
                      value: defaultSweatRate,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                      items: SweatRate.values.map((rate) {
                        return DropdownMenuItem(
                          value: rate,
                          child: Text(getSweatRateLabel(rate)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            defaultSweatRate = value;
                          });
                          applyDefaultRatesToAllSports();
                        }
                      },
                    ),
                  ),
                  SizedBox(width: spacingXS),
                  GestureDetector(
                    onTap: _showSweatRateInfoDialog,
                    child: Icon(
                      Icons.info_outline,
                      color: blackyellowTheme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacingS),
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Default fluid rate:',
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(width: spacingS),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<FluidRate>(
                      value: defaultFluidRate,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                      items: FluidRate.values.map((rate) {
                        return DropdownMenuItem(
                          value: rate,
                          child: Text(getFluidRateLabel(rate)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            defaultFluidRate = value;
                          });
                          applyDefaultRatesToAllSports();
                        }
                      },
                    ),
                  ),
                  SizedBox(width: spacingXS),
                  GestureDetector(
                    onTap: _showFluidRateInfoDialog,
                    child: Icon(
                      Icons.info_outline,
                      color: blackyellowTheme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildSportSection(sports[0]), // Pre-Race-Nutrition
        _buildSwimmingNote(),
        _buildSportSection(sports[1]), // Cycling
        _buildSportSection(sports[2]), // Running
        _buildTotalSection(),
        _buildRecommendationsSection(),
      ],
    );
  }

  Widget _buildSportSection(SportNutrition sport) {
    return Container(
      margin: EdgeInsets.only(bottom: spacingL),
      padding: EdgeInsets.all(spacingL),
      decoration: BoxDecoration(
        color: blackyellowTheme.colorScheme.secondary,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sport Header
          Row(
            children: [
              Icon(sport.icon, color: sport.color, size: 24),
              SizedBox(width: spacingS),
              Text(
                sport.sportName,
                style: sectionTitleStyle,
              ),
            ],
          ),
          SizedBox(height: spacingM),

          // Duration Input (skip for Pre-Race-Nutrition)
          if (sport.sportName != 'Pre-Race-Nutrition') ...[
            TextFormField(
              controller: sport.durationController,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.timer, color: Colors.black),
                suffixText: 'HH:MM',
                labelText: 'Duration (e.g. 1:30)',
                hintText: '1:30',
                hintStyle: TextStyle(color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                labelStyle: TextStyle(color: Colors.black, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: spacingS),
          ],

          // Target Values
          Column(
            children: [
              TextFormField(
                controller: sport.carbTargetController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.local_fire_department, color: Colors.black),
                  suffixText: sport.sportName == 'Pre-Race-Nutrition' ? 'g' : 'g/h',
                  labelText: 'Carb Target',
                  filled: true,
                  fillColor: Colors.white,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  labelStyle: TextStyle(color: Colors.black, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: sport.sodiumTargetController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.water_drop, color: Colors.black),
                  suffixText: 'mg/h',
                  labelText: 'Sodium Target',
                  filled: true,
                  fillColor: Colors.white,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  labelStyle: TextStyle(color: Colors.black, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: sport.fluidTargetController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.local_drink, color: Colors.black),
                  suffixText: 'ml/h',
                  labelText: 'Fluid',
                  filled: true,
                  fillColor: Colors.white,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  labelStyle: TextStyle(color: Colors.black, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          SizedBox(height: spacingM),

          // Add Nutrition Buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _addNutritionItem(sport, NutritionType.gel),
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Gel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: primaryButtonStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _addNutritionItem(sport, NutritionType.caffeineGel),
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Caffeine Gel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: primaryButtonStyle,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacingXS),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _addNutritionItem(sport, NutritionType.bar),
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Bar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: primaryButtonStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _addNutritionItem(sport, NutritionType.bottle),
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Bottle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: primaryButtonStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacingM),

          // Nutrition Items List
          if (sport.nutritionItems.isNotEmpty)
            ...sport.nutritionItems.map((item) => _buildNutritionItem(sport, item)),

          SizedBox(height: spacingM),

          // Summary for this sport
          _buildSportSummary(sport),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(SportNutrition sport, NutritionItem item) {
    Color color;
    String description;

    switch (item.type) {
      case NutritionType.gel:
        color = blackyellowTheme.colorScheme.primary;
        final carbValue = item.gelCarbs.toString().split('.').last.substring(1); // Remove 'g' prefix
        description = 'Regular Gel ${carbValue}g';
        break;
      case NutritionType.caffeineGel:
        color = blackyellowTheme.colorScheme.primary;
        final carbValue = item.gelCarbs.toString().split('.').last.substring(1); // Remove 'g' prefix
        description = 'Caffeine Gel ${carbValue}g (${item.caffeineAmount.toInt()}mg caffeine)';
        break;
      case NutritionType.bar:
        color = blackyellowTheme.colorScheme.secondary;
        final carbValue = item.barCarbs.toString().split('.').last.substring(1); // Remove 'g' prefix
        description = 'Bar ${carbValue}g';
        break;
      case NutritionType.bottle:
        color = blackyellowTheme.colorScheme.secondary;
        description = 'Bottle ${item.bottleVolume}ml';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                  item.type == NutritionType.bottle
                    ? () {
                        // Calculate glucose and fructose based on 1:0.8 ratio
                        final totalCarbs = item.carbsAmount;
                        final glucose = totalCarbs / 1.8; // 1/(1+0.8) = 1/1.8
                        final fructose = glucose * 0.8;

                        // Calculate required number of sips based on drinking interval
                        String sipInfo = '';
                        final carbTargetPerHour = double.tryParse(sport.carbTargetController.text) ?? 0.0;
                        if (carbTargetPerHour > 0 && item.bottleVolume != null && item.bottleCarbs != null && item.bottleVolume! > 0 && item.bottleCarbs! > 0) {
                          final carbsPerMl = item.bottleCarbs! / item.bottleVolume!; // g carbs per ml
                          final carbsPerSip = carbsPerMl * sipVolume; // carbs per default sip
                          final requiredCarbsPerInterval = carbTargetPerHour * (drinkingInterval / 60); // carbs needed per interval
                          final requiredSipsPerInterval = requiredCarbsPerInterval / carbsPerSip; // sips needed per interval
                          final totalCarbsFromAllSips = requiredSipsPerInterval * carbsPerSip; // total carbs from all sips
                          sipInfo = ', ${requiredSipsPerInterval.toStringAsFixed(1)} sips every ${drinkingInterval.toInt()}min (${totalCarbsFromAllSips.toInt()}g carbs)';
                        }

                        return 'Carbs: ${totalCarbs.toInt()}g (${glucose.toInt()}g Gl/${fructose.toInt()}g Fr), Na: ${item.sodiumAmount.toInt()}mg, Fl: ${item.fluidAmount.toInt()}ml$sipInfo';
                      }()
                    : 'Carbs: ${item.carbsAmount.toInt()}g, Na: ${item.sodiumAmount.toInt()}mg, Fl: ${item.fluidAmount.toInt()}ml',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeNutritionItem(sport, item),
            icon: Icon(Icons.delete, color: Colors.white),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSportSummary(SportNutrition sport) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Summary ${sport.sportName}',
            style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spacingS),
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
              verticalInside: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            columnWidths: {
              0: FlexColumnWidth(2.0), // Breitere erste Spalte für Überschriften
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                children: [
                  TableCell(child: Text('', style: TextStyle(color: Colors.white))),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('target', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('actual', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('diff', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  )),
                ],
              ),
              TableRow(
                children: [
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Carbohydrates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), softWrap: false),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${sport.carbTarget.toInt()}g', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${sport.totalCarbs.toInt()}g', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '${sport.carbsDifference > 0 ? '+' : ''}${sport.carbsDifference.toInt()}g',
                      style: TextStyle(
                        color: sport.carbsDifference >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
              ),
              TableRow(
                children: [
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Sodium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${sport.sodiumTarget.toInt()}mg', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${sport.totalSodium.toInt()}mg', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '${sport.sodiumDifference > 0 ? '+' : ''}${sport.sodiumDifference.toInt()}mg',
                      style: TextStyle(
                        color: sport.sodiumDifference >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
              ),
              TableRow(
                children: [
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Fluid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${sport.fluidTarget.toInt()}ml', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${sport.totalFluid.toInt()}ml', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '${sport.fluidDifference > 0 ? '+' : ''}${sport.fluidDifference.toInt()}ml',
                      style: TextStyle(
                        color: sport.fluidDifference >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
              ),
              TableRow(
                children: [
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Caffeine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('-', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${sport.totalCaffeine.toInt()}mg', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('-', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    final totalCarbs = sports.fold(0.0, (sum, sport) => sum + sport.totalCarbs);
    final totalSodium = sports.fold(0.0, (sum, sport) => sum + sport.totalSodium);
    final totalFluid = sports.fold(0.0, (sum, sport) => sum + sport.totalFluid);
    final totalCaffeine = sports.fold(0.0, (sum, sport) => sum + sport.totalCaffeine);

    final targetCarbs = sports.fold(0.0, (sum, sport) => sum + sport.carbTarget);
    final targetSodium = sports.fold(0.0, (sum, sport) => sum + sport.sodiumTarget);
    final targetFluid = sports.fold(0.0, (sum, sport) => sum + sport.fluidTarget);

    final carbsDiff = totalCarbs - targetCarbs;
    final sodiumDiff = totalSodium - targetSodium;
    final fluidDiff = totalFluid - targetFluid;

    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: blackyellowTheme.colorScheme.primary,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        children: [
          Text(
            'Total Triathlon Summary',
            style: sectionTitleStyle.copyWith(color: Colors.black),
          ),
          SizedBox(height: spacingM),
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 1),
              verticalInside: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 1),
            ),
            columnWidths: {
              0: FlexColumnWidth(2.0), // Breitere erste Spalte für Überschriften
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                children: [
                  TableCell(child: Text('', style: TextStyle(color: Colors.black))),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('target', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('actual', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('diff', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  )),
                ],
              ),
              TableRow(
                children: [
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Carbohydrates', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), softWrap: false),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${targetCarbs.toInt()}g', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${totalCarbs.toInt()}g', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '${carbsDiff > 0 ? '+' : ''}${carbsDiff.toInt()}g',
                      style: TextStyle(
                        color: carbsDiff >= 0 ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
              ),
              TableRow(
                children: [
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Sodium', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${targetSodium.toInt()}mg', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${totalSodium.toInt()}mg', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '${sodiumDiff > 0 ? '+' : ''}${sodiumDiff.toInt()}mg',
                      style: TextStyle(
                        color: sodiumDiff >= 0 ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
              ),
              TableRow(
                children: [
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Fluid', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${targetFluid.toInt()}ml', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${totalFluid.toInt()}ml', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '${fluidDiff > 0 ? '+' : ''}${fluidDiff.toInt()}ml',
                      style: TextStyle(
                        color: fluidDiff >= 0 ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
              ),
              TableRow(
                children: [
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Caffeine', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('-', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${totalCaffeine.toInt()}mg', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
                  )),
                  TableCell(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('-', style: TextStyle(color: Colors.black), textAlign: TextAlign.center),
                  )),
                ],
              ),
            ],
          ),
          SizedBox(height: spacingL),
          _buildRaceRequirementsSummary(),
        ],
      ),
    );
  }

  Widget _buildRaceRequirementsSummary() {
    // Calculate nutrition items grouped by sport
    final Map<String, Map<String, int>> sportItems = {};

    for (final sport in sports) {
      final Map<String, int> items = {};

      for (final item in sport.nutritionItems) {
        String itemName = '';
        switch (item.type) {
          case NutritionType.gel:
          case NutritionType.caffeineGel:
            switch (item.gelCarbs) {
              case GelCarbs.g30: itemName = 'Energy Gel 30g'; break;
              case GelCarbs.g40: itemName = 'Energy Gel 40g'; break;
              case GelCarbs.g45: itemName = 'Energy Gel 45g'; break;
              default: itemName = 'Energy Gel'; break;
            }
            if (item.type == NutritionType.caffeineGel) {
              itemName += ' (with Caffeine)';
            }
            break;
          case NutritionType.bar:
            switch (item.barCarbs) {
              case BarCarbs.g20: itemName = 'Energy Bar 20g'; break;
              case BarCarbs.g25: itemName = 'Energy Bar 25g'; break;
              case BarCarbs.g30: itemName = 'Energy Bar 30g'; break;
              default: itemName = 'Energy Bar'; break;
            }
            break;
          case NutritionType.bottle:
            final volume = item.bottleVolume?.toInt() ?? 0;
            final carbs = item.bottleCarbs?.toInt() ?? 0;
            final sodium = item.bottleSodium?.toInt() ?? 0;
            itemName = 'Sports Drink (${volume}ml, ${carbs}g carbs, ${sodium}mg sodium)';
            break;
        }
        items[itemName] = (items[itemName] ?? 0) + 1;
      }

      if (items.isNotEmpty) {
        sportItems[sport.sportName] = items;
      }
    }

    if (sportItems.isEmpty) {
      return Container(
        padding: EdgeInsets.all(spacingM),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No nutrition items added yet. Add items to see race requirements.',
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.6),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(spacingM),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Race Requirements Checklist',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: spacingS),

          // Sport Sections
          ...sportItems.entries.map((sportEntry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${sportEntry.key}:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              ...sportEntry.value.entries.map((itemEntry) => Padding(
                padding: EdgeInsets.only(bottom: 4, left: 8),
                child: Row(
                  children: [
                    Text('□ ', style: TextStyle(color: Colors.black, fontSize: 12)),
                    Text('${itemEntry.value}x ', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        itemEntry.key,
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
              SizedBox(height: spacingS),
            ],
          )),
        ],
      ),
    );
  }


  Widget _buildSwimmingNote() {
    return Container(
      margin: EdgeInsets.only(bottom: spacingL),
      child: Text(
        'Nutrition during swimming not possible',
        style: TextStyle(
          color: blackyellowTheme.colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showSipVolumeInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'How to Measure Sip Volume',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To measure your average sip volume:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacingS),
            Text(
              '1. Take a water bottle and measure its weight on a scale when full',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '2. Take an average sip from the bottle (drink normally)',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '3. Measure the bottle weight again',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '4. Calculate the difference (1g = 1ml)',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '5. Repeat this process 3-5 times and enter the average here',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingM),
            Container(
              padding: EdgeInsets.all(spacingS),
              decoration: BoxDecoration(
                color: blackyellowTheme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tip: Most people take sips between 15-30ml. A typical average is around 22ml.',
                style: TextStyle(
                  color: blackyellowTheme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it!',
              style: TextStyle(
                color: blackyellowTheme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSweatRateInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Understanding Sweat Rate',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sweat rate determines how much sodium you lose per hour:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacingS),
            Text(
              '• Low (500mg/h): Light sweater, cooler conditions',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '• Medium (750mg/h): Average sweater, moderate conditions',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '• High (1000mg/h): Heavy sweater, hot/humid conditions',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingM),
            Container(
              padding: EdgeInsets.all(spacingS),
              decoration: BoxDecoration(
                color: blackyellowTheme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Factors: Temperature, humidity, fitness level, genetics, and acclimatization affect your sweat rate.',
                style: TextStyle(
                  color: blackyellowTheme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it!',
              style: TextStyle(
                color: blackyellowTheme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFluidRateInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Understanding Fluid Rate',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fluid rate determines how much liquid you need per hour:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacingS),
            Text(
              '• Low (500ml/h): Cooler conditions, shorter distances',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '• Medium (750ml/h): Moderate conditions, average needs',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '• High (1000ml/h): Hot conditions, high sweat rate',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: spacingM),
            Container(
              padding: EdgeInsets.all(spacingS),
              decoration: BoxDecoration(
                color: blackyellowTheme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Important: Don\'t exceed 1000ml/h to avoid stomach issues. Start drinking early in the race.',
                style: TextStyle(
                  color: blackyellowTheme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it!',
              style: TextStyle(
                color: blackyellowTheme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Container(
      margin: EdgeInsets.only(top: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: blackyellowTheme.colorScheme.secondary,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      
          SizedBox(height: spacingXS),
          Text(
            '• 300-700mg sodium per hour depending on sweat rate and conditions. Higher intake for hot weather and heavy sweaters.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),

          SizedBox(height: spacingXS),
          Text(
            '• 500-1000ml per hour depending on sweat rate, weather conditions, and exercise intensity. Start drinking early and maintain regular intake.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: spacingXS),
          Text(
            '• Maximum carbohydrate to fluid ratio 1:2 (Example: 250g carbs to 500ml water)',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: spacingXS),
          Text('• Use a mixer to blend maltodextrin and fructose', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text('• Add lemon juice for flavor', style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: spacingXS),
          Text('• 1g salt = 390mg sodium', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _NutritionDialog extends StatefulWidget {
  final NutritionType type;
  final Function(NutritionItem) onAdd;

  const _NutritionDialog({
    required this.type,
    required this.onAdd,
  });

  @override
  State<_NutritionDialog> createState() => _NutritionDialogState();
}

class _NutritionDialogState extends State<_NutritionDialog> {
  static const double spacingS = 12.0;

  ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: blackyellowTheme.colorScheme.primary,
    foregroundColor: Colors.black,
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
  );

  GelCarbs selectedGelCarbs = GelCarbs.g30;
  BarCarbs selectedBarCarbs = BarCarbs.g25;
  final TextEditingController volumeController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController sodiumController = TextEditingController();
  final TextEditingController caffeineController = TextEditingController();

  @override
  void dispose() {
    volumeController.dispose();
    carbsController.dispose();
    sodiumController.dispose();
    caffeineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: blackyellowTheme.colorScheme.secondary,
      title: Text(
        'Add ${widget.type.toString().split('.').last[0].toUpperCase()}${widget.type.toString().split('.').last.substring(1)}',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.type == NutritionType.gel || widget.type == NutritionType.caffeineGel) ...[
              Text('Carbohydrate content:', style: TextStyle(color: Colors.white)),
              DropdownButton<GelCarbs>(
                value: selectedGelCarbs,
                dropdownColor: blackyellowTheme.colorScheme.secondary,
                style: TextStyle(color: Colors.white),
                items: GelCarbs.values.map((carbs) {
                  String displayText;
                  final value = carbs.toString().split('.').last.substring(1); // Remove 'g' prefix
                  displayText = '${value}g';
                  return DropdownMenuItem(
                    value: carbs,
                    child: Text(displayText),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedGelCarbs = value;
                    });
                  }
                },
              ),
              if (widget.type == NutritionType.caffeineGel) ...[
                SizedBox(height: spacingS),
                TextFormField(
                  controller: caffeineController,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Caffeine (mg)',
                    labelStyle: TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ] else if (widget.type == NutritionType.bar) ...[
              Text('Carbohydrate content:', style: TextStyle(color: Colors.white)),
              DropdownButton<BarCarbs>(
                value: selectedBarCarbs,
                dropdownColor: blackyellowTheme.colorScheme.secondary,
                style: TextStyle(color: Colors.white),
                items: BarCarbs.values.map((carbs) {
                  final value = carbs.toString().split('.').last.substring(1); // Remove 'g' prefix
                  return DropdownMenuItem(
                    value: carbs,
                    child: Text('${value}g'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedBarCarbs = value;
                    });
                  }
                },
              ),
            ] else if (widget.type == NutritionType.bottle) ...[
              TextFormField(
                controller: volumeController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Volume (ml)',
                  labelStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: carbsController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Carbohydrates (g)',
                  labelStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: sodiumController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Sodium (mg)',
                  labelStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            final item = NutritionItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: widget.type,
              gelCarbs: (widget.type == NutritionType.gel || widget.type == NutritionType.caffeineGel) ? selectedGelCarbs : null,
              barCarbs: widget.type == NutritionType.bar ? selectedBarCarbs : null,
              bottleVolume: widget.type == NutritionType.bottle
                  ? double.tryParse(volumeController.text) : null,
              bottleCarbs: widget.type == NutritionType.bottle
                  ? double.tryParse(carbsController.text) : null,
              bottleSodium: widget.type == NutritionType.bottle
                  ? double.tryParse(sodiumController.text) : null,
              caffeine: widget.type == NutritionType.caffeineGel
                  ? double.tryParse(caffeineController.text) : null,
            );
            
            widget.onAdd(item);
            Navigator.of(context).pop();
          },
          style: primaryButtonStyle,
          child: Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}