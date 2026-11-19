import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/user_models.dart';
import '../providers/app_state_provider.dart';
import '../widgets/enhanced_cards.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Achievement> _achievements = [];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRealAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadRealAchievements() {
    final provider = context.read<AppStateProvider>();
    final history = provider.history;
    final streak = provider.getStreakDays();
    final List<Achievement> list = [];

    if (history.isNotEmpty) {
      list.add(Achievement(
        id: '1',
        title: 'First Scan',
        description: 'Scanned your first food item',
        iconName: 'camera_alt',
        unlockedAt: history.last.timestamp,
        category: 'scanning',
        points: 10,
      ));
    }

    if (history.length >= 10) {
      list.add(Achievement(
        id: '2',
        title: 'Food Explorer',
        description: 'Scanned 10 different food items',
        iconName: 'lightbulb',
        unlockedAt: history[history.length - 10].timestamp,
        category: 'scanning',
        points: 25,
      ));
    }

    if (history.length >= 50) {
      list.add(Achievement(
        id: '3',
        title: 'Scanner Master',
        description: 'Scanned 50 food items',
        iconName: 'emoji_events',
        unlockedAt: history[history.length - 50].timestamp,
        category: 'scanning',
        points: 50,
      ));
    }

    if (streak >= 7) {
      list.add(Achievement(
        id: '4',
        title: 'Consistency King',
        description: 'Tracked food for 7 consecutive days',
        iconName: 'schedule',
        unlockedAt: DateTime.now(),
        category: 'consistency',
        points: 50,
      ));
    }

    setState(() {
      _achievements = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Scanning'),
            Tab(text: 'Nutrition'),
            Tab(text: 'Consistency'),
            Tab(text: 'Goals'),
          ],
          onTap: (index) {
            setState(() {
              _selectedCategory = ['all', 'scanning', 'nutrition', 'consistency', 'goals'][index];
            });
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            // Stats Overview
            _buildStatsOverview(),
            
            // Achievements List
            Expanded(
              child: _buildAchievementsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalPoints = _achievements.fold(0, (sum, achievement) => sum + achievement.points);
    final categoryCounts = <String, int>{};
    
    for (final achievement in _achievements) {
      categoryCounts[achievement.category] = (categoryCounts[achievement.category] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              title: 'Total Points',
              value: totalPoints.toString(),
              icon: Icons.emoji_events,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: StatsCard(
              title: 'Achievements',
              value: _achievements.length.toString(),
              icon: Icons.star,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: StatsCard(
              title: 'Recent',
              value: _achievements.where((a) => 
                DateTime.now().difference(a.unlockedAt).inDays < 7
              ).length.toString(),
              icon: Icons.schedule,
              color: Colors.blue,
              subtitle: 'this week',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList() {
    final filteredAchievements = _selectedCategory == 'all' 
        ? _achievements
        : _achievements.where((a) => a.category == _selectedCategory).toList();

    if (filteredAchievements.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: filteredAchievements.length,
      itemBuilder: (context, index) {
        final achievement = filteredAchievements[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: AchievementCard(
            achievement: achievement,
            onTap: () => _showAchievementDetails(achievement),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'No achievements yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Start scanning food and reaching your goals to unlock achievements!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingL),
              GradientButton(
                text: 'Start Scanning',
                icon: Icons.camera_alt,
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to scan screen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AchievementDetailsSheet(achievement: achievement),
    );
  }
}

class _AchievementDetailsSheet extends StatelessWidget {
  final Achievement achievement;

  const _AchievementDetailsSheet({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Achievement Icon and Title
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.mediumShadow,
            ),
            child: Icon(
              _getAchievementIcon(achievement.iconName),
              color: AppTheme.textOnPrimary,
              size: 48,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          Text(
            achievement.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingS),
          
          Text(
            achievement.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Points and Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDetailItem(
                context,
                'Points',
                '${achievement.points}',
                Icons.stars,
                Colors.amber,
              ),
              _buildDetailItem(
                context,
                'Category',
                _getCategoryLabel(achievement.category),
                Icons.category,
                AppTheme.primaryGreen,
              ),
              _buildDetailItem(
                context,
                'Unlocked',
                _formatUnlockedDate(achievement.unlockedAt),
                Icons.schedule,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Share Achievement
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Share feature coming soon!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: GradientButton(
                  text: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: AppTheme.smallRadius,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'star':
        return Icons.star;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'schedule':
        return Icons.schedule;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.emoji_events;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'scanning':
        return 'Scanning';
      case 'nutrition':
        return 'Nutrition';
      case 'consistency':
        return 'Consistency';
      case 'goals':
        return 'Goals';
      default:
        return 'General';
    }
  }

  String _formatUnlockedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}