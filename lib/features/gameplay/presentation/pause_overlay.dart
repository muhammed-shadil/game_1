import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/config/game_config.dart';
import '../../../shared/widgets/pressable.dart';

/// Simple paused-state overlay with resume / restart / quit.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GameConfig.fast,
      builder: (context, t, child) => Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
            child: Container(color: Colors.black.withValues(alpha: 0.5 * t)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Opacity(opacity: t.clamp(0, 1), child: child),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paused',
                style: AppTextStyles.display
                    .copyWith(color: Colors.white, fontSize: 40)),
            const SizedBox(height: 28),
            _PauseAction(
                icon: Icons.play_arrow_rounded,
                label: 'Resume',
                onTap: onResume,
                primary: true),
            const SizedBox(height: 14),
            _PauseAction(
                icon: Icons.refresh_rounded,
                label: 'Restart',
                onTap: onRestart),
            const SizedBox(height: 14),
            _PauseAction(
                icon: Icons.home_rounded, label: 'Quit', onTap: onHome),
          ],
        ),
      ),
    );
  }
}

class _PauseAction extends StatelessWidget {
  const _PauseAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      onPressed: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: primary
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep])
              : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.1),
          border: primary
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: AppTextStyles.button.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
