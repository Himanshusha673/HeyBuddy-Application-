import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color bgColor = Color(0xFF05070B);
  static const Color cardColor = Color(0xFF101218);
  static const Color surfaceColor = Color(0xFF1D2636);
  
  // Accent Colors
  static const Color accentBlue = Color(0xFF236AF2);
  static const Color accentBlueLight = Color(0xFF4A8BFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% opacity
  static const Color textTertiary = Color(0x80FFFFFF); // 50% opacity
  static const Color textQuaternary = Color(0x61FFFFFF); // 38% opacity
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentBlue, accentBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Border Colors
  static Color borderPrimary = Colors.white.withOpacity(0.1);
  static Color borderSecondary = Colors.white.withOpacity(0.08);
  
  // Shadow Colors
  static Color shadowLight = Colors.black.withOpacity(0.3);
  static Color shadowMedium = Colors.black.withOpacity(0.5);
  
  // Message Colors
  static const Color userMessageBg = accentBlue;
  static const Color aiMessageBg = cardColor;
  static const Color otherUserMessageBg = surfaceColor;
}
