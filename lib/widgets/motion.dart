import 'dart:ui';

import 'package:atba/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Scales its child down slightly while pressed and bounces back on release.
/// Gives every tappable surface a tactile, physical feel.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.haptic = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _set(false);
              HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: _pressed ? AppMotion.fast : AppMotion.medium,
        curve: _pressed ? Curves.easeOut : AppMotion.spring,
        child: widget.child,
      ),
    );
  }
}

/// Fades + slides a child in once, optionally staggered by [index].
class EntranceAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final double offsetY;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.offsetY = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 40 * index.clamp(0, 12));
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppMotion.medium, curve: AppMotion.emphasized)
        .slideY(
          begin: offsetY,
          end: 0,
          duration: AppMotion.slow,
          curve: AppMotion.emphasized,
        );
  }
}

enum ToastType { info, success, error }

/// Shows an animated floating toast with an icon. Use for action feedback.
void showToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final (IconData icon, Color color) = switch (type) {
    ToastType.success => (Icons.check_circle_rounded, const Color(0xFF34D399)),
    ToastType.error => (Icons.error_rounded, const Color(0xFFF87171)),
    ToastType.info => (Icons.info_rounded, const Color(0xFF93C5FD)),
  };
  switch (type) {
    case ToastType.success:
      HapticFeedback.lightImpact();
    case ToastType.error:
      HapticFeedback.heavyImpact();
    case ToastType.info:
      break;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: color)
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  duration: AppMotion.slow,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: AppMotion.fast),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// A rounded, softly bordered surface. The building block of the new UI.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Gradient? gradient;
  final bool highlighted;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.onTap,
    this.onLongPress,
    this.color,
    this.gradient,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? (highlighted
                  ? Color.alphaBlend(
                      scheme.primary.withValues(alpha: 0.14),
                      color ?? scheme.surface,
                    )
                  : color ?? scheme.surface)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: highlighted
              ? scheme.primary.withValues(alpha: 0.6)
              : scheme.outlineVariant,
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: child,
    );
    if (onTap == null && onLongPress == null) return card;
    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      pressedScale: 0.975,
      child: card,
    );
  }
}

/// Small rounded square with a tinted background holding an icon.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// A pill-shaped status label.
class StatusPill extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusPill({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: c, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Progress bar that animates smoothly between values.
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color? color;

  const AnimatedProgressBar({super.key, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
      builder: (context, v, _) => LinearProgressIndicator(
        value: v,
        color: color,
        backgroundColor: (color ?? Theme.of(context).colorScheme.primary)
            .withValues(alpha: 0.14),
      ),
    );
  }
}

/// Header used at the top of list sections.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 12, 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
    if (onTap == null) return content;
    return Pressable(onTap: onTap, pressedScale: 0.98, child: content);
  }
}

/// Placeholder shown when a list is empty or failed to load.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(icon: icon, color: theme.colorScheme.primary, size: 72)
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: AppMotion.slow,
                  curve: AppMotion.spring,
                )
                .fadeIn(),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ).animate().fadeIn(duration: AppMotion.medium).slideY(begin: 0.05),
      ),
    );
  }
}

/// Shimmering skeleton list used while loading.
class SkeletonList extends StatelessWidget {
  final int count;
  final double height;

  const SkeletonList({super.key, this.count = 6, this.height = 72});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      itemBuilder: (context, i) =>
          Container(
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 1200.ms,
                delay: (i * 80).ms,
                color: scheme.onSurface.withValues(alpha: 0.06),
              ),
    );
  }
}

/// Frosted-glass container.
class Glass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blur;

  const Glass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.xl)),
    this.blur = 24,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.82),
            borderRadius: borderRadius,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Floating, pill-indicator navigation bar with animated icons.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Glass(
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: AppMotion.slow,
                    curve: Curves.easeOutBack,
                    left: itemWidth * currentIndex + 6,
                    top: 8,
                    bottom: 8,
                    width: itemWidth - 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavButton(
                            item: items[i],
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _NavButton extends StatelessWidget {
  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.88,
      child: Semantics(
        selected: selected,
        button: true,
        label: item.label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.medium,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                key: ValueKey(selected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AppMotion.medium,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
