import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/game_config.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/gameplay/presentation/game_page.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/levels/presentation/level_select_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// Route names, referenced by screens to avoid stringly-typed navigation.
abstract class Routes {
  static const home = 'home';
  static const levels = 'levels';
  static const play = 'play';
  static const settings = 'settings';
  static const achievements = 'achievements';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: Routes.home,
        pageBuilder: (context, state) =>
            _fade(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/levels',
        name: Routes.levels,
        pageBuilder: (context, state) =>
            _slide(state, const LevelSelectScreen()),
      ),
      GoRoute(
        path: '/settings',
        name: Routes.settings,
        pageBuilder: (context, state) =>
            _slide(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/achievements',
        name: Routes.achievements,
        pageBuilder: (context, state) =>
            _slide(state, const AchievementsScreen()),
      ),
      GoRoute(
        path: '/play/:id',
        name: Routes.play,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _scaleFade(state, GamePage(levelId: id));
        },
      ),
    ],
  );
});

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: GameConfig.medium,
    child: child,
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: GameConfig.medium,
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _scaleFade(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: GameConfig.medium,
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
