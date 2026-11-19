import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_models.dart';
import '../services/ai_service.dart';
import '../config/app_theme.dart';
import '../widgets/nutri_loading_indicator.dart';
import '../providers/app_state_provider.dart';

class FoodComparisonScreen extends StatefulWidget {
  final ScanData? initialFoodA;
  final ScanData? initialFoodB;

  const FoodComparisonScreen({
    super.key,
    this.initialFoodA,
    this.initialFoodB,
  });

  @override
  State<FoodComparisonScreen> createState() => _FoodComparisonScreenState();
}

class _FoodComparisonScreenState extends State<FoodComparisonScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _customFoodBController = TextEditingController();

  ScanData? _foodA;
  ScanData? _foodB;
  bool _isComparing = false;
  FoodComparisonResult? _comparisonResult;

  @override
  void initState() {
    super.initState();
    _foodA = widget.initialFoodA;
    _foodB = widget.initialFoodB;

    if (_foodA == null) {
      final history = context.read<AppStateProvider>().history;
      if (history.isNotEmpty) {
        _foodA = history.first.scanData;
      }
    }

    if (_foodA != null && _foodB != null) {
      _runComparison();
    }
  }

  @override
  void dispose() {
    _customFoodBController.dispose();
    super.dispose();
  }

  Future<void> _runComparison() async {
    if (_foodA == null || _foodB == null) return;

    setState(() {
      _isComparing = true;
    });

    try {
      final result = await _aiService.compareFoods(_foodA!, _foodB!);
      if (mounted) {
        setState(() {
          _comparisonResult = result;
          _isComparing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isComparing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to compare: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _compareWithCustomInput(String foodName) async {
    if (foodName.trim().isEmpty) return;
    Navigator.of(context).pop();

    setState(() {
      _isComparing = true;
    });

    try {
      final customFood = await _aiService.parseNaturalLanguageMeal(foodName);
      _foodB = customFood;
      await _runComparison();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isComparing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not analyze "$foodName"'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showFoodSelectorModal({required bool isSelectingA}) {
    final history = context.read<AppStateProvider>().history;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select ${isSelectingA ? "Food A" : "Food B"}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Custom food input option
                TextField(
                  controller: _customFoodBController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Or enter any food name...',
                    hintStyle: TextStyle(color: AppTheme.textTertiary),
                    prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryGreen),
                      onPressed: () => _compareWithCustomInput(_customFoodBController.text),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _compareWithCustomInput,
                ),
                const SizedBox(height: 16),
                Text(
                  'Recent Scans & Logs:',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: history.isEmpty
                      ? Center(
                          child: Text(
                            'No recent foods found.',
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (ctx, idx) {
                            final item = history[idx];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.restaurant, color: AppTheme.primaryGreen, size: 20),
                              ),
                              title: Text(
                                item.scanData.foodName,
                                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${item.parsedNutrition.calories.toInt()} kcal • ${item.mealType}',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                              onTap: () {
                                Navigator.pop(modalContext);
                                setState(() {
                                  if (isSelectingA) {
                                    _foodA = item.scanData;
                                  } else {
                                    _foodB = item.scanData;
                                  }
                                });
                                if (_foodA != null && _foodB != null) {
                                  _runComparison();
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Food Comparison',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildFoodSelectionCard(
                      food: _foodA,
                      label: 'Food A',
                      tagColor: AppTheme.primaryGreen,
                      onTap: () => _showFoodSelectorModal(isSelectingA: true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildFoodSelectionCard(
                      food: _foodB,
                      label: 'Food B',
                      tagColor: AppTheme.accentCyan,
                      onTap: () => _showFoodSelectorModal(isSelectingA: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_isComparing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: NutriLoadingIndicator(
                      size: 110,
                      message: 'Comparing nutrition & processing levels...',
                    ),
                  ),
                )
              else if (_comparisonResult != null)
                _buildComparisonDetails(_comparisonResult!)
              else if (_foodA != null && _foodB != null)
                Center(
                  child: GradientButton(
                    text: 'Compare Foods Now',
                    icon: Icons.balance_rounded,
                    onPressed: _runComparison,
                  ),
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Icon(Icons.compare_arrows_rounded, size: 64, color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                        const SizedBox(height: 14),
                        Text(
                          'Select two foods to compare macros, NOVA processing scores, and additives side-by-side.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodSelectionCard({
    required ScanData? food,
    required String label,
    required Color tagColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: food != null ? tagColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.touch_app_rounded, color: tagColor.withValues(alpha: 0.7), size: 16),
              ],
            ),
            Text(
              food?.foodName ?? 'Tap to select',
              style: TextStyle(
                color: food != null ? AppTheme.textPrimary : AppTheme.textTertiary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              food != null ? 'NOVA ${food.novaGroup}' : 'Select food',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonDetails(FoodComparisonResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Winner AI Verdict Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.2),
                AppTheme.cardBackground,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: AppTheme.accentAmber, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Winner: ${result.winner}',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.summary,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Side-by-Side Breakdown',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // Comparison Table Rows
        _buildComparisonRow(
          metric: 'Calories',
          valA: '${result.caloriesA.toInt()} kcal',
          valB: '${result.caloriesB.toInt()} kcal',
          winnerIsA: result.caloriesA < result.caloriesB,
        ),
        _buildComparisonRow(
          metric: 'Protein',
          valA: '${result.proteinA.toStringAsFixed(1)}g',
          valB: '${result.proteinB.toStringAsFixed(1)}g',
          winnerIsA: result.proteinA > result.proteinB,
        ),
        _buildComparisonRow(
          metric: 'Carbohydrates',
          valA: '${result.carbsA.toStringAsFixed(1)}g',
          valB: '${result.carbsB.toStringAsFixed(1)}g',
          winnerIsA: result.carbsA < result.carbsB,
        ),
        _buildComparisonRow(
          metric: 'Total Fat',
          valA: '${result.fatA.toStringAsFixed(1)}g',
          valB: '${result.fatB.toStringAsFixed(1)}g',
          winnerIsA: result.fatA < result.fatB,
        ),
        _buildComparisonRow(
          metric: 'NOVA Processing',
          valA: 'Group ${result.novaA}',
          valB: 'Group ${result.novaB}',
          winnerIsA: result.novaA <= result.novaB,
        ),

        const SizedBox(height: 20),

        // Strengths of Food A & Food B
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStrengthsList(
                title: result.foodAName,
                points: result.keyAdvantagesA,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStrengthsList(
                title: result.foodBName,
                points: result.keyAdvantagesB,
                color: AppTheme.accentCyan,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonRow({
    required String metric,
    required String valA,
    required String valB,
    required bool winnerIsA,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              valA,
              style: TextStyle(
                color: winnerIsA ? AppTheme.primaryGreen : AppTheme.textPrimary,
                fontWeight: winnerIsA ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              metric,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              valB,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: !winnerIsA ? AppTheme.accentCyan : AppTheme.textPrimary,
                fontWeight: !winnerIsA ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsList({
    required String title,
    required List<String> points,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (points.isEmpty)
            Text(
              'Balanced profile',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
            )
          else
            ...points.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, size: 13, color: color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}