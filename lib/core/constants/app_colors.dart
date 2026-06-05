import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

// Primary Brand Colors
const primary = Color(0xFF2196F3); // Blue
const primaryVariant = Color(0xFF2E5A88);
const secondary = Color(0xFF03DAC6); // Teal
const secondaryVariant = Color(0xFF018786);

// Legacy colors (for backward compatibility)
const headerColor = Color.fromARGB(255, 3, 19, 107);
const headerColor2 = Colors.blueAccent;
const headerColor3 = Color.fromARGB(255, 7, 201, 226);
final defaultPinTheme = PinTheme(
  width: 56,
  height: 56,
  textStyle: TextStyle(
    fontSize: 20,
    color: primaryVariant,
    fontWeight: FontWeight.w600,
  ),
  decoration: BoxDecoration(
    border: Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
    borderRadius: BorderRadius.circular(20),
  ),
);

final focusedPinTheme = defaultPinTheme.copyDecorationWith(
  border: Border.all(color: Color.fromRGBO(114, 178, 238, 1)),
  borderRadius: BorderRadius.circular(8),
);

final submittedPinTheme = defaultPinTheme.copyWith(
  decoration: defaultPinTheme.decoration!.copyWith(
    color: primaryVariant,
  ),
);

// Light Theme Colors
class LightColors {
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF5F5F5);
  static const onBackground = Color(0xFF1C1B1F);
  static const onSurface = Color(0xFF1C1B1F);
  static const onSurfaceVariant = Color(0xFF49454F);
  static const primary = Color(0xFF2196F3);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF03DAC6);
  static const onSecondary = Color(0xFF000000);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const outline = Color(0xFF79747E);
  static const shadow = Color(0xFF000000);
  static const inverseSurface = Color(0xFF313033);
  static const onInverseSurface = Color(0xFFF4EFF4);
  static const inversePrimary = Color(0xFF90CAF9);
}

// Dark Theme Colors
class DarkColors {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceVariant = Color(0xFF2C2C2C);
  static const onBackground = Color(0xFFE6E1E5);
  static const onSurface = Color(0xFFE6E1E5);
  static const onSurfaceVariant = Color(0xFFCAC4D0);
  static const primary = Color(0xFF90CAF9);
  static const onPrimary = Color(0xFF003258);
  static const secondary = Color(0xFF03DAC6);
  static const onSecondary = Color(0xFF000000);
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const outline = Color(0xFF938F99);
  static const shadow = Color(0xFF000000);
  static const inverseSurface = Color(0xFFE6E1E5);
  static const onInverseSurface = Color(0xFF313033);
  static const inversePrimary = Color(0xFF2196F3);
}

// App Colors class for easy access
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryVariant = Color(0xFF1976D2);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);

  // Light theme
  static final LightColors light = LightColors();

  // Dark theme
  static final DarkColors dark = DarkColors();

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color danger = Color(0xFFF44336);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Grey scale
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
}
