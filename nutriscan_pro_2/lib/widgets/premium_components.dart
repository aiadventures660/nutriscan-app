import 'package:flutter/material.dart';

/// Theme-aware building blocks for NutriScan Pro 2.0.
/// These widgets intentionally have no provider or API dependencies.
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PremiumSectionHeader({super.key, required this.title, this.subtitle,
    this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: theme.textTheme.bodySmall),
        ],
      ])),
      if (actionLabel != null && onAction != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ]);
  }
}

class PremiumSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const PremiumSurfaceCard({super.key, required this.child,
    this.padding = const EdgeInsets.all(20), this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class PremiumActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const PremiumActionTile({super.key, required this.title,
    required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumSurfaceCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: scheme.onPrimaryContainer)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ])),
        Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
      ]),
    );
  }
}

class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  const PremiumEmptyState({super.key, required this.title,
    required this.description, required this.icon, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(child: Padding(padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 34, backgroundColor: scheme.primaryContainer,
          child: Icon(icon, color: scheme.onPrimaryContainer, size: 30)),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(description, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 18),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    ));
  }
}
