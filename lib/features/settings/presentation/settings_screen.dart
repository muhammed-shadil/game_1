import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/pressable.dart';
import '../../progress/application/progress_providers.dart';
import '../application/settings_providers.dart';

/// Functional settings: theme, sound, haptics, reduced motion + reset progress.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return GradientScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Pressable(
                  semanticLabel: 'Back',
                  onPressed: () => context.pop(),
                  child: GlassCard(
                    padding: const EdgeInsets.all(10),
                    radius: 14,
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Settings',
                    style:
                        AppTextStyles.headline.copyWith(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _SectionLabel('Appearance'),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme',
                            style: AppTextStyles.title
                                .copyWith(color: Colors.white)),
                        const SizedBox(height: 12),
                        _ThemeSelector(
                          value: settings.themeMode,
                          onChanged: notifier.setThemeMode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Game'),
                  _ToggleTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Sound & Music',
                    subtitle: 'Effects and background music',
                    value: settings.soundEnabled,
                    onChanged: notifier.setSoundEnabled,
                  ),
                  _ToggleTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptics',
                    subtitle: 'Vibration feedback on launch & impact',
                    value: settings.haptics,
                    onChanged: notifier.setHaptics,
                  ),
                  _ToggleTile(
                    icon: Icons.motion_photos_off_rounded,
                    title: 'Reduced Motion',
                    subtitle: 'Fewer particles, no camera shake',
                    value: settings.reducedMotion,
                    onChanged: notifier.setReducedMotion,
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Data'),
                  _DangerTile(
                    icon: Icons.restart_alt_rounded,
                    title: 'Reset Progress',
                    subtitle: 'Clear all stars, coins and unlocks',
                    onTap: () => _confirmReset(context, ref),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This permanently clears all stars, coins and unlocked levels. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => context.pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(progressProvider.notifier).resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress reset')),
        );
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.label
            .copyWith(color: Colors.white.withValues(alpha: 0.5)),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
            value: ThemeMode.system,
            label: Text('System'),
            icon: Icon(Icons.brightness_auto_rounded)),
        ButtonSegment(
            value: ThemeMode.light,
            label: Text('Light'),
            icon: Icon(Icons.light_mode_rounded)),
        ButtonSegment(
            value: ThemeMode.dark,
            label: Text('Dark'),
            icon: Icon(Icons.dark_mode_rounded)),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.tertiary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.title
                          .copyWith(color: Colors.white, fontSize: 16)),
                  Text(subtitle,
                      style: AppTextStyles.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.55))),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: title,
      onPressed: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.danger),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.title.copyWith(
                          color: AppColors.danger, fontSize: 16)),
                  Text(subtitle,
                      style: AppTextStyles.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.55))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
