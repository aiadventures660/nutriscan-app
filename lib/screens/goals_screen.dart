import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/user_models.dart';
import '../providers/app_state_provider.dart';
import '../widgets/enhanced_cards.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserGoals();
  }

  void _loadUserGoals() {
    final provider = context.read<AppStateProvider>();
    final totals = provider.getDailyNutritionSummary(DateTime.now());
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weeklyScansCount = provider.history.where((e) => e.timestamp.isAfter(weekStart)).length;

    setState(() {
      _goals = [
        Goal(
          id: '1',
          title: 'Daily Calories',
          description: 'Reach your daily calorie target of ${provider.calorieTarget.toInt()} kcal',
          type: GoalType.dailyCalories,
          targetValue: provider.calorieTarget,
          currentValue: totals['calories'] ?? 0,
          startDate: DateTime(now.year, now.month, now.day),
          endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
          unit: 'kcal',
        ),
        Goal(
          id: '2',
          title: 'Weekly Scans',
          description: 'Scan at least 15 foods this week',
          type: GoalType.weeklyScans,
          targetValue: 15,
          currentValue: weeklyScansCount.toDouble(),
          startDate: weekStart,
          endDate: weekStart.add(const Duration(days: 7)),
          unit: 'scans',
        ),
        Goal(
          id: '3',
          title: 'Daily Protein',
          description: 'Meet your daily protein goal of ${provider.proteinTarget.toInt()}g',
          type: GoalType.dailyProtein,
          targetValue: provider.proteinTarget,
          currentValue: totals['protein'] ?? 0,
          startDate: DateTime(now.year, now.month, now.day),
          endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
          unit: 'g',
        ),
        Goal(
          id: '4',
          title: 'Water Intake',
          description: 'Drink at least ${(provider.waterTargetMl / 250).round()} glasses of water daily',
          type: GoalType.waterIntake,
          targetValue: (provider.waterTargetMl / 250).roundToDouble(),
          currentValue: (provider.waterIntakeMl / 250).roundToDouble(),
          startDate: DateTime(now.year, now.month, now.day),
          endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
          unit: 'glasses',
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _showAddGoalDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          children: [
            // Stats Overview
            _buildStatsOverview(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Active Goals
            Text(
              'Active Goals',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            ..._goals.where((goal) => !goal.isCompleted).map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: GoalCard(
                goal: goal,
                onTap: () => _showGoalDetails(goal),
                onEdit: () => _editGoal(goal),
              ),
            )),
            
            // Completed Goals
            if (_goals.any((goal) => goal.isCompleted)) ...[
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Completed Goals',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              ..._goals.where((goal) => goal.isCompleted).map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: GoalCard(
                  goal: goal,
                  onTap: () => _showGoalDetails(goal),
                ),
              )),
            ],
            
            const SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final activeGoals = _goals.where((goal) => !goal.isCompleted).length;
    final completedGoals = _goals.where((goal) => goal.isCompleted).length;
    final averageProgress = _goals.isNotEmpty 
        ? _goals.map((g) => g.progressPercentage).reduce((a, b) => a + b) / _goals.length
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Active Goals',
            value: activeGoals.toString(),
            icon: Icons.flag,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: StatsCard(
            title: 'Completed',
            value: completedGoals.toString(),
            icon: Icons.check_circle,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: StatsCard(
            title: 'Avg Progress',
            value: '${averageProgress.toInt()}%',
            icon: Icons.trending_up,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddGoalDialog(
        onGoalAdded: (goal) {
          setState(() {
            _goals.add(goal);
          });
        },
      ),
    );
  }

  void _editGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => _EditGoalDialog(
        goal: goal,
        onGoalUpdated: (updatedGoal) {
          setState(() {
            final index = _goals.indexWhere((g) => g.id == goal.id);
            if (index != -1) {
              _goals[index] = updatedGoal;
            }
          });
        },
      ),
    );
  }

  void _showGoalDetails(Goal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GoalDetailsSheet(goal: goal),
    );
  }
}

class _AddGoalDialog extends StatefulWidget {
  final Function(Goal) onGoalAdded;

  const _AddGoalDialog({required this.onGoalAdded});

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  GoalType _selectedType = GoalType.dailyCalories;
  final DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: const Text('Add New Goal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'Enter goal title',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter goal description',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppTheme.spacingM),
              DropdownButtonFormField<GoalType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Goal Type',
                ),
                items: GoalType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getGoalTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target Value',
                  hintText: 'Enter target (${_getGoalUnit(_selectedType)})',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a target value';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addGoal,
          child: const Text('Add Goal'),
        ),
      ],
    );
  }

  void _addGoal() {
    if (_formKey.currentState!.validate()) {
      final goal = Goal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        targetValue: double.parse(_targetController.text),
        startDate: DateTime.now(),
        endDate: _endDate,
        unit: _getGoalUnit(_selectedType),
      );
      
      widget.onGoalAdded(goal);
      Navigator.of(context).pop();
    }
  }

  String _getGoalTypeLabel(GoalType type) {
    switch (type) {
      case GoalType.dailyCalories:
        return 'Daily Calories';
      case GoalType.dailyProtein:
        return 'Daily Protein';
      case GoalType.dailyCarbs:
        return 'Daily Carbs';
      case GoalType.dailyFat:
        return 'Daily Fat';
      case GoalType.weeklyScans:
        return 'Weekly Scans';
      case GoalType.waterIntake:
        return 'Water Intake';
      case GoalType.exercise:
        return 'Exercise';
      case GoalType.weightLoss:
        return 'Weight Loss';
      case GoalType.weightGain:
        return 'Weight Gain';
      case GoalType.custom:
        return 'Custom';
    }
  }

  String _getGoalUnit(GoalType type) {
    switch (type) {
      case GoalType.dailyCalories:
        return 'kcal';
      case GoalType.dailyProtein:
      case GoalType.dailyCarbs:
      case GoalType.dailyFat:
        return 'g';
      case GoalType.weeklyScans:
        return 'scans';
      case GoalType.waterIntake:
        return 'glasses';
      case GoalType.exercise:
        return 'minutes';
      case GoalType.weightLoss:
      case GoalType.weightGain:
        return 'kg';
      case GoalType.custom:
        return '';
    }
  }
}

class _EditGoalDialog extends StatefulWidget {
  final Goal goal;
  final Function(Goal) onGoalUpdated;

  const _EditGoalDialog({required this.goal, required this.onGoalUpdated});

  @override
  State<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<_EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _currentValueController;

  @override
  void initState() {
    super.initState();
    _currentValueController = TextEditingController(
      text: widget.goal.currentValue.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: Text('Update ${widget.goal.title}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.goal.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _currentValueController,
              decoration: InputDecoration(
                labelText: 'Current Progress',
                hintText: 'Enter current value (${widget.goal.unit})',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter current progress';
                }
                if (double.tryParse(value!) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateGoal,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateGoal() {
    if (_formKey.currentState!.validate()) {
      final currentValue = double.parse(_currentValueController.text);
      final updatedGoal = Goal(
        id: widget.goal.id,
        title: widget.goal.title,
        description: widget.goal.description,
        type: widget.goal.type,
        targetValue: widget.goal.targetValue,
        currentValue: currentValue,
        startDate: widget.goal.startDate,
        endDate: widget.goal.endDate,
        isCompleted: currentValue >= widget.goal.targetValue,
        unit: widget.goal.unit,
        iconName: widget.goal.iconName,
      );
      
      widget.onGoalUpdated(updatedGoal);
      Navigator.of(context).pop();
    }
  }
}

class _GoalDetailsSheet extends StatelessWidget {
  final Goal goal;

  const _GoalDetailsSheet({required this.goal});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: goal.isCompleted 
                      ? AppTheme.success.withOpacity(0.2)
                      : AppTheme.primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goal.isCompleted ? Icons.check_circle : Icons.flag,
                  color: goal.isCompleted ? AppTheme.success : AppTheme.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      goal.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${goal.progressPercentage.toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: goal.isCompleted ? AppTheme.success : AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            backgroundColor: AppTheme.surfaceAccent,
            valueColor: AlwaysStoppedAnimation<Color>(
              goal.isCompleted ? AppTheme.success : AppTheme.primaryGreen,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '${goal.currentValue.toInt()} / ${goal.targetValue.toInt()} ${goal.unit}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Timeline
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Started',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatDate(goal.startDate),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      goal.isCompleted ? 'Completed' : 'Target Date',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatDate(goal.endDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: goal.daysRemaining < 0 ? AppTheme.error : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (!goal.isCompleted) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              goal.daysRemaining > 0 
                  ? '${goal.daysRemaining} days remaining'
                  : 'Overdue by ${-goal.daysRemaining} days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: goal.daysRemaining > 0 ? AppTheme.textSecondary : AppTheme.error,
              ),
            ),
          ],
          
          const SizedBox(height: AppTheme.spacingL),
          
          GradientButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
