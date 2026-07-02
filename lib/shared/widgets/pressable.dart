import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/game_config.dart';

/// Wraps any widget with a premium press interaction: a subtle scale-down on
/// pointer-down that springs back on release, plus optional haptics. Respects
/// the reduced-motion accessibility flag.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onPressed,
    this.pressedScale = 0.94,
    this.haptic = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double pressedScale;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool down) {
    if (!_enabled) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final scale =
        (_down && !GameConfig.reducedMotion) ? widget.pressedScale : 1.0;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: _enabled
            ? () {
                if (widget.haptic && GameConfig.hapticsEnabled) {
                  HapticFeedback.selectionClick();
                }
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: scale,
          duration: GameConfig.fast,
          curve: Curves.easeOutBack,
          child: Opacity(
            opacity: _enabled ? 1 : 0.5,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
