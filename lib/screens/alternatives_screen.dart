import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../config/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AlternativeFood model (local to this file)
// ─────────────────────────────────────────────────────────────────────────────
class AlternativeFood {
  final String name;
  final String category;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double healthScore;
  final List<String> benefits;
  final String image;
  final String description;

  AlternativeFood({
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.healthScore,
    required this.benefits,
    required this.image,
    required this.description,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AlternativesScreen
// ─────────────────────────────────────────────────────────────────────────────
class AlternativesScreen extends StatefulWidget {
  final ScanData scanData;

  const AlternativesScreen({super.key, required this.scanData});

  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen>
    with TickerProviderStateMixin {
  List<AlternativeFood> _alternatives = [];
  bool _isLoading = true;

  late final AnimationController _shimmerController;
  late final AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadAlternatives();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _loadAlternatives() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _alternatives = _generateAlternatives();
        _isLoading = false;
      });
      _listController.forward();
    });
  }

  String _extractCalories(String nutritionInfo) {
    final RegExp caloriesRegex = RegExp(r'(\d+)\s*cal');
    final match = caloriesRegex.firstMatch(nutritionInfo.toLowerCase());
    return match?.group(1) ?? '250';
  }

  List<AlternativeFood> _generateAlternatives() {
    String scannedFood = widget.scanData.foodName.toLowerCase();
    String category = _determineFoodCategory(scannedFood);

    if (category == 'fruit') {
      return _generateFruitAlternatives(scannedFood);
    } else if (category == 'snack' || category == 'processed') {
      return _generateHealthySnackAlternatives(scannedFood);
    } else if (category == 'protein') {
      return _generateProteinAlternatives(scannedFood);
    } else if (category == 'grain' || category == 'carb') {
      return _generateGrainAlternatives(scannedFood);
    } else if (category == 'dairy') {
      return _generateDairyAlternatives(scannedFood);
    } else if (category == 'vegetable') {
      return _generateVegetableAlternatives(scannedFood);
    } else {
      return _generateGeneralHealthyAlternatives(scannedFood);
    }
  }

  String _determineFoodCategory(String foodName) {
    if (foodName.contains('apple') || foodName.contains('banana') ||
        foodName.contains('orange') || foodName.contains('berry') ||
        foodName.contains('grape') || foodName.contains('mango') ||
        foodName.contains('fruit')) {
      return 'fruit';
    }
    if (foodName.contains('chip') || foodName.contains('cookie') ||
        foodName.contains('candy') || foodName.contains('soda') ||
        foodName.contains('cake') || foodName.contains('chocolate') ||
        foodName.contains('donut') || foodName.contains('ice cream')) {
      return 'snack';
    }
    if (foodName.contains('chicken') || foodName.contains('beef') ||
        foodName.contains('fish') || foodName.contains('egg') ||
        foodName.contains('meat') || foodName.contains('salmon') ||
        foodName.contains('tuna') || foodName.contains('turkey')) {
      return 'protein';
    }
    if (foodName.contains('bread') || foodName.contains('rice') ||
        foodName.contains('pasta') || foodName.contains('cereal') ||
        foodName.contains('oat') || foodName.contains('wheat') ||
        foodName.contains('quinoa') || foodName.contains('grain')) {
      return 'grain';
    }
    if (foodName.contains('milk') || foodName.contains('cheese') ||
        foodName.contains('yogurt') || foodName.contains('butter') ||
        foodName.contains('cream') || foodName.contains('dairy')) {
      return 'dairy';
    }
    if (foodName.contains('carrot') || foodName.contains('broccoli') ||
        foodName.contains('spinach') || foodName.contains('tomato') ||
        foodName.contains('lettuce') || foodName.contains('vegetable') ||
        foodName.contains('pepper') || foodName.contains('onion')) {
      return 'vegetable';
    }
    return 'general';
  }

  List<AlternativeFood> _generateFruitAlternatives(String scannedFood) {
    return [
      AlternativeFood(
        name: 'Fresh Blueberries',
        category: 'Antioxidant-Rich Fruit',
        calories: 84,
        protein: 1.1,
        carbs: 21.5,
        fat: 0.3,
        healthScore: 9.5,
        benefits: ['High Antioxidants', 'Brain Health', 'Low Glycemic'],
        image: '🫐',
        description: 'Packed with antioxidants and perfect for brain health with natural sweetness.',
      ),
      AlternativeFood(
        name: 'Avocado Slices',
        category: 'Healthy Fats Fruit',
        calories: 160,
        protein: 2.0,
        carbs: 8.5,
        fat: 14.7,
        healthScore: 9.3,
        benefits: ['Healthy Fats', 'Fiber Rich', 'Heart Health'],
        image: '🥑',
        description: 'Rich in monounsaturated fats and fiber for sustained energy.',
      ),
      AlternativeFood(
        name: 'Greek Yogurt with Berries',
        category: 'Protein-Rich Alternative',
        calories: 130,
        protein: 15.0,
        carbs: 18.0,
        fat: 2.5,
        healthScore: 9.1,
        benefits: ['High Protein', 'Probiotics', 'Calcium Rich'],
        image: '🍓',
        description: 'Combines fruit sweetness with protein and probiotics for gut health.',
      ),
    ];
  }

  List<AlternativeFood> _generateHealthySnackAlternatives(String scannedFood) {
    return [
      AlternativeFood(
        name: 'Mixed Nuts & Seeds',
        category: 'Healthy Snack',
        calories: 180,
        protein: 6.0,
        carbs: 6.0,
        fat: 15.0,
        healthScore: 9.0,
        benefits: ['Healthy Fats', 'Protein', 'Vitamin E'],
        image: '🥜',
        description: 'Nutrient-dense alternative with healthy fats and sustained energy.',
      ),
      AlternativeFood(
        name: 'Dark Chocolate (70%+)',
        category: 'Antioxidant Treat',
        calories: 155,
        protein: 2.2,
        carbs: 13.0,
        fat: 12.0,
        healthScore: 8.5,
        benefits: ['Antioxidants', 'Heart Health', 'Mood Boost'],
        image: '🍫',
        description: 'Satisfies cravings while providing beneficial antioxidants.',
      ),
      AlternativeFood(
        name: 'Hummus with Vegetables',
        category: 'Fiber-Rich Snack',
        calories: 120,
        protein: 5.0,
        carbs: 15.0,
        fat: 5.0,
        healthScore: 9.2,
        benefits: ['Plant Protein', 'Fiber', 'Low Glycemic'],
        image: '🥕',
        description: 'Satisfying combination of protein, fiber, and nutrients.',
      ),
    ];
  }

  List<AlternativeFood> _generateProteinAlternatives(String scannedFood) {
    return [
      AlternativeFood(
        name: 'Grilled Chicken Breast',
        category: 'Protein',
        calories: 165,
        protein: 31.0,
        carbs: 0.0,
        fat: 3.6,
        healthScore: 9.2,
        benefits: ['High protein', 'Low fat', 'Rich in B vitamins'],
        image: '🍗',
        description: 'Lean protein source with essential amino acids',
      ),
      AlternativeFood(
        name: 'Quinoa Bowl',
        category: 'Grains',
        calories: 222,
        protein: 8.1,
        carbs: 39.4,
        fat: 3.6,
        healthScore: 8.8,
        benefits: ['Complete protein', 'High fiber', 'Gluten-free'],
        image: '🥗',
        description: 'Superfood grain with all essential amino acids',
      ),
      AlternativeFood(
        name: 'Greek Yogurt',
        category: 'Dairy',
        calories: 100,
        protein: 17.0,
        carbs: 6.0,
        fat: 0.4,
        healthScore: 8.5,
        benefits: ['Probiotics', 'High protein', 'Calcium rich'],
        image: '🥛',
        description: 'Probiotic-rich dairy with gut health benefits',
      ),
      AlternativeFood(
        name: 'Avocado Toast',
        category: 'Healthy Fats',
        calories: 234,
        protein: 6.0,
        carbs: 20.0,
        fat: 15.0,
        healthScore: 8.3,
        benefits: ['Healthy fats', 'Fiber rich', 'Heart healthy'],
        image: '🥑',
        description: 'Monounsaturated fats for heart health',
      ),
      AlternativeFood(
        name: 'Salmon Fillet',
        category: 'Seafood',
        calories: 206,
        protein: 22.0,
        carbs: 0.0,
        fat: 12.0,
        healthScore: 9.5,
        benefits: ['Omega-3 fatty acids', 'High protein', 'Brain health'],
        image: '🐟',
        description: 'Rich in omega-3s for brain and heart health',
      ),
    ];
  }

  List<AlternativeFood> _generateGrainAlternatives(String scannedFood) {
    return [
      AlternativeFood(
        name: 'Brown Rice Bowl',
        category: 'Whole Grain',
        calories: 216,
        protein: 5.0,
        carbs: 45.0,
        fat: 1.8,
        healthScore: 8.7,
        benefits: ['Whole Grain', 'Fiber Rich', 'B Vitamins'],
        image: '🍚',
        description: 'Nutrient-dense whole grain with sustained energy release.',
      ),
      AlternativeFood(
        name: 'Quinoa Salad',
        category: 'Complete Protein Grain',
        calories: 222,
        protein: 8.1,
        carbs: 39.4,
        fat: 3.6,
        healthScore: 9.0,
        benefits: ['Complete Protein', 'Gluten-Free', 'High Fiber'],
        image: '🥗',
        description: 'Superfood grain with all essential amino acids.',
      ),
      AlternativeFood(
        name: 'Overnight Oats',
        category: 'Heart-Healthy Grain',
        calories: 180,
        protein: 6.0,
        carbs: 32.0,
        fat: 3.5,
        healthScore: 8.5,
        benefits: ['Beta-Glucan', 'Heart Health', 'Sustained Energy'],
        image: '🥣',
        description: 'Soluble fiber that helps reduce cholesterol levels.',
      ),
    ];
  }

  List<AlternativeFood> _generateDairyAlternatives(String scannedFood) {
    return [
      AlternativeFood(
        name: 'Greek Yogurt',
        category: 'Probiotic Dairy',
        calories: 100,
        protein: 17.0,
        carbs: 6.0,
        fat: 0.4,
        healthScore: 9.1,
        benefits: ['Probiotics', 'High Protein', 'Calcium'],
        image: '🥛',
        description: 'Gut-friendly dairy packed with beneficial bacteria.',
      ),
      AlternativeFood(
        name: 'Cottage Cheese',
        category: 'High-Protein Dairy',
        calories: 98,
        protein: 11.0,
        carbs: 3.4,
        fat: 4.3,
        healthScore: 8.8,
        benefits: ['Casein Protein', 'Low Carb', 'Calcium Rich'],
        image: '🧀',
        description: 'Slow-digesting protein ideal for muscle recovery.',
      ),
      AlternativeFood(
        name: 'Almond Milk (Unsweetened)',
        category: 'Plant-Based Alternative',
        calories: 40,
        protein: 1.0,
        carbs: 2.0,
        fat: 3.0,
        healthScore: 8.3,
        benefits: ['Low Calorie', 'Lactose-Free', 'Vitamin E'],
        image: '🥛',
        description: 'Light, nutritious alternative for lactose-sensitive individuals.',
      ),
    ];
  }

  List<AlternativeFood> _generateVegetableAlternatives(String scannedFood) {
    return [
      AlternativeFood(
        name: 'Roasted Rainbow Vegetables',
        category: 'Antioxidant Powerhouse',
        calories: 85,
        protein: 3.0,
        carbs: 18.0,
        fat: 1.0,
        healthScore: 9.4,
        benefits: ['High Antioxidants', 'Fiber Rich', 'Vitamin Packed'],
        image: '🥕',
        description: 'Colorful mix of nutrients supporting overall health.',
      ),
      AlternativeFood(
        name: 'Kale & Spinach Salad',
        category: 'Leafy Green Powerhouse',
        calories: 35,
        protein: 4.0,
        carbs: 7.0,
        fat: 0.5,
        healthScore: 9.6,
        benefits: ['Iron Rich', 'Folate', 'Vitamin K'],
        image: '🥬',
        description: 'Nutrient-dense greens supporting bone and blood health.',
      ),
      AlternativeFood(
        name: 'Roasted Sweet Potato',
        category: 'Complex Carb Vegetable',
        calories: 112,
        protein: 2.0,
        carbs: 26.0,
        fat: 0.1,
        healthScore: 8.9,
        benefits: ['Beta-Carotene', 'Fiber', 'Potassium'],
        image: '🍠',
        description: 'Natural sweetness with immune-boosting nutrients.',
      ),
    ];
  }

  List<AlternativeFood> _generateGeneralHealthyAlternatives(String scannedFood) {
    return [
      AlternativeFood(
        name: 'Mediterranean Bowl',
        category: 'Balanced Meal',
        calories: 320,
        protein: 12.0,
        carbs: 35.0,
        fat: 15.0,
        healthScore: 9.2,
        benefits: ['Balanced Macros', 'Heart Healthy', 'Anti-Inflammatory'],
        image: '🥗',
        description: 'Complete meal following Mediterranean diet principles.',
      ),
      AlternativeFood(
        name: 'Green Smoothie',
        category: 'Nutrient Dense Drink',
        calories: 150,
        protein: 5.0,
        carbs: 30.0,
        fat: 2.0,
        healthScore: 8.8,
        benefits: ['Vitamins & Minerals', 'Hydrating', 'Antioxidants'],
        image: '🥤',
        description: 'Liquid nutrition packed with fruits and vegetables.',
      ),
      AlternativeFood(
        name: 'Trail Mix (Unsweetened)',
        category: 'Energy Snack',
        calories: 190,
        protein: 6.0,
        carbs: 16.0,
        fat: 12.0,
        healthScore: 8.4,
        benefits: ['Healthy Fats', 'Sustained Energy', 'Portable'],
        image: '🥜',
        description: 'Perfect on-the-go snack with natural energy boost.',
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Premium header ──────────────────────────────────────────
              SliverToBoxAdapter(child: _buildPremiumHeader()),

              // ── Scanned food comparison card ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildComparisonCard(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Section label ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSectionHeader('Recommended Alternatives'),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Content (loading / list / empty) ───────────────────────
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildShimmerCard(),
                      childCount: 3,
                    ),
                  ),
                )
              else if (_alternatives.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) {
                        final delay = index * 0.1;
                        return AnimatedBuilder(
                          animation: _listController,
                          builder: (ctx, child) {
                            final t = (_listController.value - delay).clamp(0.0, 1.0);
                            final curve = Curves.easeOutCubic.transform(t);
                            return Opacity(
                              opacity: curve,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - curve)),
                                child: child,
                              ),
                            );
                          },
                          child: _buildAlternativeCard(_alternatives[index]),
                        );
                      },
                      childCount: _alternatives.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Premium header ─────────────────────────────────────────────────────────
  Widget _buildPremiumHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          // Title
          Expanded(
            child: Text(
              'Healthier Alternatives',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          // Healthier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_rounded, color: Colors.black, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_alternatives.length} options',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer skeleton card ──────────────────────────────────────────────────
  Widget _buildShimmerCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        final shimmerPos = _shimmerController.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment(-1 + shimmerPos * 3, 0),
              end: Alignment(shimmerPos * 3, 0),
              colors: [
                AppTheme.surfaceLight,
                AppTheme.surfaceLight.withValues(alpha: 0.5),
                AppTheme.glassBorder.withValues(alpha: 0.6),
                AppTheme.surfaceLight.withValues(alpha: 0.5),
                AppTheme.surfaceLight,
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon area placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.glassBorder.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color: AppTheme.glassBorder.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 11,
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.glassBorder.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: List.generate(4, (i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            height: 24,
                            width: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.glassBorder.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Comparison card (scanned food) ─────────────────────────────────────────
  Widget _buildComparisonCard() {
    final origCals = int.tryParse(_extractCalories(widget.scanData.nutritionInfo)) ?? 250;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon area
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9A44), Color(0xFFFC6076)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.fastfood_rounded, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.scanData.foodName,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$origCals kcal',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.recommend_rounded, color: Colors.black, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── Alternative food card ──────────────────────────────────────────────────
  Widget _buildAlternativeCard(AlternativeFood alternative) {
    final gradients = [
      const LinearGradient(colors: [Color(0xFF00C774), Color(0xFF009B58)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
    ];
    final gradIndex = alternative.name.length % gradients.length;
    final grad = gradients[gradIndex];
    final scoreColor = _getHealthScoreColor(alternative.healthScore);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: icon + name + badges ─────────────────────────
              Row(
                children: [
                  // Gradient icon area
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: grad,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _isSingleEmoji(alternative.image)
                          ? Text(
                              alternative.image,
                              style: const TextStyle(fontSize: 28),
                            )
                          : Icon(
                              _getFoodIcon(alternative.category),
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alternative.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            // Health score badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: scoreColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: scoreColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${alternative.healthScore}/10',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          alternative.category,
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Description
              Text(
                alternative.description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              // ── Nutrition badges ───────────────────────────────────────
              _buildNutritionBadgesRow(alternative),

              const SizedBox(height: 12),

              // ── Bottom row: benefits ──────────────────
              if (alternative.benefits.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: alternative.benefits.map((benefit) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.glassBorder),
                          ),
                          child: Text(
                            benefit,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Nutrition badges row with "vs Original" ────────────────────────────────
  Widget _buildNutritionBadgesRow(AlternativeFood alternative) {
    final origCals = int.tryParse(_extractCalories(widget.scanData.nutritionInfo)) ?? 250;
    final calDiff = origCals - alternative.calories;
    final calDiffStr = calDiff > 0 ? '-$calDiff' : '+${calDiff.abs()}';
    final calDiffColor = calDiff > 0 ? AppTheme.primaryGreen : AppTheme.errorRed;

    return Row(
      children: [
        // Calories badge
        Expanded(
          child: _buildNutritionBadge(
            label: 'Calories',
            value: '${alternative.calories}',
            color: const Color(0xFFFF9A44),
          ),
        ),
        const SizedBox(width: 6),
        // Protein badge
        Expanded(
          child: _buildNutritionBadge(
            label: 'Protein',
            value: '${alternative.protein.toStringAsFixed(1)}g',
            color: const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(width: 6),
        // vs Original diff
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: calDiffColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: calDiffColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text(
                  calDiffStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: calDiffColor,
                  ),
                ),
                Text(
                  'vs Original',
                  style: TextStyle(fontSize: 9, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🥦', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              'No Alternatives Found',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find healthier alternatives for "${widget.scanData.foodName}" right now.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  bool _isSingleEmoji(String s) {
    if (s.isEmpty) return false;
    final runes = s.runes.toList();
    // Simple heuristic: 1-2 runes for most emojis
    return runes.length <= 2;
  }

  IconData _getFoodIcon(String category) {
    switch (category.toLowerCase()) {
      case 'protein':
        return Icons.fitness_center;
      case 'grains':
        return Icons.grain;
      case 'dairy':
        return Icons.local_drink;
      case 'healthy fats':
        return Icons.favorite;
      case 'seafood':
        return Icons.set_meal;
      default:
        return Icons.restaurant;
    }
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 9.0) return Colors.green;
    if (score >= 8.0) return AppTheme.primaryGreen;
    if (score >= 7.0) return Colors.orange;
    return Colors.red;
  }
}
