import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/app_theme.dart';

/// Reusable NutriScan loading animation widget powered by Lottie.
/// Uses the custom emerald pulse animation from assets/animations/loading.json.
class NutriLoadingIndicator extends StatelessWidget {
  final double size;
  final String? message;
  final TextStyle? messageStyle;
  final bool showBackground;

  const NutriLoadingIndicator({
    super.key,
    this.size = 100,
    this.message,
    this.messageStyle,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Lottie.asset(
      'assets/animations/loading.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 3,
          ),
        );
      },
    );

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
      color: Colors.black.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: NutriLoadingIndicator(
        size: 130,
        message: message,
        showBackground: true,
      ),
    );
  }
}
