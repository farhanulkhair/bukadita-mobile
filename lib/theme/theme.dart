import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================
/// APP THEME - Semua styling aplikasi Bukadita
/// ============================================

class AppTheme {
  // ==================== COLORS ====================

  // Primary & Brand Colors
  static const Color primary = Color(0xFF578FCA);
  static const Color secondary = Color(0xFF27548A);
  static const Color primaryLight = Color(0xFF4681C4);
  static const Color secondaryDark = Color(0xFF1E3F6F);

  // Brand colors (alias untuk compatibility)
  static const Color brand_01 = secondary;
  static const Color brand_02 = Color(0xFF3674B5);

  // Gray Scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);

  // Error/Red Colors
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);

  // Success/Green Colors
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green200 = Color(0xFFBBF7D0);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);

  // Blue Colors
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);

  // Orange Colors
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange500 = Color(0xFFF97316);
  static const Color orange600 = Color(0xFFEA580C);

  // Basic Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFF5F7FA);
  static const Color error = red600;
  static const Color success = green600;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientHover = LinearGradient(
    colors: [primaryLight, secondaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ==================== TEXT STYLES ====================

  // Heading Styles
  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: secondary,
  );

  static TextStyle headingLarge = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: secondary,
  );

  static TextStyle headingMedium = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: secondary,
  );

  static TextStyle headingSmall = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: secondary,
  );

  static TextStyle subheading = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: gray600,
  );

  // Label Styles
  static TextStyle label = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: secondary,
  );

  static TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: gray700,
  );

  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: gray600,
  );

  static TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: gray700,
  );

  // Body Styles
  static TextStyle body = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: gray700,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: gray600,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: gray500,
  );

  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: gray700,
  );

  // Input Styles
  static TextStyle hint = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: gray400,
  );

  static TextStyle input = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: gray700,
  );

  static TextStyle inputError = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: red600,
  );

  // Link Styles
  static TextStyle link = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primary,
    decoration: TextDecoration.underline,
  );

  static TextStyle linkMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primary,
  );

  // Button Styles
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: white,
  );

  // ==================== FLUTTER THEME DATA ====================

  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      error: error,
      background: background,
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.poppinsTextTheme(),
    scaffoldBackgroundColor: white,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: gray50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: red500),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: hint,
    ),
  );

  // Alias untuk compatibility dengan kode lama
  static ThemeData get LightTheme => lightTheme;
}

// ==================== BACKWARD COMPATIBILITY ====================
// Alias untuk kode lama yang masih pakai AppColors & AppTextStyles

class AppColors {
  static const Color primary = AppTheme.primary;
  static const Color secondary = AppTheme.secondary;
  static const Color primaryLight = AppTheme.primaryLight;
  static const Color secondaryDark = AppTheme.secondaryDark;
  static const Color gray50 = AppTheme.gray50;
  static const Color gray100 = AppTheme.gray100;
  static const Color gray200 = AppTheme.gray200;
  static const Color gray300 = AppTheme.gray300;
  static const Color gray400 = AppTheme.gray400;
  static const Color gray500 = AppTheme.gray500;
  static const Color gray600 = AppTheme.gray600;
  static const Color gray700 = AppTheme.gray700;
  static const Color gray800 = AppTheme.gray800;
  static const Color red50 = AppTheme.red50;
  static const Color red200 = AppTheme.red200;
  static const Color red400 = AppTheme.red400;
  static const Color red500 = AppTheme.red500;
  static const Color red600 = AppTheme.red600;
  static const Color red700 = AppTheme.red700;
  static const Color orange50 = AppTheme.orange50;
  static const Color orange500 = AppTheme.orange500;
  static const Color orange600 = AppTheme.orange600;
  static const Color green50 = AppTheme.green50;
  static const Color green200 = AppTheme.green200;
  static const Color green500 = AppTheme.green500;
  static const Color green600 = AppTheme.green600;
  static const Color green700 = AppTheme.green700;
  static const Color blue50 = AppTheme.blue50;
  static const Color blue200 = AppTheme.blue200;
  static const Color blue600 = AppTheme.blue600;
  static const Color blue700 = AppTheme.blue700;
  static const Color white = AppTheme.white;
  static const Color black = AppTheme.black;
  static const Color background = AppTheme.background;
  static const Color error = AppTheme.error;
  static const LinearGradient primaryGradient = AppTheme.primaryGradient;
  static const LinearGradient primaryGradientHover =
      AppTheme.primaryGradientHover;
}

class AppTextStyles {
  static TextStyle get heading => AppTheme.heading;
  static TextStyle get headingLarge => AppTheme.headingLarge;
  static TextStyle get headingMedium => AppTheme.headingMedium;
  static TextStyle get headingSmall => AppTheme.headingSmall;
  static TextStyle get subheading => AppTheme.subheading;
  static TextStyle get label => AppTheme.label;
  static TextStyle get labelMedium => AppTheme.labelMedium;
  static TextStyle get labelSmall => AppTheme.labelSmall;
  static TextStyle get labelLarge => AppTheme.labelLarge;
  static TextStyle get body => AppTheme.body;
  static TextStyle get bodyMedium => AppTheme.bodyMedium;
  static TextStyle get bodySmall => AppTheme.bodySmall;
  static TextStyle get bodyLarge => AppTheme.bodyLarge;
  static TextStyle get hint => AppTheme.hint;
  static TextStyle get input => AppTheme.input;
  static TextStyle get inputError => AppTheme.inputError;
  static TextStyle get link => AppTheme.link;
  static TextStyle get linkMedium => AppTheme.linkMedium;
  static TextStyle get button => AppTheme.button;
}
