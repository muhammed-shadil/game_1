import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pressable.dart';
import '../game/puzzle_game.dart';

/// In-game overlay: pause/back, level name, remaining shots + targets. Reads the
/// game's [ValueNotifier]s so it rebuilds only the affected chip on change.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.game,
    required this.onPause,
  });

  final PuzzleGame game;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pressable(
                  semanticLabel: 'Pause',
                  onPressed: onPause,
                  child: GlassCard(
                    padding: const EdgeInsets.all(10),
                    radius: 14,
                    child:
                        const Icon(Icons.pause_rounded, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  radius: 14,
                  child: Text(
                    game.level.name,
                    style: AppTextStyles.title.copyWith(color: Colors.white),
                  ),
                ),
                const Spacer(),
                _TargetsChip(game: game),
                const SizedBox(width: 12),
                _ShotsChip(game: game),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: _ZoomControls(game: game),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.game});
  final PuzzleGame game;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(icon: Icons.add_rounded, onTap: game.zoomIn),
        const SizedBox(height: 10),
        _ZoomButton(icon: Icons.remove_rounded, onTap: game.zoomOut),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Zoom',
      onPressed: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        radius: 14,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _TargetsChip extends StatelessWidget {
  const _TargetsChip({required this.game});
  final PuzzleGame game;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: 14,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.adjust_rounded, color: AppColors.secondary, size: 20),
          const SizedBox(width: 6),
          ValueListenableBuilder<int>(
            valueListenable: game.targetsLeft,
            builder: (context, value, _) => Text(
              '$value',
              style: AppTextStyles.counter.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShotsChip extends StatelessWidget {
  const _ShotsChip({required this.game});
  final PuzzleGame game;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: 14,
      child: ValueListenableBuilder<int>(
        valueListenable: game.shotsLeft,
        builder: (context, value, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(game.level.shots, (i) {
            final available = i < value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: available ? AppColors.primary : Colors.white24,
                  boxShadow: available
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
