import 'package:atba/theme/app_theme.dart';
import 'package:atba/theme/theme_presets.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

/// Horizontal list of theme swatches bound to a settings key.
class ThemePresetPicker extends StatelessWidget {
  final String title;
  final IconData icon;
  final String settingKey;
  final String defaultValue;
  final Brightness brightness;

  const ThemePresetPicker({
    super.key,
    required this.title,
    required this.icon,
    required this.settingKey,
    required this.defaultValue,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueChangeObserver<String>(
      cacheKey: settingKey,
      defaultValue: defaultValue,
      builder: (context, value, onChanged) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(title, style: theme.textTheme.titleSmall),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: Text(
                        ThemePresets.byId(value).name,
                        key: ValueKey(value),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ThemePresets.all.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final p = ThemePresets.all[i];
                    return _Swatch(
                      preset: p,
                      brightness: brightness,
                      selected: p.id == value,
                      onTap: () => Settings.setValue<String>(
                        settingKey,
                        p.id,
                        notify: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  final ThemePreset preset;
  final Brightness brightness;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.preset,
    required this.brightness,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = brightness == Brightness.dark;
    final bg = dark
        ? (preset.darkBackground ?? const Color(0xFF15161C))
        : (preset.lightBackground ?? const Color(0xFFF5F6F8));
    final accent = preset.preview.first == bg
        ? preset.preview[1]
        : preset.preview.first;
    return Pressable(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (preset.usesDynamicColor || preset.usesCustomColor)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: SweepGradient(
                          colors: [...preset.preview, preset.preview.first],
                        ),
                      ),
                    )
                  else ...[
                    ColoredBox(color: bg),
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                  if (preset.usesDynamicColor)
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  if (preset.usesCustomColor)
                    const Icon(
                      Icons.colorize_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: AppMotion.fast,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            preset.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
