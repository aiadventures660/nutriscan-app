import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'dart:ui';

class AppTheme {
  // Dynamic theme flag
  static bool isDark = false;
  static void setDarkMode(bool dark) => isDark = dark;

  // Primary Vibrant Emerald & Health Colors
  static Color get primaryGreen =>
      isDark ? const Color(0xFF00E676) : const Color(0xFF00B368);
  static Color get primaryGreenDark =>
      isDark ? const Color(0xFF00B358) : const Color(0xFF008F52);
  static Color get primaryGreenLight =>
      isDark ? const Color(0xFF142E20) : const Color(0xFFE6FAF0);
  static Color get neonGlow =>
      isDark ? const Color(0xFF00E676) : const Color(0xFF00B368);

  // Modern Macro Accent Colors
  static Color get macroProtein =>
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  static Color get macroCarbs =>
      isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static Color get macroFat =>
      isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
  static Color get macroCalories =>
      isDark ? const Color(0xFF00E676) : const Color(0xFF00B368);
  static Color get accentPurple =>
      isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
  static Color get accentCyan =>
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  static Color get accentAmber =>
      isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static const Color errorRed = Color(0xFFE11D48);

  // Background Colors
  static Color get backgroundDark =>
      isDark ? const Color(0xFF080C0A) : const Color(0xFFF7FAF8);
  static Color get backgroundMedium =>
      isDark ? const Color(0xFF0F1512) : const Color(0xFFEFF5F1);
  static Color get backgroundLight =>
      isDark ? const Color(0xFF161E1A) : const Color(0xFFE4EDE7);
  static Color get cardBackground =>
      isDark ? const Color(0xFF141C18) : const Color(0xFFFFFFFF);

  // Elevated Surface Colors
  static Color get glassSurface =>
      isDark ? const Color(0x99121915) : const Color(0xF5FFFFFF);
  static Color get glassBorder =>
      isDark ? const Color(0x2200E676) : const Color(0x180F1A14);
  static Color get glassBorderGreen =>
      isDark ? const Color(0x4400E676) : const Color(0x3300B368);
  static Color get surfaceDark =>
      isDark ? const Color(0xFF101713) : const Color(0xFFFFFFFF);
  static Color get surfaceLight =>
      isDark ? const Color(0xFF19221C) : const Color(0xFFF1F6F3);
  static Color get surfaceAccent =>
      isDark ? const Color(0xFF222E26) : const Color(0xFFE3EDE6);

  // Text Colors
  static Color get textPrimary =>
      isDark ? const Color(0xFFF0F5F2) : const Color(0xFF0F1A14);
  static Color get textSecondary =>
      isDark ? const Color(0xFF94A89C) : const Color(0xFF4A6153);
  static Color get textTertiary =>
      isDark ? const Color(0xFF5D7366) : const Color(0xFF788E81);
  static Color get textOnPrimary =>
      isDark ? const Color(0xFF080C0A) : const Color(0xFFFFFFFF);

  // Status Colors
  static Color get success =>
      isDark ? const Color(0xFF00E676) : const Color(0xFF00B368);
  static Color get warning =>
      isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static const Color error = Color(0xFFE11D48);
  static Color get info =>
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF00E676), Color(0xFF00B358)]
            : const [Color(0xFF00C774), Color(0xFF009B58)],
      );

  static LinearGradient get emeraldCyanGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF00E676), Color(0xFF00E5FF)]
            : const [Color(0xFF00B368), Color(0xFF0284C7)],
      );

  static const LinearGradient fireGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFE11D48)],
  );

  static LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF080C0A), Color(0xFF0D1410), Color(0xFF080C0A)]
            : const [Color(0xFFF8FAF9), Color(0xFFEFF5F1), Color(0xFFF8FAF9)],
      );

  static LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF141C18), Color(0xFF0F1512)]
            : const [Color(0xFFFFFFFF), Color(0xFFF9FBFA)],
      );

  static LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0x9918231E), Color(0x770E1511)]
            : const [Color(0xFAFFFFFF), Color(0xF2F5F8F6)],
      );

  // Shadows
  static List<BoxShadow> get softShadow => isDark
      ? const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x0C0F1A14),
            offset: Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ];

  static List<BoxShadow> get neonGlowShadow => [
        BoxShadow(
          color: (isDark ? const Color(0xFF00E676) : const Color(0xFF00B368))
              .withValues(alpha: isDark ? 0.35 : 0.25),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get mediumShadow => isDark
      ? const [
          BoxShadow(
            color: Color(0x60000000),
            offset: Offset(0, 6),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x120F1A14),
            offset: Offset(0, 6),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ];

  static List<BoxShadow> get strongShadow => isDark
      ? const [
          BoxShadow(
            color: Color(0x80000000),
            offset: Offset(0, 10),
            blurRadius: 28,
            spreadRadius: 0,
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x180F1A14),
            offset: Offset(0, 10),
            blurRadius: 28,
            spreadRadius: 0,
          ),
        ];

  // Border Radius
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(10));
  static const BorderRadius mediumRadius =
      BorderRadius.all(Radius.circular(16));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(22));
  static const BorderRadius extraLargeRadius =
      BorderRadius.all(Radius.circular(28));

  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF00B368),
      scaffoldBackgroundColor: const Color(0xFFF7FAF8),
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: _pageTransitionsTheme,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00B368),
        primaryContainer: Color(0xFFE6FAF0),
        secondary: Color(0xFF0284C7),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFE11D48),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFF0F1A14),
        onSurface: Color(0xFF0F1A14),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0F1A14),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: largeRadius),
        shadowColor: Color(0x140F1A14),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Color(0xFFE6FAF0),
        indicatorShape: StadiumBorder(),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: Color(0xFF00B368),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0xFFB7C7BD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: const Color(0xFF17221B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F6F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00B368), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B368),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: mediumRadius),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        displaySmall: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineLarge: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleSmall: TextStyle(
          color: Color(0xFF4A6153),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF0F1A14),
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF4A6153),
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF788E81),
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      extensions: [
        ClerkThemeExtension(
          colors: const ClerkThemeColors(
            background: Colors.white,
            altBackground: Color(0xFFF1F6F3),
            borderSide: Color(0x3300B368),
            text: Color(0xFF0F1A14),
            icon: Color(0xFF00B368),
            lightweightText: Color(0xFF4A6153),
            error: Color(0xFFE11D48),
            accent: Color(0xFF00B368),
          ),
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF00E676),
      scaffoldBackgroundColor: const Color(0xFF080C0A),
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: _pageTransitionsTheme,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E676),
        primaryContainer: Color(0xFF142E20),
        secondary: Color(0xFF38BDF8),
        surface: Color(0xFF101713),
        error: Color(0xFFE11D48),
        onPrimary: Color(0xFF080C0A),
        onSecondary: Color(0xFFF0F5F2),
        onSurface: Color(0xFFF0F5F2),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF0F5F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF141C18),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: largeRadius),
        shadowColor: Color(0x40000000),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Color(0xFF142E20),
        indicatorShape: StadiumBorder(),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: Color(0xFF00E676),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0xFF53675B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: const Color(0xFF1B2820),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF19221C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676),
          foregroundColor: const Color(0xFF080C0A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: mediumRadius),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        displaySmall: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineLarge: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleSmall: TextStyle(
          color: Color(0xFF94A89C),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFF0F5F2),
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF94A89C),
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF5D7366),
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      extensions: [
        ClerkThemeExtension(
          colors: const ClerkThemeColors(
            background: Color(0xFF101713),
            altBackground: Color(0xFF132219),
            borderSide: Color(0x3300E676),
            text: Color(0xFFF0F5F2),
            icon: Color(0xFF00E676),
            lightweightText: Color(0xFF94A89C),
            error: Color(0xFFE11D48),
            accent: Color(0xFF00E676),
          ),
        ),
      ],
    );
  }

  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );
  // Premium 2026 Design Tokens
  static const double borderRadiusXS = 6.0;
  static const double borderRadiusSM = 10.0;
  static const double borderRadiusMD = 16.0;
  static const double borderRadiusLG = 24.0;
  static const double borderRadiusXL = 32.0;
  static const double borderRadius2XL = 40.0;

  // Premium Spacing Scale
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Premium Gradient Variants
  static LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF00E676), Color(0xFF00B358), Color(0xFF006633)]
            : const [Color(0xFF00C774), Color(0xFF009B58), Color(0xFF006633)],
      );

  static LinearGradient get subtleGreenGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF00E676).withValues(alpha: 0.15), const Color(0xFF00B358).withValues(alpha: 0.08)]
            : [const Color(0xFF00C774).withValues(alpha: 0.12), const Color(0xFF009B58).withValues(alpha: 0.06)],
      );

  static LinearGradient get darkCardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF1A2420), Color(0xFF131B17)]
            : const [Color(0xFFFFFFFF), Color(0xFFF4F9F6)],
      );

  static LinearGradient get proteinGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
      );

  static LinearGradient get carbsGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      );

  static LinearGradient get fatGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
      );

  static LinearGradient get purpleGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
      );

  // Premium Shadow System
  static List<BoxShadow> get cardShadow => isDark
      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))]
      : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)), BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))];

  static List<BoxShadow> get greenGlowShadow => [
        BoxShadow(color: primaryGreen.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 0, offset: const Offset(0, 4)),
        BoxShadow(color: primaryGreen.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 0, offset: const Offset(0, 8)),
      ];

  static List<BoxShadow> get innerShadow => isDark
      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2), spreadRadius: -2)]
      : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2), spreadRadius: -2)];

  // Premium Typography
  static TextStyle get displayLarge => TextStyle(
        color: textPrimary, fontSize: 36, fontWeight: FontWeight.w900,
        letterSpacing: -1.2, height: 1.1,
      );
  static TextStyle get displayMedium => TextStyle(
        color: textPrimary, fontSize: 28, fontWeight: FontWeight.w800,
        letterSpacing: -0.8, height: 1.15,
      );
  static TextStyle get headlineLarge => TextStyle(
        color: textPrimary, fontSize: 24, fontWeight: FontWeight.w800,
        letterSpacing: -0.6, height: 1.2,
      );
  static TextStyle get headlineMedium => TextStyle(
        color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700,
        letterSpacing: -0.4, height: 1.25,
      );
  static TextStyle get headlineSmall => TextStyle(
        color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700,
        letterSpacing: -0.3, height: 1.3,
      );
  static TextStyle get titleLarge => TextStyle(
        color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
        letterSpacing: -0.2, height: 1.4,
      );
  static TextStyle get bodyLarge => TextStyle(
        color: textSecondary, fontSize: 15, fontWeight: FontWeight.w400,
        letterSpacing: 0, height: 1.5,
      );
  static TextStyle get bodyMedium => TextStyle(
        color: textSecondary, fontSize: 13, fontWeight: FontWeight.w400,
        letterSpacing: 0, height: 1.5,
      );
  static TextStyle get labelLarge => TextStyle(
        color: textTertiary, fontSize: 12, fontWeight: FontWeight.w600,
        letterSpacing: 0.4, height: 1.4,
      );
  static TextStyle get labelSmall => TextStyle(
        color: textTertiary, fontSize: 10, fontWeight: FontWeight.w600,
        letterSpacing: 0.6, height: 1.4,
      );
}

// --- Premium Shimmer Loading Widget ---
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppTheme.borderRadiusMD,
    this.margin,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = AppTheme.isDark
        ? const Color(0xFF1E2823)
        : const Color(0xFFE8F0EA);
    final shimmerColor = AppTheme.isDark
        ? const Color(0xFF283028)
        : const Color(0xFFF4FAF6);

    return Container(
      margin: widget.margin,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + _animation.value * 2, 0),
                end: Alignment(1.0 + _animation.value * 2, 0),
                colors: [baseColor, shimmerColor, baseColor],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Premium Metric Chip ---
class MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const MetricChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSM),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Glassmorphism Card with subtle blur, translucent gradient, and border
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Gradient? gradient;
  final double blurAmount;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.borderColor,
    this.gradient,
    this.blurAmount = 10,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppTheme.largeRadius;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: boxShadow ?? AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient ?? AppTheme.glassGradient,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: borderColor ?? AppTheme.glassBorder,
                width: 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: effectiveRadius,
                splashColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                highlightColor: AppTheme.primaryGreen.withValues(alpha: 0.04),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Backward compatible AppCard
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool withGradient;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.withGradient = false,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: margin,
      padding: padding,
      onTap: onTap,
      boxShadow: boxShadow,
      gradient: withGradient ? AppTheme.cardGradient : AppTheme.glassGradient,
      child: child,
    );
  }
}

// Modern Gradient Action Button
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? textColor;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.padding,
    this.gradient,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.primaryGradient,
        borderRadius: AppTheme.mediumRadius,
        boxShadow: AppTheme.neonGlowShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppTheme.mediumRadius,
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: 14,
                ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.textOnPrimary,
                      ),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon,
                        color: textColor ?? AppTheme.textOnPrimary, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? AppTheme.textOnPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
