import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../services/storage_service.dart';
import '../widgets/user_avatar_widget.dart';
import 'clerk_auth_screen.dart';

class UserSetupScreen extends StatefulWidget {
  final bool isFirstTime;

  const UserSetupScreen({
    super.key,
    this.isFirstTime = true,
  });

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 Controllers & State
  late TextEditingController _nameController;
  late int _age;
  late String _gender;
  late double _heightCm;
  late double _weightKg;
  late String _activityLevel;
  late String _goal;

  // Step 2 Targets State
  late double _calorieTarget;
  late double _proteinTarget;
  late double _carbsTarget;
  late double _fatTarget;
  late int _waterTargetMl;

  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active',
  ];

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'Healthy Lifestyle',
      'title': 'Healthy Lifestyle',
      'subtitle': 'Balanced nourishment & energy',
      'icon': Icons.spa_rounded,
      'color': AppTheme.primaryGreen,
    },
    {
      'id': 'Weight Loss',
      'title': 'Weight Loss',
      'subtitle': 'Calorie deficit & high protein',
      'icon': Icons.trending_down_rounded,
      'color': AppTheme.macroFat,
    },
    {
      'id': 'Muscle Building',
      'title': 'Muscle Building',
      'subtitle': 'Caloric surplus & muscle growth',
      'icon': Icons.fitness_center_rounded,
      'color': AppTheme.macroProtein,
    },
    {
      'id': 'Keto / Low-Carb',
      'title': 'Keto / Low-Carb',
      'subtitle': 'Higher healthy fats, low carbs',
      'icon': Icons.bolt_rounded,
      'color': AppTheme.macroCarbs,
    },
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppStateProvider>();
    _nameController = TextEditingController(
      text: provider.userProfileName == 'Nutrition User' ? '' : provider.userProfileName,
    );
    _age = provider.userAge;
    _gender = provider.userGender;
    _heightCm = provider.userHeightCm;
    _weightKg = provider.userWeightKg;
    _activityLevel = provider.userActivityLevel;
    _goal = provider.userGoal;

    _calorieTarget = provider.calorieTarget;
    _proteinTarget = provider.proteinTarget;
    _carbsTarget = provider.carbsTarget;
    _fatTarget = provider.fatTarget;
    _waterTargetMl = provider.waterTargetMl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _recalculateTargets() {
    final rec = AppStateProvider.calculateRecommendedTargets(
      age: _age,
      gender: _gender,
      heightCm: _heightCm,
      weightKg: _weightKg,
      activityLevel: _activityLevel,
      goal: _goal,
    );

    setState(() {
      _calorieTarget = rec['calories'] ?? 2100;
      _proteinTarget = rec['protein'] ?? 140;
      _carbsTarget = rec['carbs'] ?? 220;
      _fatTarget = rec['fat'] ?? 65;
      _waterTargetMl = (rec['water'] ?? 2500).round();
    });
  }

  void _goToStep2() {
    HapticFeedback.lightImpact();
    _recalculateTargets();
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentStep = 1);
  }

  void _goToStep1() {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentStep = 0);
  }

  Future<void> _saveAndFinish() async {
    HapticFeedback.mediumImpact();
    final provider = context.read<AppStateProvider>();
    final enteredName = _nameController.text.trim();
    final finalName = enteredName.isNotEmpty
        ? enteredName
        : (provider.userProfileName.isNotEmpty ? provider.userProfileName : 'Nutrition User');

    await provider.saveUserProfileAndTargets(
      name: finalName,
      email: provider.userProfileEmail,
      age: _age,
      gender: _gender,
      heightCm: _heightCm,
      weightKg: _weightKg,
      activityLevel: _activityLevel,
      goal: _goal,
      calories: _calorieTarget,
      protein: _proteinTarget,
      carbs: _carbsTarget,
      fat: _fatTarget,
      waterMl: _waterTargetMl,
    );

    if (widget.isFirstTime) {
      await StorageService().setOnboardingComplete();
      await StorageService().setProfileSetupComplete(true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => const ClerkAuthScreen(),
            transitionsBuilder: (context, anim, secAnim, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Profile & Nutrition targets updated!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _skipSetup() async {
    HapticFeedback.selectionClick();
    if (widget.isFirstTime) {
      _recalculateTargets();
      final provider = context.read<AppStateProvider>();
      await provider.saveUserProfileAndTargets(
        name: provider.userProfileName,
        email: provider.userProfileEmail,
        age: _age,
        gender: _gender,
        heightCm: _heightCm,
        weightKg: _weightKg,
        activityLevel: _activityLevel,
        goal: _goal,
        calories: _calorieTarget,
        protein: _proteinTarget,
        carbs: _carbsTarget,
        fat: _fatTarget,
        waterMl: _waterTargetMl,
      );
      await StorageService().setOnboardingComplete();
      await StorageService().setProfileSetupComplete(true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => const ClerkAuthScreen(),
            transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              child: child,
            ),
          ),
        );
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    AppTheme.setDarkMode(appState.isDarkMode);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep == 1)
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
                        onPressed: _goToStep1,
                      )
                    else if (!widget.isFirstTime)
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppTheme.textPrimary, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 40),

                    // Step Indicator Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentStep == 0 ? Icons.person_outline_rounded : Icons.pie_chart_rounded,
                            size: 14,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentStep == 0 ? 'Step 1 of 2: Profile' : 'Step 2 of 2: Targets',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Skip Button
                    if (widget.isFirstTime)
                      TextButton(
                        onPressed: _skipSetup,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _currentStep == 0 ? 0.5 : 1.0,
                    backgroundColor: AppTheme.cardBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    minHeight: 4,
                  ),
                ),
              ),

              // Steps PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1Profile(appState),
                    _buildStep2Targets(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 1: User Profile & Metrics ---
  Widget _buildStep1Profile(AppStateProvider provider) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Title & Description
        Text(
          'Personalize Your Journey 🥗',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tell us about yourself so we can calculate your optimal daily nutrition targets.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        // Avatar / Photo Selector
        Center(
          child: Column(
            children: [
              UserAvatarWidget(
                photoPath: provider.userPhotoPath,
                userName: _nameController.text.trim().isNotEmpty
                    ? _nameController.text.trim()
                    : provider.userProfileName,
                radius: 40,
                showEditBadge: true,
                onTap: () {
                  showPhotoPickerSheet(context, provider);
                },
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  showPhotoPickerSheet(context, provider);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: AppTheme.primaryGreen, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Set Profile Photo / Avatar',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Name Field
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Name',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Alex Morgan',
                    hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Gender Selector
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biological Gender',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Used for accurate metabolic rate formulas',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildGenderOption('Female', Icons.female_rounded),
                  const SizedBox(width: 10),
                  _buildGenderOption('Male', Icons.male_rounded),
                  const SizedBox(width: 10),
                  _buildGenderOption('Other', Icons.person_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Age, Height, Weight Row
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Body Metrics',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),

              // Age Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Age', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('$_age years', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primaryGreen,
                  inactiveTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  thumbColor: AppTheme.primaryGreen,
                  overlayColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _age.toDouble(),
                  min: 14,
                  max: 90,
                  divisions: 76,
                  onChanged: (val) => setState(() => _age = val.round()),
                ),
              ),

              const SizedBox(height: 10),

              // Height Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Height', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${_heightCm.round()} cm', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.macroProtein,
                  inactiveTrackColor: AppTheme.macroProtein.withValues(alpha: 0.2),
                  thumbColor: AppTheme.macroProtein,
                  overlayColor: AppTheme.macroProtein.withValues(alpha: 0.15),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _heightCm,
                  min: 120,
                  max: 220,
                  divisions: 100,
                  onChanged: (val) => setState(() => _heightCm = val.roundToDouble()),
                ),
              ),

              const SizedBox(height: 10),

              // Weight Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weight', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${_weightKg.toStringAsFixed(1)} kg', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.macroCarbs,
                  inactiveTrackColor: AppTheme.macroCarbs.withValues(alpha: 0.2),
                  thumbColor: AppTheme.macroCarbs,
                  overlayColor: AppTheme.macroCarbs.withValues(alpha: 0.15),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _weightKg,
                  min: 35,
                  max: 180,
                  divisions: 290,
                  onChanged: (val) => setState(() => _weightKg = double.parse(val.toStringAsFixed(1))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Activity Level
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Physical Activity Level',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activityLevels.map((lvl) {
                  final isSelected = _activityLevel == lvl;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _activityLevel = lvl);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                            : AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.glassBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        lvl,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Health Goal
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Primary Nutrition Goal',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: _goals.map((g) {
                  final isSelected = _goal == g['id'];
                  final Color color = g['color'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _goal = g['id']);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.12)
                            : AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : AppTheme.glassBorder,
                          width: isSelected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(g['icon'] as IconData, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g['title'] as String,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  g['subtitle'] as String,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: color, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Continue to Step 2 Button
        GradientButton(
          text: 'Calculate Nutrition Targets →',
          onPressed: _goToStep2,
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, IconData icon) {
    final isSelected = _gender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _gender = label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                : AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.glassBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textTertiary,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 2: Custom Daily Nutrition Targets ---
  Widget _buildStep2Targets() {
    final totalEnergyKcal = (_proteinTarget * 4) + (_carbsTarget * 4) + (_fatTarget * 9);
    final proteinPct = totalEnergyKcal > 0 ? ((_proteinTarget * 4) / totalEnergyKcal * 100).round() : 25;
    final carbsPct = totalEnergyKcal > 0 ? ((_carbsTarget * 4) / totalEnergyKcal * 100).round() : 50;
    final fatPct = totalEnergyKcal > 0 ? ((_fatTarget * 9) / totalEnergyKcal * 100).round() : 25;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Title & Description
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Targets 🎯',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calculated based on your ${_goal.toLowerCase()} goal',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
              tooltip: 'Reset to Recommended',
              onPressed: () {
                HapticFeedback.lightImpact();
                _recalculateTargets();
              },
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Daily Calories Card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.local_fire_department_rounded, color: AppTheme.primaryGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Calorie Target',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Total daily energy intake',
                            style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${_calorieTarget.round()} kcal',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildAdjustButton(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      if (_calorieTarget > 1200) {
                        setState(() => _calorieTarget -= 50);
                      }
                    },
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryGreen,
                        inactiveTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                        thumbColor: AppTheme.primaryGreen,
                        trackHeight: 5,
                      ),
                      child: Slider(
                        value: _calorieTarget,
                        min: 1200,
                        max: 4200,
                        divisions: 60,
                        onChanged: (val) => setState(() => _calorieTarget = val.roundToDouble()),
                      ),
                    ),
                  ),
                  _buildAdjustButton(
                    icon: Icons.add_rounded,
                    onTap: () {
                      if (_calorieTarget < 4200) {
                        setState(() => _calorieTarget += 50);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Macronutrient Split Visual Bar
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Energy Distribution',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      Expanded(
                        flex: proteinPct.clamp(1, 100),
                        child: Container(color: AppTheme.macroProtein),
                      ),
                      Expanded(
                        flex: carbsPct.clamp(1, 100),
                        child: Container(color: AppTheme.macroCarbs),
                      ),
                      Expanded(
                        flex: fatPct.clamp(1, 100),
                        child: Container(color: AppTheme.macroFat),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroLegend('Protein', '$proteinPct%', AppTheme.macroProtein),
                  _buildMacroLegend('Carbs', '$carbsPct%', AppTheme.macroCarbs),
                  _buildMacroLegend('Fat', '$fatPct%', AppTheme.macroFat),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Protein Target
        _buildMacroCard(
          title: 'Daily Protein',
          amount: _proteinTarget,
          unit: 'g',
          subtitle: '${(_proteinTarget * 4).round()} kcal · Supports muscles & recovery',
          color: AppTheme.macroProtein,
          icon: Icons.fitness_center_rounded,
          min: 40,
          max: 260,
          onChanged: (val) => setState(() => _proteinTarget = val),
          onMinus: () => setState(() => _proteinTarget = (_proteinTarget - 5).clamp(40, 260)),
          onPlus: () => setState(() => _proteinTarget = (_proteinTarget + 5).clamp(40, 260)),
        ),
        const SizedBox(height: 12),

        // Carbs Target
        _buildMacroCard(
          title: 'Daily Carbohydrates',
          amount: _carbsTarget,
          unit: 'g',
          subtitle: '${(_carbsTarget * 4).round()} kcal · Fuel for daily activities',
          color: AppTheme.macroCarbs,
          icon: Icons.grain_rounded,
          min: 20,
          max: 450,
          onChanged: (val) => setState(() => _carbsTarget = val),
          onMinus: () => setState(() => _carbsTarget = (_carbsTarget - 5).clamp(20, 450)),
          onPlus: () => setState(() => _carbsTarget = (_carbsTarget + 5).clamp(20, 450)),
        ),
        const SizedBox(height: 12),

        // Fat Target
        _buildMacroCard(
          title: 'Daily Healthy Fats',
          amount: _fatTarget,
          unit: 'g',
          subtitle: '${(_fatTarget * 9).round()} kcal · Hormonal health & vitality',
          color: AppTheme.macroFat,
          icon: Icons.opacity_rounded,
          min: 30,
          max: 180,
          onChanged: (val) => setState(() => _fatTarget = val),
          onMinus: () => setState(() => _fatTarget = (_fatTarget - 5).clamp(30, 180)),
          onPlus: () => setState(() => _fatTarget = (_fatTarget + 5).clamp(30, 180)),
        ),
        const SizedBox(height: 12),

        // Water Target
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.macroProtein.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.water_drop_rounded, color: AppTheme.macroProtein, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Water Intake',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Recommended hydration volume',
                        style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.macroProtein.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.macroProtein.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '$_waterTargetMl ml',
                  style: TextStyle(
                    color: AppTheme.macroProtein,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Button
        GradientButton(
          text: widget.isFirstTime ? 'Save Targets & Launch NutriScan 🚀' : 'Save Changes ✓',
          onPressed: _saveAndFinish,
        ),
      ],
    );
  }

  Widget _buildAdjustButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 18),
      ),
    );
  }

  Widget _buildMacroLegend(String label, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Text(
          pct,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String title,
    required double amount,
    required String unit,
    required String subtitle,
    required Color color,
    required IconData icon,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${amount.round()} $unit',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAdjustButton(icon: Icons.remove_rounded, onTap: onMinus),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: color.withValues(alpha: 0.2),
                    thumbColor: color,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: amount.clamp(min, max),
                    min: min,
                    max: max,
                    divisions: ((max - min) / 5).round(),
                    onChanged: (val) => onChanged(val.roundToDouble()),
                  ),
                ),
              ),
              _buildAdjustButton(icon: Icons.add_rounded, onTap: onPlus),
            ],
          ),
        ],
      ),
    );
  }
}
