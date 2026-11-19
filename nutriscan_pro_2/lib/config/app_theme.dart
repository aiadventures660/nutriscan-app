import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class AppTheme {
  // Dynamic theme flag
  static bool isDark = false;
  static void setDarkMode(bool dark) => isDark = dark;

  // Primary Vibrant Emerald & Health Colors
  static Color get primaryGreen => isDark ? const Color(0xFF00E676) : const Color(0xFF00B368);
  static Color get primaryGreenDark => isDark ? const Color(0xFF00B358) : const Color(0xFF008F52);
  static Color get primaryGreenLight => isDark ? const Color(0xFF142E20) : const Color(0xFFE6FAF0);
  static Color get neonGlow => isDark ? const Color(0xFF00E676) : const Color(0xFF00B368);

  // Modern Macro Accent Colors
  static Color get macroProtein => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  static Color get macroCarbs => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static Color get macroFat => isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
  static Color get macroCalories => isDark ? const Color(0xFF00E676) : const Color(0xFF00B368);
  static Color get accentPurple => isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
  static Color get accentCyan => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
  static Color get accentAmber => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static const Color errorRed = Color(0xFFE11D48);

  // Background Colors
  static Color get backgroundDark => isDark ? const Color(0xFF080C0A) : const Color(0xFFF7FAF8);
  static Color get backgroundMedium => isDark ? const Color(0xFF0F1512) : const Color(0xFFEFF5F1);
  static Color get backgroundLight => isDark ? const Color(0xFF161E1A) : const Color(0xFFE4EDE7);
  static Color get cardBackground => isDark ? const Color(0xFF141C18) : const Color(0xFFFFFFFF);

  // Elevated Surface Colors
  static Color get glassSurface => isDark ? const Color(0x99121915) : const Color(0xF5FFFFFF);
  static Color get glassBorder => isDark ? const Color(0x2200E676) : const Color(0x180F1A14);
  static Color get glassBorderGreen => isDark ? const Color(0x4400E676) : const Color(0x3300B368);
  static Color get surfaceDark => isDark ? const Color(0xFF101713) : const Color(0xFFFFFFFF);
  static Color get surfaceLight => isDark ? const Color(0xFF19221C) : const Color(0xFFF1F6F3);
  static Color get surfaceAccent => isDark ? const Color(0xFF222E26) : const Color(0xFFE3EDE6);

  // Text Colors
  static Color get textPrimary => isDark ? const Color(0xFFF0F5F2) : const Color(0xFF0F1A14);
  static Color get textSecondary => isDark ? const Color(0xFF94A89C) : const Color(0xFF4A6153);
  static Color get textTertiary => isDark ? const Color(0xFF5D7366) : const Color(0xFF788E81);
  static Color get textOnPrimary => isDark ? const Color(0xFF080C0A) : const Color(0xFFFFFFFF);

  // Status Colors
  static Color get success => isDark ? const Color(0xFF00E676) : const Color(0xFF00B368);
  static Color get warning => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static const Color error = Color(0xFFE11D48);
  static Color get info => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

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
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(22));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(28));

  // NutriScan Pro 2.0 design tokens (backward compatible)
  static const double touchTarget = 48;
  static const double screenHorizontalPadding = 20;
  static const double premiumCardRadius = 22;
  static const Duration quickMotion = Duration(milliseconds: 220);
  static const Duration standardMotion = Duration(milliseconds: 300);

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
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF00E676),
      scaffoldBackgroundColor: const Color(0xFF080C0A),
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
                    Icon(icon, color: textColor ?? AppTheme.textOnPrimary, size: 20),
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
