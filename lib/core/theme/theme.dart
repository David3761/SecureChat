import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF4A86F7);
  static const Color title = Color(0xFF35353D);
  static const Color grey = Color(0xFF8B98A9);
  static const Color secondaryBackground = Color(0xFFF6F5F3);
  static const Color darkerSecondaryBackground = Color(0xFFE9E8E5);
  static const Color onSecondaryBackground = Color(0xFF656462);
  static const Color body = Color(0xFF6A7185);
  static const Color stroke = Color(0xFFE9EDF1);
  static const Color background = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color red = Color(0xFFD94841);
  static const Color skyBlue = Color(0xFF57B6F0);

  static const Color darkBackground = Color(0xFF121212);

  static const List<Color> avatarColors = [
    Color(0xFF57B6F0),
    Color(0xFFD94841),
    Color(0xFFF2A84C),
    Color(0xFF83BF6E),
    Color(0xFF670FCD),
  ];

  static const Gradient blueGradient = LinearGradient(
    colors: [Color(0xFF4A86F7), Color(0xFF2448B1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient greenGradient = LinearGradient(
    colors: [Color(0xFF73BC78), Color(0xFF438A62)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    const textTheme = TextTheme(
      // DISPLAYS: Huge, expressive headers (Onboarding, Empty States)
      displayLarge: TextStyle(
        color: AppColors.title,
        fontWeight: FontWeight.w800,
        fontSize: 40,
        letterSpacing: -1.2,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        color: AppColors.title,
        fontWeight: FontWeight.w800,
        fontSize: 32,
        letterSpacing: -0.8,
        height: 1.15,
      ),
      displaySmall: TextStyle(
        color: AppColors.title,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.6,
      ),

      // HEADLINES: Main screen headers (e.g., "Chats", "Profile")
      headlineLarge: TextStyle(
        color: AppColors.title,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: AppColors.title,
        fontWeight: FontWeight.bold,
        fontSize: 20,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        color: AppColors.title,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        letterSpacing: -0.2,
      ),

      // TITLES: Dialog headers, AppBars, ListTile titles
      titleLarge: TextStyle(
        color: AppColors.title,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        color: AppColors.title,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        color: AppColors.onSecondaryBackground,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),

      // BODY: Standard paragraphs, list item subtitles
      bodyLarge: TextStyle(
        color: AppColors.title,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.body,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: AppColors.grey,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        letterSpacing: 0.2,
      ),

      // LABELS: Buttons, overlines, tiny status text
      labelLarge: TextStyle(
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        color: AppColors.body,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        color: AppColors.red,
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 0.3,
        height: 1.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryBlue,
      textTheme: GoogleFonts.interTextTheme(textTheme),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.skyBlue,
        error: AppColors.red,
        surface: AppColors.background,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.title,
        onError: AppColors.white,
        outline: AppColors.stroke,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        centerTitle: true,
        elevation: 0,
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryBlue,
        selectionColor: AppColors.skyBlue,
        selectionHandleColor: AppColors.primaryBlue,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 20.0,
        ),

        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.labelLarge,
        hintStyle: textTheme.bodySmall,
        errorStyle: textTheme.labelSmall,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.stroke, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.stroke, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.red, width: 2.0),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color.fromARGB(104, 158, 158, 158),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
