import 'package:flutter/material.dart';

class AppTheme {
  // Shared text theme (adjust font family as needed, Roboto is a good default)
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, fontFamily: 'Roboto'), // Often used for AppBar titles
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
    bodyLarge: TextStyle(fontSize: 16.0, fontFamily: 'Roboto'),
    bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Roboto'), // Default text style
    bodySmall: TextStyle(fontSize: 12.0, fontFamily: 'Roboto'),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, fontFamily: 'Roboto'), // For buttons
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00C853), // Energetic Green
    scaffoldBackgroundColor: const Color(0xFF121212), // Very dark gray, almost black
    cardColor: const Color(0xFF1E1E1E), // Dark gray for cards/elements
    hintColor: const Color(0xFFA0A0A0), // Secondary text
    textTheme: _textTheme.apply(
      bodyColor: const Color(0xFFE0E0E0), // Very light gray for main text
      displayColor: const Color(0xFFFFFFFF), // White for larger display text
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00C853), // Energetic Green
      secondary: Color(0xFF4CAF50), // Slightly less vibrant green or another accent
      surface: Color(0xFF1E1E1E), // Card background
      background: Color(0xFF121212), // Main background
      error: Colors.redAccent,
      onPrimary: Colors.black, // Text on primary color buttons
      onSecondary: Colors.black,
      onSurface: Color(0xFFE0E0E0), // Text on cards
      onBackground: Color(0xFFE0E0E0), // Text on main background
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 0,
      titleTextStyle: _textTheme.titleLarge?.copyWith(color: const Color(0xFFFFFFFF)),
      iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00C853), // Energetic Green
      foregroundColor: Colors.black,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF00C853); // Energetic Green
        }
        return null; // Default
      }),
      checkColor: MaterialStateProperty.all(Colors.black), // Color of the check mark
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF00C853); // Energetic Green
        }
        return null; // Default
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00C853), // Energetic Green
        foregroundColor: Colors.black,
        textStyle: _textTheme.labelLarge?.copyWith(color: Colors.black),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF00C853), // Energetic Green
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFF00C853)), // Energetic Green
      ),
      hintStyle: TextStyle(color: const Color(0xFFA0A0A0).withOpacity(0.6)),
      labelStyle: const TextStyle(color: Color(0xFF00C853)),
    ),
    // Add other theme properties as needed (slider, switch, etc.)
  );

  // Light Theme (Optional, but good practice)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF00C853), // Energetic Green
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light gray background
    cardColor: Colors.white,
    hintColor: const Color(0xFF616161), // Darker gray for secondary text
    textTheme: _textTheme.apply(
      bodyColor: const Color(0xFF212121), // Nearly black for main text
      displayColor: Colors.black,
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00C853),
      secondary: Color(0xFF4CAF50),
      surface: Colors.white,
      background: Color(0xFFF5F5F5),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFF212121),
      onBackground: Color(0xFF212121),
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF00C853),
      elevation: 1,
      titleTextStyle: _textTheme.titleLarge?.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00C853),
      foregroundColor: Colors.white,
    ),
     checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF00C853); // Energetic Green
        }
        return null; // Default
      }),
      checkColor: MaterialStateProperty.all(Colors.white), // Color of the check mark
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF00C853); // Energetic Green
        }
        return null; // Default
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00C853),
        foregroundColor: Colors.white,
        textStyle: _textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF00C853),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFF00C853)),
      ),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      labelStyle: const TextStyle(color: Color(0xFF00C853)),
    ),
  );
}
