import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/nutrition_tip_card.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/api_status_banner.dart';
import '../widgets/nutri_loading_indicator.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'tip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppStateProvider>(); if (!provider.isInitialized) { provider.initialize(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          ScanScreen(),
          HistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Status Banner
            const ApiStatusBanner(),
            
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getTimeOfDay()}!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready to scan?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF38e07b).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Add notification functionality
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF38e07b),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Daily Summary Card
            const DailySummaryCard(),

            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'Scan Food',
                    subtitle: 'Take a photo',
                    color: const Color(0xFF38e07b),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ScanScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.history_outlined,
                    title: 'View History',
                    subtitle: 'Past scans',
                    color: Colors.blue,
                    onTap: () {
                      // TODO: Navigate to history tab
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nutrition Tips Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Nutrition Tips',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer<AppStateProvider>(
                      builder: (context, provider, child) {
                        return provider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF38e07b),
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: () async {
                                  // Refresh tips with AI-generated content
                                  await provider.refreshNutritionTips();
                                },
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Color(0xFF38e07b),
                                  size: 20,
                                ),
                                tooltip: 'Refresh Tips',
                              );
                      },
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    final provider = context.read<AppStateProvider>();
                    switch (value) {
                      case 'personalized':
                        await provider.loadPersonalizedTips();
                        break;
                      case 'all':
                        await provider.loadNutritionTips();
                        break;
                      case 'refresh':
                        await provider.refreshNutritionTips();
                        break;
                    }
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF38e07b),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'personalized',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.white70),
                          SizedBox(width: 8),
                          Text('Personalized Tips'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'all',
                      child: Row(
                        children: [
                          Icon(Icons.list, color: Colors.white70),
                          SizedBox(width: 8),
                          Text('All Tips'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.white70),
                          SizedBox(width: 8),
                          Text('Refresh with AI'),
                        ],
                      ),
                    ),
                  ],
                  color: const Color(0xFF2a2a2a),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Nutrition Tips List
            Consumer<AppStateProvider>(
              builder: (context, provider, child) {
                final tips = provider.nutritionTips.take(3).toList();
                
                if (provider.isLoading && tips.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: NutriLoadingIndicator(
                        size: 90,
                        message: 'Generating personalized nutrition tips...',
                      ),
                    ),
                  );
                }
                
                if (tips.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Text(
                            'No nutrition tips available',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await provider.loadNutritionTips();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Load Tips'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38e07b),
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Show AI indicator if we have history
                    if (provider.history.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38e07b).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF38e07b).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Color(0xFF38e07b),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'AI-powered tips based on your scans',
                              style: TextStyle(
                                color: Color(0xFF38e07b),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Tips list
                    ...tips
                        .map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: NutritionTipCard(
                                tip: tip,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => TipDetailScreen(tip: tip),
                                    ),
                                  );
                                },
                              ),
                            ))
                        ,
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
