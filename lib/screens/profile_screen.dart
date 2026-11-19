import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../providers/app_state_provider.dart';
import '../config/app_theme.dart';
import '../services/health_sync_service.dart';
import '../services/storage_service.dart';
import '../widgets/user_avatar_widget.dart';
import '../services/api_client.dart';
import 'clerk_auth_screen.dart';
import 'onboarding_screen.dart';
import 'user_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Nutrition Explorer';
  String _userEmail = 'user@nutriscan.ai';
  bool _notificationsEnabled = true;
  String _preferredUnits = 'Metric (kg, ml)';
  
  // Dietary Preferences Tags
  final List<String> _selectedDietaryTags = ['High Protein', 'Gluten Free'];
  final List<String> _availableDietaryTags = [
    'High Protein',
    'Low Carb',
    'Keto',
    'Vegetarian',
    'Vegan',
    'Gluten Free',
    'Dairy Free',
    'Low Sodium',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name');
      final savedEmail = prefs.getString('user_email');
      if (savedName != null || savedEmail != null) {
        setState(() {
          if (savedName != null && savedName.isNotEmpty) _userName = savedName;
          if (savedEmail != null && savedEmail.isNotEmpty) _userEmail = savedEmail;
        });
      }
    } catch (_) {}
  }

  /// Verifies active, unexpired Clerk session from live Clerk SDK state.
  /// Never relies on local cached flags, onboarding status, or stored IDs.
  bool _isClerkSessionActive(ClerkAuthState clerkAuth) {
    if (clerkAuth.isNotAvailable) return false;
    final session = clerkAuth.session;
    final user = clerkAuth.user;
    if (session == null || user == null) return false;
    if (!session.isActive) return false;
    if (session.expireAt.millisecondsSinceEpoch <= DateTime.now().millisecondsSinceEpoch) {
      return false;
    }
    return true;
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
          bottom: false,
          child: Consumer<AppStateProvider>(
            builder: (context, provider, child) {
              final totalScans = provider.history.length;
              final streakDays = provider.getStreakDays();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Profile',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showEditProfileDialog(context, provider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, color: AppTheme.primaryGreen, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
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
                  ),

                  // Profile Feed
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. Hero Profile Card
                        _buildHeroProfileCard(provider),

                        const SizedBox(height: 16),

                        // 2. Performance Stats 4-Grid
                        _buildStatsGrid(totalScans, streakDays, provider),

                        const SizedBox(height: 16),

                        // 3. Google Health Connect & Apple Health Interface
                        _buildHealthSyncCard(provider),

                        const SizedBox(height: 16),

                        // 4. Clinical Doctor & Dietitian Report Generator
                        _buildDoctorReportCard(context, provider),

                        const SizedBox(height: 16),

                        // 5. Daily Nutrition Goals Customizer
                        _buildNutritionTargetsCard(provider),

                        const SizedBox(height: 16),

                        // 6. Dietary Preferences & Allergies
                        _buildDietaryPreferencesCard(),

                        const SizedBox(height: 16),

                        // 7. App Settings & Preferences
                        _buildAppSettingsCard(provider),

                        const SizedBox(height: 16),

                        // 8. Data & Privacy Support
                        _buildDataAndPrivacyCard(provider),

                        const SizedBox(height: 110), // Padding for floating bottom dock
                      ]),
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

  Widget _buildHeroProfileCard(AppStateProvider provider) {
    // Resolve real Clerk user data
    final clerkAuth = ClerkAuth.of(context);
    final isAuth = _isClerkSessionActive(clerkAuth);
    final clerkUser = isAuth ? clerkAuth.user : null;
    final clerkName = clerkUser?.firstName != null
        ? '${clerkUser!.firstName} ${clerkUser.lastName ?? ''}'.trim()
        : (clerkUser?.username ?? '');
    final emails = clerkUser?.emailAddresses;
    final clerkEmail = (emails != null && emails.isNotEmpty)
        ? emails.first.emailAddress
        : '';

    final effectiveName = clerkName.isNotEmpty
        ? clerkName
        : (isAuth && provider.userProfileName.trim().isNotEmpty
            ? provider.userProfileName
            : (isAuth ? _userName : (provider.userProfileName.trim().isNotEmpty ? provider.userProfileName : 'Guest Explorer')));
    final effectiveEmail = clerkEmail.isNotEmpty
        ? clerkEmail
        : (isAuth && provider.userProfileEmail.trim().isNotEmpty
            ? provider.userProfileEmail
            : (isAuth ? _userEmail : 'Not Signed In'));
    final effectivePhoto = (provider.userPhotoPath != null && provider.userPhotoPath!.isNotEmpty)
        ? provider.userPhotoPath
        : clerkUser?.imageUrl;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar with camera button connected to Clerk profile picture
          UserAvatarWidget(
            photoPath: effectivePhoto,
            userName: effectiveName,
            radius: 36,
            showBorder: true,
            showEditBadge: true,
            onTap: () => showPhotoPickerSheet(context, provider),
          ),

          const SizedBox(width: 18),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        effectiveName,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: isAuth ? AppTheme.primaryGradient : null,
                        color: isAuth ? null : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAuth ? 'PRO' : 'GUEST',
                        style: TextStyle(
                          color: isAuth ? Colors.black : AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  effectiveEmail,
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryGreen, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'Healthy Explorer • Level 4',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

  Widget _buildStatsGrid(int totalScans, int streakDays, AppStateProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Scans Logged',
            value: '$totalScans',
            color: AppTheme.primaryGreen,
            icon: Icons.qr_code_scanner_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'Active Streak',
            value: '$streakDays days',
            color: AppTheme.macroCarbs,
            icon: Icons.local_fire_department_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: color.withValues(alpha: 0.25),
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
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSyncCard(AppStateProvider provider) {
    final isSync = provider.isHealthConnectSynced;

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
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: AppTheme.accentCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Health Connect & Apple Health',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isSync,
                activeThumbColor: AppTheme.primaryGreen,
                activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                onChanged: (val) => provider.toggleHealthSync(val),
              ),
            ],
          ),

          if (isSync) ...[
            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 14),

            // Live Synced Metrics Row
            Row(
              children: [
                _buildSyncMetric('Steps Today', '7,842', Icons.directions_walk_rounded, AppTheme.primaryGreen),
                const SizedBox(width: 8),
                _buildSyncMetric('Active Burn', '-420 kcal', Icons.local_fire_department_rounded, AppTheme.accentAmber),
                const SizedBox(width: 8),
                _buildSyncMetric('Hydration', '+1,750 ml', Icons.water_drop_rounded, AppTheme.accentCyan),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Synced with Health Connect',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    provider.syncWithHealthConnect();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Synced activity & burned calories with Health Connect! ⚡'),
                        backgroundColor: AppTheme.primaryGreenDark,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, color: AppTheme.accentCyan, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Sync Now',
                          style: TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorReportCard(BuildContext context, AppStateProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFB388FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Color(0xFFB388FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Nutrition Export',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Medical-grade summary for consultations',
                      style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showDoctorReportDialog(context, provider),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export Clinical Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB388FF),
                side: BorderSide(color: const Color(0xFFB388FF).withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDoctorReportDialog(BuildContext context, AppStateProvider provider) {
    final report = HealthSyncService.generateDoctorReport(
      userName: _userName,
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      Icon(Icons.medical_information_rounded, color: AppTheme.primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Clinical Nutrition Report',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
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
                'Formatted for Registered Dietitians, Nutritionists & Medical Practitioners.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 380),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
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
                        content: const Text('Doctor report copied to clipboard! 📋'),
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

  Widget _buildNutritionTargetsCard(AppStateProvider provider) {
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
                  Icon(Icons.track_changes_rounded, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Nutrition Targets',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UserSetupScreen(isFirstTime: false),
                    ),
                  );
                },
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Target Rows with visual micro meters
          _buildTargetItem(
            name: 'Daily Calories',
            targetStr: '${provider.calorieTarget.toInt()} kcal',
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 8),
          _buildTargetItem(
            name: 'Protein Goal',
            targetStr: '${provider.proteinTarget.toInt()} g',
            color: AppTheme.macroProtein,
          ),
          const SizedBox(height: 8),
          _buildTargetItem(
            name: 'Carbs Goal',
            targetStr: '${provider.carbsTarget.toInt()} g',
            color: AppTheme.macroCarbs,
          ),
          const SizedBox(height: 8),
          _buildTargetItem(
            name: 'Fats Goal',
            targetStr: '${provider.fatTarget.toInt()} g',
            color: AppTheme.macroFat,
          ),
          const SizedBox(height: 8),
          _buildTargetItem(
            name: 'Hydration Target',
            targetStr: '${provider.waterTargetMl} ml',
            color: AppTheme.macroProtein,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetItem({
    required String name,
    required String targetStr,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            targetStr,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDietaryPreferencesCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu_rounded, color: AppTheme.macroCarbs, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dietary Focus & Allergies',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableDietaryTags.map((tag) {
              final isSelected = _selectedDietaryTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDietaryTags.remove(tag);
                    } else {
                      _selectedDietaryTags.add(tag);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(Icons.check_rounded, color: AppTheme.primaryGreen, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard(AppStateProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.macroProtein, size: 20),
              const SizedBox(width: 8),
              Text(
                'App Preferences',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Theme Mode (Appearance) Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance / Theme',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose light or dark visual style',
                        style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildThemeOption(
                    label: 'Light',
                    icon: Icons.light_mode_rounded,
                    isSelected: provider.themeMode == ThemeMode.light,
                    onTap: () => provider.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    label: 'Dark',
                    icon: Icons.dark_mode_rounded,
                    isSelected: provider.themeMode == ThemeMode.dark,
                    onTap: () => provider.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    label: 'System',
                    icon: Icons.brightness_auto_rounded,
                    isSelected: provider.themeMode == ThemeMode.system,
                    onTap: () => provider.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 14),

          // Notifications Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal & Water Reminders',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Daily reminders to log your food',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                  ),
                ],
              ),
              Switch(
                value: _notificationsEnabled,
                activeThumbColor: AppTheme.primaryGreen,
                activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                inactiveThumbColor: AppTheme.textSecondary,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 12),

          // Units Row
          GestureDetector(
            onTap: () {
              setState(() {
                _preferredUnits = _preferredUnits.startsWith('Metric')
                    ? 'Imperial (lbs, oz)'
                    : 'Metric (kg, ml)';
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Measurement Units',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toggle between Metric & Imperial',
                      style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Text(
                    _preferredUnits,
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textTertiary,
              ),
              const SizedBox(width: 6),
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

  Widget _buildDataAndPrivacyCard(AppStateProvider provider) {
    final clerkAuth = ClerkAuth.of(context);

    return ListenableBuilder(
      listenable: clerkAuth,
      builder: (context, _) {
        final isAuthLoading = clerkAuth.isNotAvailable;
        final bool isAuthenticated = !isAuthLoading && _isClerkSessionActive(clerkAuth);

        return GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppTheme.accentPurple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Data & Support',
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

              // Unauthenticated Action: Log In / Sign Up
              if (!isAuthenticated && !isAuthLoading) ...[
                _buildActionRow(
                  title: 'Log In / Sign Up',
                  subtitle: 'Sign in to sync meal history and access your account',
                  icon: Icons.login_rounded,
                  color: AppTheme.primaryGreen,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ClerkAuthScreen()),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Authenticated Protected Action 1: Password Management
              if (isAuthenticated) ...[
                _buildActionRow(
                  title: 'Password Management',
                  subtitle: 'Change or manage your password',
                  icon: Icons.lock_outline_rounded,
                  color: AppTheme.accentPurple,
                  onTap: () => _showPasswordManagementDialog(context),
                ),
                const SizedBox(height: 10),
              ],

              // Recalculate Nutrition Targets Button (Always Available)
              _buildActionRow(
                title: 'Recalculate Nutrition Targets',
                icon: Icons.calculate_rounded,
                color: AppTheme.primaryGreen,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const UserSetupScreen(isFirstTime: false)),
                ),
              ),

              const SizedBox(height: 10),

              // Tutorial Button (Always Available)
              _buildActionRow(
                title: 'Onboarding Tutorial',
                icon: Icons.school_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                ),
              ),

              // Authenticated Protected Action 2: Clear Scan History
              if (isAuthenticated) ...[
                const SizedBox(height: 10),
                _buildActionRow(
                  title: 'Clear Scan History',
                  icon: Icons.delete_outline_rounded,
                  color: AppTheme.error,
                  onTap: () => _showClearDataDialog(context, provider),
                ),
              ],

              // Authenticated Protected Action 3: Log Out
              if (isAuthenticated) ...[
                const SizedBox(height: 10),
                _buildActionRow(
                  title: 'Log Out',
                  icon: Icons.logout_rounded,
                  color: AppTheme.error,
                  onTap: () => _showLogoutDialog(context, provider),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionRow({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppTheme.primaryGreen;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color ?? AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: effectiveColor, size: 18),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppStateProvider provider) {
    final clerkAuth = ClerkAuth.of(context, listen: false);
    final clerkUser = clerkAuth.user;
    final clerkName = clerkUser?.firstName != null
        ? '${clerkUser!.firstName} ${clerkUser.lastName ?? ''}'.trim()
        : (clerkUser?.username ?? '');
    final emails = clerkUser?.emailAddresses;
    final clerkEmail = (emails != null && emails.isNotEmpty)
        ? emails.first.emailAddress
        : '';

    final currentName = clerkName.isNotEmpty
        ? clerkName
        : (provider.userProfileName.trim().isNotEmpty
            ? provider.userProfileName
            : _userName);
    final currentEmail = clerkEmail.isNotEmpty
        ? clerkEmail
        : (provider.userProfileEmail.trim().isNotEmpty
            ? provider.userProfileEmail
            : _userEmail);

    final nameCtrl = TextEditingController(text: currentName == 'Nutrition User' ? '' : currentName);
    final emailCtrl = TextEditingController(text: currentEmail);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isSaving)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Avatar preview & change button
                Center(
                  child: Column(
                    children: [
                      UserAvatarWidget(
                        photoPath: provider.userPhotoPath ?? clerkUser?.imageUrl,
                        userName: currentName,
                        radius: 34,
                        showEditBadge: true,
                        onTap: () {
                          Navigator.pop(dialogCtx);
                          showPhotoPickerSheet(context, provider);
                        },
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(dialogCtx);
                          showPhotoPickerSheet(context, provider);
                        },
                        child: Text(
                          'Change Photo or Avatar',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  readOnly: true,
                  style: TextStyle(color: AppTheme.textSecondary),
                  decoration: InputDecoration(
                    labelText: 'Email Address (Verified)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: Icon(Icons.verified_rounded, color: AppTheme.primaryGreen, size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                      child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final newName = nameCtrl.text.trim().isEmpty ? 'Nutrition User' : nameCtrl.text.trim();
                              setDialogState(() => isSaving = true);

                              // 1. Update Clerk user via supported SDK methods
                              try {
                                final parts = newName.split(' ');
                                final firstName = parts.first;
                                final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;

                                if (clerkAuth.user != null) {
                                  await clerkAuth.updateUser(
                                    firstName: firstName,
                                    lastName: lastName,
                                  );
                                }
                              } catch (e) {
                                debugPrint('Clerk updateUser error: $e');
                              }

                              // 2. Update local state & AppStateProvider
                              setState(() {
                                _userName = newName;
                              });
                              await provider.setUserProfile(newName, currentEmail);

                              // 3. Sync to Supabase backend API
                              try {
                                await ApiClient().updateProfile({'name': newName});
                              } catch (e) {
                                debugPrint('Backend profile update notice: $e');
                              }

                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text('Profile updated successfully! ✨'),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                );
                              }
                            },
                      child: Text(
                        isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordManagementDialog(BuildContext context) {
    final clerkAuth = ClerkAuth.of(context, listen: false);
    if (!_isClerkSessionActive(clerkAuth)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to manage your password.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    final user = clerkAuth.user;
    final hasPassword = user?.passwordEnabled ?? false;

    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_rounded, color: AppTheme.primaryGreen, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Password Management',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!hasPassword) ...[
                  Text(
                    'You are signed in with Google or an OTP code and do not currently have a password set.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your account credentials are secure and verified.',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Close'),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Update your account password securely.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: currentPassCtrl,
                    obscureText: true,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.check_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                        child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final currentPass = currentPassCtrl.text;
                                final newPass = newPassCtrl.text;
                                final confirmPass = confirmPassCtrl.text;

                                if (currentPass.isEmpty || newPass.isEmpty) {
                                  setDialogState(() => errorMessage = 'Please fill in all fields.');
                                  return;
                                }
                                if (newPass.length < 8) {
                                  setDialogState(() => errorMessage = 'Password must be at least 8 characters.');
                                  return;
                                }
                                if (newPass != confirmPass) {
                                  setDialogState(() => errorMessage = 'New passwords do not match.');
                                  return;
                                }

                                setDialogState(() {
                                  isSubmitting = true;
                                  errorMessage = null;
                                });

                                try {
                                  await clerkAuth.updateUserPassword(
                                    currentPass,
                                    newPass,
                                    signOut: false,
                                  );
                                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Password updated successfully! 🔒'),
                                        backgroundColor: AppTheme.primaryGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() {
                                    isSubmitting = false;
                                    errorMessage = 'Failed to update password: $e';
                                  });
                                }
                              },
                        child: Text(isSubmitting ? 'Updating...' : 'Update Password'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showClearDataDialog(BuildContext context, AppStateProvider provider) {
    final clerkAuth = ClerkAuth.of(context, listen: false);
    if (!_isClerkSessionActive(clerkAuth)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to clear your scan history.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Clear Scan History?',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This will erase all logged meal history and daily totals from this device. This action cannot be undone.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearHistory();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('History cleared'),
                          backgroundColor: AppTheme.cardBackground,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete All'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppStateProvider provider) {
    final clerkAuth = ClerkAuth.of(context, listen: false);
    if (!_isClerkSessionActive(clerkAuth)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active authenticated session found.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.logout_rounded, color: AppTheme.error, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Log Out?',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to log out? Your saved nutrition profile and meal history will remain safe on this device.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      try {
                        await ClerkAuth.of(context).signOut();
                      } catch (e) {
                        debugPrint('Clerk signOut notice: $e');
                      }
                      ApiClient().setSessionToken(null);
                      await provider.onClerkLogout();
                      await StorageService().clearAuthSession();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const ClerkAuthScreen(isRedirectAfterLogout: true),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Log Out'),
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
