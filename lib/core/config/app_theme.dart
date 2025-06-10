import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primaryBackground,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 1.0,
        iconTheme: IconThemeData(color: AppColors.appBarText),
        titleTextStyle: TextStyle(
          color: AppColors.appBarText,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: const TextStyle(color: AppColors.appBarText, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(color: Colors.grey[800]),
        labelSmall: const TextStyle(color: AppColors.searchHintText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: AppColors.searchHintText, fontSize: 14),
        filled: true,
        fillColor: AppColors.searchBarBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: AppColors.appBarText.withOpacity(0.3)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.appBarText)
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.appBarText,
          foregroundColor: AppColors.primaryBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
        )
      )
    );
  }
}
