import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

final Color primaryButtonColor = Color.fromRGBO(237, 189, 107, 1);
final Color navigationColor = Color.fromRGBO(24, 24, 24, 1);
final Color primaryColor = Color(0xFFEDBD6B);
final Color buttonTextColor = Colors.black;
const Color appPanelColor = Color(0xFF1C1C1C);
const Color appPanelHighlightColor = Color(0xFF161616);
const double appPanelRadius = 16;

TextTheme _appTextTheme(TextTheme base) {
  final barlowTextTheme = GoogleFonts.barlowTextTheme(base).apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
    decoration: TextDecoration.none,
  );

  TextStyle? oswald(TextStyle? style) => style == null
      ? null
      : GoogleFonts.oswald(
          textStyle: style.copyWith(
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        );

  return barlowTextTheme.copyWith(
    displayLarge: oswald(barlowTextTheme.displayLarge),
    displayMedium: oswald(barlowTextTheme.displayMedium),
    displaySmall: oswald(barlowTextTheme.displaySmall),
    headlineLarge: oswald(barlowTextTheme.headlineLarge),
    headlineMedium: oswald(barlowTextTheme.headlineMedium),
    headlineSmall: oswald(barlowTextTheme.headlineSmall),
    titleLarge: oswald(barlowTextTheme.titleLarge),
    titleMedium: oswald(barlowTextTheme.titleMedium),
    titleSmall: oswald(barlowTextTheme.titleSmall),
  );
}

final ThemeData blackyellowTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: createMaterialColor(primaryButtonColor),
    accentColor: navigationColor,
  ),
  primaryColor: primaryButtonColor,
  fontFamily: GoogleFonts.barlow().fontFamily,

  // Global Picker Themes
  datePickerTheme: DatePickerThemeData(
    backgroundColor: Color.fromRGBO(24, 24, 24, 1),
    surfaceTintColor: Colors.transparent,
    headerBackgroundColor: primaryButtonColor,
    headerForegroundColor: Colors.black,
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.black;
      }
      return Colors.white;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return primaryButtonColor;
      }
      return Colors.transparent;
    }),
    todayForegroundColor: WidgetStateProperty.all(primaryButtonColor),
    todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
    yearForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.black;
      }
      return Colors.white;
    }),
    yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return primaryButtonColor;
      }
      return Colors.transparent;
    }),
    dayOverlayColor: WidgetStateProperty.all(
      primaryButtonColor.withOpacity(0.1),
    ),
    yearOverlayColor: WidgetStateProperty.all(
      primaryButtonColor.withOpacity(0.1),
    ),
  ),

  timePickerTheme: TimePickerThemeData(
    backgroundColor: Color.fromRGBO(24, 24, 24, 1),
    dialBackgroundColor: Color.fromRGBO(40, 40, 40, 1),
    dialHandColor: primaryButtonColor,
    dialTextColor: Colors.white,
    hourMinuteTextColor: Colors.white,
    hourMinuteColor: Color.fromRGBO(40, 40, 40, 1),
    dayPeriodTextColor: Colors.white,
    dayPeriodColor: Color.fromRGBO(40, 40, 40, 1),
    entryModeIconColor: primaryButtonColor,
  ),

  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: Color.fromRGBO(24, 24, 24, 1),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    modalBackgroundColor: Color.fromRGBO(24, 24, 24, 1),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: Color.fromRGBO(24, 24, 24, 1),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    titleTextStyle: GoogleFonts.oswald(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: GoogleFonts.barlow(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
  ),
  textTheme: _appTextTheme(ThemeData.dark().textTheme),
  primaryTextTheme: _appTextTheme(ThemeData.dark().primaryTextTheme),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all<Color>(primaryButtonColor),
      shape: WidgetStateProperty.all<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Add radius here
        ),
      ),
      foregroundColor: WidgetStateProperty.all<Color>(buttonTextColor),
    ),
  ),
);

// Define a custom MaterialColor
MaterialColor createMaterialColor(Color color) {
  Map<int, Color> swatch = {
    50: Color.fromRGBO(color.red, color.green, color.blue, .1),
    100: Color.fromRGBO(color.red, color.green, color.blue, .2),
    200: Color.fromRGBO(color.red, color.green, color.blue, .3),
    300: Color.fromRGBO(color.red, color.green, color.blue, .4),
    400: Color.fromRGBO(color.red, color.green, color.blue, .5),
    500: color,
    600: Color.fromRGBO(color.red, color.green, color.blue, .7),
    700: Color.fromRGBO(color.red, color.green, color.blue, .8),
    800: Color.fromRGBO(color.red, color.green, color.blue, .9),
    900: Color.fromRGBO(color.red, color.green, color.blue, 1),
  };
  return MaterialColor(color.value, swatch);
}

// Cupertino Theme für einheitliche Modal-Designs
final CupertinoThemeData cupertinoTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryButtonColor,
  scaffoldBackgroundColor: Colors.black,
  barBackgroundColor: navigationColor,
  textTheme: CupertinoTextThemeData(
    primaryColor: Colors.white,
    textStyle: GoogleFonts.barlow(
      color: Colors.white,
      decoration: TextDecoration.none,
    ),
    actionTextStyle: GoogleFonts.barlow(
      color: primaryButtonColor,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
    navTitleTextStyle: GoogleFonts.oswald(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none,
    ),
    navActionTextStyle: GoogleFonts.barlow(
      color: primaryButtonColor,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
    navLargeTitleTextStyle: GoogleFonts.oswald(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none,
    ),
    pickerTextStyle: GoogleFonts.barlow(
      color: Colors.white,
      decoration: TextDecoration.none,
    ),
    dateTimePickerTextStyle: GoogleFonts.barlow(
      color: Colors.white,
      decoration: TextDecoration.none,
    ),
    tabLabelTextStyle: GoogleFonts.barlow(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    ),
  ),
);

BoxDecoration appPanelDecoration({bool highlighted = false}) {
  return BoxDecoration(
    color: highlighted ? appPanelHighlightColor : appPanelColor,
    borderRadius: BorderRadius.circular(appPanelRadius),
    border: Border.all(
      color: highlighted
          ? primaryButtonColor.withOpacity(0.18)
          : Colors.white.withOpacity(0.05),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.16),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

// Helper Widget für einheitliche Modal-Container
class CustomModalContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CustomModalContainer({
    super.key,
    required this.child,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: navigationColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      padding: padding ?? EdgeInsets.all(20),
      child: child,
    );
  }
}

// Helper für einheitliche Modal-Header
class ModalHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const ModalHeader({super.key, required this.title, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: primaryButtonColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
