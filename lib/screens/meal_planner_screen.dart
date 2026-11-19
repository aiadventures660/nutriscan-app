import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../widgets/nutri_loading_indicator.dart';
import '../providers/app_state_provider.dart';
import '../models/food_models.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _newGroceryController = TextEditingController();
  String _selectedAisle = 'Produce';

  final List<String> _aisles = [
    'Produce',
    'Protein',
    'Dairy',
    'Pantry',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newGroceryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Meal Prep & Smart Grocery',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textTertiary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'AI Meal Plan', icon: Icon(Icons.restaurant_menu_rounded, size: 20)),
            Tab(text: 'Smart Grocery', icon: Icon(Icons.checklist_rounded, size: 20)),
          ],
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMealPlanTab(provider),
              _buildGroceryTab(provider),
            ],
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: AI MEAL PREP PLAN
  // -------------------------------------------------------------
  Widget _buildMealPlanTab(AppStateProvider provider) {
    if (provider.isGeneratingMealPlan) {
      return const Center(
        child: NutriLoadingIndicator(
          size: 110,
          message: 'Generating your tailored meal plan...',
        ),
      );
    }

    final meals = provider.currentMealPlan;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Action Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.18),
                  AppTheme.cardBackground,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target-Aligned Meal Prep',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${provider.calorieTarget} kcal daily target',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => provider.generateNewMealPlan(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.black, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Regenerate',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Meal List
          ...meals.map((item) => _buildMealCard(item, provider)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMealCard(MealPlanItem item, AppStateProvider provider) {
    Color badgeColor = AppTheme.primaryGreen;
    if (item.mealType.toLowerCase().contains('lunch')) badgeColor = AppTheme.accentCyan;
    if (item.mealType.toLowerCase().contains('dinner')) badgeColor = AppTheme.macroProtein;
    if (item.mealType.toLowerCase().contains('snack')) badgeColor = AppTheme.accentAmber;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.mealType.toUpperCase(),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    item.prepTime,
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Macro Row
          Row(
            children: [
              _buildMacroBadge('${item.calories.toInt()} kcal', AppTheme.primaryGreen),
              const SizedBox(width: 8),
              _buildMacroBadge('${item.protein.toInt()}g P', AppTheme.macroProtein),
              const SizedBox(width: 8),
              _buildMacroBadge('${item.carbs.toInt()}g C', AppTheme.macroCarbs),
              const SizedBox(width: 8),
              _buildMacroBadge('${item.fat.toInt()}g F', AppTheme.macroFat),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Ingredients bullets
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.ingredients.map((ing) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ing,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // 1-Tap Log Meal button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final scanData = ScanData(
                  foodName: item.title,
                  nutritionInfo: '${item.calories} kcal, ${item.protein}g protein, ${item.carbs}g carbs, ${item.fat}g fat',
                  healthScore: '9/10',
                  recommendations: 'Prepared from AI Meal Plan',
                  ingredients: item.ingredients,
                  vitaminsAndMinerals: [
                    VitaminMineral(name: 'Vitamin A', amount: '200mcg', dailyValue: '22%'),
                    VitaminMineral(name: 'Iron', amount: '2.5mg', dailyValue: '14%'),
                  ],
                  imagePath: '',
                  novaGroup: 1,
                  additives: const [],
                  allergens: const [],
                );

                final entry = LoggedFoodEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  scanData: scanData,
                  timestamp: DateTime.now(),
                  parsedNutrition: ParsedNutritionValues(
                    calories: item.calories.toDouble(),
                    protein: item.protein.toDouble(),
                    carbs: item.carbs.toDouble(),
                    fat: item.fat.toDouble(),
                  ),
                  mealType: item.mealType,
                );

                provider.addToHistory(entry);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged "${item.title}" to ${item.mealType}! 🥗'),
                    backgroundColor: AppTheme.primaryGreenDark,
                  ),
                );
              },
              icon: const Icon(Icons.add_task_rounded, size: 16),
              label: Text('Log this to ${item.mealType}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: SMART GROCERY CHECKLIST
  // -------------------------------------------------------------
  Widget _buildGroceryTab(AppStateProvider provider) {
    final groceryList = provider.groceryList;
    final totalCount = groceryList.length;
    final checkedCount = groceryList.where((i) => i.isCompleted).length;

    // Group items by aisle
    final Map<String, List<GroceryItem>> grouped = {};
    for (final item in groceryList) {
      grouped.putIfAbsent(item.aisle, () => []).add(item);
    }

    return Column(
      children: [
        // Top Toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shopping Progress: $checkedCount/$totalCount',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.copy_rounded, color: AppTheme.primaryGreen, size: 20),
                    tooltip: 'Copy all items',
                    onPressed: () {
                      final buffer = StringBuffer('🛒 NutriScan Pro Smart Grocery List:\n');
                      for (final item in groceryList) {
                        buffer.writeln('${item.isCompleted ? "[x]" : "[ ]"} ${item.name} (${item.aisle})');
                      }
                      Clipboard.setData(ClipboardData(text: buffer.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Grocery list copied to clipboard! 📋'),
                          backgroundColor: AppTheme.cardBackground,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.cleaning_services_rounded, color: AppTheme.accentAmber, size: 20),
                    tooltip: 'Clear completed',
                    onPressed: () => provider.clearCompletedGrocery(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Add Item Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newGroceryController,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add grocery item (e.g. Avocado)...',
                    hintStyle: TextStyle(color: AppTheme.textTertiary),
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      provider.addGroceryItem(val.trim(), _selectedAisle);
                      _newGroceryController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedAisle,
                dropdownColor: AppTheme.cardBackground,
                underline: const SizedBox(),
                items: _aisles
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a, style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAisle = val);
                },
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 28),
                onPressed: () {
                  if (_newGroceryController.text.trim().isNotEmpty) {
                    provider.addGroceryItem(_newGroceryController.text.trim(), _selectedAisle);
                    _newGroceryController.clear();
                  }
                },
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white12),

        // List grouped by Aisle
        Expanded(
          child: grouped.isEmpty
              ? Center(
                  child: Text(
                    'No grocery items. Add one or regenerate meal plan!',
                    style: TextStyle(color: AppTheme.textTertiary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  children: grouped.entries.map((entry) {
                    final aisleName = entry.key;
                    final items = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: Row(
                              children: [
                                Icon(_getAisleIcon(aisleName), size: 16, color: AppTheme.primaryGreen),
                                const SizedBox(width: 8),
                                Text(
                                  aisleName,
                                  style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map(
                            (gItem) => CheckboxListTile(
                              value: gItem.isCompleted,
                              activeColor: AppTheme.primaryGreen,
                              checkColor: Colors.black,
                              dense: true,
                              title: Text(
                                gItem.name,
                                style: TextStyle(
                                  color: gItem.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary,
                                  decoration: gItem.isCompleted ? TextDecoration.lineThrough : null,
                                  fontSize: 14,
                                ),
                              ),
                              onChanged: (_) => provider.toggleGroceryItem(gItem.id),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  IconData _getAisleIcon(String aisle) {
    final lower = aisle.toLowerCase();
    if (lower.contains('produce') || lower.contains('greens')) return Icons.eco_rounded;
    if (lower.contains('protein') || lower.contains('seafood') || lower.contains('meat')) return Icons.set_meal_rounded;
    if (lower.contains('dairy') || lower.contains('egg')) return Icons.egg_rounded;
    return Icons.inventory_2_rounded;
  }
}