import 'package:flutter/material.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';

enum NutritionType { gel, caffeineGel, bar, bottle }
enum GelCarbs { g30, g40, g45 }
enum BarCarbs { g20, g25, g30 }

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

  @override
  void initState() {
    super.initState();
    sports = [
      SportNutrition(
        sportName: 'Swimming',
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
        Text(
          'Triathlon Nutrition Calculator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 15),
        // Drinking Settings Input
        Container(
          padding: EdgeInsets.all(15),
          margin: EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: blackyellowTheme.colorScheme.secondary,
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Drinking interval:',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: drinkingIntervalController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        suffixText: 'min',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Default sip volume:',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: sipVolumeController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        suffixText: 'ml/sip',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ...sports.map((sport) => _buildSportSection(sport)),
        _buildTotalSection(),
        _buildRecommendationsSection(),
      ],
    );
  }

  Widget _buildSportSection(SportNutrition sport) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
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
              SizedBox(width: 10),
              Text(
                sport.sportName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),

          // Duration Input
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
          SizedBox(height: 10),

          // Target Values
          Column(
            children: [
              TextFormField(
                controller: sport.carbTargetController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.local_fire_department, color: Colors.black),
                  suffixText: 'g/h',
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
              SizedBox(height: 10),
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
              SizedBox(height: 10),
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
          SizedBox(height: 15),

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
                        label: Text('Gel', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blackyellowTheme.colorScheme.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _addNutritionItem(sport, NutritionType.caffeineGel),
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Caffeine Gel', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blackyellowTheme.colorScheme.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _addNutritionItem(sport, NutritionType.bar),
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Bar', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blackyellowTheme.colorScheme.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _addNutritionItem(sport, NutritionType.bottle),
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Bottle', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blackyellowTheme.colorScheme.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 15),

          // Nutrition Items List
          if (sport.nutritionItems.isNotEmpty)
            ...sport.nutritionItems.map((item) => _buildNutritionItem(sport, item)),

          SizedBox(height: 15),

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
                          final actualCarbsPerInterval = requiredSipsPerInterval * carbsPerSip; // actual carbs delivered per interval
                          sipInfo = ', ${requiredSipsPerInterval.toInt()} sips every ${drinkingInterval.toInt()}min (${actualCarbsPerInterval.toInt()}g carbs)';
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Table(
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
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Table(
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
      
          SizedBox(height: 5),
          Text(
            '300-700mg sodium per hour depending on sweat rate and conditions. Higher intake for hot weather and heavy sweaters.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 10),
          Text(
            'Fluid intake recommendations:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '500-1000ml per hour depending on sweat rate, weather conditions, and exercise intensity. Start drinking early and maintain regular intake.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            'Maximum carbohydrate to fluid ratio 1:2 (Example: 250g carbs to 500ml water)',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text('• Use a mixer to blend maltodextrin and fructose', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text('• Add lemon juice for flavor', style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 5),
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
                  final value = carbs.toString().split('.').last.substring(1); // Remove 'g' prefix
                  return DropdownMenuItem(
                    value: carbs,
                    child: Text('${value}g'),
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
                SizedBox(height: 10),
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
              SizedBox(height: 10),
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
              SizedBox(height: 10),
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
          child: Text('Cancel', style: TextStyle(color: Colors.white70)),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: blackyellowTheme.colorScheme.primary,
          ),
          child: Text('Add', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}