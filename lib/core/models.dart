import 'package:nutrition_calculator_app/core/enums.dart';

class NutritionItem {
  final String id;
  final NutritionType type;
  final GelCarbs? gelCarbs;
  final BarCarbs? barCarbs;
  final double? bottleVolume;
  final double? bottleCarbs;
  final double? bottleSodium;
  final double? customSodium;
  final double? caffeine;
  final String? customName;
  final double? customCarbs;
  final double? customFluid;

  NutritionItem({
    required this.id,
    required this.type,
    this.gelCarbs,
    this.barCarbs,
    this.bottleVolume,
    this.bottleCarbs,
    this.bottleSodium,
    this.customSodium,
    this.caffeine,
    this.customName,
    this.customCarbs,
    this.customFluid,
  });

  double get carbsAmount {
    switch (type) {
      case NutritionType.gel:
      case NutritionType.caffeineGel:
        switch (gelCarbs) {
          case GelCarbs.g30:
            return 30.0;
          case GelCarbs.g40:
            return 40.0;
          case GelCarbs.g45:
            return 45.0;
          default:
            return 0.0;
        }
      case NutritionType.bar:
        switch (barCarbs) {
          case BarCarbs.g20:
            return 20.0;
          case BarCarbs.g25:
            return 25.0;
          case BarCarbs.g30:
            return 30.0;
          default:
            return 0.0;
        }
      case NutritionType.bottle:
        return bottleCarbs ?? 0.0;
      case NutritionType.chews:
        return 0.0;
      case NutritionType.custom:
        return customCarbs ?? 0.0;
    }
  }

  double get sodiumAmount {
    switch (type) {
      case NutritionType.gel:
      case NutritionType.caffeineGel:
        return customSodium ?? 50.0;
      case NutritionType.bar:
        return customSodium ?? 30.0;
      case NutritionType.bottle:
        return bottleSodium ?? 0.0;
      case NutritionType.chews:
        return customSodium ?? 40.0;
      case NutritionType.custom:
        return customSodium ?? 0.0;
    }
  }

  double get fluidAmount {
    switch (type) {
      case NutritionType.gel:
      case NutritionType.caffeineGel:
        return 0.0;
      case NutritionType.bar:
        return 0.0;
      case NutritionType.bottle:
        return bottleVolume ?? 0.0;
      case NutritionType.chews:
        return 0.0;
      case NutritionType.custom:
        return customFluid ?? 0.0;
    }
  }

  double get caffeineAmount => caffeine ?? 0.0;
}

class TimelineEvent {
  final String sportName;
  final TimelineEventType type;
  final int offsetMinutes;
  final double? distanceKm;
  final String title;
  final String detail;

  TimelineEvent({
    required this.sportName,
    required this.type,
    required this.offsetMinutes,
    this.distanceKm,
    required this.title,
    required this.detail,
  });
}
