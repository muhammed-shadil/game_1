import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// A row of three stars used on level cards and result screens.
///
/// When [animate] is true the earned stars pop in sequence — used on the
/// victory screen for a satisfying reveal.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.stars,
    this.size = 22,
    this.animate = false,
    this.spacing = 2,
  });

  final int stars;
  final double size;
  final bool animate;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < stars;
        final star = Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: earned ? AppColors.star : AppColors.starDim,
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: !animate || !earned
              ? star
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 350 + i * 180),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) =>
                      Transform.scale(scale: v.clamp(0, 1.4), child: child),
                  child: star,
                ),
        );
      }),
    );
  }
}
