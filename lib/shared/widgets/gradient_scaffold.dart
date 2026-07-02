import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// A scaffold whose background is a slowly drifting radial+linear gradient,
/// giving menus an ambient, premium feel without any assets.
class GradientScaffold extends StatefulWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.colors = AppColors.menuBackdrop,
    this.animate = true,
  });

  final Widget child;
  final List<Color> colors;
  final bool animate;

  @override
  State<GradientScaffold> createState() => _GradientScaffoldState();
}

class _GradientScaffoldState extends State<GradientScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 0.4, -1),
                end: Alignment(1, 1 - t * 0.4),
                colors: widget.colors,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Soft ambient blob for depth.
                Positioned(
                  top: -120 + t * 40,
                  right: -80,
                  child: _blob(AppColors.primary.withValues(alpha: 0.25), 320),
                ),
                Positioned(
                  bottom: -140 - t * 30,
                  left: -90,
                  child:
                      _blob(AppColors.secondary.withValues(alpha: 0.18), 360),
                ),
                child!,
              ],
            ),
          );
        },
        child: SafeArea(child: widget.child),
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
