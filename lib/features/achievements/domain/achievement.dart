import 'package:flutter/material.dart';

/// Snapshot of player stats used to evaluate whether achievements are unlocked.
class AchievementContext {
  const AchievementContext({
    required this.won,
    required this.shotsUsed,
    required this.stars,
    required this.completedLevels,
    required this.threeStarLevels,
    required this.totalExplosions,
    required this.totalTargets,
    required this.totalLevels,
  });

  final bool won;
  final int shotsUsed;
  final int stars;
  final int completedLevels;
  final int threeStarLevels;
  final int totalExplosions;
  final int totalTargets;
  final int totalLevels;
}

/// A single unlockable achievement with a coin payout.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.coinReward,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int coinReward;

  /// Predicate over the current [AchievementContext].
  final bool Function(AchievementContext ctx) isUnlocked;
}

/// The catalogue of achievements. Order is display order.
final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_win',
    title: 'First Blast',
    description: 'Complete your first level',
    icon: Icons.flag_rounded,
    coinReward: 25,
    isUnlocked: (c) => c.completedLevels >= 1,
  ),
  Achievement(
    id: 'perfectionist',
    title: 'Perfectionist',
    description: 'Earn 3 stars on a level',
    icon: Icons.star_rounded,
    coinReward: 40,
    isUnlocked: (c) => c.threeStarLevels >= 1,
  ),
  Achievement(
    id: 'sharpshooter',
    title: 'Sharpshooter',
    description: 'Win a level with a single shot',
    icon: Icons.center_focus_strong_rounded,
    coinReward: 50,
    isUnlocked: (c) => c.won && c.shotsUsed <= 1,
  ),
  Achievement(
    id: 'getting_started',
    title: 'Getting Started',
    description: 'Complete 5 levels',
    icon: Icons.trending_up_rounded,
    coinReward: 50,
    isUnlocked: (c) => c.completedLevels >= 5,
  ),
  Achievement(
    id: 'demolition',
    title: 'Demolition Expert',
    description: 'Trigger 10 explosions',
    icon: Icons.local_fire_department_rounded,
    coinReward: 60,
    isUnlocked: (c) => c.totalExplosions >= 10,
  ),
  Achievement(
    id: 'halfway',
    title: 'Halfway There',
    description: 'Complete 25 levels',
    icon: Icons.military_tech_rounded,
    coinReward: 120,
    isUnlocked: (c) => c.completedLevels >= 25,
  ),
  Achievement(
    id: 'target_master',
    title: 'Target Master',
    description: 'Destroy 100 targets',
    icon: Icons.adjust_rounded,
    coinReward: 80,
    isUnlocked: (c) => c.totalTargets >= 100,
  ),
  Achievement(
    id: 'champion',
    title: 'Champion',
    description: 'Complete every level',
    icon: Icons.emoji_events_rounded,
    coinReward: 300,
    isUnlocked: (c) => c.completedLevels >= c.totalLevels,
  ),
];
