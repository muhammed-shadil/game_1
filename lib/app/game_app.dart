import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/game_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget. Wires the router + Material 3 themes. Theme mode follows the
/// system by default; the settings layer can later expose an override.
class GameApp extends ConsumerWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: GameConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
