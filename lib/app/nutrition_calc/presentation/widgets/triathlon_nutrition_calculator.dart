import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nutrition_calculator_app/core/enums.dart';
import 'package:nutrition_calculator_app/core/models.dart';
import 'package:nutrition_calculator_app/core/utils.dart';
import 'package:nutrition_calculator_app/core/presentation/theme/theme.dart';
import 'package:nutrition_calculator_app/services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SportNutrition {
  final String sportName;
  final IconData icon;
  final Color color;
  final TextEditingController durationController;
  final TextEditingController carbTargetController;
  final TextEditingController sodiumTargetController;
  final TextEditingController fluidTargetController;
  final TextEditingController distanceController;
  final List<NutritionItem> nutritionItems;

  SportNutrition({
    required this.sportName,
    required this.icon,
    required this.color,
  }) : durationController = TextEditingController(),
       carbTargetController = TextEditingController(),
       sodiumTargetController = TextEditingController(),
       fluidTargetController = TextEditingController(),
       distanceController = TextEditingController(),
       nutritionItems = [];

  double get totalCarbs =>
      nutritionItems.fold(0.0, (sum, item) => sum + item.carbsAmount);
  double get totalSodium =>
      nutritionItems.fold(0.0, (sum, item) => sum + item.sodiumAmount);
  double get totalFluid =>
      nutritionItems.fold(0.0, (sum, item) => sum + item.fluidAmount);
  double get totalCaffeine =>
      nutritionItems.fold(0.0, (sum, item) => sum + item.caffeineAmount);

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

  double get carbTarget => sportName == 'Pre-Race-Nutrition'
      ? (double.tryParse(carbTargetController.text) ?? 0.0)
      : (double.tryParse(carbTargetController.text) ?? 0.0) * (duration / 60);
  double get sodiumTarget => sportName == 'Pre-Race-Nutrition'
      ? (double.tryParse(sodiumTargetController.text) ?? 0.0)
      : (double.tryParse(sodiumTargetController.text) ?? 0.0) * (duration / 60);
  double get fluidTarget => sportName == 'Pre-Race-Nutrition'
      ? (double.tryParse(fluidTargetController.text) ?? 0.0)
      : (double.tryParse(fluidTargetController.text) ?? 0.0) * (duration / 60);

  double get carbsDifference => totalCarbs - carbTarget;
  double get sodiumDifference => totalSodium - sodiumTarget;
  double get fluidDifference => totalFluid - fluidTarget;
}

extension on NutritionType {
  String get storageValue => name;
}

extension on GelCarbs {
  String get storageValue => name;
}

extension on BarCarbs {
  String get storageValue => name;
}

extension on SweatRate {
  String get storageValue => name;
}

extension on FluidRate {
  String get storageValue => name;
}

extension on EventDistance {
  String get storageValue => name;
}

NutritionType _nutritionTypeFromStorageValue(String? value) {
  return NutritionType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => NutritionType.gel,
  );
}

GelCarbs? _gelCarbsFromStorageValue(String? value) {
  for (final item in GelCarbs.values) {
    if (item.name == value) {
      return item;
    }
  }
  return null;
}

BarCarbs? _barCarbsFromStorageValue(String? value) {
  for (final item in BarCarbs.values) {
    if (item.name == value) {
      return item;
    }
  }
  return null;
}

SweatRate _sweatRateFromStorageValue(String? value) {
  return SweatRate.values.firstWhere(
    (item) => item.name == value,
    orElse: () => SweatRate.medium,
  );
}

FluidRate _fluidRateFromStorageValue(String? value) {
  return FluidRate.values.firstWhere(
    (item) => item.name == value,
    orElse: () => FluidRate.medium,
  );
}

EventDistance? _eventDistanceFromStorageValue(String? value) {
  for (final item in EventDistance.values) {
    if (item.name == value) {
      return item;
    }
  }
  return null;
}

class TriathlonNutritionCalculator extends StatefulWidget {
  final bool isGerman;
  final bool restoreLastConfiguration;
  final ValueChanged<Map<String, dynamic>>? onConfigurationChanged;

  const TriathlonNutritionCalculator({
    super.key,
    required this.isGerman,
    this.restoreLastConfiguration = true,
    this.onConfigurationChanged,
  });

  @override
  State<TriathlonNutritionCalculator> createState() =>
      TriathlonNutritionCalculatorState();
}

class TriathlonNutritionCalculatorState
    extends State<TriathlonNutritionCalculator> {
  late List<SportNutrition> sports;
  final TextEditingController configurationNameController =
      TextEditingController();
  final TextEditingController sipVolumeController = TextEditingController(
    text: '22',
  );
  final TextEditingController drinkingIntervalController =
      TextEditingController(text: '10');
  final TextEditingController emailController = TextEditingController();

  SweatRate defaultSweatRate = SweatRate.medium;
  FluidRate defaultFluidRate = FluidRate.medium;
  EventDistance? selectedEventDistance;
  CalculatorView currentView = CalculatorView.input;
  late String _configurationId;
  Timer? _autoSaveTimer;
  bool _isApplyingConfiguration = false;

  List<SportNutrition> _createDefaultSports() {
    return [
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
  }

  Map<String, dynamic> exportConfiguration() {
    return {
      'id': _configurationId,
      'name': _effectiveConfigurationName,
      'savedAt': DateTime.now().toIso8601String(),
      'selectedEventDistance': selectedEventDistance?.storageValue,
      'defaultSweatRate': defaultSweatRate.storageValue,
      'defaultFluidRate': defaultFluidRate.storageValue,
      'drinkingInterval': drinkingIntervalController.text,
      'sipVolume': sipVolumeController.text,
      'email': emailController.text,
      'sports': sports
          .map(
            (sport) => {
              'sportName': sport.sportName,
              'distance': sport.distanceController.text,
              'duration': sport.durationController.text,
              'carbTarget': sport.carbTargetController.text,
              'sodiumTarget': sport.sodiumTargetController.text,
              'fluidTarget': sport.fluidTargetController.text,
              'nutritionItems': sport.nutritionItems
                  .map(
                    (item) => {
                      'id': item.id,
                      'type': item.type.storageValue,
                      'gelCarbs': item.gelCarbs?.storageValue,
                      'barCarbs': item.barCarbs?.storageValue,
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
            },
          )
          .toList(),
    };
  }

  void importConfiguration(Map<String, dynamic> configuration) {
    _isApplyingConfiguration = true;
    setState(() {
      _configurationId =
          configuration['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString();
      configurationNameController.text =
          configuration['name']?.toString() ??
          _defaultConfigurationName(DateTime.now());
      selectedEventDistance = _eventDistanceFromStorageValue(
        configuration['selectedEventDistance']?.toString(),
      );
      defaultSweatRate = _sweatRateFromStorageValue(
        configuration['defaultSweatRate']?.toString(),
      );
      defaultFluidRate = _fluidRateFromStorageValue(
        configuration['defaultFluidRate']?.toString(),
      );
      drinkingIntervalController.text =
          configuration['drinkingInterval']?.toString() ?? '10';
      sipVolumeController.text = configuration['sipVolume']?.toString() ?? '22';
      emailController.text = configuration['email']?.toString() ?? '';
      applyDefaultRatesToAllSports();

      final sportsData = configuration['sports'];
      final byName = <String, Map<String, dynamic>>{};
      if (sportsData is List) {
        for (final item in sportsData) {
          if (item is Map) {
            final mapped = item.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            final sportName = mapped['sportName']?.toString();
            if (sportName != null) {
              byName[sportName] = mapped;
            }
          }
        }
      }

      for (final sport in sports) {
        final sportData = byName[sport.sportName];
        sport.distanceController.text =
            sportData?['distance']?.toString() ?? '';
        sport.durationController.text =
            sportData?['duration']?.toString() ?? '';
        sport.carbTargetController.text =
            sportData?['carbTarget']?.toString() ?? '';
        sport.sodiumTargetController.text =
            sportData?['sodiumTarget']?.toString() ?? '';
        sport.fluidTargetController.text =
            sportData?['fluidTarget']?.toString() ?? '';

        final items = <NutritionItem>[];
        final nutritionItems = sportData?['nutritionItems'];
        if (nutritionItems is List) {
          for (final item in nutritionItems) {
            if (item is! Map) {
              continue;
            }
            final mapped = item.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            items.add(
              NutritionItem(
                id:
                    mapped['id']?.toString() ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                type: _nutritionTypeFromStorageValue(
                  mapped['type']?.toString() ?? NutritionType.gel.storageValue,
                ),
                gelCarbs: _gelCarbsFromStorageValue(
                  mapped['gelCarbs']?.toString(),
                ),
                barCarbs: _barCarbsFromStorageValue(
                  mapped['barCarbs']?.toString(),
                ),
                bottleVolume: (mapped['bottleVolume'] as num?)?.toDouble(),
                bottleCarbs: (mapped['bottleCarbs'] as num?)?.toDouble(),
                bottleSodium: (mapped['bottleSodium'] as num?)?.toDouble(),
                customSodium: (mapped['customSodium'] as num?)?.toDouble(),
                caffeine: (mapped['caffeine'] as num?)?.toDouble(),
                customName: mapped['customName']?.toString(),
                customCarbs: (mapped['customCarbs'] as num?)?.toDouble(),
                customFluid: (mapped['customFluid'] as num?)?.toDouble(),
              ),
            );
          }
        }

        sport.nutritionItems
          ..clear()
          ..addAll(items);
      }
    });
    _isApplyingConfiguration = false;
  }

  String get _effectiveConfigurationName {
    final trimmed = configurationNameController.text.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return _defaultConfigurationName(DateTime.now());
  }

  String _defaultConfigurationName(DateTime timestamp) {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return widget.isGerman
        ? 'Plan $day.$month.${timestamp.year} $hour:$minute'
        : 'Plan ${timestamp.year}-$month-$day $hour:$minute';
  }

  void _registerAutoSaveListeners() {
    final controllers = <TextEditingController>[
      configurationNameController,
      sipVolumeController,
      drinkingIntervalController,
      emailController,
      for (final sport in sports) ...[
        sport.distanceController,
        sport.durationController,
        sport.carbTargetController,
        sport.sodiumTargetController,
        sport.fluidTargetController,
      ],
    ];

    for (final controller in controllers) {
      controller.addListener(_queueAutoSave);
    }
  }

  void _queueAutoSave() {
    if (_isApplyingConfiguration) {
      return;
    }

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () async {
      final configuration = exportConfiguration();
      await StorageService.saveLastConfiguration(configuration);
      if (widget.onConfigurationChanged == null) {
        await StorageService.saveConfiguration(configuration);
      }
      widget.onConfigurationChanged?.call(configuration);
    });
  }

  Future<void> _loadInitialConfiguration() async {
    if (!widget.restoreLastConfiguration) {
      configurationNameController.text = _defaultConfigurationName(
        DateTime.now(),
      );
      _queueAutoSave();
      return;
    }

    final lastConfiguration = await StorageService.loadLastConfiguration();
    if (!mounted) {
      return;
    }

    if (lastConfiguration != null) {
      importConfiguration(lastConfiguration);
      return;
    }

    configurationNameController.text = _defaultConfigurationName(
      DateTime.now(),
    );
    _queueAutoSave();
  }

  double getSweatRateValue(SweatRate rate) {
    switch (rate) {
      case SweatRate.low:
        return 500.0;
      case SweatRate.medium:
        return 750.0;
      case SweatRate.high:
        return 1000.0;
    }
  }

  double getFluidRateValue(FluidRate rate) {
    switch (rate) {
      case FluidRate.low:
        return 500.0;
      case FluidRate.medium:
        return 750.0;
      case FluidRate.high:
        return 1000.0;
    }
  }

  String getEventDistanceDisplayName(EventDistance distance) {
    switch (distance) {
      case EventDistance.sprint:
        return widget.isGerman ? 'Sprintdistanz' : 'Sprint Distance';
      case EventDistance.olympic:
        return widget.isGerman ? 'Olympische Distanz' : 'Olympic Distance';
      case EventDistance.middle:
        return widget.isGerman ? 'Mitteldistanz' : 'Middle Distance';
      case EventDistance.long:
        return widget.isGerman ? 'Langdistanz' : 'Long Distance';
    }
  }

  String getEventDistanceDetails(EventDistance distance) {
    switch (distance) {
      case EventDistance.sprint:
        return widget.isGerman
            ? 'Schwimmen: 750m | Radfahren: 20km | Laufen: 5km'
            : 'Swimming: 750m | Cycling: 20km | Running: 5km';
      case EventDistance.olympic:
        return widget.isGerman
            ? 'Schwimmen: 1,5km | Radfahren: 40km | Laufen: 10km'
            : 'Swimming: 1.5km | Cycling: 40km | Running: 10km';
      case EventDistance.middle:
        return widget.isGerman
            ? 'Schwimmen: 1,9km | Radfahren: 90km | Laufen: 21,1km'
            : 'Swimming: 1.9km | Cycling: 90km | Running: 21.1km';
      case EventDistance.long:
        return widget.isGerman
            ? 'Schwimmen: 3,8km | Radfahren: 180km | Laufen: 42,2km'
            : 'Swimming: 3.8km | Cycling: 180km | Running: 42.2km';
    }
  }

  String getSportDistance(EventDistance distance, String sportName) {
    switch (distance) {
      case EventDistance.sprint:
        switch (sportName) {
          case 'Pre-Race-Nutrition':
            return '';
          case 'Cycling':
            return widget.isGerman ? '20km' : '20km';
          case 'Running':
            return widget.isGerman ? '5km' : '5km';
          default:
            return '';
        }
      case EventDistance.olympic:
        switch (sportName) {
          case 'Pre-Race-Nutrition':
            return '';
          case 'Cycling':
            return widget.isGerman ? '40km' : '40km';
          case 'Running':
            return widget.isGerman ? '10km' : '10km';
          default:
            return '';
        }
      case EventDistance.middle:
        switch (sportName) {
          case 'Pre-Race-Nutrition':
            return '';
          case 'Cycling':
            return widget.isGerman ? '90km' : '90km';
          case 'Running':
            return widget.isGerman ? '21,1km' : '21.1km';
          default:
            return '';
        }
      case EventDistance.long:
        switch (sportName) {
          case 'Pre-Race-Nutrition':
            return '';
          case 'Cycling':
            return widget.isGerman ? '180km' : '180km';
          case 'Running':
            return widget.isGerman ? '42,2km' : '42.2km';
          default:
            return '';
        }
    }
  }

  String _getSwimmingDistance(EventDistance distance) {
    switch (distance) {
      case EventDistance.sprint:
        return '750m';
      case EventDistance.olympic:
        return '1,5km';
      case EventDistance.middle:
        return '1,9km';
      case EventDistance.long:
        return '3,8km';
    }
  }

  String _getCyclingDistance(EventDistance distance) {
    switch (distance) {
      case EventDistance.sprint:
        return '20km';
      case EventDistance.olympic:
        return '40km';
      case EventDistance.middle:
        return '90km';
      case EventDistance.long:
        return '180km';
    }
  }

  String _getRunningDistance(EventDistance distance) {
    switch (distance) {
      case EventDistance.sprint:
        return '5km';
      case EventDistance.olympic:
        return '10km';
      case EventDistance.middle:
        return widget.isGerman ? '21,1km' : '21.1km';
      case EventDistance.long:
        return widget.isGerman ? '42,2km' : '42.2km';
    }
  }

  Widget _buildEventDistanceRow(IconData icon, String sport, String distance) {
    return Row(
      children: [
        Icon(icon, color: blackyellowTheme.colorScheme.primary, size: 20),
        SizedBox(width: 8),
        Text(
          sport,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Spacer(),
        Text(
          distance,
          style: TextStyle(
            color: blackyellowTheme.colorScheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void applyDefaultRatesToAllSports() {
    final defaultSodiumTarget = getSweatRateValue(defaultSweatRate);
    final defaultFluidTarget = getFluidRateValue(defaultFluidRate);

    for (final sport in sports) {
      // Skip applying default values to Pre-Race-Nutrition
      if (sport.sportName != 'Pre-Race-Nutrition') {
        sport.sodiumTargetController.text = defaultSodiumTarget.toString();
        sport.fluidTargetController.text = defaultFluidTarget.toString();
      }
    }
    setState(() {});
  }

  void _updateSportDistances(EventDistance distance) {
    for (final sport in sports) {
      switch (distance) {
        case EventDistance.sprint:
          switch (sport.sportName) {
            case 'Cycling':
              sport.distanceController.text = '20';
              break;
            case 'Running':
              sport.distanceController.text = '5';
              break;
          }
          break;
        case EventDistance.olympic:
          switch (sport.sportName) {
            case 'Cycling':
              sport.distanceController.text = '40';
              break;
            case 'Running':
              sport.distanceController.text = '10';
              break;
          }
          break;
        case EventDistance.middle:
          switch (sport.sportName) {
            case 'Cycling':
              sport.distanceController.text = '90';
              break;
            case 'Running':
              sport.distanceController.text = '21.1';
              break;
          }
          break;
        case EventDistance.long:
          switch (sport.sportName) {
            case 'Cycling':
              sport.distanceController.text = '180';
              break;
            case 'Running':
              sport.distanceController.text = '42.2';
              break;
          }
          break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    sports = _createDefaultSports();
    _configurationId = DateTime.now().microsecondsSinceEpoch.toString();

    // Apply default rates to all sports on initialization
    applyDefaultRatesToAllSports();
    _registerAutoSaveListeners();
    _loadInitialConfiguration();
  }

  @override
  void dispose() {
    if (!_isApplyingConfiguration) {
      final configuration = exportConfiguration();
      unawaited(StorageService.saveLastConfiguration(configuration));
      if (widget.onConfigurationChanged == null) {
        unawaited(StorageService.saveConfiguration(configuration));
      }
      widget.onConfigurationChanged?.call(configuration);
    }
    for (final sport in sports) {
      sport.durationController.dispose();
      sport.carbTargetController.dispose();
      sport.sodiumTargetController.dispose();
      sport.fluidTargetController.dispose();
      sport.distanceController.dispose();
    }
    configurationNameController.dispose();
    sipVolumeController.dispose();
    drinkingIntervalController.dispose();
    emailController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  double get sipVolume => double.tryParse(sipVolumeController.text) ?? 22.0;
  double get drinkingInterval =>
      double.tryParse(drinkingIntervalController.text) ?? 10.0;

  double _parseLocalizedDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  // Typography Constants
  TextStyle get headingStyle =>
      blackyellowTheme.textTheme.headlineSmall!.copyWith(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );

  TextStyle get sectionTitleStyle =>
      blackyellowTheme.textTheme.titleLarge!.copyWith(
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

  TextStyle get bodyStyle =>
      TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500);

  TextStyle get captionStyle => TextStyle(
    color: Colors.white.withOpacity(0.8),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  Color get pageCardColor => appPanelHighlightColor;
  Color get sectionCardColor => appPanelColor;
  Color get fieldFillColor => Color(0xFF242424);
  Color get fieldBorderColor => Colors.white.withOpacity(0.08);
  Color get fieldHintColor => Colors.white.withOpacity(0.5);
  Color get mutedTextColor => Colors.white.withOpacity(0.72);
  double get panelRadius => appPanelRadius;
  double get fieldRadius => 6;

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      suffixText: suffixText,
      suffixStyle: TextStyle(color: mutedTextColor, fontSize: 12),
      labelText: labelText,
      hintText: hintText,
      hintStyle: TextStyle(color: fieldHintColor),
      filled: true,
      fillColor: fieldFillColor,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: TextStyle(color: fieldHintColor, fontSize: 13),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: fieldBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: fieldBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(
          color: blackyellowTheme.colorScheme.primary.withOpacity(0.9),
          width: 1.4,
        ),
      ),
    );
  }

  TextStyle get inputTextStyle =>
      TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500);

  BoxDecoration _panelDecoration({bool highlighted = false}) {
    return appPanelDecoration(highlighted: highlighted);
  }

  // Spacing Constants
  static const double spacingXS = 8.0;
  static const double spacingS = 10.0;
  static const double spacingM = 16.0;
  static const double spacingL = 20.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // Consistent button style
  ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: blackyellowTheme.colorScheme.primary,
    foregroundColor: Colors.black,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.3),
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  );

  ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: blackyellowTheme.colorScheme.secondary,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.3),
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  );

  void _addNutritionItem(SportNutrition sport, NutritionType type) {
    showDialog(
      context: context,
      builder: (context) => _NutritionDialog(
        type: type,
        isGerman: widget.isGerman,
        onAdd: (item) {
          setState(() {
            sport.nutritionItems.add(item);
          });
          _queueAutoSave();
        },
      ),
    );
  }

  void _removeNutritionItem(SportNutrition sport, NutritionItem item) {
    setState(() {
      sport.nutritionItems.remove(item);
    });
    _queueAutoSave();
  }

  void _editNutritionItem(SportNutrition sport, NutritionItem item) {
    showDialog(
      context: context,
      builder: (context) => _NutritionDialog(
        type: item.type,
        isGerman: widget.isGerman,
        existingItem: item,
        onAdd: (editedItem) {
          setState(() {
            final index = sport.nutritionItems.indexOf(item);
            if (index != -1) {
              sport.nutritionItems[index] = editedItem;
            }
          });
          _queueAutoSave();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildViewToggle(),
        SizedBox(height: spacingL),
        _buildHeaderSection(),
        SizedBox(height: spacingL),
        if (currentView == CalculatorView.input)
          _buildInputView()
        else
          _buildTimelineView(),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pool, color: blackyellowTheme.primaryColor, size: 24),
            SizedBox(width: spacingXS),
            Icon(
              Icons.directions_bike,
              color: blackyellowTheme.primaryColor,
              size: 24,
            ),
            SizedBox(width: spacingXS),
            Icon(
              Icons.directions_run,
              color: blackyellowTheme.primaryColor,
              size: 24,
            ),
          ],
        ),
        SizedBox(height: spacingS),
        const SizedBox.shrink(),
        SizedBox(height: spacingM),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacingM),
          child: Text(
            widget.isGerman
                ? 'Plane deine optimale Triathlon-Ernährungsstrategie. Gib deine Renndauer ein, stelle Hydratationspräferenzen ein und wechsle danach direkt in die Race-Day-Timeline.'
                : 'Plan your optimal triathlon nutrition strategy. Enter your race duration, set hydration preferences, and switch straight into the race-day timeline.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    final tabs = [
      (CalculatorView.input, widget.isGerman ? 'Eingabe' : 'Input'),
      (CalculatorView.timeline, 'Timeline'),
    ];

    return Container(
      padding: EdgeInsets.all(4),
      child: Row(
        children: tabs.map((tab) {
          final isActive = currentView == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  currentView = tab.$1;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? blackyellowTheme.colorScheme.primary.withOpacity(0.95)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(fieldRadius),
                ),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputView() {
    return Column(
      children: [
        _buildConfigurationSection(),
        _buildEventSelectionSection(),
        _buildDrinkingSettingsSection(),
        _buildSportSection(sports[0]),
        _buildSwimmingNote(),
        _buildSportSection(sports[1]),
        _buildSportSection(sports[2]),
        _buildTotalSection(),
        SizedBox(height: 15),
        _buildRaceRequirementsSection(),
        SizedBox(height: 15),
        _buildExportEmailSection(),
        _buildImpressumSection(),
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return Container(
      padding: EdgeInsets.all(spacingL),
      margin: EdgeInsets.only(bottom: spacingL),
      decoration: _panelDecoration(highlighted: true),
      child: TextFormField(
        controller: configurationNameController,
        style: inputTextStyle,
        decoration: _inputDecoration(
          prefixIcon: Icon(
            Icons.edit_note,
            color: blackyellowTheme.colorScheme.primary,
          ),
          labelText: widget.isGerman ? 'Bezeichnung' : 'Description',
          hintText: widget.isGerman
              ? 'z. B. Ironman Frankfurt 2026'
              : 'e.g. Ironman Frankfurt 2026',
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildEventSelectionSection() {
    return Container(
      padding: EdgeInsets.all(spacingL),
      margin: EdgeInsets.only(bottom: spacingL),
      decoration: _panelDecoration(highlighted: true),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final dropdown = DropdownButtonFormField<EventDistance>(
                initialValue: selectedEventDistance,
                style: inputTextStyle,
                dropdownColor: pageCardColor,
                iconEnabledColor: blackyellowTheme.colorScheme.primary,
                decoration: _inputDecoration(
                  prefixIcon: Icon(
                    Icons.emoji_events,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman ? 'Eventart' : 'Event type',
                ),
                hint: Text(
                  widget.isGerman ? 'Wähle Distanz' : 'Select distance',
                  style: TextStyle(color: fieldHintColor),
                ),
                items: EventDistance.values.map((distance) {
                  return DropdownMenuItem(
                    value: distance,
                    child: Text(getEventDistanceDisplayName(distance)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEventDistance = value;
                    if (value != null) {
                      _updateSportDistances(value);
                    }
                  });
                  _queueAutoSave();
                },
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isGerman ? 'Eventart:' : 'Event type:',
                      style: labelStyle,
                    ),
                    SizedBox(height: 8),
                    dropdown,
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      widget.isGerman ? 'Eventart:' : 'Event type:',
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(width: spacingS),
                  Expanded(child: dropdown),
                ],
              );
            },
          ),
          if (selectedEventDistance != null) ...[
            SizedBox(height: spacingM),
            Padding(
              padding: EdgeInsets.all(spacingS),
              child: Column(
                children: [
                  _buildEventDistanceRow(
                    Icons.pool,
                    widget.isGerman ? 'Schwimmen' : 'Swimming',
                    _getSwimmingDistance(selectedEventDistance!),
                  ),
                  SizedBox(height: 8),
                  _buildEventDistanceRow(
                    Icons.directions_bike,
                    widget.isGerman ? 'Radfahren' : 'Cycling',
                    _getCyclingDistance(selectedEventDistance!),
                  ),
                  SizedBox(height: 8),
                  _buildEventDistanceRow(
                    Icons.directions_run,
                    widget.isGerman ? 'Laufen' : 'Running',
                    _getRunningDistance(selectedEventDistance!),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrinkingSettingsSection() {
    return Container(
      padding: EdgeInsets.all(spacingL),
      margin: EdgeInsets.only(bottom: spacingL),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final intervalField = TextFormField(
                controller: drinkingIntervalController,
                style: inputTextStyle,
                decoration: _inputDecoration(
                 prefixIcon: Icon(
                   Icons.timer,
                   color: blackyellowTheme.colorScheme.primary,
                 ),
                 labelText: widget.isGerman
                     ? 'Trinkintervall'
                     : 'Drinking interval',
                 suffixText: 'min',
                ),                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isGerman
                          ? 'Trinkintervall (min):'
                          : 'Drinking interval (min):',
                      style: labelStyle,
                    ),
                    SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: intervalField),
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      widget.isGerman
                          ? 'Trinkintervall (min):'
                          : 'Drinking interval (min):',
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(width: spacingS),
                  Expanded(child: intervalField),
                ],
              );
            },
          ),
          SizedBox(height: spacingS),
          LayoutBuilder(
            builder: (context, constraints) {
              final sipField = TextFormField(
                controller: sipVolumeController,
                style: inputTextStyle,
                decoration: _inputDecoration(
                 prefixIcon: Icon(
                   Icons.local_drink,
                   color: blackyellowTheme.colorScheme.primary,
                 ),
                 labelText: widget.isGerman ? 'Schluckvolumen' : 'Sip volume',
                 suffixText: 'ml/sip',
                ),                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              );

              if (constraints.maxWidth < 400) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.isGerman
                              ? 'Standard Schluckvolumen (ml):'
                              : 'Default sip volume (ml):',
                          style: labelStyle,
                        ),
                        SizedBox(width: 8),
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
                    SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: sipField),
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      widget.isGerman
                          ? 'Standard Schluckvolumen (ml):'
                          : 'Default sip volume (ml):',
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(width: spacingS),
                  Expanded(child: sipField),
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
              );
            },
          ),
          SizedBox(height: spacingS),
          LayoutBuilder(
            builder: (context, constraints) {
              final sweatRateDropdown = DropdownButtonFormField<SweatRate>(
                initialValue: defaultSweatRate,
                isExpanded: true,
                selectedItemBuilder: (context) {
                  return SweatRate.values.map((rate) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        getSweatRateCompactLabel(rate, widget.isGerman),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList();
                },
                style: inputTextStyle,
                dropdownColor: pageCardColor,
                iconEnabledColor: blackyellowTheme.colorScheme.primary,
                decoration: _inputDecoration(
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman ? 'Schweißrate' : 'Sweat rate',
                ),
                items: SweatRate.values.map((rate) {
                  return DropdownMenuItem(
                    value: rate,
                    child: Text(
                      getSweatRateLabel(rate, widget.isGerman),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      defaultSweatRate = value;
                    });
                    applyDefaultRatesToAllSports();
                    _queueAutoSave();
                  }
                },
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.isGerman
                              ? 'Standard Schweißrate:'
                              : 'Default sweat rate:',
                          style: labelStyle,
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
                    SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: sweatRateDropdown),
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      widget.isGerman
                          ? 'Standard Schweißrate:'
                          : 'Default sweat rate:',
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(width: spacingS),
                  Expanded(child: sweatRateDropdown),
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
              );
            },
          ),
          SizedBox(height: spacingS),
          LayoutBuilder(
            builder: (context, constraints) {
              final fluidRateDropdown = DropdownButtonFormField<FluidRate>(
                initialValue: defaultFluidRate,
                isExpanded: true,
                selectedItemBuilder: (context) {
                  return FluidRate.values.map((rate) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        getFluidRateCompactLabel(rate, widget.isGerman),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList();
                },
                style: inputTextStyle,
                dropdownColor: pageCardColor,
                iconEnabledColor: blackyellowTheme.colorScheme.primary,
                decoration: _inputDecoration(
                  prefixIcon: Icon(
                    Icons.opacity,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman
                      ? 'Flüssigkeitsrate'
                      : 'Fluid rate',
                ),
                items: FluidRate.values.map((rate) {
                  return DropdownMenuItem(
                    value: rate,
                    child: Text(
                      getFluidRateLabel(rate, widget.isGerman),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      defaultFluidRate = value;
                    });
                    applyDefaultRatesToAllSports();
                    _queueAutoSave();
                  }
                },
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.isGerman
                              ? 'Standard Flüssigkeitsrate:'
                              : 'Default fluid rate:',
                          style: labelStyle,
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
                    SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: fluidRateDropdown),
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      widget.isGerman
                          ? 'Standard Flüssigkeitsrate:'
                          : 'Default fluid rate:',
                      style: labelStyle,
                    ),
                  ),
                  SizedBox(width: spacingS),
                  Expanded(child: fluidRateDropdown),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView() {
    final timelines = {
      for (final sport in sports) sport: _generateTimelineForSport(sport),
    };
    final hasTimelineData = timelines.values.any((events) => events.isNotEmpty);

    return Column(
      children: [
        _buildTimelineSummaryCard(),
        SizedBox(height: spacingL),
        if (!hasTimelineData)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacingL),
            decoration: _panelDecoration(),
            child: Column(
              children: [
                Icon(
                  Icons.timeline,
                  size: 40,
                  color: blackyellowTheme.colorScheme.primary,
                ),
                SizedBox(height: spacingM),
                Text(
                  widget.isGerman
                      ? 'Noch keine Timeline verfügbar'
                      : 'No timeline available yet',
                  style: sectionTitleStyle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacingS),
                Text(
                  widget.isGerman
                      ? 'Trage Dauer, Distanz und Ernährungsartikel in der Eingabe-Ansicht ein. Danach erscheint hier deine vertikale Race-Day Timeline.'
                      : 'Add duration, distance, and nutrition items in the input view. Your vertical race-day timeline will appear here afterwards.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          for (final sport in sports) ...[
            _buildSportTimelineSection(sport, timelines[sport] ?? const []),
            SizedBox(height: spacingL),
          ],
        ],
        _buildImpressumSection(),
      ],
    );
  }

  Widget _buildTimelineSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacingL),
      decoration: _panelDecoration(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isGerman ? 'Race-Day Timeline' : 'Race-Day Timeline',
            style: sectionTitleStyle,
          ),
          SizedBox(height: spacingS),
          Text(
            widget.isGerman
                ? 'Zeitpunkte und Kilometer basieren auf deinen Eingaben. Trinken wird über das Intervall verteilt, Ernährungspunkte werden entlang des Abschnitts eingeplant.'
                : 'Times and kilometres are generated from your inputs. Drinks are distributed by interval, and nutrition points are placed across each segment.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          SizedBox(height: spacingM),
          Wrap(
            spacing: spacingS,
            runSpacing: spacingS,
            children: [
              _buildTimelineSummaryChip(
                icon: Icons.flag,
                label: selectedEventDistance == null
                    ? (widget.isGerman ? 'Freie Distanz' : 'Custom distance')
                    : _getEventDistanceName(selectedEventDistance!),
              ),
              _buildTimelineSummaryChip(
                icon: Icons.schedule,
                label:
                    '${widget.isGerman ? 'Intervall' : 'Interval'}: ${drinkingInterval.toInt()} min',
              ),
              _buildTimelineSummaryChip(
                icon: Icons.local_drink,
                label:
                    '${widget.isGerman ? 'Schluck' : 'Sip'}: ${sipVolume.toInt()} ml',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSummaryChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fieldFillColor,
        borderRadius: BorderRadius.circular(fieldRadius),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: blackyellowTheme.colorScheme.primary),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSportTimelineSection(
    SportNutrition sport,
    List<TimelineEvent> events,
  ) {
    final title = sport.sportName == 'Pre-Race-Nutrition'
        ? (widget.isGerman ? 'Pre-Race' : 'Pre-Race')
        : sport.sportName;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacingL),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sport.icon, color: sport.color, size: 24),
              SizedBox(width: spacingS),
              Expanded(child: Text(title, style: sectionTitleStyle)),
              if (sport.sportName != 'Pre-Race-Nutrition')
                Text(
                  '${_formatDurationLabel(sport.duration)} • ${_formatDistanceLabel(sport)}',
                  style: captionStyle,
                ),
            ],
          ),
          SizedBox(height: spacingM),
          if (events.isEmpty)
            Text(
              widget.isGerman
                  ? 'Keine Timeline-Events vorhanden. Füge Dauer, Distanz und Verpflegung hinzu.'
                  : 'No timeline events yet. Add duration, distance, and nutrition items.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: [
                for (int index = 0; index < events.length; index++)
                  _buildTimelineEventRow(
                    events[index],
                    isLast: index == events.length - 1,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineEventRow(TimelineEvent event, {required bool isLast}) {
    final color = _timelineEventColor(event.type);

    return IntrinsicHeight(
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : spacingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 74,
              child: Text(
                _formatTimelineOffset(event.offsetMinutes),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                event.distanceKm == null
                    ? ' '
                    : 'km ${event.distanceKm!.toStringAsFixed(1)}',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      color: isLast
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.18),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacingS),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fieldFillColor,
                  borderRadius: BorderRadius.circular(fieldRadius),
                  border: Border.all(color: color.withOpacity(0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _timelineEventIcon(event.type),
                          color: color,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      event.detail,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TimelineEvent> _generateTimelineForSport(SportNutrition sport) {
    final events = <TimelineEvent>[
      ..._generateNutritionTimelineEvents(sport),
      ..._generateDrinkTimelineEvents(sport),
    ];
    events.sort((a, b) => a.offsetMinutes.compareTo(b.offsetMinutes));
    return events;
  }

  List<TimelineEvent> _generateDrinkTimelineEvents(SportNutrition sport) {
    if (sport.sportName == 'Pre-Race-Nutrition') {
      return const [];
    }

    final durationMinutes = sport.duration.round();
    final interval = drinkingInterval.round();
    final distanceKm = _parseLocalizedDouble(sport.distanceController.text);

    if (durationMinutes <= 0 || interval <= 0) {
      return const [];
    }

    final events = <TimelineEvent>[];
    for (int minute = interval; minute < durationMinutes; minute += interval) {
      events.add(
        TimelineEvent(
          sportName: sport.sportName,
          type: TimelineEventType.drink,
          offsetMinutes: minute,
          distanceKm: _calculateDistanceAtOffset(
            totalDistanceKm: distanceKm,
            totalDurationMinutes: durationMinutes,
            offsetMinutes: minute,
          ),
          title: widget.isGerman
              ? '${sipVolume.toInt()} ml trinken'
              : 'Drink ${sipVolume.toInt()} ml',
          detail: widget.isGerman
              ? 'Regelmäßiger Trinkpunkt basierend auf deinem Intervall.'
              : 'Regular drink point based on your interval.',
        ),
      );
    }

    return events;
  }

  List<TimelineEvent> _generateNutritionTimelineEvents(SportNutrition sport) {
    if (sport.nutritionItems.isEmpty) {
      return const [];
    }

    final regularItems = sport.nutritionItems
        .where((item) => item.type != NutritionType.caffeineGel)
        .toList();
    final caffeineItems = sport.nutritionItems
        .where((item) => item.type == NutritionType.caffeineGel)
        .toList();
    final events = <TimelineEvent>[];

    events.addAll(
      _distributeNutritionItems(
        sport: sport,
        items: regularItems,
        startFraction: sport.sportName == 'Pre-Race-Nutrition' ? 0.0 : 0.12,
        endFraction: sport.sportName == 'Pre-Race-Nutrition' ? 1.0 : 0.88,
      ),
    );
    events.addAll(
      _distributeNutritionItems(
        sport: sport,
        items: caffeineItems,
        startFraction: sport.sportName == 'Pre-Race-Nutrition' ? 0.6 : 0.6,
        endFraction: 0.92,
      ),
    );

    return events;
  }

  List<TimelineEvent> _distributeNutritionItems({
    required SportNutrition sport,
    required List<NutritionItem> items,
    required double startFraction,
    required double endFraction,
  }) {
    if (items.isEmpty) {
      return const [];
    }

    if (sport.sportName == 'Pre-Race-Nutrition') {
      const startMinute = -45;
      const endMinute = -10;
      final span = endMinute - startMinute;
      final step = span / (items.length + 1);

      return items.asMap().entries.map((entry) {
        final minute = (startMinute + step * (entry.key + 1)).round();
        return TimelineEvent(
          sportName: sport.sportName,
          type: _timelineEventTypeForNutrition(entry.value.type),
          offsetMinutes: minute,
          title: _timelineTitleForItem(entry.value),
          detail: _timelineDetailForItem(entry.value),
        );
      }).toList();
    }

    final durationMinutes = sport.duration.round();
    final distanceKm = _parseLocalizedDouble(sport.distanceController.text);
    if (durationMinutes <= 0) {
      return const [];
    }

    final windowStart = (durationMinutes * startFraction).round();
    final windowEnd = (durationMinutes * endFraction).round();
    final safeWindowEnd = windowEnd <= windowStart
        ? durationMinutes
        : windowEnd;
    final span = safeWindowEnd - windowStart;
    final step = span / (items.length + 1);

    return items.asMap().entries.map((entry) {
      final minute = (windowStart + step * (entry.key + 1)).round();
      return TimelineEvent(
        sportName: sport.sportName,
        type: _timelineEventTypeForNutrition(entry.value.type),
        offsetMinutes: minute,
        distanceKm: _calculateDistanceAtOffset(
          totalDistanceKm: distanceKm,
          totalDurationMinutes: durationMinutes,
          offsetMinutes: minute,
        ),
        title: _timelineTitleForItem(entry.value),
        detail: _timelineDetailForItem(entry.value),
      );
    }).toList();
  }

  double? _calculateDistanceAtOffset({
    required double totalDistanceKm,
    required int totalDurationMinutes,
    required int offsetMinutes,
  }) {
    if (totalDistanceKm <= 0 || totalDurationMinutes <= 0) {
      return null;
    }

    final progress = offsetMinutes / totalDurationMinutes;
    final clampedProgress = progress.clamp(0.0, 1.0);
    return totalDistanceKm * clampedProgress;
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
        return widget.isGerman ? 'Chews' : 'Chews';
      case NutritionType.custom:
        return item.customName?.trim().isNotEmpty == true
            ? item.customName!.trim()
            : (widget.isGerman ? 'Eigenes Item' : 'Custom item');
    }
  }

  String _timelineDetailForItem(NutritionItem item) {
    final carbs = item.carbsAmount.toInt();
    final sodium = item.sodiumAmount.toInt();
    final fluid = item.fluidAmount.toInt();
    final caffeine = item.caffeineAmount.toInt();

    switch (item.type) {
      case NutritionType.gel:
        return widget.isGerman
            ? '$carbs g Kohlenhydrate, $sodium mg Natrium'
            : '$carbs g carbohydrates, $sodium mg sodium';
      case NutritionType.caffeineGel:
        return widget.isGerman
            ? '$carbs g Kohlenhydrate, $sodium mg Natrium, $caffeine mg Koffein'
            : '$carbs g carbohydrates, $sodium mg sodium, $caffeine mg caffeine';
      case NutritionType.bar:
        return widget.isGerman
            ? '$carbs g Kohlenhydrate, $sodium mg Natrium'
            : '$carbs g carbohydrates, $sodium mg sodium';
      case NutritionType.bottle:
        return widget.isGerman
            ? '$fluid ml Flüssigkeit, $carbs g Kohlenhydrate, $sodium mg Natrium'
            : '$fluid ml fluid, $carbs g carbohydrates, $sodium mg sodium';
      case NutritionType.chews:
        return widget.isGerman
            ? '$sodium mg Natrium, Elektrolytpunkt'
            : '$sodium mg sodium, electrolyte point';
      case NutritionType.custom:
        final parts = <String>[];
        if (carbs > 0) {
          parts.add(
            widget.isGerman
                ? '$carbs g Kohlenhydrate'
                : '$carbs g carbohydrates',
          );
        }
        if (sodium > 0) {
          parts.add(
            widget.isGerman ? '$sodium mg Natrium' : '$sodium mg sodium',
          );
        }
        if (fluid > 0) {
          parts.add(
            widget.isGerman ? '$fluid ml Flüssigkeit' : '$fluid ml fluid',
          );
        }
        if (caffeine > 0) {
          parts.add(
            widget.isGerman ? '$caffeine mg Koffein' : '$caffeine mg caffeine',
          );
        }
        return parts.isEmpty
            ? (widget.isGerman ? 'Benutzerdefiniertes Item' : 'Custom item')
            : parts.join(', ');
    }
  }

  IconData _timelineEventIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.drink:
        return Icons.local_drink;
      case TimelineEventType.gel:
        return Icons.bolt;
      case TimelineEventType.caffeineGel:
        return Icons.flash_on;
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

  Color _timelineEventColor(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.drink:
        return Colors.lightBlueAccent;
      case TimelineEventType.gel:
        return blackyellowTheme.colorScheme.primary;
      case TimelineEventType.caffeineGel:
        return Colors.orangeAccent;
      case TimelineEventType.bar:
        return Color(0xFFC6922A);
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

  String _formatTimelineOffset(int minutes) {
    final isNegative = minutes < 0;
    final absoluteMinutes = minutes.abs();
    final hours = absoluteMinutes ~/ 60;
    final remainingMinutes = absoluteMinutes % 60;
    final formatted =
        '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}';
    return isNegative ? 'T-$formatted' : formatted;
  }

  String _formatDurationLabel(double durationMinutes) {
    final totalMinutes = durationMinutes.round();
    if (totalMinutes <= 0) {
      return widget.isGerman ? 'ohne Dauer' : 'no duration';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _formatDistanceLabel(SportNutrition sport) {
    final distanceKm = _parseLocalizedDouble(sport.distanceController.text);
    if (distanceKm <= 0) {
      return widget.isGerman ? 'ohne Distanz' : 'no distance';
    }
    return '${distanceKm.toStringAsFixed(distanceKm.truncateToDouble() == distanceKm ? 0 : 1)} km';
  }

  Widget _buildSportSection(SportNutrition sport) {
    return Container(
      margin: EdgeInsets.only(bottom: spacingL),
      padding: EdgeInsets.all(spacingL),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sport Header
          Row(
            children: [
              Icon(sport.icon, color: sport.color, size: 24),
              SizedBox(width: spacingS),
              Text(
                sport.sportName == 'Pre-Race-Nutrition'
                    ? (widget.isGerman ? 'Pre-Race' : 'Pre-Race')
                    : sport.sportName == 'Cycling'
                    ? (widget.isGerman ? 'Radfahren' : 'Cycling')
                    : sport.sportName == 'Running'
                    ? (widget.isGerman ? 'Laufen' : 'Running')
                    : sport.sportName,
                style: sectionTitleStyle,
              ),
            ],
          ),
          SizedBox(height: spacingS),
          Padding(
            padding: EdgeInsets.only(bottom: spacingM),
            child: Text(
              sport.sportName == 'Pre-Race-Nutrition'
                  ? (widget.isGerman
                      ? 'Lege hier fest, wie viele Kohlenhydrate und Natrium du in den Stunden vor dem Start (Pre-Race) zu dir nehmen möchtest.'
                      : 'Define how many carbohydrates and how much sodium you want to consume in the hours before the start (Pre-Race).')
                  : sport.sportName == 'Cycling'
                      ? (widget.isGerman
                          ? 'Gib hier deine geplante Distanz und Dauer für die Radstrecke sowie deine Zielwerte pro Stunde ein.'
                          : 'Enter your planned distance and duration for the cycling segment as well as your target values per hour.')
                      : (widget.isGerman
                          ? 'Gib hier deine geplante Distanz und Dauer für die Laufstrecke sowie deine Zielwerte pro Stunde ein.'
                          : 'Enter your planned distance and duration for the running segment as well as your target values per hour.'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),

          // Distance Input (skip for Pre-Race-Nutrition)
          if (sport.sportName != 'Pre-Race-Nutrition') ...[
            TextFormField(
              controller: sport.distanceController,
              style: inputTextStyle,
              decoration: _inputDecoration(
                prefixIcon: Icon(
                  sport.sportName == 'Cycling'
                      ? Icons.directions_bike
                      : sport.sportName == 'Running'
                      ? Icons.directions_run
                      : Icons.show_chart,
                  color: blackyellowTheme.colorScheme.primary,
                ),
                suffixText: 'km',
                labelText: widget.isGerman ? 'Distanz (km)' : 'Distance (km)',
                hintText: sport.sportName == 'Cycling' ? '180' : '42.2',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: spacingS),
          ],

          // Duration Input (skip for Pre-Race-Nutrition)
          if (sport.sportName != 'Pre-Race-Nutrition') ...[
            TextFormField(
              controller: sport.durationController,
              style: inputTextStyle,
              decoration: _inputDecoration(
                prefixIcon: Icon(
                  Icons.timer,
                  color: blackyellowTheme.colorScheme.primary,
                ),
                suffixText: 'HH:MM',
                labelText: widget.isGerman
                    ? 'Dauer (z.B. 1:30)'
                    : 'Duration (e.g. 1:30)',
                hintText: '1:30',
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
                style: inputTextStyle,
                decoration: _inputDecoration(
                  prefixIcon: Icon(
                    Icons.local_fire_department,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  suffixText: sport.sportName == 'Pre-Race-Nutrition'
                      ? 'g'
                      : 'g/h',
                  labelText: sport.sportName == 'Pre-Race-Nutrition'
                      ? (widget.isGerman
                            ? 'Kohlenhydrat-Ziel (g)'
                            : 'Carb Target (g)')
                      : (widget.isGerman
                            ? 'Kohlenhydrat-Ziel (g/h)'
                            : 'Carb Target (g/h)'),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: sport.sodiumTargetController,
                style: inputTextStyle,
                decoration: _inputDecoration(
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  suffixText: sport.sportName == 'Pre-Race-Nutrition'
                      ? 'mg'
                      : 'mg/h',
                  labelText: sport.sportName == 'Pre-Race-Nutrition'
                      ? (widget.isGerman
                            ? 'Natrium-Ziel (mg)'
                            : 'Sodium Target (mg)')
                      : (widget.isGerman
                            ? 'Natrium-Ziel (mg/h)'
                            : 'Sodium Target (mg/h)'),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: sport.fluidTargetController,
                style: inputTextStyle,
                decoration: _inputDecoration(
                  prefixIcon: Icon(
                    Icons.local_drink,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  suffixText: sport.sportName == 'Pre-Race-Nutrition'
                      ? 'ml'
                      : 'ml/h',
                  labelText: sport.sportName == 'Pre-Race-Nutrition'
                      ? (widget.isGerman
                            ? 'Flüssigkeitsziel (ml)'
                            : 'Fluid (ml)')
                      : (widget.isGerman
                            ? 'Flüssigkeitsziel (ml/h)'
                            : 'Fluid (ml/h)'),
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
                        onPressed: () =>
                            _addNutritionItem(sport, NutritionType.gel),
                        icon: Icon(Icons.add, size: 16),
                        label: Text(
                          widget.isGerman ? 'Gel' : 'Gel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: primaryButtonStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _addNutritionItem(sport, NutritionType.caffeineGel),
                        icon: Icon(Icons.add, size: 16),
                        label: Text(
                          widget.isGerman ? 'Koffein Gel' : 'Caffeine Gel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        onPressed: () =>
                            _addNutritionItem(sport, NutritionType.bar),
                        icon: Icon(Icons.add, size: 16),
                        label: Text(
                          widget.isGerman ? 'Riegel' : 'Bar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: primaryButtonStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _addNutritionItem(sport, NutritionType.bottle),
                        icon: Icon(Icons.add, size: 16),
                        label: Text(
                          widget.isGerman ? 'Flasche' : 'Bottle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        onPressed: () =>
                            _addNutritionItem(sport, NutritionType.chews),
                        icon: Icon(Icons.add, size: 16),
                        label: Text(
                          widget.isGerman ? 'Chews' : 'Chews',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: primaryButtonStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _addNutritionItem(sport, NutritionType.custom),
                        icon: Icon(Icons.add, size: 16),
                        label: Text(
                          widget.isGerman ? 'Eigenes' : 'Custom',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
            _buildReorderableNutritionList(sport),

          SizedBox(height: spacingM),

          // Summary for this sport
          _buildSportSummary(sport),
        ],
      ),
    );
  }

  Widget _buildReorderableNutritionList(SportNutrition sport) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = sport.nutritionItems.removeAt(oldIndex);
          sport.nutritionItems.insert(newIndex, item);
        });
        _queueAutoSave();
      },
      children: sport.nutritionItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildNutritionItem(sport, item, index);
      }).toList(),
    );
  }

  Widget _buildNutritionItem(
    SportNutrition sport,
    NutritionItem item,
    int index,
  ) {
    Color color;
    String description;

    switch (item.type) {
      case NutritionType.gel:
        color = blackyellowTheme.colorScheme.primary;
        final carbValue = item.gelCarbs
            .toString()
            .split('.')
            .last
            .substring(1); // Remove 'g' prefix
        description = widget.isGerman
            ? 'Gel ${carbValue}g'
            : 'Gel ${carbValue}g';
        break;
      case NutritionType.caffeineGel:
        color = blackyellowTheme.colorScheme.primary;
        final carbValue = item.gelCarbs
            .toString()
            .split('.')
            .last
            .substring(1); // Remove 'g' prefix
        description = widget.isGerman
            ? 'Koffein Gel ${carbValue}g (${item.caffeineAmount.toInt()}mg Koffein)'
            : 'Caffeine Gel ${carbValue}g (${item.caffeineAmount.toInt()}mg caffeine)';
        break;
      case NutritionType.bar:
        color = blackyellowTheme.colorScheme.secondary;
        final carbValue = item.barCarbs
            .toString()
            .split('.')
            .last
            .substring(1); // Remove 'g' prefix
        description = widget.isGerman
            ? 'Riegel ${carbValue}g'
            : 'Bar ${carbValue}g';
        break;
      case NutritionType.bottle:
        color = blackyellowTheme.colorScheme.secondary;
        description = widget.isGerman
            ? 'Flasche ${item.bottleVolume}ml'
            : 'Bottle ${item.bottleVolume}ml';
        break;
      case NutritionType.chews:
        color = blackyellowTheme.colorScheme.primary;
        description = widget.isGerman
            ? 'Chews (${item.sodiumAmount.toInt()}mg Na)'
            : 'Chews (${item.sodiumAmount.toInt()}mg Na)';
        break;
      case NutritionType.custom:
        color = blackyellowTheme.colorScheme.primary;
        description = item.customName?.trim().isNotEmpty == true
            ? item.customName!.trim()
            : (widget.isGerman ? 'Eigenes Item' : 'Custom item');
        break;
    }

    return GestureDetector(
      key: ValueKey('${sport.sportName}_$index'),
      onTap: () => _editNutritionItem(sport, item),
      child: Container(
        margin: EdgeInsets.only(bottom: 5),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle, color: Colors.white70, size: 20),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.type == NutritionType.bottle
                        ? () {
                            // Calculate glucose and fructose based on 1:0.8 ratio
                            final totalCarbs = item.carbsAmount;
                            final glucose =
                                totalCarbs / 1.8; // 1/(1+0.8) = 1/1.8
                            final fructose = glucose * 0.8;

                            // Calculate required number of sips based on drinking interval
                            String sipInfo = '';
                            final carbTargetPerHour =
                                double.tryParse(
                                  sport.carbTargetController.text,
                                ) ??
                                0.0;
                            if (carbTargetPerHour > 0 &&
                                item.bottleVolume != null &&
                                item.bottleCarbs != null &&
                                item.bottleVolume! > 0 &&
                                item.bottleCarbs! > 0) {
                              final carbsPerMl =
                                  item.bottleCarbs! /
                                  item.bottleVolume!; // g carbs per ml
                              final carbsPerSip =
                                  carbsPerMl *
                                  sipVolume; // carbs per default sip
                              final requiredCarbsPerInterval =
                                  carbTargetPerHour *
                                  (drinkingInterval /
                                      60); // carbs needed per interval
                              final requiredSipsPerInterval =
                                  requiredCarbsPerInterval /
                                  carbsPerSip; // sips needed per interval
                              final totalCarbsFromAllSips =
                                  requiredSipsPerInterval *
                                  carbsPerSip; // total carbs from all sips
                              sipInfo =
                                  ', ${requiredSipsPerInterval.toStringAsFixed(1)} sips every ${drinkingInterval.toInt()}min (${totalCarbsFromAllSips.toInt()}g carbs)';
                            }

                            return widget.isGerman
                                ? 'Kohlenhydrate: ${totalCarbs.toInt()}g (${glucose.toInt()}g Gl/${fructose.toInt()}g Fr), Na: ${item.sodiumAmount.toInt()}mg, Fl: ${item.fluidAmount.toInt()}ml$sipInfo'
                                : 'Carbs: ${totalCarbs.toInt()}g (${glucose.toInt()}g Gl/${fructose.toInt()}g Fr), Na: ${item.sodiumAmount.toInt()}mg, Fl: ${item.fluidAmount.toInt()}ml$sipInfo';
                          }()
                        : widget.isGerman
                        ? 'Kohlenhydrate: ${item.carbsAmount.toInt()}g, Na: ${item.sodiumAmount.toInt()}mg, Fl: ${item.fluidAmount.toInt()}ml'
                        : 'Carbs: ${item.carbsAmount.toInt()}g, Na: ${item.sodiumAmount.toInt()}mg, Fl: ${item.fluidAmount.toInt()}ml',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
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
      ),
    );
  }

  Widget _buildSportSummary(SportNutrition sport) {
    return Column(
      children: [
        Text(
          widget.isGerman
              ? 'Zusammenfassung ${sport.sportName}'
              : 'Summary ${sport.sportName}',
          style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spacingM),
        // Kohlenhydrate Progress Bar
        _buildProgressBar(
          Icons.local_fire_department,
          widget.isGerman ? 'Kohlenhydrate' : 'Carbohydrates',
          sport.totalCarbs,
          sport.carbTarget,
          blackyellowTheme.colorScheme.primary,
          'g',
        ),
        SizedBox(height: spacingM),
        // Natrium Progress Bar
        _buildProgressBar(
          Icons.water_drop,
          widget.isGerman ? 'Natrium' : 'Sodium',
          sport.totalSodium,
          sport.sodiumTarget,
          blackyellowTheme.colorScheme.primary,
          'mg',
        ),
        SizedBox(height: spacingM),
        // Flüssigkeit Progress Bar
        _buildProgressBar(
          Icons.local_drink,
          widget.isGerman ? 'Flüssigkeit' : 'Fluid',
          sport.totalFluid,
          sport.fluidTarget,
          blackyellowTheme.colorScheme.primary,
          'ml',
        ),
        if (sport.totalCaffeine > 0) ...[
          SizedBox(height: spacingM),
          // Koffein Progress Bar (nur wenn vorhanden)
          _buildProgressBar(
            Icons.coffee,
            widget.isGerman ? 'Koffein' : 'Caffeine',
            sport.totalCaffeine,
            sport.totalCaffeine, // Kein Ziel, daher 100%
            blackyellowTheme.colorScheme.primary,
            'mg',
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(
    IconData icon,
    String label,
    double current,
    double target,
    Color color,
    String unit,
  ) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isOverTarget = current > target && target > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Spacer(),
            Text(
              '${current.toInt()}$unit / ${target.toInt()}$unit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: isOverTarget ? blackyellowTheme.primaryColor : color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    final totalCarbs = sports.fold(0.0, (sum, sport) => sum + sport.totalCarbs);
    final totalSodium = sports.fold(
      0.0,
      (sum, sport) => sum + sport.totalSodium,
    );
    final totalFluid = sports.fold(0.0, (sum, sport) => sum + sport.totalFluid);
    final totalCaffeine = sports.fold(
      0.0,
      (sum, sport) => sum + sport.totalCaffeine,
    );

    final targetCarbs = sports.fold(
      0.0,
      (sum, sport) => sum + sport.carbTarget,
    );
    final targetSodium = sports.fold(
      0.0,
      (sum, sport) => sum + sport.sodiumTarget,
    );
    final targetFluid = sports.fold(
      0.0,
      (sum, sport) => sum + sport.fluidTarget,
    );

    final carbsDiff = totalCarbs - targetCarbs;
    final sodiumDiff = totalSodium - targetSodium;
    final fluidDiff = totalFluid - targetFluid;

    return Container(
      padding: EdgeInsets.all(15),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pool,
                color: blackyellowTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Icon(
                Icons.directions_bike,
                color: blackyellowTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Icon(
                Icons.directions_run,
                color: blackyellowTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                widget.isGerman
                    ? 'Gesamt Triathlon Zusammenfassung'
                    : 'Total Triathlon Summary',
                style: sectionTitleStyle,
              ),
            ],
          ),
          SizedBox(height: spacingM),
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              verticalInside: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            columnWidths: {
              0: FlexColumnWidth(
                2.0,
              ), // Breitere erste Spalte für Überschriften
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                children: [
                  TableCell(
                    child: Text('', style: TextStyle(color: Colors.white)),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'target',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'actual',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'diff',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: blackyellowTheme.colorScheme.primary,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Carbohydrates',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${targetCarbs.toInt()}g',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${totalCarbs.toInt()}g',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${carbsDiff > 0 ? '+' : ''}${carbsDiff.toInt()}g',
                        style: TextStyle(
                          color: carbsDiff >= 0
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            color: blackyellowTheme.colorScheme.primary,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Sodium',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${targetSodium.toInt()}mg',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${totalSodium.toInt()}mg',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${sodiumDiff > 0 ? '+' : ''}${sodiumDiff.toInt()}mg',
                        style: TextStyle(
                          color: sodiumDiff >= 0
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_drink,
                            color: blackyellowTheme.colorScheme.primary,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Fluid',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${targetFluid.toInt()}ml',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${totalFluid.toInt()}ml',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${fluidDiff > 0 ? '+' : ''}${fluidDiff.toInt()}ml',
                        style: TextStyle(
                          color: fluidDiff >= 0
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.coffee,
                            color: blackyellowTheme.colorScheme.primary,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Caffeine',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '-',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${totalCaffeine.toInt()}mg',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '-',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              case GelCarbs.g30:
                itemName = 'Energy Gel 30g';
                break;
              case GelCarbs.g40:
                itemName = 'Energy Gel 40g';
                break;
              case GelCarbs.g45:
                itemName = 'Energy Gel 45g';
                break;
              default:
                itemName = 'Energy Gel';
                break;
            }
            if (item.type == NutritionType.caffeineGel) {
              itemName += ' (with Caffeine)';
            }
            break;
          case NutritionType.bar:
            switch (item.barCarbs) {
              case BarCarbs.g20:
                itemName = 'Energy Bar 20g';
                break;
              case BarCarbs.g25:
                itemName = 'Energy Bar 25g';
                break;
              case BarCarbs.g30:
                itemName = 'Energy Bar 30g';
                break;
              default:
                itemName = 'Energy Bar';
                break;
            }
            break;
          case NutritionType.bottle:
            final volume = item.bottleVolume?.toInt() ?? 0;
            final carbs = item.bottleCarbs?.toInt() ?? 0;
            final sodium = item.bottleSodium?.toInt() ?? 0;
            itemName =
                'Sports Drink (${volume}ml, ${carbs}g carbs, ${sodium}mg sodium)';
            break;
          case NutritionType.chews:
            final sodium = item.sodiumAmount.toInt();
            itemName = 'Sodium Chews (${sodium}mg sodium)';
            break;
          case NutritionType.custom:
            itemName = item.customName?.trim().isNotEmpty == true
                ? item.customName!.trim()
                : 'Custom Item';
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
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.isGerman
              ? 'Noch keine Ernährungsartikel hinzugefügt. Fügen Sie Artikel hinzu, um Rennanforderungen zu sehen.'
              : 'No nutrition items added yet. Add items to see race requirements.',
          style: TextStyle(
            color: Colors.black.withOpacity(0.6),
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
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isGerman
                ? 'Rennanforderungen Checkliste'
                : 'Race Requirements Checklist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: spacingS),

          // Sport Sections
          ...sportItems.entries.map(
            (sportEntry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sportEntry.key}:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                ...sportEntry.value.entries.map(
                  (itemEntry) => Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 8),
                    child: Row(
                      children: [
                        Text(
                          '□ ',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          '${itemEntry.value}x ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            itemEntry.key,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacingS),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceRequirementsSection() {
    // Create map to collect items by sport
    final Map<String, Map<String, int>> sportItems = {};

    for (final sport in sports) {
      final Map<String, int> items = {};
      for (final item in sport.nutritionItems) {
        String itemName = '';
        switch (item.type) {
          case NutritionType.gel:
          case NutritionType.caffeineGel:
            switch (item.gelCarbs) {
              case GelCarbs.g30:
                itemName = 'Energy Gel 30g';
                break;
              case GelCarbs.g40:
                itemName = 'Energy Gel 40g';
                break;
              case GelCarbs.g45:
                itemName = 'Energy Gel 45g';
                break;
              default:
                itemName = 'Energy Gel';
                break;
            }
            if (item.type == NutritionType.caffeineGel) {
              itemName += ' (with Caffeine)';
            }
            break;
          case NutritionType.bar:
            switch (item.barCarbs) {
              case BarCarbs.g20:
                itemName = 'Energy Bar 20g';
                break;
              case BarCarbs.g25:
                itemName = 'Energy Bar 25g';
                break;
              case BarCarbs.g30:
                itemName = 'Energy Bar 30g';
                break;
              default:
                itemName = 'Energy Bar';
                break;
            }
            break;
          case NutritionType.bottle:
            final volume = item.bottleVolume?.toInt() ?? 0;
            final carbs = item.bottleCarbs?.toInt() ?? 0;
            final sodium = item.bottleSodium?.toInt() ?? 0;
            itemName =
                'Sports Drink (${volume}ml, ${carbs}g carbs, ${sodium}mg sodium)';
            break;
          case NutritionType.chews:
            final sodium = item.sodiumAmount.toInt();
            itemName = 'Sodium Chews (${sodium}mg sodium)';
            break;
          case NutritionType.custom:
            itemName = item.customName?.trim().isNotEmpty == true
                ? item.customName!.trim()
                : 'Custom Item';
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
        decoration: _panelDecoration(),
        child: Column(
          children: [
            Text(
              widget.isGerman
                  ? 'Rennanforderungen Checkliste'
                  : 'Race Requirements Checklist',
              style: sectionTitleStyle,
            ),
            SizedBox(height: spacingM),
            Text(
              widget.isGerman
                  ? 'Noch keine Ernährungsartikel hinzugefügt. Fügen Sie Artikel hinzu, um Rennanforderungen zu sehen.'
                  : 'No nutrition items added yet. Add items to see race requirements.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(spacingM),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isGerman
                ? 'Rennanforderungen Checkliste'
                : 'Race Requirements Checklist',
            style: sectionTitleStyle,
          ),
          SizedBox(height: spacingM),

          // Sport Sections
          ...sportItems.entries.map(
            (sportEntry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sportEntry.key}:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ...sportEntry.value.entries.map(
                  (itemEntry) => Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 16),
                    child: Row(
                      children: [
                        Text(
                          '□ ',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          '${itemEntry.value}x ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            itemEntry.key,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacingS),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwimmingNote() {
    return Container(
      margin: EdgeInsets.only(bottom: spacingL),
      child: Text(
        widget.isGerman
            ? 'Ernährung während des Schwimmens nicht möglich'
            : 'Nutrition during swimming not possible',
        style: TextStyle(
          color: blackyellowTheme.colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildExportEmailSection() {
    final totalCarbs = sports.fold(0.0, (sum, sport) => sum + sport.totalCarbs);

    // Nur anzeigen wenn Berechnung vorhanden
    if (totalCarbs == 0) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(spacingM),
      decoration: _panelDecoration(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: blackyellowTheme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: spacingS),
              Text(
                widget.isGerman
                    ? 'Ernährungsplan per Email'
                    : 'Nutrition Plan via Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: spacingS),
          Text(
            widget.isGerman
                ? 'Erhalte deinen personalisierten Triathlon-Ernährungsplan kostenlos per Email mit detaillierten Empfehlungen und Einkaufsliste!'
                : 'Get your personalized triathlon nutrition plan for free via email with detailed recommendations and shopping list!',
            style: TextStyle(color: mutedTextColor, fontSize: 14, height: 1.4),
          ),
          SizedBox(height: spacingM),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: emailController,
                  style: inputTextStyle,
                  decoration: _inputDecoration(
                    prefixIcon: Icon(
                      Icons.email,
                      color: blackyellowTheme.colorScheme.primary,
                    ),
                    labelText: widget.isGerman
                        ? 'Email-Adresse'
                        : 'Email Address',
                    hintText: widget.isGerman
                        ? 'deine@email.de'
                        : 'your@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(width: spacingS),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _sendNutritionPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blackyellowTheme.colorScheme.primary,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      widget.isGerman ? 'Senden' : 'Send',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpressumSection() {
    return Container(
      margin: EdgeInsets.only(top: spacingL),
      padding: EdgeInsets.all(spacingM),
      decoration: _panelDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => _showImpressum(),
            child: Text(
              widget.isGerman ? 'Impressum' : 'Imprint',
              style: TextStyle(
                color: blackyellowTheme.colorScheme.primary,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: EdgeInsets.only(top: spacingM),
      padding: EdgeInsets.all(spacingS),
      child: Text(
        '* Affiliate-Link',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showImpressum() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: blackyellowTheme.colorScheme.secondary,
          title: Text(
            widget.isGerman ? 'Impressum' : 'Imprint',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isGerman
                      ? 'Angaben gemäß § 5 TMG'
                      : 'Information according to § 5 TMG',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  widget.isGerman
                      ? 'Jan Drees\nMarie-Curie-Str. 2\n49076 Osnabrück\nDeutschland'
                      : 'Jan Drees\nMarie-Curie-Str. 2\n49076 Osnabrück\nGermany',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                SizedBox(height: 15),
                Text(
                  widget.isGerman ? 'Kontakt' : 'Contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'E-Mail: mail@united-in-pace.com',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                SizedBox(height: 15),
                Text(
                  widget.isGerman ? 'Haftungsausschluss' : 'Disclaimer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  widget.isGerman
                      ? 'Die Inhalte dieser Seite wurden mit größter Sorgfalt erstellt. Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte können wir jedoch keine Gewähr übernehmen.\n\nAffiliate-Links: Diese Seite enthält Affiliate-Links. Beim Kauf über diese Links erhalten wir eine Provision, ohne dass für Sie zusätzliche Kosten entstehen.'
                      : 'The contents of this page have been created with the utmost care. However, we cannot guarantee the accuracy, completeness and timeliness of the content.\n\nAffiliate links: This page contains affiliate links. When you purchase through these links, we receive a commission without any additional costs to you.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                widget.isGerman ? 'Schließen' : 'Close',
                style: TextStyle(color: blackyellowTheme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSipVolumeInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '2. Take an average sip from the bottle (drink normally)',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '3. Measure the bottle weight again',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '4. Calculate the difference (1g = 1ml)',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '5. Repeat this process 3-5 times and enter the average here',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingM),
            Container(
              padding: EdgeInsets.all(spacingS),
              decoration: BoxDecoration(
                color: blackyellowTheme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
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
              widget.isGerman ? 'Verstanden!' : 'Got it!',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '• Medium (750mg/h): Average sweater, moderate conditions',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '• High (1000mg/h): Heavy sweater, hot/humid conditions',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingM),
            Container(
              padding: EdgeInsets.all(spacingS),
              decoration: BoxDecoration(
                color: blackyellowTheme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
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
              widget.isGerman ? 'Verstanden!' : 'Got it!',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '• Medium (750ml/h): Moderate conditions, average needs',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingXS),
            Text(
              '• High (1000ml/h): Hot conditions, high sweat rate',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            SizedBox(height: spacingM),
            Container(
              padding: EdgeInsets.all(spacingS),
              decoration: BoxDecoration(
                color: blackyellowTheme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
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
              widget.isGerman ? 'Verstanden!' : 'Got it!',
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
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildDrinkMixingSection(),
        ],
      ),
    );
  }

  Widget _buildDrinkMixingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isGerman ? 'Empfohlene Produkte:' : 'Recommended Products:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: spacingS),
        Text(
          widget.isGerman
              ? 'Für selbstgemischte Getränke mit optimaler Kohlenhydrataufnahme:'
              : 'For self-mixed drinks with optimal carbohydrate uptake:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        SizedBox(height: spacingS),
        Text(
          widget.isGerman
              ? 'Maltodextrin und Fructose bieten eine sehr kostengünstige Lösung im Vergleich zu teuren Sporternährungsmarken. Mische deine eigenen Getränke zu einem Bruchteil der Kosten und erreiche das gleiche 1:0.8 Glucose-Fructose-Verhältnis wie in Premium-Produkten. Verwende einen Mixer zum Mischen. Füge Zitronensaft für den Geschmack hinzu.'
              : 'Maltodextrin and fructose offer a highly cost-effective solution compared to expensive sports nutrition brands. Mix your own drinks at a fraction of the cost while achieving the same 1:0.8 glucose-fructose ratio used in premium products. Use a mixer to blend maltodextrin and fructose. Add salt for electrolytes. Add lemon juice for flavor.',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
        ),
        SizedBox(height: spacingM),
        Row(
          children: [
            Expanded(
              child: _buildProductCard(
                'Maltodextrin',
                '',
                'assets/images/Malto.png',
                'https://amzn.to/46DJE8J',
              ),
            ),
            SizedBox(width: spacingS),
            Expanded(
              child: _buildProductCard(
                'Fructose',
                '',
                'assets/images/fruchtzucker.png',
                'https://amzn.to/3Kc0kLP',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductCard(
    String title,
    String description,
    String imageUrl,
    String affiliateUrl,
  ) {
    return Container(
      padding: EdgeInsets.all(spacingS),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              imageUrl,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: spacingXS),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacingS),
          ElevatedButton(
            onPressed: () => _launchAffiliateUrl(affiliateUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: blackyellowTheme.colorScheme.primary,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            child: Text(widget.isGerman ? 'ZUM PRODUKT *' : 'TO THE PRODUCT *'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchAffiliateUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  void _sendNutritionPlan() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showErrorDialog(
        widget.isGerman ? 'Ungültige Email-Adresse' : 'Invalid Email Address',
        widget.isGerman
            ? 'Bitte geben Sie eine gültige Email-Adresse ein.'
            : 'Please enter a valid email address.',
      );
      return;
    }

    // Show loading indicator
    _showLoadingDialog();

    try {
      // Send email automatically
      final success = await _sendEmailAutomatically(email);

      Navigator.pop(context); // Close loading dialog

      if (success) {
        _showSuccessDialog();
        emailController.clear();
      } else {
        _showErrorDialog(
          widget.isGerman
              ? 'Email-Versand fehlgeschlagen'
              : 'Email sending failed',
          widget.isGerman
              ? 'Entschuldigung, es gab ein Problem beim Versenden. Bitte versuchen Sie es erneut.'
              : 'Sorry, there was a problem sending the email. Please try again.',
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(
        widget.isGerman ? 'Netzwerkfehler' : 'Network Error',
        widget.isGerman
            ? 'Bitte prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.'
            : 'Please check your internet connection and try again.',
      );
    }
  }

  String _generateNutritionPlanContent() {
    final totalCarbs = sports.fold(0.0, (sum, sport) => sum + sport.totalCarbs);
    final totalSodium = sports.fold(
      0.0,
      (sum, sport) => sum + sport.totalSodium,
    );
    final totalFluid = sports.fold(0.0, (sum, sport) => sum + sport.totalFluid);
    final totalCaffeine = sports.fold(
      0.0,
      (sum, sport) => sum + sport.totalCaffeine,
    );

    if (widget.isGerman) {
      return '''
🏊‍♂️🚴‍♂️🏃‍♂️ DEIN PERSONALISIERTER TRIATHLON ERNÄHRUNGSPLAN

Erstellt mit RATIO - Advanced Sports Nutrition Planning
Website: https://nutrition.united-in-pace.com

═══════════════════════════════════════

📊 ZUSAMMENFASSUNG DEINER BERECHNUNG IM KOMPLETTEN TRIATHLON:
${selectedEventDistance != null ? '\n🏁 Event-Distanz: ${_getEventDistanceName(selectedEventDistance!)}\n' : ''}
• Kohlenhydrate gesamt: ${totalCarbs.toInt()}g
• Natrium gesamt: ${totalSodium.toInt()}mg
• Flüssigkeit gesamt: ${totalFluid.toInt()}ml
• Koffein gesamt: ${totalCaffeine.toInt()}mg

⚙️ TRINK-EINSTELLUNGEN:
• Trinkintervall: ${drinkingInterval.toInt()} Minuten
• Schluckvolumen: ${sipVolume.toInt()}ml

═══════════════════════════════════════

📋 DETAILLIERTE AUFSCHLÜSSELUNG PRO SPORTART:

${_generateSportBreakdown()}

═══════════════════════════════════════

🕒 RACE-DAY TIMELINE:

${_generateTimelineBreakdown()}

═══════════════════════════════════════

📧 Fragen? Schreib uns: mail@united-in-pace.com
🌐 Mehr Tools: https://nutrition.united-in-pace.com

Viel Erfolg bei deinem nächsten Triathlon! 🏆
      ''';
    } else {
      return '''
🏊‍♂️🚴‍♂️🏃‍♂️ YOUR PERSONALIZED TRIATHLON NUTRITION PLAN

Created with RATIO - Advanced Sports Nutrition Planning
Website: https://nutrition.united-in-pace.com

═══════════════════════════════════════

📊 YOUR CALCULATION SUMMARY:
${selectedEventDistance != null ? '\n🏁 Event Distance: ${_getEventDistanceName(selectedEventDistance!)}\n' : ''}
• Total Carbohydrates: ${totalCarbs.toInt()}g
• Total Sodium: ${totalSodium.toInt()}mg
• Total Fluid: ${totalFluid.toInt()}ml
• Total Caffeine: ${totalCaffeine.toInt()}mg

⚙️ DRINKING SETTINGS:
• Drinking interval: ${drinkingInterval.toInt()} minutes
• Sip volume: ${sipVolume.toInt()}ml

═══════════════════════════════════════

📋 DETAILED BREAKDOWN BY SPORT:

${_generateSportBreakdown()}

═══════════════════════════════════════

🕒 RACE-DAY TIMELINE:

${_generateTimelineBreakdown()}

═══════════════════════════════════════


📧 Questions? Email us: mail@united-in-pace.com
🌐 More tools: https://nutrition.united-in-pace.com

Good luck with your next triathlon! 🏆
      ''';
    }
  }

  String _generateSportBreakdown() {
    StringBuffer breakdown = StringBuffer();

    for (final sport in sports) {
      if (sport.nutritionItems.isNotEmpty || sport.carbTarget > 0) {
        breakdown.writeln('');
        breakdown.writeln('🏃 ${sport.sportName.toUpperCase()}');
        breakdown.writeln(
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        );

        // Duration and targets (skip for Pre-Race-Nutrition)
        if (sport.sportName != 'Pre-Race-Nutrition') {
          breakdown.writeln(
            '${widget.isGerman ? 'Dauer' : 'Duration'}: ${sport.durationController.text} ${widget.isGerman ? 'Stunden' : 'hours'}',
          );
          breakdown.writeln('');
        }
        breakdown.writeln('${widget.isGerman ? 'ZIELE' : 'TARGETS'}:');
        breakdown.writeln(
          '• ${widget.isGerman ? 'Kohlenhydrate' : 'Carbohydrates'}: ${sport.carbTarget.toInt()}g',
        );
        breakdown.writeln(
          '• ${widget.isGerman ? 'Natrium' : 'Sodium'}: ${sport.sodiumTarget.toInt()}mg',
        );
        breakdown.writeln(
          '• ${widget.isGerman ? 'Flüssigkeit' : 'Fluid'}: ${sport.fluidTarget.toInt()}ml',
        );
        breakdown.writeln('');

        // Actual vs target comparison
        final carbDiff = sport.totalCarbs - sport.carbTarget;
        final sodiumDiff = sport.totalSodium - sport.sodiumTarget;
        final fluidDiff = sport.totalFluid - sport.fluidTarget;

        breakdown.writeln(
          '${widget.isGerman ? 'TATSÄCHLICHE WERTE' : 'ACTUAL VALUES'}:',
        );
        breakdown.writeln(
          '• ${widget.isGerman ? 'Kohlenhydrate' : 'Carbohydrates'}: ${sport.totalCarbs.toInt()}g (${carbDiff >= 0 ? '+' : ''}${carbDiff.toInt()}g)',
        );
        breakdown.writeln(
          '• ${widget.isGerman ? 'Natrium' : 'Sodium'}: ${sport.totalSodium.toInt()}mg (${sodiumDiff >= 0 ? '+' : ''}${sodiumDiff.toInt()}mg)',
        );
        breakdown.writeln(
          '• ${widget.isGerman ? 'Flüssigkeit' : 'Fluid'}: ${sport.totalFluid.toInt()}ml (${fluidDiff >= 0 ? '+' : ''}${fluidDiff.toInt()}ml)',
        );
        breakdown.writeln('');

        if (sport.nutritionItems.isNotEmpty) {
          breakdown.writeln(
            '${widget.isGerman ? 'ERNÄHRUNGSPRODUKTE' : 'NUTRITION PRODUCTS'}:',
          );
          for (int i = 0; i < sport.nutritionItems.length; i++) {
            final item = sport.nutritionItems[i];
            final description = _getDetailedItemDescription(item);
            breakdown.writeln('${i + 1}. $description');
          }
          breakdown.writeln('');
        }
      }
    }

    return breakdown.toString();
  }

  String _generateTimelineBreakdown() {
    final buffer = StringBuffer();

    for (final sport in sports) {
      final events = _generateTimelineForSport(sport);
      if (events.isEmpty) {
        continue;
      }

      final title = sport.sportName == 'Pre-Race-Nutrition'
          ? 'PRE-RACE'
          : sport.sportName.toUpperCase();
      buffer.writeln(title);
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      for (final event in events) {
        final kmLabel = event.distanceKm == null
            ? ''
            : ' | km ${event.distanceKm!.toStringAsFixed(1)}';
        buffer.writeln(
          '${_formatTimelineOffset(event.offsetMinutes)}$kmLabel | ${event.title} | ${event.detail}',
        );
      }
      buffer.writeln('');
    }

    if (buffer.isEmpty) {
      return widget.isGerman
          ? 'Keine Timeline verfügbar. Bitte füge Dauer, Distanz und Ernährungsartikel hinzu.'
          : 'No timeline available. Please add duration, distance, and nutrition items.';
    }

    return buffer.toString();
  }

  String _getDetailedItemDescription(NutritionItem item) {
    switch (item.type) {
      case NutritionType.gel:
      case NutritionType.caffeineGel:
        final carbValue = item.gelCarbs.toString().split('.').last.substring(1);
        if (widget.isGerman) {
          final caffeine = item.type == NutritionType.caffeineGel
              ? ' (${item.caffeineAmount.toInt()}mg Koffein)'
              : '';
          return '${item.type == NutritionType.caffeineGel ? 'Koffein ' : ''}Gel ${carbValue}g$caffeine - ${item.carbsAmount.toInt()}g Kohlenhydrate, ${item.sodiumAmount.toInt()}mg Natrium';
        } else {
          final caffeine = item.type == NutritionType.caffeineGel
              ? ' (${item.caffeineAmount.toInt()}mg Caffeine)'
              : '';
          return '${item.type == NutritionType.caffeineGel ? 'Caffeine ' : ''}Gel ${carbValue}g$caffeine - ${item.carbsAmount.toInt()}g Carbohydrates, ${item.sodiumAmount.toInt()}mg Sodium';
        }
      case NutritionType.bar:
        final carbValue = item.barCarbs.toString().split('.').last.substring(1);
        if (widget.isGerman) {
          return 'Riegel ${carbValue}g - ${item.carbsAmount.toInt()}g Kohlenhydrate, ${item.sodiumAmount.toInt()}mg Natrium';
        } else {
          return 'Bar ${carbValue}g - ${item.carbsAmount.toInt()}g Carbohydrates, ${item.sodiumAmount.toInt()}mg Sodium';
        }
      case NutritionType.bottle:
        if (widget.isGerman) {
          return 'Flasche ${item.bottleVolume}ml - ${item.carbsAmount.toInt()}g Kohlenhydrate, ${item.sodiumAmount.toInt()}mg Natrium, ${item.fluidAmount.toInt()}ml Flüssigkeit';
        } else {
          return 'Bottle ${item.bottleVolume}ml - ${item.carbsAmount.toInt()}g Carbohydrates, ${item.sodiumAmount.toInt()}mg Sodium, ${item.fluidAmount.toInt()}ml Fluid';
        }
      case NutritionType.chews:
        if (widget.isGerman) {
          return 'Chews - ${item.sodiumAmount.toInt()}mg Natrium (nur Elektrolyte)';
        } else {
          return 'Chews - ${item.sodiumAmount.toInt()}mg Sodium (electrolytes only)';
        }
      case NutritionType.custom:
        final name = item.customName?.trim().isNotEmpty == true
            ? item.customName!.trim()
            : (widget.isGerman ? 'Eigenes Item' : 'Custom item');
        final parts = <String>[];
        if (item.carbsAmount > 0) {
          parts.add(
            widget.isGerman
                ? '${item.carbsAmount.toInt()}g Kohlenhydrate'
                : '${item.carbsAmount.toInt()}g Carbohydrates',
          );
        }
        if (item.sodiumAmount > 0) {
          parts.add(
            widget.isGerman
                ? '${item.sodiumAmount.toInt()}mg Natrium'
                : '${item.sodiumAmount.toInt()}mg Sodium',
          );
        }
        if (item.fluidAmount > 0) {
          parts.add(
            widget.isGerman
                ? '${item.fluidAmount.toInt()}ml Flüssigkeit'
                : '${item.fluidAmount.toInt()}ml Fluid',
          );
        }
        if (item.caffeineAmount > 0) {
          parts.add(
            widget.isGerman
                ? '${item.caffeineAmount.toInt()}mg Koffein'
                : '${item.caffeineAmount.toInt()}mg Caffeine',
          );
        }
        return parts.isEmpty ? name : '$name - ${parts.join(', ')}';
    }
  }

  String _getEventDistanceName(EventDistance distance) {
    switch (distance) {
      case EventDistance.sprint:
        return widget.isGerman ? 'Sprintdistanz' : 'Sprint Distance';
      case EventDistance.olympic:
        return widget.isGerman ? 'Olympische Distanz' : 'Olympic Distance';
      case EventDistance.middle:
        return widget.isGerman ? 'Mitteldistanz' : 'Middle Distance';
      case EventDistance.long:
        return widget.isGerman ? 'Langdistanz' : 'Long Distance';
    }
  }

  Future<bool> _sendEmailAutomatically(String toEmail) async {
    final planContent = _generateNutritionPlanContent();

    final subject = widget.isGerman
        ? 'Dein personalisierter Triathlon Ernährungsplan'
        : 'Your personalized Triathlon Nutrition Plan';

    try {
      // Email über Standard-Email-Client öffnen
      final mailtoUrl =
          'mailto:$toEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(planContent)}';
      final Uri uri = Uri.parse(mailtoUrl);

      if (await launchUrl(uri)) {
        return true;
      }

      // Fallback - Download Dialog wenn Email-Client nicht verfügbar
      await _generateDownloadableFile(toEmail, planContent);
      return true;
    } catch (e) {
      // Last resort - show plan in dialog
      _showPlanInDialog();
      return true;
    }
  }

  Future<void> _generateDownloadableFile(String email, String content) async {
    // For web deployment, we'll trigger a download
    final fileName =
        'triathlon_nutrition_plan_${DateTime.now().millisecondsSinceEpoch}.txt';

    // Create downloadable content
    final blob =
        '''
Email: $email
Generated: ${DateTime.now().toString()}

$content
    ''';

    // In a real web app, you would use dart:html to trigger download
    // For now, we'll show the content in a copyable dialog
    _showDownloadDialog(blob, fileName);
  }

  void _showDownloadDialog(String content, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        title: Row(
          children: [
            Icon(Icons.download, color: blackyellowTheme.colorScheme.primary),
            SizedBox(width: 8),
            Text(
              widget.isGerman ? 'Plan bereit!' : 'Plan Ready!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                widget.isGerman
                    ? 'Dein Ernährungsplan wurde erstellt. Du kannst ihn kopieren oder als Datei speichern:'
                    : 'Your nutrition plan has been created. You can copy it or save it as a file:',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              widget.isGerman ? 'Schließen' : 'Close',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard functionality could be added here
              Navigator.pop(context);
              _showSuccessDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: blackyellowTheme.colorScheme.primary,
              foregroundColor: Colors.black,
            ),
            child: Text(widget.isGerman ? 'Fertig' : 'Done'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                blackyellowTheme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 20),
            Text(
              widget.isGerman ? 'Email wird versendet...' : 'Sending email...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        title: Text(title, style: TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: blackyellowTheme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        title: Row(
          children: [
            Text(
              widget.isGerman ? 'Email senden!' : 'Send Email!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          widget.isGerman
              ? 'Es sollte sich nun dein E-Mail-Programm öffnen. Damit kannst du die E-Mail mit deinem Ernährungsplan versenden.'
              : 'Your email program should now open. You can use it to send the email with your nutrition plan.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              widget.isGerman ? 'Super!' : 'Great!',
              style: TextStyle(color: blackyellowTheme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanInDialog() {
    final planContent = _generateNutritionPlanContent();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blackyellowTheme.colorScheme.secondary,
        title: Text(
          widget.isGerman ? 'Dein Ernährungsplan' : 'Your Nutrition Plan',
          style: TextStyle(color: Colors.white),
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              planContent,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              widget.isGerman ? 'Schließen' : 'Close',
              style: TextStyle(color: blackyellowTheme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

enum GlucoseFructoseRatio {
  ratio1to08('1:0.8'),
  ratio2to1('2:1');

  const GlucoseFructoseRatio(this.displayName);
  final String displayName;
}

class GlucoseFructoseCalculatorWidget extends StatefulWidget {
  final bool isGerman;
  const GlucoseFructoseCalculatorWidget({Key? key, required this.isGerman})
    : super(key: key);

  @override
  GlucoseFructoseCalculatorWidgetState createState() =>
      GlucoseFructoseCalculatorWidgetState();
}

class GlucoseFructoseCalculatorWidgetState
    extends State<GlucoseFructoseCalculatorWidget> {
  double maltoRatio = 1.8;
  double amountWaterRatio = 9.375;
  GlucoseFructoseRatio selectedRatio = GlucoseFructoseRatio.ratio1to08;
  TextEditingController carbAmount = TextEditingController();
  String resultMalto = '';
  String resultFructose = '';
  String resultAmountWater = '';
  double get cardRadius => appPanelRadius;
  double get fieldRadius => 6;

  Color get panelColor => appPanelColor;
  Color get fieldColor => Color(0xFF242424);
  Color get hintColor => Colors.white.withOpacity(0.5);

  InputDecoration _calculatorInputDecoration() {
    return InputDecoration(
      prefixIcon: Icon(
        Icons.calculate,
        color: blackyellowTheme.colorScheme.primary,
      ),
      suffixText: 'g',
      suffixStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      labelText: widget.isGerman
          ? 'Kohlenhydratmenge in g'
          : 'Carb amount in g',
      filled: true,
      fillColor: fieldColor,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: TextStyle(color: hintColor, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(
          color: blackyellowTheme.colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  void calculateCarbAmount() {
    final carbAmountValue = double.tryParse(carbAmount.text);
    if (carbAmountValue != null) {
      double malto, fructose;

      if (selectedRatio == GlucoseFructoseRatio.ratio1to08) {
        malto = carbAmountValue / maltoRatio;
        fructose = carbAmountValue / maltoRatio * 0.8;
      } else {
        malto = carbAmountValue * (2.0 / 3.0);
        fructose = carbAmountValue * (1.0 / 3.0);
      }

      var amountWater = amountWaterRatio * carbAmountValue;
      setState(() {
        resultMalto = '${malto.toStringAsFixed(1)} g';
        resultFructose = '${fructose.toStringAsFixed(1)} g';
        resultAmountWater = '${amountWater.toStringAsFixed(1)} ml';
      });
    } else {
      setState(() {
        if (carbAmount.text.isEmpty) {
          resultMalto = '';
          resultFructose = '';
          resultAmountWater = '';
        }
      });
    }
  }

  void _showRatioInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: blackyellowTheme.colorScheme.secondary,
          title: Text(
            'Glucose-Fructose Ratio Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1:0.8 Ratio (Recommended)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Optimal for most endurance sports\n• Better gastric emptying\n• Lower risk of GI issues\n• Maximizes carb absorption (~90g/hour)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '2:1 Ratio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Traditional sports nutrition ratio\n• Higher glucose content\n• Good for shorter events\n• May cause GI stress at high rates',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: blackyellowTheme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 25.0, bottom: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isGerman
                    ? 'Glucose-Fructose Verhältnis Rechner'
                    : 'Glucose-Fructose Ratio Calculator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isGerman
                    ? 'Geben Sie die Menge der Kohlenhydrate in g ein'
                    : 'Enter the amount of carbs in g',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(15),
          decoration: appPanelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ratio Dropdown
              Row(
                children: [
                  Text(
                    widget.isGerman ? 'Verhältnis: ' : 'Ratio: ',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(fieldRadius),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: DropdownButton<GlucoseFructoseRatio>(
                      value: selectedRatio,
                      dropdownColor: panelColor,
                      iconEnabledColor: blackyellowTheme.colorScheme.primary,
                      underline: SizedBox.shrink(),
                      isDense: true,
                      style: TextStyle(color: Colors.white, fontSize: 14),
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
                          calculateCarbAmount();
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showRatioInfoDialog(),
                    child: Icon(Icons.info_outline, color: Colors.white, size: 20),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Input Field
              TextFormField(
                maxLength: 6,
                controller: carbAmount,
                style: TextStyle(color: Colors.white),
                cursorColor: blackyellowTheme.colorScheme.primary,
                decoration: _calculatorInputDecoration(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  calculateCarbAmount();
                },
              ),

              // Results
              if (resultMalto.isNotEmpty && resultFructose.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.only(top: 0),
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isGerman
                            ? 'Menge Maltodextrin: $resultMalto'
                            : 'Amount of Maltodextrin: $resultMalto',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.isGerman
                            ? 'Menge Fructose: $resultFructose'
                            : 'Amount of Fructose: $resultFructose',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.isGerman
                            ? 'Sie sollten es mit $resultAmountWater Wasser mischen'
                            : 'You should mix it with: $resultAmountWater water',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

}

class _NutritionDialog extends StatefulWidget {
  final NutritionType type;
  final bool isGerman;
  final Function(NutritionItem) onAdd;
  final NutritionItem? existingItem;

  const _NutritionDialog({
    required this.type,
    required this.isGerman,
    required this.onAdd,
    this.existingItem,
  });

  @override
  State<_NutritionDialog> createState() => _NutritionDialogState();
}

class _NutritionDialogState extends State<_NutritionDialog> {
  static const double spacingS = 12.0;
  Color get fieldColor => Color(0xFF242424);
  Color get hintColor => Colors.white.withOpacity(0.5);
  double get fieldRadius => 6;

  InputDecoration _dialogInputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      hintStyle: TextStyle(color: hintColor),
      labelStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: fieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(
          color: blackyellowTheme.colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  String _getGermanTypeName(NutritionType type) {
    switch (type) {
      case NutritionType.gel:
        return 'Gel';
      case NutritionType.caffeineGel:
        return 'Koffein Gel';
      case NutritionType.bar:
        return 'Riegel';
      case NutritionType.bottle:
        return 'Flasche';
      case NutritionType.chews:
        return 'Chews';
      case NutritionType.custom:
        return 'Eigenes Item';
    }
  }

  ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: blackyellowTheme.colorScheme.primary,
    foregroundColor: Colors.black,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.3),
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  );

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

    // Pre-populate fields if editing existing item
    if (widget.existingItem != null) {
      final item = widget.existingItem!;

      switch (item.type) {
        case NutritionType.gel:
        case NutritionType.caffeineGel:
          selectedGelCarbs = item.gelCarbs ?? GelCarbs.g30;
          if (item.customSodium != null) {
            sodiumController.text = item.customSodium!.toString();
          }
          if (item.type == NutritionType.caffeineGel && item.caffeine != null) {
            caffeineController.text = item.caffeine!.toString();
          }
          break;
        case NutritionType.bar:
          selectedBarCarbs = item.barCarbs ?? BarCarbs.g25;
          break;
        case NutritionType.bottle:
          if (item.bottleVolume != null) {
            volumeController.text = item.bottleVolume!.toString();
          }
          if (item.bottleCarbs != null) {
            carbsController.text = item.bottleCarbs!.toString();
          }
          if (item.customSodium != null) {
            sodiumController.text = item.customSodium!.toString();
          }
          break;
        case NutritionType.chews:
          if (item.customSodium != null) {
            sodiumController.text = item.customSodium!.toString();
          }
          break;
        case NutritionType.custom:
          nameController.text = item.customName ?? '';
          carbsController.text = item.customCarbs?.toString() ?? '';
          sodiumController.text = item.customSodium?.toString() ?? '';
          volumeController.text = item.customFluid?.toString() ?? '';
          caffeineController.text = item.caffeine?.toString() ?? '';
          break;
      }
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
      backgroundColor: Color(0xFF161616),
      title: Text(
        widget.existingItem != null
            ? (widget.isGerman
                  ? 'Bearbeiten ${_getGermanTypeName(widget.type)}'
                  : 'Edit ${widget.type.toString().split('.').last[0].toUpperCase()}${widget.type.toString().split('.').last.substring(1)}')
            : (widget.isGerman
                  ? 'Hinzufügen ${_getGermanTypeName(widget.type)}'
                  : 'Add ${widget.type.toString().split('.').last[0].toUpperCase()}${widget.type.toString().split('.').last.substring(1)}'),
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.type == NutritionType.gel ||
                widget.type == NutritionType.caffeineGel) ...[
              Text(
                widget.isGerman
                    ? 'Kohlenhydratgehalt:'
                    : 'Carbohydrate content:',
                style: TextStyle(color: Colors.white),
              ),
              DropdownButton<GelCarbs>(
                value: selectedGelCarbs,
                dropdownColor: Color(0xFF161616),
                iconEnabledColor: blackyellowTheme.colorScheme.primary,
                style: TextStyle(color: Colors.white),
                items: GelCarbs.values.map((carbs) {
                  String displayText;
                  final value = carbs
                      .toString()
                      .split('.')
                      .last
                      .substring(1); // Remove 'g' prefix
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
                  style: TextStyle(color: Colors.white),
                  decoration: _dialogInputDecoration(
                    labelText: widget.isGerman
                        ? 'Koffein (mg)'
                        : 'Caffeine (mg)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              SizedBox(height: spacingS),
              TextFormField(
                controller: sodiumController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                ),
                keyboardType: TextInputType.number,
              ),
            ] else if (widget.type == NutritionType.bar) ...[
              Text(
                widget.isGerman
                    ? 'Kohlenhydratgehalt:'
                    : 'Carbohydrate content:',
                style: TextStyle(color: Colors.white),
              ),
              DropdownButton<BarCarbs>(
                value: selectedBarCarbs,
                dropdownColor: Color(0xFF161616),
                iconEnabledColor: blackyellowTheme.colorScheme.primary,
                style: TextStyle(color: Colors.white),
                items: BarCarbs.values.map((carbs) {
                  final value = carbs
                      .toString()
                      .split('.')
                      .last
                      .substring(1); // Remove 'g' prefix
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
              SizedBox(height: spacingS),
              TextFormField(
                controller: sodiumController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                ),
                keyboardType: TextInputType.number,
              ),
            ] else if (widget.type == NutritionType.bottle) ...[
              TextFormField(
                controller: volumeController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  prefixIcon: Icon(
                    Icons.local_drink,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman ? 'Volumen (ml)' : 'Volume (ml)',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: carbsController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  prefixIcon: Icon(
                    Icons.bolt,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman
                      ? 'Kohlenhydrate (g)'
                      : 'Carbohydrates (g)',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: sodiumController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                ),
                keyboardType: TextInputType.number,
              ),
            ] else if (widget.type == NutritionType.chews) ...[
              TextFormField(
                controller: sodiumController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                  hintText: '40',
                ),
                keyboardType: TextInputType.number,
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
              TextFormField(
                controller: nameController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  labelText: widget.isGerman ? 'Bezeichnung' : 'Label',
                  hintText: widget.isGerman ? 'z. B. Banane' : 'e.g. Banana',
                  prefixIcon: Icon(
                    Icons.label,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: carbsController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  prefixIcon: Icon(
                    Icons.bolt,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman
                      ? 'Kohlenhydrate (g)'
                      : 'Carbohydrates (g)',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: sodiumController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  prefixIcon: Icon(
                    Icons.water_drop,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman ? 'Natrium (mg)' : 'Sodium (mg)',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: volumeController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  prefixIcon: Icon(
                    Icons.local_drink,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman
                      ? 'Flüssigkeit (ml)'
                      : 'Fluid (ml)',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: spacingS),
              TextFormField(
                controller: caffeineController,
                style: TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration(
                  prefixIcon: Icon(
                    Icons.coffee,
                    color: blackyellowTheme.colorScheme.primary,
                  ),
                  labelText: widget.isGerman ? 'Koffein (mg)' : 'Caffeine (mg)',
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
          child: Text(
            widget.isGerman ? 'Abbrechen' : 'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final item = NutritionItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
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
              customSodium:
                  (widget.type == NutritionType.gel ||
                      widget.type == NutritionType.caffeineGel ||
                      widget.type == NutritionType.bar ||
                      widget.type == NutritionType.chews ||
                      widget.type == NutritionType.custom)
                  ? double.tryParse(sodiumController.text)
                  : null,
              caffeine:
                  (widget.type == NutritionType.caffeineGel ||
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
            );

            widget.onAdd(item);
            Navigator.of(context).pop();
          },
          style: primaryButtonStyle,
          child: Text(
            widget.existingItem != null
                ? (widget.isGerman ? 'Speichern' : 'Save')
                : (widget.isGerman ? 'Hinzufügen' : 'Add'),
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
