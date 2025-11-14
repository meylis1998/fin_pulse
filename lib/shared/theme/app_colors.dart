import 'package:flutter/material.dart';

/// App color palette for FinPulse
class AppColors {
  // Primary colors (Financial blue theme)
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);

  // Secondary colors (Green for gains)
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF388E3C);
  static const Color secondaryLight = Color(0xFF66BB6A);

  // Market colors
  static const Color bullish = Color(0xFF4CAF50); // Green for gains
  static const Color bearish = Color(0xFFF44336); // Red for losses
  static const Color neutral = Color(0xFF9E9E9E); // Gray for no change

  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF121212);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  // Chart colors
  static const Color candleGreen = Color(0xFF26A69A); // Teal green
  static const Color candleRed = Color(0xFFEF5350); // Lighter red
  static const Color chartGrid = Color(0xFFE0E0E0);
  static const Color chartAxis = Color(0xFF9E9E9E);

  // Technical indicator colors
  static const Color sma20 = Color(0xFF2196F3); // Blue
  static const Color sma50 = Color(0xFFFF9800); // Orange
  static const Color sma200 = Color(0xFF9C27B0); // Purple
  static const Color ema12 = Color(0xFF00BCD4); // Cyan
  static const Color ema26 = Color(0xFFE91E63); // Pink
  static const Color ema = Color(0xFF00BCD4); // Cyan (alias for ema12)
  static const Color rsi = Color(0xFFFFEB3B); // Yellow
  static const Color macd = Color(0xFF795548); // Brown
  static const Color bollingerBand = Color(0xFF9C27B0); // Purple
  static const Color macdLine = Color(0xFF2196F3); // Blue
  static const Color macdSignal = Color(0xFFFF9800); // Orange
  static const Color macdHistogram = Color(0xFF4CAF50); // Green

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bullishGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bearishGradient = LinearGradient(
    colors: [Color(0xFFEF5350), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark theme colors (namespace with 'dark' prefix)
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
}
