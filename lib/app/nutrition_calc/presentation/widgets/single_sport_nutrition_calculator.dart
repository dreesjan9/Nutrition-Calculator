import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nutrition_calculator_app/core/enums.dart';
import 'package:nutrition_calculator_app/core/models.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';
import 'package:nutrition_calculator_app/core/utils.dart';
import 'package:nutrition_calculator_app/app/nutrition_calc/presentation/widgets/sweat_rate_calculator_dialog.dart';

GelCarbs? _singleSportGelCarbsFromStorage(String? value) {
  for (final item in GelCarbs.values) {
    if (item.name == value) {
      return item;
    }
  }
  return null;
}

BarCarbs? _singleSportBarCarbsFromStorage(String? value) {
  for (final item in BarCarbs.values) {
    if (item.name == value) {
      return item;
    }
  }
  return null;
}

class SingleSportNutritionCalculator extends StatefulWidget {
  const SingleSportNutritionCalculator({
    super.key,
    required this.isGerman,
    required this.sportName,
    required this.sportIcon,
    required this.defaultCarbsPerHour,
    required this.defaultSodiumPerHour,
    required this.defaultFluidPerHour,
    this.onConfigurationChanged,
  });

  final bool isGerman;
  final String sportName;
  final IconData sportIcon;
  final String defaultCarbsPerHour;
  final String defaultSodiumPerHour;
  final String defaultFluidPerHour;
  final ValueChanged<Map<String, dynamic>>? onConfigurationChanged;

  @override
  State<SingleSportNutritionCalculator> createState() =>
      SingleSportNutritionCalculatorState();
}

class SingleSportNutritionCalculatorState
    extends State<SingleSportNutritionCalculator> {
  final TextEditingController configurationNameController =
      TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController distanceController = TextEditingController();
  final TextEditingController drinkingIntervalController =
      TextEditingController(text: '15');
  final TextEditingController carbTargetController = TextEditingController();
  final TextEditingController sodiumTargetController = TextEditingController();
  final TextEditingController fluidTargetController = TextEditingController();
  
  final List<NutritionItem> preRaceNutritionItems = [];
  final List<NutritionItem> nutritionItems = [];
  
  SweatRate defaultSweatRate = SweatRate.medium;
  FluidRate defaultFluidRate = FluidRate.medium;

  final TextEditingController preRaceCarbTargetController =
      TextEditingController(text: '0');
  final TextEditingController preRaceSodiumTargetController =
      TextEditingController(text: '0');
  final TextEditingController preRaceFluidTargetController =
      TextEditingController(text: '0');

  late String _configurationId;
  Timer? _autoSaveTimer;
  bool _isApplyingConfiguration = false;
  CalculatorView currentView = CalculatorView.input;

  TextStyle _pageHeadingStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineMedium!
      .copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800);

  TextStyle _sectionHeadingStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .titleLarge!
      .copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold);

  TextStyle _cardHeadingStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .titleMedium!
      .copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    _configurationId = DateTime.now().microsecondsSinceEpoch.toString();
    configurationNameController.text = _defaultConfigurationName(
      DateTime.now(),
    );
    carbTargetController.text = widget.defaultCarbsPerHour;
    sodiumTargetController.text = widget.defaultSodiumPerHour;
    fluidTargetController.text = widget.defaultFluidPerHour;

    for (final controller in [
      configurationNameController,
      durationController,
      distanceController,
      drinkingIntervalController,
      carbTargetController,
      sodiumTargetController,
      fluidTargetController,
      preRaceCarbTargetController,
      preRaceSodiumTargetController,
      preRaceFluidTargetController,
    ]) {
      controller.addListener(_scheduleAutoSave);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    configurationNameController.dispose();
    durationController.dispose();
    distanceController.dispose();
    drinkingIntervalController.dispose();
    carbTargetController.dispose();
    sodiumTargetController.dispose();
    fluidTargetController.dispose();
    preRaceCarbTargetController.dispose();
    preRaceSodiumTargetController.dispose();
    preRaceFluidTargetController.dispose();
    super.dispose();
  }

  void applyDefaultRates() {
    double defaultSodiumTarget = 0.0;
    double defaultFluidTarget = 0.0;

    switch (defaultSweatRate) {
      case SweatRate.low:
        defaultSodiumTarget = 500.0;
        break;
      case SweatRate.medium:
        defaultSodiumTarget = 750.0;
        break;
      case SweatRate.high:
        defaultSodiumTarget = 1000.0;
        break;
    }

    switch (defaultFluidRate) {
      case FluidRate.low:
        defaultFluidTarget = 500.0;
        break;
      case FluidRate.medium:
        defaultFluidTarget = 700.0;
        break;
      case FluidRate.high:
        defaultFluidTarget = 900.0;
        break;
    }

    sodiumTargetController.text = defaultSodiumTarget.toStringAsFixed(0);
    fluidTargetController.text = defaultFluidTarget.toStringAsFixed(0);

    setState(() {});
    _scheduleAutoSave();
  }

  Future<void> _openSweatRateCalculator() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => SweatRateCalculatorDialog(isGerman: widget.isGerman),
    );

    if (result != null && mounted) {
      setState(() {
        fluidTargetController.text = result.toStringAsFixed(0);
      });
      _scheduleAutoSave();
    }
  }

  void _showSweatRateInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        title: Text(
          widget.isGerman ? 'Was ist die Schweißrate?' : 'What is Sweat Rate?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          widget.isGerman
              ? 'Die Schweißrate gibt an, wie viel Natrium du pro Stunde verlierst. Ein Standardwert ist 750mg/h. Wenn du weiße Salzränder auf der Kleidung hast, wähle "Hoch".'
              : 'Sweat rate indicates how much sodium you lose per hour. A standard value is 750mg/h. If you see white salt stains on your clothes, choose "High".',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              widget.isGerman ? 'Verstanden' : 'Got it',
              style: TextStyle(color: blackyellowTheme.colorScheme.primary),
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
        title: Text(
          widget.isGerman
              ? 'Was ist die Flüssigkeitsrate?'
              : 'What is Fluid Rate?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          widget.isGerman
              ? 'Die Flüssigkeitsrate gibt an, wie viel Flüssigkeit du pro Stunde trinken möchtest. 700ml/h ist ein guter Durchschnittswert für die meisten Athleten.'
              : 'Fluid rate indicates how much fluid you want to drink per hour. 700ml/h is a good average for most athletes.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              widget.isGerman ? 'Verstanden' : 'Got it',
              style: TextStyle(color: blackyellowTheme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _defaultConfigurationName(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '${widget.sportName} $day.$month';
  }

  double get durationInMinutes {
    final text = durationController.text.trim();
    if (text.isEmpty) {
      return 0.0;
    }
    if (text.contains(':')) {
      final parts = text.split(':');
      if (parts.length == 2) {
        final hours = double.tryParse(parts[0]) ?? 0.0;
        final minutes = double.tryParse(parts[1]) ?? 0.0;
        return (hours * 60) + minutes;
      }
    }
    return double.tryParse(text) ?? 0.0;
  }

  double get carbsTargetTotal =>
      (double.tryParse(carbTargetController.text.replaceAll(',', '.')) ?? 0.0) *
      (durationInMinutes / 60);
  double get sodiumTargetTotal =>
      (double.tryParse(sodiumTargetController.text.replaceAll(',', '.')) ?? 0.0) *
      (durationInMinutes / 60);
  double get fluidTargetTotal =>
      (double.tryParse(fluidTargetController.text.replaceAll(',', '.')) ?? 0.0) *
      (durationInMinutes / 60);

  double get preRaceTotalCarbs =>
      preRaceNutritionItems.fold(0.0, (sum, item) => sum + item.carbsAmount);
  double get preRaceTotalSodium =>
      preRaceNutritionItems.fold(0.0, (sum, item) => sum + item.sodiumAmount);
  double get preRaceTotalFluid =>
      preRaceNutritionItems.fold(0.0, (sum, item) => sum + item.fluidAmount);
  double get preRaceTotalCaffeine =>
      preRaceNutritionItems.fold(0.0, (sum, item) => sum + item.caffeineAmount);

  double get totalCarbs =>
      nutritionItems.fold(0.0, (sum, item) => sum + item.carbsAmount);
  double get totalSodium =>
      nutritionItems.fold(0.0, (sum, item) => sum + item.sodiumAmount);
  double get totalFluid =>
      nutritionItems.fold(0.0, (sum, item) => sum + item.fluidAmount);
  double get totalCaffeine =>
      nutritionItems.fold(0.0, (sum, item) => sum + item.caffeineAmount);

  double get drinkingIntervalMinutes =>
      double.tryParse(drinkingIntervalController.text.replaceAll(',', '.')) ??
      15.0;

  Map<String, dynamic> exportConfiguration() {
    return {
      'id': _configurationId,
      'name': configurationNameController.text.trim().isEmpty
          ? _defaultConfigurationName(DateTime.now())
          : configurationNameController.text.trim(),
      'savedAt': DateTime.now().toIso8601String(),
      'sportName': widget.sportName,
      'currentView': currentView.name,
      'duration': durationController.text,
      'distance': distanceController.text,
      'drinkingInterval': drinkingIntervalController.text,
      'carbTarget': carbTargetController.text,
      'sodiumTarget': sodiumTargetController.text,
      'fluidTarget': fluidTargetController.text,
      'defaultSweatRate': defaultSweatRate.name,
      'defaultFluidRate': defaultFluidRate.name,
      'preRaceCarbTarget': preRaceCarbTargetController.text,
      'preRaceSodiumTarget': preRaceSodiumTargetController.text,
      'preRaceFluidTarget': preRaceFluidTargetController.text,
      'preRaceNutritionItems': preRaceNutritionItems
          .map(
            (item) => {
              'id': item.id,
              'type': item.type.name,
              'gelCarbs': item.gelCarbs?.name,
              'barCarbs': item.barCarbs?.name,
              'bottleVolume': item.bottleVolume,
              'bottleCarbs': item.bottleCarbs,
              'bottleSodium': item.bottleSodium,
              'customSodium': item.customSodium,
              'caffeine': item.caffeine,
              'customName': item.customName,
              'customCarbs': item.customCarbs,
              'customFluid': item.customFluid,
            },
          )
          .toList(),
      'nutritionItems': nutritionItems
          .map(
            (item) => {
              'id': item.id,
              'type': item.type.name,
              'gelCarbs': item.gelCarbs?.name,
              'barCarbs': item.barCarbs?.name,
              'bottleVolume': item.bottleVolume,
              'bottleCarbs': item.bottleCarbs,
              'bottleSodium': item.bottleSodium,
              'customSodium': item.customSodium,
              'caffeine': item.caffeine,
              'customName': item.customName,
              'customCarbs': item.customCarbs,
              'customFluid': item.customFluid,
            },
          )
          .toList(),
    };
  }

  void importConfiguration(Map<String, dynamic> configuration) {
    _isApplyingConfiguration = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _configurationId =
            configuration['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString();
        configurationNameController.text =
            configuration['name']?.toString() ??
            _defaultConfigurationName(DateTime.now());
        currentView = CalculatorView.values.firstWhere(
          (view) => view.name == configuration['currentView'],
          orElse: () => CalculatorView.input,
        );
        durationController.text = configuration['duration']?.toString() ?? '';
        distanceController.text = configuration['distance']?.toString() ?? '';
        drinkingIntervalController.text =
            configuration['drinkingInterval']?.toString() ?? '15';
        carbTargetController.text =
            configuration['carbTarget']?.toString() ?? widget.defaultCarbsPerHour;
        sodiumTargetController.text =
            configuration['sodiumTarget']?.toString() ??
            widget.defaultSodiumPerHour;
        fluidTargetController.text =
            configuration['fluidTarget']?.toString() ??
            widget.defaultFluidPerHour;

        defaultSweatRate = SweatRate.values.firstWhere(
          (e) => e.name == configuration['defaultSweatRate'],
          orElse: () => SweatRate.medium,
        );
        defaultFluidRate = FluidRate.values.firstWhere(
          (e) => e.name == configuration['defaultFluidRate'],
          orElse: () => FluidRate.medium,
        );

        preRaceCarbTargetController.text =
            configuration['preRaceCarbTarget']?.toString() ?? '0';
        preRaceSodiumTargetController.text =
            configuration['preRaceSodiumTarget']?.toString() ?? '0';
        preRaceFluidTargetController.text =
            configuration['preRaceFluidTarget']?.toString() ?? '0';

        preRaceNutritionItems.clear();
        final preRaceItems = configuration['preRaceNutritionItems'];
        if (preRaceItems is List) {
          for (final item in preRaceItems) {
            if (item is! Map) {
              continue;
            }
            preRaceNutritionItems.add(
              NutritionItem(
                id:
                    item['id']?.toString() ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                type: NutritionType.values.firstWhere(
                  (type) => type.name == item['type'],
                  orElse: () => NutritionType.gel,
                ),
                gelCarbs: _singleSportGelCarbsFromStorage(
                  item['gelCarbs']?.toString(),
                ),
                barCarbs: _singleSportBarCarbsFromStorage(
                  item['barCarbs']?.toString(),
                ),
                bottleVolume: (item['bottleVolume'] as num?)?.toDouble(),
                bottleCarbs: (item['bottleCarbs'] as num?)?.toDouble(),
                bottleSodium: (item['bottleSodium'] as num?)?.toDouble(),
                customSodium: (item['customSodium'] as num?)?.toDouble(),
                caffeine: (item['caffeine'] as num?)?.toDouble(),
                customName: item['customName']?.toString(),
                customCarbs: (item['customCarbs'] as num?)?.toDouble(),
                customFluid: (item['customFluid'] as num?)?.toDouble(),
              ),
            );
          }
        }

        nutritionItems.clear();
        final items = configuration['nutritionItems'];
        if (items is List) {
          for (final item in items) {
            if (item is! Map) {
              continue;
            }
            nutritionItems.add(
              NutritionItem(
                id:
                    item['id']?.toString() ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                type: NutritionType.values.firstWhere(
                  (type) => type.name == item['type'],
                  orElse: () => NutritionType.gel,
                ),
                gelCarbs: _singleSportGelCarbsFromStorage(
                  item['gelCarbs']?.toString(),
                ),
                barCarbs: _singleSportBarCarbsFromStorage(
                  item['barCarbs']?.toString(),
                ),
                bottleVolume: (item['bottleVolume'] as num?)?.toDouble(),
                bottleCarbs: (item['bottleCarbs'] as num?)?.toDouble(),
                bottleSodium: (item['bottleSodium'] as num?)?.toDouble(),
                customSodium: (item['customSodium'] as num?)?.toDouble(),
                caffeine: (item['caffeine'] as num?)?.toDouble(),
                customName: item['customName']?.toString(),
                customCarbs: (item['customCarbs'] as num?)?.toDouble(),
                customFluid: (item['customFluid'] as num?)?.toDouble(),
              ),
            );
          }
        }
      });
      _isApplyingConfiguration = false;
    });
  }

  void _scheduleAutoSave() {
    if (_isApplyingConfiguration || widget.onConfigurationChanged == null) {
      return;
    }
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 450), () {
      widget.onConfigurationChanged?.call(exportConfiguration());
    });
  }

  void _addNutritionItem(NutritionType type, {bool isPreRace = false}) {
    showDialog(
      context: context,
      builder: (context) => _SingleSportNutritionDialog(
        type: type,
        isGerman: widget.isGerman,
        onAdd: (item) {
          setState(() {
            if (isPreRace) {
              preRaceNutritionItems.add(item);
            } else {
              nutritionItems.add(item);
            }
          });
          _scheduleAutoSave();
        },
      ),
    );
  }

  void _editNutritionItem(NutritionItem item, {bool isPreRace = false}) {
    showDialog(
      context: context,
      builder: (context) => _SingleSportNutritionDialog(
        type: item.type,
        isGerman: widget.isGerman,
        existingItem: item,
        onAdd: (editedItem) {
          setState(() {
            if (isPreRace) {
              final index = preRaceNutritionItems.indexOf(item);
              if (index != -1) {
                preRaceNutritionItems[index] = editedItem;
              }
            } else {
              final index = nutritionItems.indexOf(item);
              if (index != -1) {
                nutritionItems[index] = editedItem;
              }
            }
          });
          _scheduleAutoSave();
        },
      ),
    );
  }

  void _removeNutritionItem(NutritionItem item, {bool isPreRace = false}) {
    setState(() {
      if (isPreRace) {
        preRaceNutritionItems.remove(item);
      } else {
        nutritionItems.remove(item);
      }
    });
    _scheduleAutoSave();
  }

  BoxDecoration _panelDecoration({bool highlighted = false}) {
    return appPanelDecoration(highlighted: highlighted);
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    String? suffixText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF242424),
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: Colors.white.withOpacity(0.72),
        fontSize: 12,
      ),
      prefixIcon: prefixIcon,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: blackyellowTheme.colorScheme.primary.withOpacity(0.9),
          width: 1.4,
        ),
      ),
    );
  }

  List<TimelineEvent> _generateTimelineEvents() {
    final events = <TimelineEvent>[];

    // Pre-Race Events
    if (preRaceNutritionItems.isNotEmpty) {
      const step = 20; // 20 mins intervals for Pre-Race
      for (int i = 0; i < preRaceNutritionItems.length; i++) {
        final minute = -(preRaceNutritionItems.length - i) * step;
        final item = preRaceNutritionItems[i];
        events.add(
          TimelineEvent(
            sportName: 'Pre-Race',
            type: _timelineEventTypeForNutrition(item.type),
            offsetMinutes: minute,
            title: _timelineTitleForItem(item),
            detail: _timelineDetailForItem(item),
          ),
        );
      }
    }

    final totalMinutes = durationInMinutes.round();
    if (totalMinutes > 0) {
      events.addAll(_generateNutritionTimelineEvents(totalMinutes));
      events.addAll(_generateDrinkTimelineEvents(totalMinutes));
    }

    events.sort((a, b) => a.offsetMinutes.compareTo(b.offsetMinutes));
    return events;
  }

  List<TimelineEvent> _generateNutritionTimelineEvents(int totalMinutes) {
    if (nutritionItems.isEmpty) {
      return const [];
    }

    final events = <TimelineEvent>[];
    final distanceValue =
        double.tryParse(distanceController.text.replaceAll(',', '.')) ?? 0.0;
    
    // We start nutrition at 12% and end at 88% of duration to avoid start/end overlap
    final windowStart = (totalMinutes * 0.12).round();
    final windowEnd = (totalMinutes * 0.88).round();
    final span = windowEnd - windowStart;
    final step = span / (nutritionItems.length + 1);

    for (var i = 0; i < nutritionItems.length; i++) {
      final minute = (windowStart + step * (i + 1)).round();
      final distanceKm = distanceValue > 0
          ? (distanceValue * minute / totalMinutes)
          : null;
      final item = nutritionItems[i];
      events.add(
        TimelineEvent(
          sportName: widget.sportName,
          type: _timelineEventTypeForNutrition(item.type),
          offsetMinutes: minute,
          distanceKm: distanceKm,
          title: _timelineTitleForItem(item),
          detail: _timelineDetailForItem(item),
        ),
      );
    }
    return events;
  }

  List<TimelineEvent> _generateDrinkTimelineEvents(int totalMinutes) {
    final interval = drinkingIntervalMinutes.round();
    if (interval <= 0) {
      return const [];
    }

    final fluidPerInterval =
        (double.tryParse(fluidTargetController.text.replaceAll(',', '.')) ??
            0.0) *
        (interval / 60);
    final distanceValue =
        double.tryParse(distanceController.text.replaceAll(',', '.')) ?? 0.0;
    final events = <TimelineEvent>[];
    for (var minute = interval; minute < totalMinutes; minute += interval) {
      events.add(
        TimelineEvent(
          sportName: widget.sportName,
          type: TimelineEventType.drink,
          offsetMinutes: minute,
          distanceKm: distanceValue > 0
              ? (distanceValue * minute / totalMinutes)
              : null,
          title: widget.isGerman ? 'Trinken' : 'Drink',
          detail: widget.isGerman
              ? '${fluidPerInterval.toStringAsFixed(0)} ml gemäß Intervall'
              : '${fluidPerInterval.toStringAsFixed(0)} ml based on interval',
        ),
      );
    }
    return events;
  }

  TimelineEventType _timelineEventTypeForNutrition(NutritionType type) {
    switch (type) {
      case NutritionType.gel:
        return TimelineEventType.gel;
      case NutritionType.caffeineGel:
        return TimelineEventType.caffeineGel;
      case NutritionType.bar:
        return TimelineEventType.bar;
      case NutritionType.bottle:
        return TimelineEventType.bottle;
      case NutritionType.chews:
        return TimelineEventType.chews;
      case NutritionType.custom:
        return TimelineEventType.custom;
    }
  }

  String _timelineTitleForItem(NutritionItem item) {
    switch (item.type) {
      case NutritionType.gel:
        return widget.isGerman
            ? 'Gel ${item.carbsAmount.toInt()}g'
            : 'Gel ${item.carbsAmount.toInt()}g';
      case NutritionType.caffeineGel:
        return widget.isGerman
            ? 'Koffein Gel ${item.carbsAmount.toInt()}g'
            : 'Caffeine Gel ${item.carbsAmount.toInt()}g';
      case NutritionType.bar:
        return widget.isGerman
            ? 'Riegel ${item.carbsAmount.toInt()}g'
            : 'Bar ${item.carbsAmount.toInt()}g';
      case NutritionType.bottle:
        return widget.isGerman
            ? 'Flasche ${item.fluidAmount.toInt()}ml'
            : 'Bottle ${item.fluidAmount.toInt()}ml';
      case NutritionType.chews:
        return 'Chews';
      case NutritionType.custom:
        return item.customName?.trim().isNotEmpty == true
            ? item.customName!.trim()
            : (widget.isGerman ? 'Eigenes Item' : 'Custom item');
    }
  }

  String _timelineDetailForItem(NutritionItem item) {
    final parts = <String>[
      '${item.carbsAmount.toStringAsFixed(0)}g carbs',
      '${item.sodiumAmount.toStringAsFixed(0)}mg sodium',
    ];
    if (item.fluidAmount > 0) {
      parts.add('${item.fluidAmount.toStringAsFixed(0)}ml fluid');
    }
    if (item.caffeineAmount > 0) {
      parts.add('${item.caffeineAmount.toStringAsFixed(0)}mg caffeine');
    }
    if (parts.isEmpty) {
      return widget.isGerman ? 'Benutzerdefiniertes Item' : 'Custom item';
    }
    return parts.join(' • ');
  }

  Color _timelineEventColor(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.drink:
        return Colors.lightBlueAccent;
      case TimelineEventType.gel:
        return blackyellowTheme.colorScheme.primary;
      case TimelineEventType.caffeineGel:
        return Colors.orangeAccent;
      case TimelineEventType.bar:
        return const Color(0xFFC6922A);
      case TimelineEventType.bottle:
        return Colors.cyanAccent;
      case TimelineEventType.chews:
        return Colors.redAccent;
      case TimelineEventType.custom:
        return Colors.tealAccent;
      case TimelineEventType.note:
        return Colors.white70;
    }
  }

  IconData _timelineEventIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.drink:
        return Icons.local_drink;
      case TimelineEventType.gel:
        return Icons.bolt;
      case TimelineEventType.caffeineGel:
        return Icons.coffee;
      case TimelineEventType.bar:
        return Icons.lunch_dining;
      case TimelineEventType.bottle:
        return Icons.sports_bar;
      case TimelineEventType.chews:
        return Icons.grain;
      case TimelineEventType.custom:
        return Icons.edit_note;
      case TimelineEventType.note:
        return Icons.info_outline;
    }
  }

  String _formatTimelineOffset(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (minutes < 0) {
        final absMins = minutes.abs();
        final h = absMins ~/ 60;
        final m = absMins % 60;
        return '-${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}';
  }

  Widget _buildTimelineToggle() {
    final tabs = [
      (CalculatorView.input, widget.isGerman ? 'Eingabe' : 'Input'),
      (CalculatorView.timeline, 'Timeline'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: tabs.map((tab) {
          final isActive = currentView == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  currentView = tab.$1;
                });
                _scheduleAutoSave();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? blackyellowTheme.colorScheme.primary
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSweatRateDropdown() {
    return DropdownButtonFormField<SweatRate>(
      initialValue: defaultSweatRate,
      isExpanded: true,
      selectedItemBuilder: (context) {
        return SweatRate.values.map((rate) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              getSweatRateCompactLabel(rate, widget.isGerman),
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList();
      },
      dropdownColor: const Color(0xFF1C1C1C),
      iconEnabledColor: blackyellowTheme.colorScheme.primary,
      decoration: _inputDecoration(
        labelText: widget.isGerman ? 'Schweißrate' : 'Sweat rate',
        prefixIcon: Icon(Icons.water_drop, color: blackyellowTheme.colorScheme.primary),
      ),
      items: SweatRate.values.map((rate) {
        return DropdownMenuItem(
          value: rate,
          child: Text(
            getSweatRateLabel(rate, widget.isGerman),
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            defaultSweatRate = value;
          });
          applyDefaultRates();
        }
      },
    );
  }

  Widget _buildFluidRateDropdown() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<FluidRate>(
            initialValue: defaultFluidRate,
            isExpanded: true,
            selectedItemBuilder: (context) {
              return FluidRate.values.map((rate) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    getFluidRateCompactLabel(rate, widget.isGerman),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList();
            },
            dropdownColor: const Color(0xFF1C1C1C),
            iconEnabledColor: blackyellowTheme.colorScheme.primary,
            decoration: _inputDecoration(
              labelText: widget.isGerman ? 'Flüssigkeitsrate' : 'Fluid rate',
              prefixIcon: Icon(Icons.opacity, color: blackyellowTheme.colorScheme.primary),
            ),
            items: FluidRate.values.map((rate) {
              return DropdownMenuItem(
                value: rate,
                child: Text(
                  getFluidRateLabel(rate, widget.isGerman),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  defaultFluidRate = value;
                });
                applyDefaultRates();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF242424),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: IconButton(
            onPressed: _openSweatRateCalculator,
            icon: Icon(Icons.calculate_outlined, color: blackyellowTheme.colorScheme.primary),
            tooltip: widget.isGerman ? 'Schweißrate berechnen' : 'Calculate sweat rate',
          ),
        ),
      ],
    );
  }

  Widget _buildPreRaceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 10),
              Text(
                widget.isGerman ? 'Pre-Race Nutrition' : 'Pre-Race Nutrition',
                style: _sectionHeadingStyle(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: preRaceCarbTargetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    labelText: widget.isGerman ? 'Ziel Carbs (g)' : 'Target Carbs (g)',
                    prefixIcon: Icon(Icons.local_fire_department, color: Colors.orangeAccent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: preRaceSodiumTargetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    labelText: widget.isGerman ? 'Ziel Natrium (mg)' : 'Target Sodium (mg)',
                    prefixIcon: Icon(Icons.water_drop, color: Colors.orangeAccent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.isGerman ? 'Items für Pre-Race:' : 'Items for Pre-Race:',
            style: _cardHeadingStyle(context).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildAddButtons(isPreRace: true),
          if (preRaceNutritionItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...preRaceNutritionItems.map((item) => _buildNutritionItemRow(item, isPreRace: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildAddButtons({bool isPreRace = false}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAddButton(NutritionType.gel, 'Gel', isPreRace: isPreRace),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAddButton(
                NutritionType.caffeineGel,
                widget.isGerman ? 'Koffein Gel' : 'Caffeine Gel',
                isPreRace: isPreRace,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildAddButton(
                NutritionType.bar,
                widget.isGerman ? 'Riegel' : 'Bar',
                isPreRace: isPreRace,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAddButton(
                NutritionType.bottle,
                widget.isGerman ? 'Flasche' : 'Bottle',
                isPreRace: isPreRace,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildAddButton(NutritionType.chews, 'Chews', isPreRace: isPreRace),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAddButton(
                NutritionType.custom,
                widget.isGerman ? 'Eigenes' : 'Custom',
                isPreRace: isPreRace,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionItemRow(NutritionItem item, {bool isPreRace = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: () => _editNutritionItem(item, isPreRace: isPreRace),
        title: Text(
          _itemLabel(item),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [
            '${item.carbsAmount.toStringAsFixed(0)} g carbs',
            '${item.sodiumAmount.toStringAsFixed(0)} mg sodium',
            if (item.fluidAmount > 0) '${item.fluidAmount.toStringAsFixed(0)} ml fluid',
            if (item.caffeineAmount > 0) '${item.caffeineAmount.toStringAsFixed(0)} mg caffeine',
          ].join(' • '),
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        trailing: IconButton(
          onPressed: () => _removeNutritionItem(item, isPreRace: isPreRace),
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineViewContent() {
    final events = _generateTimelineEvents();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isGerman ? 'Race-Day Timeline' : 'Race-Day Timeline',
            style: _sectionHeadingStyle(context),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isGerman
                ? 'Deine geplanten Drinks und Nutrition-Items entlang der Session.'
                : 'Your planned drinks and nutrition items across the session.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _timelineSummaryChip(
                icon: widget.sportIcon,
                label: widget.sportName,
              ),
              _timelineSummaryChip(
                icon: Icons.timer,
                label: _formatTimelineOffset(durationInMinutes.round()),
              ),
              _timelineSummaryChip(
                icon: Icons.local_drink,
                label:
                    '${widget.isGerman ? 'Intervall' : 'Interval'}: ${drinkingIntervalMinutes.toInt()} min',
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                widget.isGerman
                    ? 'Trage Dauer, Trinkintervall und Nutrition-Items ein. Danach erscheint hier deine Timeline.'
                    : 'Add duration, drink interval and nutrition items. Your timeline will appear here afterwards.',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
            )
          else
            ...events.asMap().entries.map((entry) {
              final event = entry.value;
              final isLast = entry.key == events.length - 1;
              return _buildTimelineEventRow(event, isLast: isLast);
            }),
        ],
      ),
    );
  }

  Widget _timelineSummaryChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: blackyellowTheme.colorScheme.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEventRow(TimelineEvent event, {required bool isLast}) {
    final color = _timelineEventColor(event.type);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 82,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTimelineOffset(event.offsetMinutes),
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white12,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _timelineEventIcon(event.type),
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (event.distanceKm != null)
                    Text(
                      '${event.distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (event.distanceKm != null) const SizedBox(height: 4),
                  Text(
                    event.detail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required double actual,
    required double target,
    required String unit,
    required IconData icon,
  }) {
    final delta = actual - target;
    final isGood = delta >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: blackyellowTheme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${actual.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            delta == 0
                ? (widget.isGerman ? 'Genau im Ziel' : 'Exactly on target')
                : isGood
                ? (widget.isGerman
                      ? '+${delta.toStringAsFixed(0)} $unit über Ziel'
                      : '+${delta.toStringAsFixed(0)} $unit above target')
                : (widget.isGerman
                      ? '${delta.toStringAsFixed(0)} $unit unter Ziel'
                      : '${delta.toStringAsFixed(0)} $unit below target'),
            style: TextStyle(
              color: isGood ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: _panelDecoration().copyWith(
            gradient: LinearGradient(
              colors: [
                blackyellowTheme.colorScheme.secondary,
                const Color(0xFF222222),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        const SizedBox.shrink(),
        const SizedBox(height: 10),
        const SizedBox.shrink(),
              const SizedBox(height: 10),
              Text(
                widget.isGerman
                    ? 'Plane Ernährung, Hydration und Verpflegung für eine einzelne Session und wechsle danach direkt in die Timeline.'
                    : 'Plan fuel, hydration and nutrition for a single session, then switch straight into the timeline.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildTimelineToggle(),
        const SizedBox(height: 16),
        if (currentView == CalculatorView.input) ...[
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: configurationNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    labelText: widget.isGerman ? 'Bezeichnung' : 'Description',
                    prefixIcon: Icon(
                      Icons.edit_note,
                      color: blackyellowTheme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isGerman
                      ? 'Gib hier deine geplanten Eckdaten für diese Session ein:'
                      : 'Enter your planned data for this session:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth > 500
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: TextField(
                            controller: distanceController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              labelText: widget.isGerman
                                  ? 'Distanz (km)'
                                  : 'Distance (km)',
                              prefixIcon: Icon(
                                widget.sportIcon,
                                color: blackyellowTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: TextField(
                            controller: durationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              labelText: widget.isGerman
                                  ? 'Dauer (HH:MM)'
                                  : 'Duration (HH:MM)',
                              prefixIcon: Icon(
                                Icons.timer,
                                color: blackyellowTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: TextField(
                            controller: drinkingIntervalController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              labelText: widget.isGerman
                                  ? 'Trinkintervall (min)'
                                  : 'Drink interval (min)',
                              prefixIcon: Icon(
                                Icons.local_drink,
                                color: blackyellowTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: _panelDecoration(highlighted: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.isGerman ? 'Hydratations-Einstellungen' : 'Hydration Settings',
                      style: _cardHeadingStyle(context),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showSweatRateInfoDialog,
                      child: Icon(Icons.info_outline, color: blackyellowTheme.colorScheme.primary, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isGerman
                      ? 'Wähle deine erwartete Schweiß- und Trinkrate aus, um deine Standard-Hydratationsziele automatisch zu setzen.'
                      : 'Select your expected sweat and drinking rates to automatically set your default hydration targets.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSweatRateDropdown(),
                const SizedBox(height: 16),
                _buildFluidRateDropdown(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, color: Colors.orangeAccent, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      widget.isGerman ? 'Pre-Race Nutrition' : 'Pre-Race Nutrition',
                      style: _sectionHeadingStyle(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isGerman
                      ? 'Lege hier fest, wie viele Kohlenhydrate und Natrium du in der Zeit vor dem Start (Pre-Race) zu dir nehmen möchtest.'
                      : 'Define how many carbohydrates and how much sodium you want to consume in the time before the start (Pre-Race).',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: preRaceCarbTargetController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          labelText: widget.isGerman ? 'Kohlenhydrat-Ziel (g)' : 'Target Carbs (g)',
                          prefixIcon: Icon(Icons.local_fire_department, color: Colors.orangeAccent),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: preRaceSodiumTargetController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          labelText: widget.isGerman ? 'Natrium-Ziel (mg)' : 'Target Sodium (mg)',
                          prefixIcon: Icon(Icons.water_drop, color: Colors.orangeAccent),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isGerman ? 'Items für Pre-Race:' : 'Items for Pre-Race:',
                  style: _cardHeadingStyle(context).copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildAddButtons(isPreRace: true),
                if (preRaceNutritionItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...preRaceNutritionItems.map((item) => _buildNutritionItemRow(item, isPreRace: true)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.sportIcon, color: blackyellowTheme.colorScheme.primary, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      '${widget.sportName} Nutrition',
                      style: _sectionHeadingStyle(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isGerman
                      ? 'Lege hier deine Zielwerte pro Stunde fest. Diese dienen als Basis für deine Verpflegungsplanung.'
                      : 'Set your hourly target values here. These serve as the basis for your nutrition planning.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth > 500
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: TextField(
                            controller: carbTargetController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              labelText: widget.isGerman
                                  ? 'Kohlenhydrat-Ziel (g/h)'
                                  : 'Carbs Target (g/h)',
                              prefixIcon: Icon(
                                Icons.local_fire_department,
                                color: blackyellowTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: TextField(
                            controller: sodiumTargetController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              labelText: widget.isGerman
                                  ? 'Natrium-Ziel (mg/h)'
                                  : 'Sodium Target (mg/h)',
                              prefixIcon: Icon(
                                Icons.water_drop,
                                color: blackyellowTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: TextField(
                            controller: fluidTargetController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              labelText: widget.isGerman
                                  ? 'Flüssigkeitsziel (ml/h)'
                                  : 'Fluid Target (ml/h)',
                              prefixIcon: Icon(
                                Icons.opacity,
                                color: blackyellowTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isGerman ? 'Items während der Session:' : 'Items during session:',
                  style: _cardHeadingStyle(context).copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildAddButtons(isPreRace: false),
                if (nutritionItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...nutritionItems.map((item) => _buildNutritionItemRow(item, isPreRace: false)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isGerman ? 'Zusammenfassung (Total)' : 'Summary (Total)',
                  style: _cardHeadingStyle(context),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildMetric(
                            label: 'Carbs',
                            actual: preRaceTotalCarbs + totalCarbs,
                            target: (double.tryParse(preRaceCarbTargetController.text.replaceAll(',', '.')) ?? 0.0) + carbsTargetTotal,
                            unit: 'g',
                            icon: Icons.local_fire_department,
                          ),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildMetric(
                            label: 'Sodium',
                            actual: preRaceTotalSodium + totalSodium,
                            target: (double.tryParse(preRaceSodiumTargetController.text.replaceAll(',', '.')) ?? 0.0) + sodiumTargetTotal,
                            unit: 'mg',
                            icon: Icons.water_drop,
                          ),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildMetric(
                            label: 'Fluid',
                            actual: preRaceTotalFluid + totalFluid,
                            target: (double.tryParse(preRaceFluidTargetController.text.replaceAll(',', '.')) ?? 0.0) + fluidTargetTotal,
                            unit: 'ml',
                            icon: Icons.opacity,
                          ),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bolt,
                                      color: blackyellowTheme.colorScheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.isGerman ? 'Koffein' : 'Caffeine',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(preRaceTotalCaffeine + totalCaffeine).toStringAsFixed(0)} mg',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          _buildTimelineViewContent(),
        ],
      ],
    );
  }

  Widget _buildAddButton(NutritionType type, String label, {bool isPreRace = false}) {
    return ElevatedButton.icon(
      onPressed: () => _addNutritionItem(type, isPreRace: isPreRace),
      style: ElevatedButton.styleFrom(
        backgroundColor: blackyellowTheme.colorScheme.primary,
        foregroundColor: Colors.black,
      ),
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
    );
  }

  String _itemLabel(NutritionItem item) {
    switch (item.type) {
      case NutritionType.gel:
        return 'Gel ${item.carbsAmount.toStringAsFixed(0)}g';
      case NutritionType.caffeineGel:
        return 'Caffeine Gel ${item.carbsAmount.toStringAsFixed(0)}g';
      case NutritionType.bar:
        return 'Bar ${item.carbsAmount.toStringAsFixed(0)}g';
      case NutritionType.bottle:
        return 'Bottle ${item.fluidAmount.toStringAsFixed(0)}ml';
      case NutritionType.chews:
        return 'Chews';
      case NutritionType.custom:
        return item.customName?.trim().isNotEmpty == true
            ? item.customName!.trim()
            : (widget.isGerman ? 'Eigenes Item' : 'Custom item');
    }
  }
}

class _SingleSportNutritionDialog extends StatefulWidget {
  const _SingleSportNutritionDialog({
    required this.type,
    required this.isGerman,
    required this.onAdd,
    this.existingItem,
  });

  final NutritionType type;
  final bool isGerman;
  final ValueChanged<NutritionItem> onAdd;
  final NutritionItem? existingItem;

  @override
  State<_SingleSportNutritionDialog> createState() =>
      _SingleSportNutritionDialogState();
}

class _SingleSportNutritionDialogState
    extends State<_SingleSportNutritionDialog> {
  GelCarbs selectedGelCarbs = GelCarbs.g30;
  BarCarbs selectedBarCarbs = BarCarbs.g25;
  final TextEditingController volumeController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController sodiumController = TextEditingController();
  final TextEditingController caffeineController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item == null) {
      return;
    }
    selectedGelCarbs = item.gelCarbs ?? selectedGelCarbs;
    selectedBarCarbs = item.barCarbs ?? selectedBarCarbs;
    volumeController.text = item.bottleVolume?.toString() ?? '';
    carbsController.text =
        item.type == NutritionType.custom
            ? item.customCarbs?.toString() ?? ''
            : item.bottleCarbs?.toString() ?? '';
    sodiumController.text =
        item.customSodium?.toString() ?? item.bottleSodium?.toString() ?? '';
    caffeineController.text = item.caffeine?.toString() ?? '';
    nameController.text = item.customName ?? '';
    if (item.type == NutritionType.custom) {
      volumeController.text = item.customFluid?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    volumeController.dispose();
    carbsController.dispose();
    sodiumController.dispose();
    caffeineController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: blackyellowTheme.colorScheme.secondary,
      title: Text(
        widget.isGerman ? 'Verpflegungs-Item' : 'Nutrition item',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.type == NutritionType.gel ||
                widget.type == NutritionType.caffeineGel) ...[
              DropdownButton<GelCarbs>(
                value: selectedGelCarbs,
                dropdownColor: blackyellowTheme.colorScheme.secondary,
                style: const TextStyle(color: Colors.white),
                items: GelCarbs.values.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text('${item.name.substring(1)}g'),
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
              if (widget.type == NutritionType.caffeineGel)
                TextField(
                  controller: caffeineController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF242424),
                    labelText: widget.isGerman ? 'Koffein (mg)' : 'Caffeine (mg)',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: sodiumController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ] else if (widget.type == NutritionType.bar) ...[
              DropdownButton<BarCarbs>(
                value: selectedBarCarbs,
                dropdownColor: blackyellowTheme.colorScheme.secondary,
                style: const TextStyle(color: Colors.white),
                items: BarCarbs.values.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text('${item.name.substring(1)}g'),
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
              const SizedBox(height: 10),
              TextField(
                controller: sodiumController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ] else if (widget.type == NutritionType.bottle) ...[
              TextField(
                controller: volumeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Volumen (ml)' : 'Volume (ml)',
                  prefixIcon: Icon(
                    Icons.local_drink,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: carbsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Kohlenhydrate (g)' : 'Carbs (g)',
                  prefixIcon: Icon(
                    Icons.bolt,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sodiumController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ] else if (widget.type == NutritionType.chews) ...[
              TextField(
                controller: sodiumController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ] else if (widget.type == NutritionType.custom) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  widget.isGerman
                      ? 'Geben Sie eine Bezeichnung für den eigenen Eintrag ein:'
                      : 'Enter a label for the custom entry:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Bezeichnung' : 'Label',
                  prefixIcon: Icon(
                    Icons.label,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  hintText: widget.isGerman ? 'z. B. Banane' : 'e.g. Banana',
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: carbsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Kohlenhydrate (g)' : 'Carbs (g)',
                  prefixIcon: Icon(
                    Icons.bolt,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sodiumController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: volumeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Flüssigkeit (ml)' : 'Fluid (ml)',
                  prefixIcon: Icon(
                    Icons.local_drink,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: caffeineController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  labelText: widget.isGerman ? 'Koffein (mg)' : 'Caffeine (mg)',
                  prefixIcon: Icon(
                    Icons.coffee,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            widget.isGerman ? 'Abbrechen' : 'Cancel',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(
              NutritionItem(
                id:
                    widget.existingItem?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                type: widget.type,
                gelCarbs:
                    (widget.type == NutritionType.gel ||
                        widget.type == NutritionType.caffeineGel)
                    ? selectedGelCarbs
                    : null,
                barCarbs: widget.type == NutritionType.bar
                    ? selectedBarCarbs
                    : null,
                bottleVolume: widget.type == NutritionType.bottle
                    ? double.tryParse(volumeController.text)
                    : null,
                bottleCarbs: widget.type == NutritionType.bottle
                    ? double.tryParse(carbsController.text)
                    : null,
                bottleSodium: widget.type == NutritionType.bottle
                    ? double.tryParse(sodiumController.text)
                    : null,
                customSodium: widget.type == NutritionType.bottle
                    ? null
                    : double.tryParse(sodiumController.text),
                caffeine: (widget.type == NutritionType.caffeineGel ||
                        widget.type == NutritionType.custom)
                    ? double.tryParse(caffeineController.text)
                    : null,
                customName: widget.type == NutritionType.custom
                    ? nameController.text.trim()
                    : null,
                customCarbs: widget.type == NutritionType.custom
                    ? double.tryParse(carbsController.text)
                    : null,
                customFluid: widget.type == NutritionType.custom
                    ? double.tryParse(volumeController.text)
                    : null,
              ),
            );
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: blackyellowTheme.colorScheme.primary,
            foregroundColor: Colors.black,
          ),
          child: Text(
            widget.existingItem != null
                ? (widget.isGerman ? 'Speichern' : 'Save')
                : (widget.isGerman ? 'Hinzufügen' : 'Add'),
          ),
        ),
      ],
    );
  }
}
