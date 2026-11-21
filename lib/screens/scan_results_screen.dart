import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/food_models.dart';
import '../config/app_theme.dart';
import '../widgets/animated_components.dart';
import '../widgets/nutri_loading_indicator.dart';
import '../services/ai_service.dart';
import 'alternatives_screen.dart';
import 'enhanced_home_screen.dart';
import 'food_comparison_screen.dart';

class ScanResultsScreen extends StatefulWidget {
  const ScanResultsScreen({super.key});

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  String _selectedMeal = 'Breakfast';
  double _quantityCount = 1.0;
  bool _isGramMode = false;
  double _customGrams = 100.0;
  String? _initializedFoodId;

  @override
  void initState() {
    super.initState();
    _selectedMeal = _getMealTypeFromCurrentTime();
  }

  void _initPortionState(ScanData scanData) {
    if (_initializedFoodId != scanData.id) {
      _initializedFoodId = scanData.id;
      _quantityCount =
          scanData.itemCount > 1 ? scanData.itemCount.toDouble() : 1.0;
      _customGrams = scanData.unitWeightGrams > 0
          ? (scanData.unitWeightGrams * _quantityCount)
          : 100.0;
      _isGramMode = false;
    }
  }

  double _getEffectiveMultiplier(ScanData scanData) {
    if (_isGramMode) {
      final baseGrams =
          scanData.unitWeightGrams > 0 ? scanData.unitWeightGrams : 100.0;
      return (_customGrams / baseGrams).clamp(0.05, 50.0);
    } else {
      return _quantityCount.clamp(0.1, 50.0);
    }
  }

  String _getEffectivePortionLabel(ScanData scanData) {
    if (_isGramMode) {
      return '${_customGrams.toInt()}g';
    } else {
      final countStr = _quantityCount == _quantityCount.toInt()
          ? '${_quantityCount.toInt()}'
          : _quantityCount.toStringAsFixed(1);
      final unit = scanData.unitName.isNotEmpty ? scanData.unitName : 'piece';
      return '$countStr $unit${_quantityCount > 1 ? "s" : ""}';
    }
  }

  String _getMealTypeFromCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 19) return 'Dinner';
    return 'Snacks';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Consumer<AppStateProvider>(
          builder: (context, provider, child) {
            final scanData = provider.currentScanData;

            if (scanData == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.no_food_rounded,
                      color: AppTheme.textSecondary,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No scan data available',
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      text: 'Back to Home',
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const EnhancedHomeScreen()),
                        (route) => false,
                      ),
                    ),
                  ],
                ),
              );
            }

            _initPortionState(scanData);
            final baseNutrition = scanData.singleItemParsedNutrition;

            return SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EnhancedHomeScreen()),
                              (route) => false,
                            ),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: AppTheme.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          Text(
                            'Scan Analysis',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Nutrition card ready to share!'),
                                  backgroundColor: AppTheme.cardBackground,
                                ),
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.share_rounded,
                                color: AppTheme.textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content Body
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. Food Hero Card
                        _buildFoodHeroCard(scanData, provider),

                        const SizedBox(height: 14),

                        // 2. AI Portion & Precision Quantity Selector Card
                        _buildQuantityAndPortionCard(scanData),

                        const SizedBox(height: 14),

                        // 3. Allergen Alert Banner (if allergens detected)
                        if (scanData.allergens.isNotEmpty) ...[
                          _buildAllergenBanner(scanData.allergens),
                          const SizedBox(height: 14),
                        ],

                        // 4. Yuka-Style NOVA Group & Harmful Additives Meter
                        _buildNovaAndAdditivesCard(scanData),

                        const SizedBox(height: 16),

                        // 5. Nutri-Score & Health Rating Meter
                        _buildNutriScoreCard(scanData),

                        const SizedBox(height: 16),

                        // 6. Macronutrients Breakdown Grid
                        _buildMacrosGrid(baseNutrition, scanData),

                        const SizedBox(height: 16),

                        // 7. Interactive AI Nutrition Coach Card
                        _buildAskCoachCard(context, scanData),

                        const SizedBox(height: 16),

                        // 8. Vitamins & Minerals Meter
                        if (scanData.vitaminsAndMinerals.isNotEmpty)
                          _buildMicronutrientsCard(
                              scanData.vitaminsAndMinerals, scanData),

                        const SizedBox(height: 16),

                        // 9. AI Dietary Recommendations
                        _buildAiRecommendationsCard(scanData.recommendations),

                        const SizedBox(height: 20),

                        // 10. Meal Slot Selector
                        _buildMealSelectorCard(scanData),

                        const SizedBox(height: 24),

                        // 11. Action Buttons (Save to Log, Basket, Compare, Alternatives)
                        _buildBottomActionButtons(
                            context, scanData, baseNutrition),

                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFoodHeroCard(ScanData scanData, AppStateProvider provider) {
    final isFav = provider.isFavorite(scanData.foodName);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Food Image preview with Hero animation
          Hero(
            tag: 'food_hero_image_${scanData.id}',
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.surfaceLight,
                border: Border.all(
                  color: AppTheme.surfaceLight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: (scanData.imagePath.isNotEmpty &&
                        File(scanData.imagePath).existsSync())
                    ? Image.file(
                        File(scanData.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.restaurant_rounded,
                          color: AppTheme.primaryGreen,
                          size: 36,
                        ),
                      )
                    : (scanData.imagePath.startsWith('http')
                        ? Image.network(
                            scanData.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.restaurant_rounded,
                              color: AppTheme.primaryGreen,
                              size: 36,
                            ),
                          )
                        : Icon(
                            Icons.restaurant_rounded,
                            color: AppTheme.primaryGreen,
                            size: 36,
                          )),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Food Title & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        scanData.foodName,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BouncingWidget(
                      scaleFactor: 0.85,
                      onTap: () {
                        provider.toggleFavorite(scanData);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !isFav
                                  ? 'Added "${scanData.foodName}" to Favorites ❤️'
                                  : 'Removed from Favorites.',
                            ),
                            backgroundColor: AppTheme.cardBackground,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isFav
                              ? Colors.redAccent.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color:
                              isFav ? Colors.redAccent : AppTheme.textTertiary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      scanData.itemCount > 1
                          ? Icons.collections_rounded
                          : Icons.scale_rounded,
                      size: 13,
                      color: scanData.itemCount > 1
                          ? AppTheme.accentCyan
                          : AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        scanData.itemCount > 1
                            ? '${scanData.itemCount} ${scanData.unitName}s detected'
                            : '${scanData.servingSize} • ${scanData.singleItemParsedNutrition.calories.toInt()} kcal',
                        style: TextStyle(
                          color: scanData.itemCount > 1
                              ? AppTheme.accentCyan
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityAndPortionCard(ScanData scanData) {
    final baseNutrition = scanData.singleItemParsedNutrition;
    final singleCals = baseNutrition.calories.toInt();
    final totalCals = (baseNutrition.calories * scanData.itemCount).toInt();
    final unit = scanData.unitName.isNotEmpty ? scanData.unitName : 'piece';
    final portionLabel = _getEffectivePortionLabel(scanData);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: scanData.itemCount > 1
          ? AppTheme.accentCyan.withValues(alpha: 0.5)
          : AppTheme.primaryGreen.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: (scanData.itemCount > 1
                                ? AppTheme.accentCyan
                                : AppTheme.primaryGreen)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        scanData.itemCount > 1
                            ? Icons.auto_awesome
                            : Icons.scale_rounded,
                        color: scanData.itemCount > 1
                            ? AppTheme.accentCyan
                            : AppTheme.primaryGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portion & Quantity',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Serving: ${scanData.servingSize}',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Unit Switcher: Count vs Grams
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isGramMode = false;
                          if (scanData.unitWeightGrams > 0) {
                            _quantityCount =
                                (_customGrams / scanData.unitWeightGrams)
                                    .clamp(0.5, 30.0);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: !_isGramMode
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Pieces',
                          style: TextStyle(
                            color: !_isGramMode
                                ? Colors.black
                                : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: !_isGramMode
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isGramMode = true;
                          if (scanData.unitWeightGrams > 0) {
                            _customGrams =
                                (scanData.unitWeightGrams * _quantityCount)
                                    .clamp(25.0, 2000.0);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isGramMode
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Grams',
                          style: TextStyle(
                            color: _isGramMode
                                ? Colors.black
                                : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight:
                                _isGramMode ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // If AI detected multiple items (e.g., 3 apples in photo):
          if (scanData.itemCount > 1) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.accentCyan.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.collections_rounded,
                          color: AppTheme.accentCyan, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${scanData.itemCount} ${unit}s detected',
                          style: TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Quick Select: 1 Item (Just 1)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isGramMode = false;
                              _quantityCount = 1.0;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: (!_isGramMode && _quantityCount == 1.0)
                                  ? AppTheme.accentCyan
                                  : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (!_isGramMode && _quantityCount == 1.0)
                                    ? AppTheme.accentCyan
                                    : AppTheme.glassBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Just 1 $unit',
                                  style: TextStyle(
                                    color:
                                        (!_isGramMode && _quantityCount == 1.0)
                                            ? Colors.black
                                            : AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$singleCals kcal • ~${scanData.unitWeightGrams.toInt()}g',
                                  style: TextStyle(
                                    color:
                                        (!_isGramMode && _quantityCount == 1.0)
                                            ? Colors.black87
                                            : AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick Select: All items in photo
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isGramMode = false;
                              _quantityCount = scanData.itemCount.toDouble();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: (!_isGramMode &&
                                      _quantityCount ==
                                          scanData.itemCount.toDouble())
                                  ? AppTheme.accentCyan
                                  : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (!_isGramMode &&
                                        _quantityCount ==
                                            scanData.itemCount.toDouble())
                                    ? AppTheme.accentCyan
                                    : AppTheme.glassBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'All ${scanData.itemCount} ${unit}s',
                                  style: TextStyle(
                                    color: (!_isGramMode &&
                                            _quantityCount ==
                                                scanData.itemCount.toDouble())
                                        ? Colors.black
                                        : AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalCals kcal • ~${(scanData.unitWeightGrams * scanData.itemCount).toInt()}g',
                                  style: TextStyle(
                                    color: (!_isGramMode &&
                                            _quantityCount ==
                                                scanData.itemCount.toDouble())
                                        ? Colors.black87
                                        : AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Stepper & Quick Adjustment Chips
          if (!_isGramMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$portionLabel (~${(scanData.unitWeightGrams * _quantityCount).toInt()}g)',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      _buildStepButton(
                        icon: Icons.remove,
                        onPressed: _quantityCount > 0.5
                            ? () => setState(() => _quantityCount =
                                (_quantityCount - 0.5).clamp(0.5, 30.0))
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _quantityCount == _quantityCount.toInt()
                              ? '${_quantityCount.toInt()}'
                              : _quantityCount.toStringAsFixed(1),
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _buildStepButton(
                        icon: Icons.add,
                        onPressed: () => setState(() => _quantityCount =
                            (_quantityCount + 0.5).clamp(0.5, 30.0)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [0.5, 1.0, 2.0, 3.0, 4.0].map((val) {
                final isSelected = _quantityCount == val;
                final label = val == val.toInt()
                    ? '${val.toInt()} $unit${val > 1 ? "s" : ""}'
                    : '$val $unit';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => setState(() => _quantityCount = val),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen.withValues(alpha: 0.25)
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_customGrams.toInt()}g (~${(_customGrams / (scanData.unitWeightGrams > 0 ? scanData.unitWeightGrams : 100.0)).toStringAsFixed(1)} $unit)',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      _buildStepButton(
                        icon: Icons.remove,
                        onPressed: _customGrams > 25
                            ? () => setState(() => _customGrams =
                                (_customGrams - 25).clamp(25.0, 2000.0))
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '${_customGrams.toInt()}g',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _buildStepButton(
                        icon: Icons.add,
                        onPressed: () => setState(() => _customGrams =
                            (_customGrams + 25).clamp(25.0, 2000.0)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [50.0, 100.0, 150.0, 200.0, 300.0].map((val) {
                final isSelected = _customGrams == val;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => setState(() => _customGrams = val),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen.withValues(alpha: 0.25)
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${val.toInt()}g',
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepButton(
      {required IconData icon, required VoidCallback? onPressed}) {
    return BouncingWidget(
      onTap: onPressed,
      scaleFactor: 0.88,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onPressed != null
              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onPressed != null
                ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                : Colors.white12,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed != null ? AppTheme.primaryGreen : Colors.white24,
        ),
      ),
    );
  }

  Widget _buildAllergenBanner(List<String> allergens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppTheme.accentAmber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Allergen Alert: Contains ${allergens.join(", ")}',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNovaAndAdditivesCard(ScanData scanData) {
    final nova = scanData.novaGroup;
    String novaTitle = 'NOVA 1 • Unprocessed';
    String novaDesc = 'Natural or minimally processed whole foods.';
    Color novaColor = AppTheme.primaryGreen;

    if (nova == 2) {
      novaTitle = 'NOVA 2 • Culinary Ingredient';
      novaDesc = 'Oils, butter, and seasonings for cooking.';
      novaColor = const Color(0xFF88D840);
    } else if (nova == 3) {
      novaTitle = 'NOVA 3 • Processed Food';
      novaDesc = 'Whole foods with added salt, sugar, or oil.';
      novaColor = AppTheme.accentAmber;
    } else if (nova >= 4) {
      novaTitle = 'NOVA 4 • Ultra-Processed';
      novaDesc = 'Industrial formulations with additives & flavorings.';
      novaColor = AppTheme.errorRed;
    }

    final additives = scanData.additives;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: novaColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.science_rounded, color: novaColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Processing & Additives',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: novaColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: novaColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'NOVA $nova',
                  style: TextStyle(
                    color: novaColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            novaTitle,
            style: TextStyle(
              color: novaColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            novaDesc,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: AppTheme.glassBorder),
          const SizedBox(height: 10),
          Text(
            'Additives',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (additives.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'No harmful additives detected',
                    style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            ...additives.map((add) {
              Color riskCol = AppTheme.primaryGreen;
              if (add.riskLevel.toLowerCase() == 'moderate') {
                riskCol = AppTheme.accentAmber;
              }
              if (add.riskLevel.toLowerCase() == 'high') {
                riskCol = AppTheme.errorRed;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: riskCol.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: riskCol.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        add.code.isNotEmpty ? add.code : add.name,
                        style: TextStyle(
                            color: riskCol,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${add.name} • ${add.purpose}',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      add.riskLevel.toUpperCase(),
                      style: TextStyle(
                          color: riskCol,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAskCoachCard(BuildContext context, ScanData scanData) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.25),
                  AppTheme.accentCyan.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppTheme.primaryGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Nutrition Coach',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ask about macros, diet goals, or swaps',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showAskCoachModal(context, scanData),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ask',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showAskCoachModal(BuildContext context, ScanData scanData) {
    final textController = TextEditingController();
    String? currentAnswer;
    bool isThinking = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            void ask(String question) async {
              if (question.trim().isEmpty) return;
              setModalState(() {
                isThinking = true;
                currentAnswer = null;
              });

              try {
                final ans =
                    await AIService().askNutritionQuestion(scanData, question);
                setModalState(() {
                  currentAnswer = ans;
                  isThinking = false;
                });
              } catch (e) {
                setModalState(() {
                  currentAnswer = 'Sorry, could not answer right now: $e';
                  isThinking = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: AppTheme.primaryGreen, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Coach on "${scanData.foodName}"',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.close, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick Prompts
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildQuickPromptChip(
                            'Is this good for weight loss?', ask),
                        _buildQuickPromptChip(
                            'Can I eat this before workout?', ask),
                        _buildQuickPromptChip(
                            'What is a healthy swap for this?', ask),
                        _buildQuickPromptChip(
                            'What is an optimal portion size?', ask),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Custom Question Input
                    TextField(
                      controller: textController,
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ask your custom question...',
                        hintStyle: TextStyle(color: AppTheme.textTertiary),
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send_rounded,
                              color: AppTheme.primaryGreen),
                          onPressed: () => ask(textController.text),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: ask,
                    ),

                    const SizedBox(height: 16),

                    if (isThinking)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: NutriLoadingIndicator(
                            size: 90,
                            message: 'Coach is analyzing nutrition & formulation...',
                          ),
                        ),
                      )
                    else if (currentAnswer != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.primaryGreen,
                              child: const Icon(Icons.person,
                                  size: 16, color: Colors.black),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentAnswer!,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
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
      },
    );
  }

  Widget _buildQuickPromptChip(String text, Function(String) onSelected) {
    return ActionChip(
      label: Text(text,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 11)),
      backgroundColor: AppTheme.surfaceLight,
      side: BorderSide(color: AppTheme.glassBorder),
      onPressed: () => onSelected(text),
    );
  }

  Widget _buildNutriScoreCard(ScanData scanData) {
    // Derive score letter and rating from healthScore text
    final scoreText = scanData.healthScore;
    String scoreLetter = 'A';
    int numericScore = 85;

    final match = RegExp(r'(\d+)(?:/10)?').firstMatch(scoreText);
    if (match != null) {
      final raw = int.tryParse(match.group(1) ?? '8') ?? 8;
      numericScore = raw <= 10 ? raw * 10 : raw;
      if (numericScore >= 80) {
        scoreLetter = 'A';
      } else if (numericScore >= 65) {
        scoreLetter = 'B';
      } else if (numericScore >= 50) {
        scoreLetter = 'C';
      } else if (numericScore >= 35) {
        scoreLetter = 'D';
      } else {
        scoreLetter = 'E';
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Health & Nutri-Score',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCountText(
                      value: numericScore.toDouble(),
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' / 100',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AnimatedRadialScoreGauge(
                score: numericScore,
                size: 88,
                strokeWidth: 8,
                primaryColor: scoreLetter == 'A' || scoreLetter == 'B'
                    ? AppTheme.primaryGreen
                    : scoreLetter == 'C'
                        ? AppTheme.accentAmber
                        : AppTheme.errorRed,
                label: 'Grade $scoreLetter',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nutri-Score A, B, C, D, E Badges
                    Row(
                      children: [
                        _buildNutriPill(
                            'A', const Color(0xFF00A86B), scoreLetter == 'A'),
                        const SizedBox(width: 4),
                        _buildNutriPill(
                            'B', const Color(0xFF55C500), scoreLetter == 'B'),
                        const SizedBox(width: 4),
                        _buildNutriPill(
                            'C', const Color(0xFFF2C94C), scoreLetter == 'C'),
                        const SizedBox(width: 4),
                        _buildNutriPill(
                            'D', const Color(0xFFF2994A), scoreLetter == 'D'),
                        const SizedBox(width: 4),
                        _buildNutriPill(
                            'E', const Color(0xFFEB5757), scoreLetter == 'E'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      scoreText,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutriPill(String letter, Color color, bool isSelected) {
    return Expanded(
      child: Container(
        height: isSelected ? 42 : 32,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSelected ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacrosGrid(ParsedNutritionValues parsed, ScanData scanData) {
    final mult = _getEffectiveMultiplier(scanData);
    final effectiveCals = parsed.calories * mult;
    final effectiveProtein = parsed.protein * mult;
    final effectiveCarbs = parsed.carbs * mult;
    final effectiveFat = parsed.fat * mult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macronutrients',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMacroCard(
                title: 'Calories',
                value: effectiveCals,
                isInt: true,
                suffix: ' kcal',
                color: AppTheme.primaryGreen,
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMacroCard(
                title: 'Protein',
                value: effectiveProtein,
                isInt: false,
                suffix: 'g',
                color: AppTheme.macroProtein,
                icon: Icons.fitness_center_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMacroCard(
                title: 'Carbs',
                value: effectiveCarbs,
                isInt: false,
                suffix: 'g',
                color: AppTheme.macroCarbs,
                icon: Icons.bolt_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMacroCard(
                title: 'Fats',
                value: effectiveFat,
                isInt: false,
                suffix: 'g',
                color: AppTheme.macroFat,
                icon: Icons.grain_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String title,
    required double value,
    required String suffix,
    required Color color,
    required IconData icon,
    bool isInt = false,
  }) {
    return BouncingWidget(
      scaleFactor: 0.94,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderColor: color.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedCountText(
              value: value,
              decimalPlaces: isInt ? 0 : 1,
              suffix: suffix,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicronutrientsCard(
      List<VitaminMineral> items, ScanData scanData) {
    final mult = _getEffectiveMultiplier(scanData);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.biotech_rounded,
                color: AppTheme.accentPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Vitamins & Minerals',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) {
            double dvProgress = 0.3;
            final match = RegExp(r'(\d+)%').firstMatch(item.dailyValue);
            if (match != null) {
              final pct = double.tryParse(match.group(1) ?? '30') ?? 30;
              dvProgress = ((pct * mult) / 100).clamp(0.05, 1.0);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${item.amount} (${item.dailyValue})',
                        style: TextStyle(
                          color: AppTheme.accentPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: dvProgress,
                      backgroundColor: AppTheme.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.accentPurple,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiRecommendationsCard(String recommendations) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Nutrition Advisor',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recommendations,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSelectorCard(ScanData scanData) {
    final mealOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
    final portionLabel = _getEffectivePortionLabel(scanData);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log to Meal Slot',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  portionLabel,
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Meal Option Pills
          Row(
            children: mealOptions.map((meal) {
              final isSelected = _selectedMeal == meal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMeal = meal),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.glassBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          meal,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons(
    BuildContext context,
    ScanData scanData,
    ParsedNutritionValues parsedNutrition,
  ) {
    final mult = _getEffectiveMultiplier(scanData);
    final adjustedNutrition = ParsedNutritionValues(
      calories: parsedNutrition.calories * mult,
      protein: parsedNutrition.protein * mult,
      carbs: parsedNutrition.carbs * mult,
      fat: parsedNutrition.fat * mult,
    );
    final portionLabel = _getEffectivePortionLabel(scanData);
    final totalCals = adjustedNutrition.calories.toInt();

    return Column(
      children: [
        // Primary Save Button
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Save $portionLabel to $_selectedMeal • $totalCals kcal',
            icon: Icons.check_circle_rounded,
            onPressed: () {
              final entry = LoggedFoodEntry(
                scanData: scanData,
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                timestamp: DateTime.now(),
                parsedNutrition: adjustedNutrition,
                mealType: _selectedMeal,
              );

              context.read<AppStateProvider>().addToHistory(entry);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Logged $portionLabel of ${scanData.foodName} to $_selectedMeal! 🥗'),
                  backgroundColor: AppTheme.primaryGreenDark,
                ),
              );

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const EnhancedHomeScreen()),
                (route) => false,
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // 2 Secondary Actions: Add to Basket + Compare Food
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AppStateProvider>().addToBasket(
                        scanData,
                        adjustedNutrition,
                        _selectedMeal,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Added $portionLabel of "${scanData.foodName}" to Meal Basket 🧺!'),
                      backgroundColor: AppTheme.cardBackground,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_basket_rounded, size: 16),
                label:
                    const Text('Add to Basket', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentCyan,
                  side: BorderSide(
                      color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          FoodComparisonScreen(initialFoodA: scanData),
                    ),
                  );
                },
                icon: const Icon(Icons.balance_rounded, size: 16),
                label:
                    const Text('Compare Food', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentAmber,
                  side: BorderSide(
                      color: AppTheme.accentAmber.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Alternatives Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AlternativesScreen(scanData: scanData),
                ),
              );
            },
            icon: const Icon(Icons.swap_horizontal_circle_rounded, size: 18),
            label: const Text('View Healthier Alternatives'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
