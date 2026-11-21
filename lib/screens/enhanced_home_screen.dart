import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../config/app_theme.dart';
import '../widgets/macro_rings_widget.dart';
import '../widgets/streak_tracker_widget.dart';
import '../widgets/water_tracker_widget.dart';
import '../widgets/meal_breakdown_widget.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/animated_components.dart';
import '../widgets/nutri_loading_indicator.dart';
import '../models/food_models.dart';
import '../services/health_sync_service.dart';
import '../services/ai_service.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'tip_detail_screen.dart';
import 'meal_planner_screen.dart';
import 'food_comparison_screen.dart';

// ---------------------------------------------------------------------------
// EnhancedHomeScreen — root shell with bottom nav
// ---------------------------------------------------------------------------
class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppStateProvider>();
      if (!provider.isInitialized) {
        provider.initialize();
      }
    });
  }

  void _openScanScreen(BuildContext context,
      [ScanMode mode = ScanMode.vision]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ScanScreen(initialMode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        context.select<AppStateProvider, bool>((p) => p.isDarkMode);
    AppTheme.setDarkMode(isDarkMode);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _DashboardTab(
              onOpenScan: () => _openScanScreen(context),
              onOpenProfile: () => setState(() => _currentIndex = 3),
            ),
            const HistoryScreen(),
            const AnalyticsScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onScanTap: () => _openScanScreen(context),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DashboardTab — the main premium 2026 dashboard
// ---------------------------------------------------------------------------
class _DashboardTab extends StatefulWidget {
  final VoidCallback onOpenScan;
  final VoidCallback? onOpenProfile;

  const _DashboardTab({
    required this.onOpenScan,
    this.onOpenProfile,
  });

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  // Staggered animations for each section
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;

  late final Animation<double> _calorieOpacity;
  late final Animation<Offset> _calorieSlide;

  late final Animation<double> _macroOpacity;
  late final Animation<Offset> _macroSlide;

  late final Animation<double> _actionsOpacity;
  late final Animation<Offset> _actionsSlide;

  late final Animation<double> _mealsOpacity;
  late final Animation<Offset> _mealsSlide;

  late final Animation<double> _waterStreakOpacity;
  late final Animation<Offset> _waterStreakSlide;

  late final Animation<double> _tipsOpacity;
  late final Animation<Offset> _tipsSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Helper to build staggered opacity animations
    Animation<double> opacityAt(double from, double to) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(from, to, curve: Curves.easeOut),
          ),
        );

    // Helper to build staggered slide animations (slide up from bottom)
    Animation<Offset> slideAt(double from, double to) =>
        Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(from, to, curve: Curves.easeOutCubic),
          ),
        );

    _headerOpacity = opacityAt(0.0, 0.3);
    _headerSlide = slideAt(0.0, 0.3);

    _calorieOpacity = opacityAt(0.1, 0.4);
    _calorieSlide = slideAt(0.1, 0.4);

    _macroOpacity = opacityAt(0.2, 0.5);
    _macroSlide = slideAt(0.2, 0.5);

    _actionsOpacity = opacityAt(0.3, 0.6);
    _actionsSlide = slideAt(0.3, 0.6);

    _mealsOpacity = opacityAt(0.45, 0.72);
    _mealsSlide = slideAt(0.45, 0.72);

    _waterStreakOpacity = opacityAt(0.55, 0.82);
    _waterStreakSlide = slideAt(0.55, 0.82);

    _tipsOpacity = opacityAt(0.65, 1.0);
    _tipsSlide = slideAt(0.65, 1.0);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          final today = DateTime.now();
          final summary = provider.getDailyNutritionSummary(today);
          final todayEntries = provider.getEntriesForDate(today);
          final streak = provider.getStreakDays();

          final calories = (summary['calories'] ?? 0).toDouble();
          final calorieTarget = provider.calorieTarget.toDouble();
          final remaining = (calorieTarget - calories).clamp(0, calorieTarget);
          final progress = calorieTarget > 0
              ? (calories / calorieTarget).clamp(0.0, 1.0)
              : 0.0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ----------------------------------------------------------------
              // 1. PREMIUM HERO HEADER
              // ----------------------------------------------------------------
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerOpacity,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _buildHeroHeader(context, provider),
                  ),
                ),
              ),

              // ----------------------------------------------------------------
              // Content feed
              // ----------------------------------------------------------------
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 2. DAILY CALORIE HERO CARD
                    FadeTransition(
                      opacity: _calorieOpacity,
                      child: SlideTransition(
                        position: _calorieSlide,
                        child: _buildCalorieHeroCard(
                          calories: calories,
                          calorieTarget: calorieTarget,
                          remaining: remaining.toDouble(),
                          progress: progress,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. MACRO RINGS — glass container
                    FadeTransition(
                      opacity: _macroOpacity,
                      child: SlideTransition(
                        position: _macroSlide,
                        child: _buildGlassWrapper(
                          child: MacroRingsWidget(
                            calories: summary['calories'] ?? 0,
                            calorieTarget: provider.calorieTarget,
                            protein: summary['protein'] ?? 0,
                            proteinTarget: provider.proteinTarget,
                            carbs: summary['carbs'] ?? 0,
                            carbsTarget: provider.carbsTarget,
                            fat: summary['fat'] ?? 0,
                            fatTarget: provider.fatTarget,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. QUICK ACTION CARDS (horizontal scroll)
                    FadeTransition(
                      opacity: _actionsOpacity,
                      child: SlideTransition(
                        position: _actionsSlide,
                        child: _buildQuickActionsSection(context, provider),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Meal basket banner (if any)
                    if (provider.mealBasket.isNotEmpty) ...[
                      _buildMealBasketBanner(context, provider),
                      const SizedBox(height: 14),
                    ],

                    // 1-tap quick-log favorites
                    if (provider.favorites.isNotEmpty) ...[
                      _buildQuickLogFavoritesCarousel(context, provider),
                      const SizedBox(height: 20),
                    ],

                    // 5. TODAY'S MEALS SECTION
                    FadeTransition(
                      opacity: _mealsOpacity,
                      child: SlideTransition(
                        position: _mealsSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              label: "Today's Meals",
                              icon: Icons.restaurant_rounded,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(height: 10),
                            MealBreakdownWidget(
                              entries: todayEntries,
                              onAddMeal: (mealType) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ScanScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 6. WATER & STREAK ROW
                    FadeTransition(
                      opacity: _waterStreakOpacity,
                      child: SlideTransition(
                        position: _waterStreakSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              label: 'Hydration & Streak',
                              icon: Icons.local_fire_department_rounded,
                              color: AppTheme.accentAmber,
                            ),
                            const SizedBox(height: 10),
                            StreakTrackerWidget(streakDays: streak),
                            const SizedBox(height: 12),
                            WaterTrackerWidget(
                              currentMl: provider.waterIntakeMl,
                              targetMl: provider.waterTargetMl,
                              onAddWater: (amount) =>
                                  provider.addWater(amount),
                              onResetWater: () => provider.resetWater(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 7. AI NUTRITION TIPS
                    FadeTransition(
                      opacity: _tipsOpacity,
                      child: SlideTransition(
                        position: _tipsSlide,
                        child: _buildNutritionTipsSection(context, provider),
                      ),
                    ),

                    // Bottom padding for ModernBottomNav clearance
                    const SizedBox(height: 110),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PREMIUM HERO HEADER
  // -------------------------------------------------------------------------
  Widget _buildHeroHeader(BuildContext context, AppStateProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.greenGlowShadow,
      ),
      child: Row(
        children: [
          // Avatar — tappable
          BouncingWidget(
            scaleFactor: 0.92,
            onTap: () => showPhotoPickerSheet(context, provider),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: UserAvatarWidget(
                photoPath: provider.userPhotoPath,
                userName: provider.userProfileName,
                radius: 24,
                onTap: () => showPhotoPickerSheet(context, provider),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Greeting + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getTimeOfDay()} 👋',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.userProfileName.trim().isNotEmpty
                      ? provider.userProfileName
                      : 'Nutrition User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Right-side controls
          Row(
            children: [
              // Theme toggle
              BouncingWidget(
                scaleFactor: 0.85,
                onTap: () => provider.toggleTheme(),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    provider.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Notification bell
              BouncingWidget(
                scaleFactor: 0.85,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('No new notifications 🔔'),
                      backgroundColor: AppTheme.cardBackground,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // DAILY CALORIE HERO CARD
  // -------------------------------------------------------------------------
  Widget _buildCalorieHeroCard({
    required double calories,
    required double calorieTarget,
    required double remaining,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.greenGlowShadow,
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Big animated calorie number + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedCountText(
                      value: calories.toDouble(),
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'kcal',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: remaining > 0
                        ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                        : AppTheme.macroFat.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: remaining > 0
                          ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                          : AppTheme.macroFat.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    remaining > 0
                        ? '${remaining.toInt()} kcal remaining'
                        : 'Target reached',
                    style: TextStyle(
                      color: remaining > 0
                          ? AppTheme.primaryGreen
                          : AppTheme.macroFat,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Circular progress indicator
          _buildCircularCalorieProgress(progress: progress, target: calorieTarget),
        ],
      ),
    );
  }

  Widget _buildCircularCalorieProgress({
    required double progress,
    required double target,
  }) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          CustomPaint(
            size: const Size(90, 90),
            painter: _ArcPainter(
              progress: 1.0,
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              strokeWidth: 9,
            ),
          ),
          // Fill
          CustomPaint(
            size: const Size(90, 90),
            painter: _ArcPainter(
              progress: progress,
              color: AppTheme.primaryGreen,
              strokeWidth: 9,
            ),
          ),
          // Center label
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // GLASS WRAPPER for MacroRingsWidget
  // -------------------------------------------------------------------------
  Widget _buildGlassWrapper({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.glassBorderGreen),
            boxShadow: AppTheme.softShadow,
          ),
          child: child,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // QUICK ACTIONS SECTION (header + horizontal scroll row)
  // -------------------------------------------------------------------------
  Widget _buildQuickActionsSection(
      BuildContext context, AppStateProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          label: 'Quick Actions',
          icon: Icons.flash_on_rounded,
          color: AppTheme.accentAmber,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // Scan Food
              _buildQuickActionCard(
                label: 'Scan Food',
                icon: Icons.camera_alt_rounded,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
                ),
                onTap: widget.onOpenScan,
              ),

              // Voice Log
              _buildQuickActionCard(
                label: 'Voice Log',
                icon: Icons.mic_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScanScreen(initialMode: ScanMode.voice),
                    ),
                  );
                },
              ),

              // Meal Plan
              _buildQuickActionCard(
                label: 'Meal Plan',
                icon: Icons.calendar_month_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MealPlannerScreen(),
                    ),
                  );
                },
              ),

              // Compare Foods
              _buildQuickActionCard(
                label: 'Compare',
                icon: Icons.balance_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF34D399), Color(0xFF059669)],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FoodComparisonScreen(),
                    ),
                  );
                },
              ),

              // Doctor Report
              _buildQuickActionCard(
                label: 'Dr. Report',
                icon: Icons.medical_services_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
                ),
                onTap: () => _showDoctorReportModal(context, provider),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: isLast ? 0 : 10),
      child: BouncingWidget(
        scaleFactor: 0.93,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SECTION HEADER with accent line
  // -------------------------------------------------------------------------
  Widget _buildSectionHeader({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // MEAL BASKET BANNER
  // -------------------------------------------------------------------------
  Widget _buildMealBasketBanner(
      BuildContext context, AppStateProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentCyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_basket_rounded,
                  color: AppTheme.accentCyan, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal Basket: ${provider.basketTotalItems} items',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Total: ${provider.basketTotalCalories.toInt()} kcal',
                    style: TextStyle(color: AppTheme.accentCyan, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              provider.logEntireBasket();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      'Logged all items in basket to your daily meals! 🧺🥗'),
                  backgroundColor: AppTheme.cardBackground,
                ),
              );
            },
            child: const Text('Log All',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 1-TAP QUICK-LOG FAVORITES CAROUSEL
  // -------------------------------------------------------------------------
  Widget _buildQuickLogFavoritesCarousel(
      BuildContext context, AppStateProvider provider) {
    final favorites = provider.favorites;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          label: 'Quick Log',
          icon: Icons.bolt_rounded,
          color: AppTheme.accentAmber,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, idx) {
              final fav = favorites[idx];
              final parsed =
                  AIService().parseNutritionFromText(fav.nutritionInfo);

              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            fav.foodName,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${parsed.calories.toInt()} kcal',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${parsed.protein.toInt()}g P • ${parsed.carbs.toInt()}g C',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        BouncingWidget(
                          scaleFactor: 0.88,
                          onTap: () {
                            final scanData = ScanData(
                              foodName: fav.foodName,
                              nutritionInfo: fav.nutritionInfo,
                              healthScore: fav.healthScore,
                              recommendations: fav.recommendations,
                              ingredients: fav.ingredients,
                              vitaminsAndMinerals: fav.vitaminsAndMinerals,
                              imagePath: '',
                              novaGroup: fav.novaGroup,
                            );

                            final entry = LoggedFoodEntry(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              scanData: scanData,
                              timestamp: DateTime.now(),
                              parsedNutrition: parsed,
                              mealType: fav.defaultMealType,
                            );

                            provider.addToHistory(entry);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Logged "${fav.foodName}" to ${fav.defaultMealType}! 🥗'),
                                backgroundColor: AppTheme.primaryGreenDark,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add,
                                    size: 14, color: AppTheme.textOnPrimary),
                                const SizedBox(width: 2),
                                Text(
                                  'Log',
                                  style: TextStyle(
                                    color: AppTheme.textOnPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
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
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // DOCTOR / DIETITIAN CLINICAL REPORT MODAL
  // -------------------------------------------------------------------------
  void _showDoctorReportModal(BuildContext context, AppStateProvider provider) {
    final report = HealthSyncService.generateDoctorReport(
      userName: provider.userProfileName,
      history: provider.history,
      targetCalories: provider.calorieTarget.toDouble(),
      targetProtein: provider.proteinTarget.toDouble(),
      targetCarbs: provider.carbsTarget.toDouble(),
      targetFat: provider.fatTarget.toDouble(),
      waterIntakeMl: provider.waterIntakeMl,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_information_rounded,
                          color: AppTheme.primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Clinical Nutrition Report',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Medical-grade summary formatted for your Doctor or Registered Dietitian.',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 380),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    report,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'Copy Report for Doctor / Dietitian',
                  icon: Icons.copy_rounded,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: report));
                    Navigator.pop(modalCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Doctor report copied to clipboard! 📋'),
                        backgroundColor: AppTheme.cardBackground,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // NUTRITION TIPS SECTION
  // -------------------------------------------------------------------------
  Widget _buildNutritionTipsSection(
      BuildContext context, AppStateProvider provider) {
    final tips = provider.nutritionTips.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              label: 'AI Daily Insights',
              icon: Icons.auto_awesome_rounded,
              color: AppTheme.accentPurple,
            ),
            GestureDetector(
              onTap: () => provider.refreshNutritionTips(),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.primaryGreen,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tips.isEmpty)
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NutriLoadingIndicator.card(
                    message: 'Loading daily AI recommendations...',
                  ),
                  const SizedBox(height: 14),
                  GradientButton(
                    text: 'Refresh Recommendations',
                    onPressed: () => provider.loadNutritionTips(),
                  ),
                ],
              ),
            ),
          )
        else
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TipDetailScreen(tip: tip),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryGreen
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.title,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tip.description,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textTertiary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------------------
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ---------------------------------------------------------------------------
// Custom arc painter for calorie circular progress
// ---------------------------------------------------------------------------
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2, // start at top
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
