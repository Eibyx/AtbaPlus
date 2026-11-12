import 'package:flutter/material.dart';

/// A selectable colour theme. Light and dark mode each pick one preset.
class ThemePreset {
  final String id;
  final String name;

  /// Accent seed. Null = use the Material You / custom colour instead.
  final Color? seed;

  /// Optional background/surface overrides (light, dark).
  final Color? lightBackground;
  final Color? lightSurface;
  final Color? darkBackground;
  final Color? darkSurface;
  final Color? darkSurfaceHigh;

  /// Preview colours for the picker swatch.
  final List<Color> preview;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.preview,
    this.seed,
    this.lightBackground,
    this.lightSurface,
    this.darkBackground,
    this.darkSurface,
    this.darkSurfaceHigh,
  });

  bool get usesDynamicColor => id == 'dynamic';
  bool get usesCustomColor => id == 'custom';
}

class ThemePresets {
  static const dynamic_ = ThemePreset(
    id: 'dynamic',
    name: 'Dinámico',
    preview: [Color(0xFF6750A4), Color(0xFF7D5260), Color(0xFF625B71)],
  );

  static const custom = ThemePreset(
    id: 'custom',
    name: 'Personalizado',
    preview: [Color(0xFF9E9E9E), Color(0xFF616161), Color(0xFFBDBDBD)],
  );

  static const all = <ThemePreset>[
    dynamic_,
    ThemePreset(
      id: 'gold',
      name: 'Gold',
      seed: Color(0xFFD4A72C),
      lightBackground: Color(0xFFFAF6EC),
      lightSurface: Color(0xFFFFFDF7),
      darkBackground: Color(0xFF0D0B07),
      darkSurface: Color(0xFF17140D),
      darkSurfaceHigh: Color(0xFF221D12),
      preview: [Color(0xFFD4A72C), Color(0xFFF2D27A), Color(0xFF17140D)],
    ),
    ThemePreset(
      id: 'torbox',
      name: 'TorBox',
      seed: Color(0xFF00C853),
      preview: [Color(0xFF00C853), Color(0xFF69F0AE), Color(0xFF0F1A13)],
    ),
    ThemePreset(
      id: 'ocean',
      name: 'Océano',
      seed: Color(0xFF3B82F6),
      darkBackground: Color(0xFF070B14),
      darkSurface: Color(0xFF0F1626),
      darkSurfaceHigh: Color(0xFF172036),
      preview: [Color(0xFF3B82F6), Color(0xFF93C5FD), Color(0xFF0F1626)],
    ),
    ThemePreset(
      id: 'violet',
      name: 'Violeta',
      seed: Color(0xFF8B5CF6),
      darkBackground: Color(0xFF0B0812),
      darkSurface: Color(0xFF151024),
      darkSurfaceHigh: Color(0xFF1F1833),
      preview: [Color(0xFF8B5CF6), Color(0xFFC4B5FD), Color(0xFF151024)],
    ),
    ThemePreset(
      id: 'rose',
      name: 'Rosa',
      seed: Color(0xFFF43F5E),
      lightBackground: Color(0xFFFFF5F6),
      darkBackground: Color(0xFF110709),
      darkSurface: Color(0xFF1D0E12),
      darkSurfaceHigh: Color(0xFF2A151B),
      preview: [Color(0xFFF43F5E), Color(0xFFFDA4AF), Color(0xFF1D0E12)],
    ),
    ThemePreset(
      id: 'sepia',
      name: 'Sepia',
      seed: Color(0xFF9C6B3C),
      lightBackground: Color(0xFFF6EFE2),
      lightSurface: Color(0xFFFDF8EE),
      darkBackground: Color(0xFF14100B),
      darkSurface: Color(0xFF1E1912),
      darkSurfaceHigh: Color(0xFF2A231A),
      preview: [Color(0xFF9C6B3C), Color(0xFFF6EFE2), Color(0xFF1E1912)],
    ),
    ThemePreset(
      id: 'graphite',
      name: 'Grafito',
      seed: Color(0xFF64748B),
      preview: [Color(0xFF64748B), Color(0xFFCBD5E1), Color(0xFF1E2229)],
    ),
    ThemePreset(
      id: 'amoled',
      name: 'AMOLED',
      seed: Color(0xFF60A5FA),
      lightBackground: Color(0xFFFFFFFF),
      lightSurface: Color(0xFFF4F4F5),
      darkBackground: Color(0xFF000000),
      darkSurface: Color(0xFF0A0A0A),
      darkSurfaceHigh: Color(0xFF161616),
      preview: [Color(0xFF000000), Color(0xFF60A5FA), Color(0xFF161616)],
    ),
    custom,
  ];

  static ThemePreset byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => dynamic_);
}
