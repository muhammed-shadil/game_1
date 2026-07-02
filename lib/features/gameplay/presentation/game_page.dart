import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/config/game_config.dart';
import '../../levels/application/level_providers.dart';
import '../../levels/domain/level.dart';
import '../../progress/application/progress_providers.dart';
import '../game/game_state.dart';
import '../game/puzzle_game.dart';
import 'game_hud.dart';
import 'pause_overlay.dart';
import 'result_overlay.dart';

/// Resolves the level by id then hands off to the interactive view. Kept as a
/// thin async boundary so the game view can assume a fully-loaded [Level].
class GamePage extends ConsumerWidget {
  const GamePage({super.key, required this.levelId});

  final String levelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(levelByIdProvider(levelId));
    return levelAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Could not load level:\n$e')),
      ),
      data: (level) => _GameView(level: level),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _GameView extends ConsumerStatefulWidget {
  const _GameView({required this.level});
  final Level level;

  @override
  ConsumerState<_GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<_GameView> {
  late PuzzleGame _game;
  int _epoch = 0;
  GameResult? _result;
  int _coinsEarned = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _game = _buildGame();
  }

  PuzzleGame _buildGame() {
    return PuzzleGame(
      level: widget.level,
      onResolved: _handleResolved,
    );
  }

  void _handleResolved(GameResult result) {
    if (!mounted) return;

    // Snapshot previously-earned stars so we can show *newly* earned coins.
    final prevStars =
        ref.read(progressProvider).forLevel(widget.level.id)?.stars ?? 0;

    if (result.won) {
      ref.read(progressProvider.notifier).recordCompletion(
            levelId: widget.level.id,
            stars: result.stars,
            shotsUsed: result.shotsUsed,
          );
    }

    final gainedStars =
        result.won ? (result.stars - prevStars).clamp(0, 3) : 0;

    setState(() {
      _result = result;
      _coinsEarned = gainedStars * GameConfig.coinsPerStar;
    });
  }

  void _restart() {
    setState(() {
      _epoch++;
      _game = _buildGame();
      _result = null;
      _paused = false;
    });
  }

  void _togglePause(bool pause) {
    setState(() => _paused = pause);
    if (pause) {
      _game.pauseEngine();
    } else {
      _game.resumeEngine();
    }
  }

  void _goHome() => context.goNamed(Routes.home);

  void _goNext() {
    final next = _nextLevelId();
    if (next == null) {
      _goHome();
    } else {
      context.pushReplacementNamed(Routes.play, pathParameters: {'id': next});
    }
  }

  String? _nextLevelId() {
    final levels = ref.read(levelsProvider).asData?.value;
    if (levels == null) return null;
    final idx = levels.indexWhere((l) => l.id == widget.level.id);
    if (idx >= 0 && idx < levels.length - 1) return levels[idx + 1].id;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Sky backdrop shows through the transparent game canvas.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.skyDay,
              ),
            ),
          ),
          GameWidget(key: ValueKey(_epoch), game: _game),

          // HUD hidden while an overlay is up to keep focus on the dialog.
          if (_result == null && !_paused)
            GameHud(game: _game, onPause: () => _togglePause(true)),

          if (_paused && _result == null)
            PauseOverlay(
              onResume: () => _togglePause(false),
              onRestart: _restart,
              onHome: _goHome,
            ),

          if (_result != null)
            ResultOverlay(
              won: _result!.won,
              stars: _result!.stars,
              coinsEarned: _coinsEarned,
              onRetry: _restart,
              onHome: _goHome,
              onNext: _result!.won && _nextLevelId() != null ? _goNext : null,
            ),
        ],
      ),
    );
  }
}
