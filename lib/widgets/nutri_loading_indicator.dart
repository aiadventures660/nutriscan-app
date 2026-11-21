import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/app_theme.dart';

/// Reusable NutriScan loading animation widget powered by Lottie.
/// Uses the custom emerald pulse animation from assets/animations/loading.json.
///
/// Automatically crops the 1920x1080 composition's transparent padding so the
/// visible emerald wave correctly fills the requested logical pixel dimension.
class NutriLoadingIndicator extends StatelessWidget {
  final double size;
  final String? message;
  final TextStyle? messageStyle;
  final bool showBackground;

  const NutriLoadingIndicator({
    super.key,
    this.size = 110,
    this.message,
    this.messageStyle,
    this.showBackground = false,
  });

  /// Full-screen loading preset (~160–200 logical pixels)
  const NutriLoadingIndicator.fullScreen({
    super.key,
    this.message,
    this.messageStyle,
    this.showBackground = false,
  }) : size = 180;

  /// Card / dialog loading preset (~100–120 logical pixels)
  const NutriLoadingIndicator.card({
    super.key,
    this.message,
    this.messageStyle,
    this.showBackground = false,
  }) : size = 115;

  /// Compact loading preset (~40–56 logical pixels)
  const NutriLoadingIndicator.compact({
    super.key,
    this.message,
    this.messageStyle,
    this.showBackground = false,
  }) : size = 48;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // The raw loading.json composition is 1920x1080 with the active animated vector
    // centered in an ~780x440 viewport. Cropping the transparent margins ensures
    // the visible animation matches the specified logical size accurately.
    Widget anim;
    if (reduceMotion) {
      anim = SizedBox(
        width: size * 0.45,
        height: size * 0.45,
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
          strokeWidth: 3,
        ),
      );
    } else {
      anim = SizedBox(
        width: size,
        height: size * 0.56,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 780,
            height: 440,
            child: OverflowBox(
              minWidth: 1920,
              maxWidth: 1920,
              minHeight: 1080,
              maxHeight: 1080,
              alignment: Alignment.center,
              child: Lottie.asset(
                'assets/animations/loading.json',
                fit: BoxFit.fill,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: size * 0.45,
                    height: size * 0.45,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    Widget content = anim;

    if (message != null && message!.isNotEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          content,
          const SizedBox(height: 12),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: messageStyle ??
                TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}

/// Full screen or overlay modal blocker using NutriLoadingIndicator.
class NutriLoadingOverlay extends StatelessWidget {
  final String? message;

  const NutriLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: NutriLoadingIndicator.fullScreen(
        message: message,
        showBackground: true,
      ),
    );
  }
}
