import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

final Color primaryButtonColor = Color.fromRGBO(237, 189, 107, 1);
final Color navigationColor = Color.fromRGBO(24, 24, 24, 1);
final Color primaryColor = Color(0xFFEDBD6B);
final Color buttonTextColor = Colors.black;

final ThemeData blackyellowTheme = ThemeData(
  colorScheme: ColorScheme.fromSwatch(primarySwatch: createMaterialColor(primaryButtonColor), accentColor: navigationColor),
  primaryColor: primaryButtonColor,
  fontFamily: GoogleFonts.openSans().fontFamily,
  
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
    dayOverlayColor: WidgetStateProperty.all(primaryButtonColor.withValues(alpha: 0.1)),
    yearOverlayColor: WidgetStateProperty.all(primaryButtonColor.withValues(alpha: 0.1)),
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
  ),
  
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    bodySmall: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    displayLarge: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    displayMedium: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    displaySmall: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    headlineLarge: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    headlineMedium: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    headlineSmall: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    titleSmall: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    labelLarge: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
    labelSmall: TextStyle(
      decoration: TextDecoration.none,
      color: Colors.white,
    ),
  ),
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
    50: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .1),
    100: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .2),
    200: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .3),
    300: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .4),
    400: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .5),
    500: color,
    600: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .7),
    700: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .8),
    800: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), .9),
    900: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), 1),
  };
  return MaterialColor(color.value & 0xFFFFFFFF, swatch);
}

// Cupertino Theme für einheitliche Modal-Designs
final CupertinoThemeData cupertinoTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryButtonColor,
  scaffoldBackgroundColor: Colors.black,
  barBackgroundColor: navigationColor,
  textTheme: CupertinoTextThemeData(
    primaryColor: Colors.white,
    textStyle: TextStyle(
      color: Colors.white,
      fontFamily: GoogleFonts.openSans().fontFamily,
      decoration: TextDecoration.none,
    ),
    actionTextStyle: TextStyle(
      color: primaryButtonColor,
      fontFamily: GoogleFonts.openSans().fontFamily,
      decoration: TextDecoration.none,
    ),
    navTitleTextStyle: TextStyle(
      color: Colors.white,
      fontFamily: GoogleFonts.openSans().fontFamily,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none,
    ),
    navActionTextStyle: TextStyle(
      color: primaryButtonColor,
      fontFamily: GoogleFonts.openSans().fontFamily,
      decoration: TextDecoration.none,
    ),
    navLargeTitleTextStyle: TextStyle(
      color: Colors.white,
      fontFamily: GoogleFonts.openSans().fontFamily,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none,
    ),
    pickerTextStyle: TextStyle(
      color: Colors.white,
      fontFamily: GoogleFonts.openSans().fontFamily,
      decoration: TextDecoration.none,
    ),
    dateTimePickerTextStyle: TextStyle(
      color: Colors.white,
      fontFamily: GoogleFonts.openSans().fontFamily,
      decoration: TextDecoration.none,
    ),
    tabLabelTextStyle: TextStyle(
      color: Colors.white,
      fontFamily: GoogleFonts.openSans().fontFamily,
      decoration: TextDecoration.none,
    ),
  ),
);

// Helper Widget für einheitliche Modal-Container
class CustomModalContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CustomModalContainer({
    Key? key,
    required this.child,
    this.height,
    this.padding,
  }) : super(key: key);

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

  const ModalHeader({
    Key? key,
    required this.title,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryButtonColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: GoogleFonts.openSans().fontFamily,
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