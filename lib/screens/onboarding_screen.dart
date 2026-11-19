import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../widgets/animated_components.dart';
import 'user_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Animation Controllers
  late final AnimationController _scannerAnimController;
  late final Animation<double> _scanLineAnimation;

  late final AnimationController _pulseAnimController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _ringsAnimController;
  late final Animation<double> _ringsProgressAnimation;

  late final AnimationController _waveAnimController;

  @override
  void initState() {
    super.initState();

    // 1. High-tech scanning laser line (Slide 1)
    _scannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.06, end: 0.94).animate(
      CurvedAnimation(
        parent: _scannerAnimController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // 2. Breathing pulse animation for reticles, glow, and badges
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Concentric rings entrance animation (Slide 2)
    _ringsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _ringsProgressAnimation = CurvedAnimation(
      parent: _ringsAnimController,
      curve: Curves.easeOutCubic,
    );

    // 4. Hydration liquid wave animation (Slide 3)
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _ringsAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scannerAnimController.dispose();
    _pulseAnimController.dispose();
    _ringsAnimController.dispose();
    _waveAnimController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) =>
              const UserSetupScreen(isFirstTime: true),
          transitionsBuilder: (context, anim, secAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    }
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      _ringsAnimController.reset();
      _ringsAnimController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Dynamic Ambient Glow Backdrop
          _buildAmbientBackdrop(),

          SafeArea(
            child: Column(
              children: [
                // Top Header (Brand + Skip)
                _buildTopBar(),

                // 3 Clean Minimal Slide Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildScannerSlide(),
                      _buildMacroRingsSlide(),
                      _buildHabitsAndCoachSlide(),
                    ],
                  ),
                ),

                // Floating Bottom Control Dock
                _buildBottomDock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. Dynamic Ambient Glow Backdrop
  // ===========================================================================
  Widget _buildAmbientBackdrop() {
    Color glowColor;
    Alignment glowAlignment;

    switch (_currentIndex) {
      case 0:
        glowColor = AppTheme.primaryGreen;
        glowAlignment = const Alignment(0.0, -0.45);
        break;
      case 1:
        glowColor = AppTheme.macroProtein;
        glowAlignment = const Alignment(0.0, -0.35);
        break;
      case 2:
      default:
        glowColor = const Color(0xFFF59E0B);
        glowAlignment = const Alignment(0.0, -0.40);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: glowAlignment,
          radius: 0.95,
          colors: [
            glowColor.withValues(alpha: 0.16),
            glowColor.withValues(alpha: 0.04),
            AppTheme.backgroundDark,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. Top App Bar (NutriScan Brand & Skip Button)
  // ===========================================================================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // NutriScan Brand Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                        blurRadius: 8,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'NUTRISCAN',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Skip Button
          AnimatedOpacity(
            opacity: _currentIndex < 2 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: _currentIndex < 2
                ? BouncingWidget(
                    onTap: _completeOnboarding,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.glassBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: 48),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. SLIDE 1: Clean AI Vision Scanner
  // ===========================================================================
  Widget _buildScannerSlide() {
    final isDark =
        Theme.of(context).brightness == Brightness.dark || AppTheme.isDark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Clean, Large, Bold Title
          Text(
            'Scan Meals & Labels',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 29,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 24),

          // Central Showcase: Minimal Scanner Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.35 : 0.25),
            child: Column(
              children: [
                // Camera Viewfinder Box
                Container(
                  height: 215,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF09120D) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.primaryGreen.withValues(alpha: 0.28)
                          : AppTheme.primaryGreen.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.06),
                        blurRadius: isDark ? 16 : 14,
                        offset: const Offset(0, 4),
                      ),
                      if (!isDark)
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle Tech Grid Lines
                        RepaintBoundary(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _ScannerGridPainter(
                              gridColor: isDark
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.08)
                                  : AppTheme.primaryGreen.withValues(alpha: 0.12),
                            ),
                          ),
                        ),

                        // Viewfinder Corner Brackets
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: ViewfinderBracketPainter(
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),

                        // Center Gourmet Bowl Plate
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.primaryGreen.withValues(
                                      alpha: isDark ? 0.25 : 0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: isDark
                                        ? const [
                                            Color(0xFF1B2E23),
                                            Color(0xFF0F1B14),
                                          ]
                                        : const [
                                            Color(0xFFE8F6ED),
                                            Color(0xFFDCF2E4),
                                          ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: isDark ? 0.7 : 0.8),
                                    width: 1.6,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: isDark ? 0.35 : 0.22),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.eco_rounded,
                                    size: 34,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Animated Laser Beam Line
                        AnimatedBuilder(
                          animation: _scanLineAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 215 * _scanLineAnimation.value,
                              left: 14,
                              right: 14,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          AppTheme.primaryGreen.withValues(alpha: 0.28),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 2.2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          AppTheme.primaryGreen,
                                          Colors.white,
                                          AppTheme.primaryGreen,
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryGreen,
                                          blurRadius: 10,
                                          spreadRadius: 1.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppTheme.primaryGreen.withValues(alpha: 0.28),
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

                        // Detected Item (Top Left)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xE60A120E)
                                  : Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: isDark ? 0.5 : 0.4),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: isDark ? 0.3 : 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Salmon Quinoa Bowl',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Nutri-Score A Badge (Top Right)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              'Nutri-Score A',
                              style: TextStyle(
                                color: AppTheme.textOnPrimary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3 Core Metric Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMicroNutrientPill(
                      label: 'Calories',
                      value: '520 kcal',
                      color: AppTheme.primaryGreen,
                      icon: Icons.local_fire_department_rounded,
                    ),
                    _buildMicroNutrientPill(
                      label: 'Protein',
                      value: '34 g',
                      color: AppTheme.macroProtein,
                      icon: Icons.fitness_center_rounded,
                    ),
                    _buildMicroNutrientPill(
                      label: 'Health',
                      value: '98 / 100',
                      color: AppTheme.macroCarbs,
                      icon: Icons.eco_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. SLIDE 2: Clean Concentric Macro Rings
  // ===========================================================================
  Widget _buildMacroRingsSlide() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Clean, Large, Bold Title
          Text(
            'Precision Macro Rings',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 29,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 24),

          // Central Showcase: Concentric Rings Card
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            borderColor: AppTheme.macroProtein.withValues(alpha: 0.35),
            child: Column(
              children: [
                // Rings Painter Container with Center Energy Display
                SizedBox(
                  height: 195,
                  width: 195,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _ringsProgressAnimation,
                        builder: (context, child) {
                          return RepaintBoundary(
                            child: CustomPaint(
                              size: const Size(195, 195),
                              painter: ConcentricMacroRingsPainter(
                                calorieProgress: 0.72 * _ringsProgressAnimation.value,
                                proteinProgress: 0.82 * _ringsProgressAnimation.value,
                                carbProgress: 0.65 * _ringsProgressAnimation.value,
                                fatProgress: 0.52 * _ringsProgressAnimation.value,
                              ),
                            ),
                          );
                        },
                      ),

                      // Center Energy Display
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 26,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '1,520',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          Text(
                            'of 2,100 kcal',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '72% DONE',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4 Concentric Stat Cards (2x2 Grid)
                Row(
                  children: [
                    Expanded(
                      child: _buildRingMetricCard(
                        title: 'Calories',
                        value: '1,520 kcal',
                        percent: '72%',
                        color: AppTheme.primaryGreen,
                        icon: Icons.local_fire_department_rounded,
                        progress: 0.72,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRingMetricCard(
                        title: 'Protein',
                        value: '115 / 140g',
                        percent: '82%',
                        color: AppTheme.macroProtein,
                        icon: Icons.fitness_center_rounded,
                        progress: 0.82,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRingMetricCard(
                        title: 'Carbs',
                        value: '143 / 220g',
                        percent: '65%',
                        color: AppTheme.macroCarbs,
                        icon: Icons.grain_rounded,
                        progress: 0.65,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRingMetricCard(
                        title: 'Fats',
                        value: '34 / 65g',
                        percent: '52%',
                        color: AppTheme.macroFat,
                        icon: Icons.opacity_rounded,
                        progress: 0.52,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. SLIDE 3: Clean Streaks & AI Coaching
  // ===========================================================================
  Widget _buildHabitsAndCoachSlide() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Clean, Large, Bold Title
          Text(
            'Streaks & AI Coaching',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 29,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 24),

          // Central Showcase: Streak & Hydration Card
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 7-Day Streak Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '7 Days Streak',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.fireGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'ON FIRE 🔥',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 7 Day Bubble Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDayStreakPill('M', true),
                    _buildDayStreakPill('T', true),
                    _buildDayStreakPill('W', true),
                    _buildDayStreakPill('T', true),
                    _buildDayStreakPill('F', true),
                    _buildDayStreakPill('S', true),
                    _buildDayStreakPill('S', true, isToday: true),
                  ],
                ),

                const SizedBox(height: 18),
                Divider(color: AppTheme.glassBorder, height: 1),
                const SizedBox(height: 16),

                // Hydration Tracker Preview with Wave Liquid Effect
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.macroProtein.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.macroProtein.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: AppTheme.macroProtein,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hydration Goal',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '1,750 / 2,500 ml',
                                style: TextStyle(
                                  color: AppTheme.macroProtein,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedBuilder(
                              animation: _waveAnimController,
                              builder: (context, child) {
                                return SizedBox(
                                  height: 9,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: _LiquidProgressWavePainter(
                                      progress: 0.70,
                                      wavePhase: _waveAnimController.value * 2 * math.pi,
                                      primaryColor: AppTheme.macroProtein,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Clean AI Coach Insight Pill
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.primaryGreen,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '"You\'re 25g away from your protein target! A bowl of greek yogurt will close your ring perfectly."',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.95),
                            fontSize: 12,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. Floating Bottom Navigation Dock
  // ===========================================================================
  Widget _buildBottomDock() {
    final isLast = _currentIndex == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark || AppTheme.isDark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xE60D1913) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppTheme.primaryGreen.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isDark ? 20 : 22,
            offset: const Offset(0, 6),
          ),
          if (!isDark)
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          if (_currentIndex > 0)
            BouncingWidget(
              onTap: _previousPage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF1F6F3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    size: 19,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 44),

          // Expanding Page Indicators
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isSelected = _currentIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: isSelected ? 30 : 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected
                        ? null
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFFD2DDD6)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryGreen
                                  .withValues(alpha: isDark ? 0.65 : 0.45),
                              blurRadius: 10,
                              spreadRadius: 1.2,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),

          // Next / Get Started Action Button
          BouncingWidget(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isLast ? 22 : 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.55),
                    blurRadius: 16,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLast ? 'Get Started' : 'Next',
                    style: TextStyle(
                      color: AppTheme.textOnPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isLast ? Icons.bolt_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppTheme.textOnPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Helper UI Components
  // ===========================================================================
  Widget _buildMicroNutrientPill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingMetricCard({
    required String title,
    required String value,
    required String percent,
    required Color color,
    required IconData icon,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 5),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                percent,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3.5,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStreakPill(String day, bool completed, {bool isToday = false}) {
    return Container(
      width: 38,
      height: 48,
      decoration: BoxDecoration(
        color: completed
            ? AppTheme.primaryGreen.withValues(alpha: 0.18)
            : AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppTheme.primaryGreen
              : completed
                  ? AppTheme.primaryGreen.withValues(alpha: 0.35)
                  : Colors.transparent,
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              color: completed ? AppTheme.primaryGreen : AppTheme.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Icon(
            completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: completed ? AppTheme.primaryGreen : AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Custom Painters
// =============================================================================

class _ScannerGridPainter extends CustomPainter {
  final Color gridColor;
  _ScannerGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    const step = 28.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}

class ViewfinderBracketPainter extends CustomPainter {
  final Color color;
  ViewfinderBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 22.0;
    const padding = 12.0;

    // Top-Left
    canvas.drawLine(
      const Offset(padding, padding + corner),
      const Offset(padding, padding),
      paint,
    );
    canvas.drawLine(
      const Offset(padding, padding),
      const Offset(padding + corner, padding),
      paint,
    );

    // Top-Right
    canvas.drawLine(
      Offset(size.width - padding - corner, padding),
      Offset(size.width - padding, padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(size.width - padding, padding + corner),
      paint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(padding, size.height - padding - corner),
      Offset(padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(padding + corner, size.height - padding),
      paint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(size.width - padding - corner, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, size.height - padding),
      Offset(size.width - padding, size.height - padding - corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConcentricMacroRingsPainter extends CustomPainter {
  final double calorieProgress;
  final double proteinProgress;
  final double carbProgress;
  final double fatProgress;

  ConcentricMacroRingsPainter({
    required this.calorieProgress,
    required this.proteinProgress,
    required this.carbProgress,
    required this.fatProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 9.5;
    const ringSpacing = 13.5;

    _drawRing(
      canvas,
      center,
      radius: (size.width / 2) - 8,
      strokeWidth: strokeWidth,
      progress: calorieProgress,
      color: AppTheme.primaryGreen,
    );

    _drawRing(
      canvas,
      center,
      radius: (size.width / 2) - 8 - ringSpacing,
      strokeWidth: strokeWidth,
      progress: proteinProgress,
      color: AppTheme.macroProtein,
    );

    _drawRing(
      canvas,
      center,
      radius: (size.width / 2) - 8 - (ringSpacing * 2),
      strokeWidth: strokeWidth,
      progress: carbProgress,
      color: AppTheme.macroCarbs,
    );

    _drawRing(
      canvas,
      center,
      radius: (size.width / 2) - 8 - (ringSpacing * 3),
      strokeWidth: strokeWidth,
      progress: fatProgress,
      color: AppTheme.macroFat,
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double strokeWidth,
    required double progress,
    required Color color,
  }) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = (2 * math.pi) * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant ConcentricMacroRingsPainter oldDelegate) {
    return oldDelegate.calorieProgress != calorieProgress ||
        oldDelegate.proteinProgress != proteinProgress ||
        oldDelegate.carbProgress != carbProgress ||
        oldDelegate.fatProgress != fatProgress;
  }
}

class _LiquidProgressWavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color primaryColor;

  _LiquidProgressWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    if (progress <= 0) return;

    final fillWidth = size.width * progress.clamp(0.0, 1.0);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.7),
          primaryColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, fillWidth, size.height));

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(fillWidth, 0);

    const waveAmp = 1.5;
    for (double y = 0; y <= size.height; y += 1) {
      final xOffset = math.sin((y / size.height * 2 * math.pi) + wavePhase) * waveAmp;
      path.lineTo((fillWidth + xOffset).clamp(0.0, size.width), y);
    }

    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidProgressWavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase || oldDelegate.progress != progress;
  }
}
