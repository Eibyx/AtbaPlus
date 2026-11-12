import 'dart:ui';

import 'package:atba/theme/app_theme.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';

/// Card used for every library row (torrents, web downloads, usenet).
///
/// Animates selection (tint + border + check badge), press (scale) and status
/// icon changes.
class LibraryItemCard extends StatelessWidget {
  final String title;
  final bool censored;
  final bool selected;
  final bool selecting;
  final Widget leading;
  final Widget? subtitle;
  final String? trailing;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LibraryItemCard({
    super.key,
    required this.title,
    required this.censored,
    required this.selected,
    required this.selecting,
    required this.leading,
    required this.onTap,
    required this.onLongPress,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SurfaceCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      highlighted: selected,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.medium,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: selecting
                ? Container(
                    key: ValueKey('sel$selected'),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary
                          : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.circle_outlined,
                      size: 20,
                      color: selected
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                  )
                : KeyedSubtree(key: const ValueKey('lead'), child: leading),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ImageFiltered(
                        enabled: censored,
                        imageFilter: ImageFilter.blur(
                          sigmaX: 6,
                          sigmaY: 6,
                          tileMode: TileMode.decal,
                        ),
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        trailing!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodySmall,
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Status icon in a tinted square; spins while loading.
class StatusBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool loading;

  const StatusBadge({
    super.key,
    required this.icon,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(13),
        ),
        child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
      );
    }
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: child,
      ),
      child: IconBadge(key: ValueKey(icon), icon: icon, color: color, size: 40),
    );
  }
}
