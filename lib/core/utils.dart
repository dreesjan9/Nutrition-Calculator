import 'package:nutrition_calculator_app/core/enums.dart';

String getSweatRateLabel(SweatRate rate, bool isGerman) {
  switch (rate) {
    case SweatRate.low:
      return isGerman ? 'Niedrig (ca. 500mg Na+/h)' : 'Low (~500mg Na+/h)';
    case SweatRate.medium:
      return isGerman ? 'Mittel (ca. 750mg Na+/h)' : 'Medium (~750mg Na+/h)';
    case SweatRate.high:
      return isGerman ? 'Hoch (ca. 1000mg Na+/h)' : 'High (~1000mg Na+/h)';
  }
}

String getSweatRateCompactLabel(SweatRate rate, bool isGerman) {
  switch (rate) {
    case SweatRate.low:
      return isGerman ? 'Niedrig' : 'Low';
    case SweatRate.medium:
      return isGerman ? 'Mittel' : 'Medium';
    case SweatRate.high:
      return isGerman ? 'Hoch' : 'High';
  }
}

String getFluidRateLabel(FluidRate rate, bool isGerman) {
  switch (rate) {
    case FluidRate.low:
      return isGerman ? 'Niedrig (ca. 500ml/h)' : 'Low (~500ml/h)';
    case FluidRate.medium:
      return isGerman ? 'Mittel (ca. 700ml/h)' : 'Medium (~700ml/h)';
    case FluidRate.high:
      return isGerman ? 'Hoch (ca. 900ml/h)' : 'High (~900ml/h)';
  }
}

String getFluidRateCompactLabel(FluidRate rate, bool isGerman) {
  switch (rate) {
    case FluidRate.low:
      return isGerman ? 'Niedrig' : 'Low';
    case FluidRate.medium:
      return isGerman ? 'Mittel' : 'Medium';
    case FluidRate.high:
      return isGerman ? 'Hoch' : 'High';
  }
}
