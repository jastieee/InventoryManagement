import 'package:flutter/material.dart';

/// App-wide color palette
class AppColors {
  // Primary Colors
  static const Color primaryDark = Color(0xFF213448);    // Dark Blue
  static const Color secondary = Color(0xFF547792);      // Teal
  static const Color accent = Color(0xFF94B4C1);         // Light Blue
  static const Color background = Color(0xFFEAE0CF);     // Cream

  // Shades for Dark Blue
  static const Color primaryLight = Color(0xFF2D4A65);
  static const Color primaryDarker = Color(0xFF192838);

  // Shades for Teal
  static const Color secondaryLight = Color(0xFF6B92A8);
  static const Color secondaryDark = Color(0xFF3D5F7A);

  // Shades for Light Blue
  static const Color accentLight = Color(0xFFAAC4CE);
  static const Color accentDark = Color(0xFF7FA4B4);

  // Text Colors
  static const Color textDark = Color(0xFF213448);
  static const Color textLight = Color(0xFFEAE0CF);
  static const Color textGray = Color(0xFF547792);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF547792);

  // Surface Colors
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFF94B4C1);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, accent],
  );
}

