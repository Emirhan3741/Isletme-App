import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// 🎨 Custom Colors for specific components
class CustomColors {
  CustomColors._();
  
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8F9FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// 📱 Responsive breakpoints
class Breakpoints {
  Breakpoints._();
  
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// 📏 Common sizes
class Sizes {
  Sizes._();
  
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconXLarge = 48;
  
  static const double avatarSmall = 32;
  static const double avatarMedium = 48;
  static const double avatarLarge = 64;
  
  static const double buttonHeight = 48;
  static const double inputHeight = 56;
}