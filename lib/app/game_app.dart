import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/game_config.dart';
import '../core/services/ad_service.dart';
import '../features/settings/application/settings_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget. Wires the router + Material 3 themes. Theme mode follows the
/// system by default; the settings layer can later expose an override.
///
/// Also watches the app lifecycle to show an App Open ad when the player
/// returns to a foregrounded app (rate-limited inside [AdService]).
class GameApp extends ConsumerStatefulWidget {
  const GameApp({super.key});

  @override
  ConsumerState<GameApp> createState() => _GameAppState();
}

class _GameAppState extends ConsumerState<GameApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Player brought the app back to the foreground: maybe show an App Open ad.
    // The service enforces the interval cap and skips the first launch.
    if (state == AppLifecycleState.resumed) {
      AdService.instance.showAppOpenIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(settingsProvider).themeMode;

    return MaterialApp.router(
      title: GameConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
