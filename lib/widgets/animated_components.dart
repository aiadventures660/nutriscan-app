import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// 1. BOUNCING WIDGET (Apple-Style Spring Micro-Interaction on Tap)
// ---------------------------------------------------------------------------
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final bool enableHaptic;

  const BouncingWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.94,
    this.duration = const Duration(milliseconds: 130),
    this.enableHaptic = true,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _controller.reverse();
    widget.onTap!();
  }

  void _onTapCancel() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. ANIMATED COUNT TEXT (Smooth Counting Numbers for Calories, Macros, etc.)
// ---------------------------------------------------------------------------
class AnimatedCountText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimalPlaces;
  final Duration duration;
  final Curve curve;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        final formatted = decimalPlaces > 0
            ? val.toStringAsFixed(decimalPlaces)
            : val.toInt().toString();
        return Text(
          '$prefix$formatted$suffix',
          style: style,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 3. STAGGERED SLIDE & FADE ENTRANCE ANIMATION
// ---------------------------------------------------------------------------
class StaggeredSlideFade extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration stepDelay;
  final Duration duration;
  final Offset offset;

  const StaggeredSlideFade({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = Duration.zero,
    this.stepDelay = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 550),
    this.offset = const Offset(0.0, 0.08),
  });

  @override
  State<StaggeredSlideFade> createState() => _StaggeredSlideFadeState();
}

class _StaggeredSlideFadeState extends State<StaggeredSlideFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final totalDelay = widget.baseDelay + (widget.stepDelay * widget.index);
    Future.delayed(totalDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. PULSING GLOW CONTAINER (For Floating Scan Button & Active Elements)
// ---------------------------------------------------------------------------
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double minSpread;
  final double maxSpread;
  final double minBlur;
  final double maxBlur;
  final Duration duration;
  final bool isCircle;

  const PulsingGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.minSpread = 1.0,
    this.maxSpread = 7.0,
    this.minBlur = 12.0,
    this.maxBlur = 24.0,
    this.duration = const Duration(milliseconds: 1800),
    this.isCircle = true,
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final spread = widget.minSpread +
            (_animation.value * (widget.maxSpread - widget.minSpread));
        final blur = widget.minBlur +
            (_animation.value * (widget.maxBlur - widget.minBlur));
        final opacity = (0.28 + (_animation.value * 0.28)).clamp(0.0, 1.0);

        return Container(
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.isCircle ? null : BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: opacity),
                spreadRadius: spread,
                blurRadius: blur,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// 5. ANIMATED RADIAL SCORE GAUGE (For Health & Nutri-Score)
// ---------------------------------------------------------------------------
class AnimatedRadialScoreGauge extends StatelessWidget {
  final int score; // 0 to 100
  final double size;
  final double strokeWidth;
  final Color primaryColor;
  final Color trackColor;
  final String label;

  const AnimatedRadialScoreGauge({
    super.key,
    required this.score,
    this.size = 110,
    this.strokeWidth = 9.0,
    this.primaryColor = const Color(0xFF10B981),
    this.trackColor = const Color(0x2210B981),
    this.label = 'Health Score',
  });

  @override
  Widget build(BuildContext context) {
    final targetFraction = (score / 100.0).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetFraction),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedVal, child) {
        final currentScore = (animatedVal * 100).toInt();

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RadialArcPainter(
                  fraction: animatedVal,
                  strokeWidth: strokeWidth,
                  primaryColor: primaryColor,
                  trackColor: trackColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$currentScore',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: size * 0.10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadialArcPainter extends CustomPainter {
  final double fraction;
  final double strokeWidth;
  final Color primaryColor;
  final Color trackColor;

  _RadialArcPainter({
    required this.fraction,
    required this.strokeWidth,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Glowing active arc
    if (fraction > 0.01) {
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * fraction;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [
            primaryColor.withValues(alpha: 0.6),
            primaryColor,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
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

      // Indicator tip dot
      final endAngle = startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(endAngle);
      final tipY = center.dy + radius * math.sin(endAngle);

      final tipPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2.2, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialArcPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.primaryColor != primaryColor;
  }
}

// ---------------------------------------------------------------------------
// 6. WAVE LIQUID PAINTER WIDGET (For Animated Hydration Water Wave)
// ---------------------------------------------------------------------------
class WaveLiquidWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color primaryColor;
  final Color waveColor;

  const WaveLiquidWidget({
    super.key,
    required this.progress,
    this.height = 14,
    this.primaryColor = const Color(0xFF06B6D4),
    this.waveColor = const Color(0xFF38BDF8),
  });

  @override
  State<WaveLiquidWidget> createState() => _WaveLiquidWidgetState();
}

class _WaveLiquidWidgetState extends State<WaveLiquidWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: widget.progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _WavePainter(
                        wavePhase: _animController.value * 2 * math.pi,
                        progress: animatedProgress,
                        primaryColor: widget.primaryColor,
                        waveColor: widget.waveColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double wavePhase;
  final double progress;
  final Color primaryColor;
  final Color waveColor;

  _WavePainter({
    required this.wavePhase,
    required this.progress,
    required this.primaryColor,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final fillWidth = size.width * progress;

    // Background gradient fill
    final rectPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.7),
          waveColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, fillWidth, size.height));

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(fillWidth, 0);

    // Subtle wave curve at the leading edge
    const waveHeight = 2.0;
    for (double y = 0; y <= size.height; y += 1) {
      final xOffset = math.sin((y / size.height * 2 * math.pi) + wavePhase) * waveHeight;
      path.lineTo((fillWidth + xOffset).clamp(0.0, size.width), y);
    }

    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, rectPaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase || oldDelegate.progress != progress;
  }
}

// ---------------------------------------------------------------------------
// 7. HIGH-TECH LASER SCAN OVERLAY (For Viewfinder)
// ---------------------------------------------------------------------------
class LaserScanOverlay extends StatefulWidget {
  final double width;
  final double height;
  final Color laserColor;
  final Duration duration;

  const LaserScanOverlay({
    super.key,
    this.width = 260,
    this.height = 260,
    this.laserColor = const Color(0xFF10B981),
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<LaserScanOverlay> createState() => _LaserScanOverlayState();
}

class _LaserScanOverlayState extends State<LaserScanOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // Outer Glowing Frame
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.laserColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
            ),

            // Corner Reticles with Breathing Pulse
            _buildCorner(top: 0, left: 0, isTop: true, isLeft: true),
            _buildCorner(top: 0, right: 0, isTop: true, isLeft: false),
            _buildCorner(bottom: 0, left: 0, isTop: false, isLeft: true),
            _buildCorner(bottom: 0, right: 0, isTop: false, isLeft: false),

            // Animated Laser Beam Line
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final topPos = _controller.value * (widget.height - 10);

                return Positioned(
                  top: topPos,
                  left: 6,
                  right: 6,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Upper soft gradient aura
                      Container(
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              widget.laserColor.withValues(alpha: 0.22),
                            ],
                          ),
                        ),
                      ),
                      // Sharp laser beam
                      Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: widget.laserColor,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Lower soft gradient aura
                      Container(
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.laserColor.withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    const cornerSize = 26.0;
    const stroke = 3.5;

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: cornerSize,
        height: cornerSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
          ),
          border: Border(
            top: isTop
                ? BorderSide(color: widget.laserColor, width: stroke)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: widget.laserColor, width: stroke)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: widget.laserColor, width: stroke)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: widget.laserColor, width: stroke)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. AI ANALYZING RADAR (Futuristic Multi-Ring AI Scanner Loader)
// ---------------------------------------------------------------------------
class AIAnalyzingRadar extends StatefulWidget {
  final String statusText;
  final String subtitleText;

  const AIAnalyzingRadar({
    super.key,
    this.statusText = 'Analyzing Food Image with Gemini AI...',
    this.subtitleText = 'Detecting nutritional density, NOVA group & allergens',
  });

  @override
  State<AIAnalyzingRadar> createState() => _AIAnalyzingRadarState();
}

class _AIAnalyzingRadarState extends State<AIAnalyzingRadar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulsing Ripple Wave
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseAnimation.value * 0.25);
                    final alpha = (0.35 - (_pulseAnimation.value * 0.25)).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: alpha),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Rotating Dashed Tech Ring
                RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Inner Glowing Core
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF34D399),
                        Color(0xFF059669),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            widget.statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitleText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. SKELETON CARD (2026 Shimmer Loading Skeleton)
// ---------------------------------------------------------------------------
class SkeletonCard extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius,
    this.margin,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF161F1A) : const Color(0xFFE5EDE8);
    final highlightColor =
        isDark ? const Color(0xFF26332C) : const Color(0xFFF2F7F4);

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment(-1.5 + (_shimmerController.value * 3.0), -0.3),
                end: Alignment(-0.5 + (_shimmerController.value * 3.0), 0.3),
                colors: [baseColor, highlightColor, baseColor],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0x1500E676)
                    : const Color(0x1000B368),
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. ANIMATED GRADIENT PROGRESS BAR (With Glow & Smooth 60 FPS Tween)
// ---------------------------------------------------------------------------
class AnimatedGradientBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Gradient gradient;
  final Color backgroundColor;
  final double height;
  final double borderRadius;
  final bool showGlow;
  final Duration duration;

  const AnimatedGradientBar({
    super.key,
    required this.progress,
    required this.gradient,
    this.backgroundColor = const Color(0x1FFFFFFF),
    this.height = 8.0,
    this.borderRadius = 8.0,
    this.showGlow = true,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedGradientBar> createState() => _AnimatedGradientBarState();
}

class _AnimatedGradientBarState extends State<AnimatedGradientBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0.0, end: widget.progress.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _lastProgress = widget.progress;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedGradientBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _lastProgress.clamp(0.0, 1.0),
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _lastProgress = widget.progress;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return Container(
          height: widget.height,
          width: totalWidth,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final barWidth = totalWidth * _animation.value;
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: barWidth,
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    boxShadow: widget.showGlow && clamped > 0.05
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.35),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 9. STAGGER FADE SLIDE (Apple-Style Entrance Animation for Staggered Lists)
// ---------------------------------------------------------------------------
class StaggerFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const StaggerFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  State<StaggerFadeSlide> createState() => _StaggerFadeSlideState();
}

class _StaggerFadeSlideState extends State<StaggerFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 10. NEON GLOW CONTAINER (2026 Luminous Cybernetic Border & Ambient Glow)
// ---------------------------------------------------------------------------
class NeonGlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final double borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;

  const NeonGlowContainer({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF00E676),
    this.glowRadius = 16.0,
    this.borderRadius = 20.0,
    this.gradient,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: glowColor.withValues(alpha: 0.28),
              width: 1.2,
            ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.18),
            blurRadius: glowRadius,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.08),
            blurRadius: glowRadius * 2,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
