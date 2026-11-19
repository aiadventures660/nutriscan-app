import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'animated_components.dart';

class MacroRingsWidget extends StatefulWidget {
  final double calories;
  final double calorieTarget;
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbsTarget;
  final double fat;
  final double fatTarget;
  final VoidCallback? onTap;

  const MacroRingsWidget({
    super.key,
    required this.calories,
    required this.calorieTarget,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
    this.onTap,
  });

  @override
  State<MacroRingsWidget> createState() => _MacroRingsWidgetState();
}

class _MacroRingsWidgetState extends State<MacroRingsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;
  bool _showRemaining = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(MacroRingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calories != widget.calories ||
        oldWidget.protein != widget.protein ||
        oldWidget.carbs != widget.carbs ||
        oldWidget.fat != widget.fat) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calProgress = (widget.calories / widget.calorieTarget).clamp(0.0, 1.0);
    final proProgress = (widget.protein / widget.proteinTarget).clamp(0.0, 1.0);
    final carbProgress = (widget.carbs / widget.carbsTarget).clamp(0.0, 1.0);
    final fatProgress = (widget.fat / widget.fatTarget).clamp(0.0, 1.0);

    final remainingCals = (widget.calorieTarget - widget.calories).clamp(0, 9999);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      onTap: () {
        setState(() => _showRemaining = !_showRemaining);
        if (widget.onTap != null) widget.onTap!();
      },
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.donut_large_rounded,
                      color: AppTheme.primaryGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Daily Macro Rings',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  _showRemaining ? 'Remaining' : 'Consumed',
                  style: TextStyle(
                    color: _showRemaining ? AppTheme.macroProtein : AppTheme.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Center Interactive Rings
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, child) {
              return SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(210, 210),
                      painter: _AppleFitnessRingsPainter(
                        calProgress: calProgress * _progressAnim.value,
                        proProgress: proProgress * _progressAnim.value,
                        carbProgress: carbProgress * _progressAnim.value,
                        fatProgress: fatProgress * _progressAnim.value,
                      ),
                    ),
                    // Center Content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: AppTheme.primaryGreen,
                          size: 26,
                        ),
                        const SizedBox(height: 2),
                        AnimatedCountText(
                          value: _showRemaining
                              ? remainingCals.toDouble()
                              : widget.calories,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          _showRemaining ? 'kcal left' : 'of ${widget.calorieTarget.toInt()} kcal',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(calProgress * 100).toInt()}%',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 4 Macro breakdown chips
          Row(
            children: [
              Expanded(
                child: _buildMacroBadge(
                  label: 'Calories',
                  current: widget.calories,
                  target: widget.calorieTarget,
                  unit: 'kcal',
                  color: AppTheme.primaryGreen,
                  progress: calProgress,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBadge(
                  label: 'Protein',
                  current: widget.protein,
                  target: widget.proteinTarget,
                  unit: 'g',
                  color: AppTheme.macroProtein,
                  progress: proProgress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMacroBadge(
                  label: 'Carbs',
                  current: widget.carbs,
                  target: widget.carbsTarget,
                  unit: 'g',
                  color: AppTheme.macroCarbs,
                  progress: carbProgress,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBadge(
                  label: 'Fats',
                  current: widget.fat,
                  target: widget.fatTarget,
                  unit: 'g',
                  color: AppTheme.macroFat,
                  progress: fatProgress,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge({
    required String label,
    required double current,
    required double target,
    required String unit,
    required Color color,
    required double progress,
  }) {
    final pct = (progress * 100).toInt();

    return BouncingWidget(
      scaleFactor: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                AnimatedCountText(
                  value: current,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ' / ${target.toInt()} $unit',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return LinearProgressIndicator(
                    value: val,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Concentric Rings
class _AppleFitnessRingsPainter extends CustomPainter {
  final double calProgress;
  final double proProgress;
  final double carbProgress;
  final double fatProgress;

  _AppleFitnessRingsPainter({
    required this.calProgress,
    required this.proProgress,
    required this.carbProgress,
    required this.fatProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 10.5;
    const ringSpacing = 14.5;

    // Rings from outer to inner
    // 1. Calories (Outer)
    final r1 = (size.width / 2) - (strokeWidth / 2) - 4;
    _drawRing(
      canvas: canvas,
      center: center,
      radius: r1,
      strokeWidth: strokeWidth,
      progress: calProgress,
      color: AppTheme.primaryGreen,
      glowColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
    );

    // 2. Protein
    final r2 = r1 - ringSpacing;
    _drawRing(
      canvas: canvas,
      center: center,
      radius: r2,
      strokeWidth: strokeWidth,
      progress: proProgress,
      color: AppTheme.macroProtein,
      glowColor: AppTheme.macroProtein.withValues(alpha: 0.5),
    );

    // 3. Carbs
    final r3 = r2 - ringSpacing;
    _drawRing(
      canvas: canvas,
      center: center,
      radius: r3,
      strokeWidth: strokeWidth,
      progress: carbProgress,
      color: AppTheme.macroCarbs,
      glowColor: AppTheme.macroCarbs.withValues(alpha: 0.5),
    );

    // 4. Fat (Inner)
    final r4 = r3 - ringSpacing;
    _drawRing(
      canvas: canvas,
      center: center,
      radius: r4,
      strokeWidth: strokeWidth,
      progress: fatProgress,
      color: AppTheme.macroFat,
      glowColor: AppTheme.macroFat.withValues(alpha: 0.5),
    );
  }

  void _drawRing({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double strokeWidth,
    required double progress,
    required Color color,
    required Color glowColor,
  }) {
    // Background Track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.001) return;

    // Glow Shadow
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final sweepAngle = (progress * 2 * math.pi).clamp(0.01, 2 * math.pi - 0.001);
    const startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    // Foreground Active Arc
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_AppleFitnessRingsPainter oldDelegate) {
    return oldDelegate.calProgress != calProgress ||
        oldDelegate.proProgress != proProgress ||
        oldDelegate.carbProgress != carbProgress ||
        oldDelegate.fatProgress != fatProgress;
  }
}
