import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/food_models.dart';
import '../config/app_theme.dart';
import 'scan_results_screen.dart';
import 'scan_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedMealFilter = 'All';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppStateProvider>();
      if (!provider.isInitialized) {
        provider.loadHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        context.select<AppStateProvider, bool>((p) => p.isDarkMode);
    AppTheme.setDarkMode(isDarkMode);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Consumer<AppStateProvider>(
            builder: (context, provider, child) {
              final filteredHistory = _getFilteredHistory(provider.history);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan History',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${provider.history.length} meals',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Date filter button
                              GestureDetector(
                                onTap: _pickDateFilter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _selectedDate != null
                                        ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedDate != null
                                          ? AppTheme.primaryGreen
                                          : Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: _selectedDate != null
                                            ? AppTheme.primaryGreen
                                            : AppTheme.textSecondary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _selectedDate != null
                                            ? DateFormat('MMM d').format(_selectedDate!)
                                            : 'Filter Date',
                                        style: TextStyle(
                                          color: _selectedDate != null
                                              ? AppTheme.primaryGreen
                                              : AppTheme.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_selectedDate != null) ...[
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => setState(() => _selectedDate = null),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Meal Filter Pills
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snacks'].map((filter) {
                            final isSelected = _selectedMealFilter.toLowerCase() == filter.toLowerCase();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedMealFilter = filter),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryGreen
                                          : Colors.white.withValues(alpha: 0.1),
                                      width: isSelected ? 1.4 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primaryGreen
                                          : AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // History Content or Empty State
                  if (filteredHistory.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = filteredHistory[index];

                            // Show date group header
                            bool showDateHeader = false;
                            if (index == 0) {
                              showDateHeader = true;
                            } else {
                              final prev = filteredHistory[index - 1];
                              showDateHeader = !_isSameDay(entry.timestamp, prev.timestamp);
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDateHeader) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDateHeader(entry.timestamp),
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                _buildHistoryCard(context, entry, provider),
                                const SizedBox(height: 10),
                              ],
                            );
                          },
                          childCount: filteredHistory.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    LoggedFoodEntry entry,
    AppStateProvider provider,
  ) {
    final mealType = entry.mealType ?? 'Snack';
    final calories = entry.parsedNutrition.calories.toInt();
    final protein = entry.parsedNutrition.protein.toInt();
    final carbs = entry.parsedNutrition.carbs.toInt();
    final fat = entry.parsedNutrition.fat.toInt();

    // Determine Nutri-Score badge
    String scoreLetter = 'A';
    Color scoreColor = const Color(0xFF00A86B);
    final match = RegExp(r'(\d+)(?:/10)?').firstMatch(entry.scanData.healthScore);
    if (match != null) {
      final val = int.tryParse(match.group(1) ?? '8') ?? 8;
      final numeric = val <= 10 ? val * 10 : val;
      if (numeric >= 80) {
        scoreLetter = 'A';
        scoreColor = const Color(0xFF00A86B);
      } else if (numeric >= 65) {
        scoreLetter = 'B';
        scoreColor = const Color(0xFF55C500);
      } else if (numeric >= 50) {
        scoreLetter = 'C';
        scoreColor = const Color(0xFFF2C94C);
      } else {
        scoreLetter = 'D';
        scoreColor = const Color(0xFFF2994A);
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        provider.setCurrentScanData(entry.scanData);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ScanResultsScreen()),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Image or Gradient placeholder
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppTheme.surfaceLight,
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: entry.scanData.imagePath.isNotEmpty &&
                      File(entry.scanData.imagePath).existsSync()
                  ? Image.file(
                      File(entry.scanData.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.restaurant_rounded,
                        color: AppTheme.primaryGreen,
                        size: 26,
                      ),
                    )
                  : Icon(
                      Icons.restaurant_rounded,
                      color: AppTheme.primaryGreen,
                      size: 26,
                    ),
            ),
          ),

          const SizedBox(width: 14),

          // Food Info & Macros
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.scanData.foodName,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Nutri-Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: scoreColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'Score $scoreLetter',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Text(
                      mealType,
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${DateFormat('h:mm a').format(entry.timestamp)}',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Macro badges
                Row(
                  children: [
                    _buildMicroMacroPill('$calories kcal', AppTheme.primaryGreen),
                    const SizedBox(width: 5),
                    _buildMicroMacroPill('${protein}g P', AppTheme.macroProtein),
                    const SizedBox(width: 5),
                    _buildMicroMacroPill('${carbs}g C', AppTheme.macroCarbs),
                    const SizedBox(width: 5),
                    _buildMicroMacroPill('${fat}g F', AppTheme.macroFat),
                  ],
                ),
              ],
            ),
          ),

          // Delete icon button
          IconButton(
            onPressed: () => _confirmDelete(context, entry, provider),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.textTertiary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroMacroPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.restaurant_rounded,
                color: AppTheme.primaryGreen,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Meal Logs Found',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan foods or log your meals to build your nutritional history timeline.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Scan Meal Now',
              icon: Icons.camera_alt_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ScanScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<LoggedFoodEntry> _getFilteredHistory(List<LoggedFoodEntry> all) {
    List<LoggedFoodEntry> list = List.from(all);

    if (_selectedDate != null) {
      list = list.where((e) => _isSameDay(e.timestamp, _selectedDate!)).toList();
    }

    if (_selectedMealFilter.toLowerCase() != 'all') {
      list = list.where((e) {
        return (e.mealType ?? 'Snack').toLowerCase() == _selectedMealFilter.toLowerCase();
      }).toList();
    }

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    if (check == today) return 'Today';
    if (check == yesterday) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(date);
  }

  void _pickDateFilter() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.black,
              surface: AppTheme.cardBackground,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _confirmDelete(
    BuildContext context,
    LoggedFoodEntry entry,
    AppStateProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete Meal Entry?',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remove "${entry.scanData.foodName}" from your history log?',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      provider.removeFromHistory(entry.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Meal entry removed'),
                          backgroundColor: AppTheme.cardBackground,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}