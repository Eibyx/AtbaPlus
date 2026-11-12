import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shared radii used across the app so every surface feels related.
class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
}

/// Shared motion tokens.
class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// Builds the app's modern (non-"Material looking") theme.
///
/// The accent colour still comes from the user's dynamic/custom colour, but
/// surfaces are neutral, flat and softly bordered, components are rounded and
/// ripples are replaced by subtle highlights + scale animations.
class AppTheme {
  /// Returns the font family that maps to the device's system UI font.
  ///
  /// Flutter ships Roboto as the Android default, which ignores fonts set by
  /// the OEM (One UI, HyperOS, ColorOS…). Asking Skia/Impeller for the
  /// `sans-serif` family resolves through the system's `fonts.xml`, i.e. the
  /// font the rest of the phone uses. Every other platform already defaults
  /// to its system font (SF Pro, Segoe UI, system-ui…), so we leave it alone.
  static String? get systemFontFamily {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return 'sans-serif';
    return null;
  }

  static ThemeData build({
    required ColorScheme seedScheme,
    required Brightness brightness,
    String? fontFamily,
  }) {
    final isDark = brightness == Brightness.dark;
    final accent = seedScheme.primary;

    // Neutral, slightly tinted surfaces.
    final background = isDark
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.02),
            const Color(0xFF0B0C10),
          )
        : Color.alphaBlend(
            accent.withValues(alpha: 0.015),
            const Color(0xFFF5F6F8),
          );
    final surface = isDark
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.03),
            const Color(0xFF15161C),
          )
        : Colors.white;
    final surfaceHigh = isDark
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.04),
            const Color(0xFF1D1F27),
          )
        : const Color(0xFFEEF0F3);
    final outline = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);
    final onSurface = isDark
        ? const Color(0xFFF2F3F5)
        : const Color(0xFF14151A);
    final onSurfaceVariant = isDark
        ? const Color(0xFF9A9CA8)
        : const Color(0xFF61646E);

    final scheme = seedScheme.copyWith(
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHigh,
      surfaceTint: Colors.transparent,
      outlineVariant: outline,
    );

    final family = fontFamily ?? systemFontFamily;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: family,
    );
    // Merge in the type geometry (sizes/weights) now, so component styles
    // derived from it below (app bar titles, snackbars, chips…) have sizes.
    final text = Typography.englishLike2021
        .merge(base.textTheme)
        .apply(
          fontFamily: family,
          bodyColor: onSurface,
          displayColor: onSurface,
        );

    final roundedMd = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: accent.withValues(alpha: isDark ? 0.10 : 0.07),
      hoverColor: accent.withValues(alpha: 0.05),
      focusColor: accent.withValues(alpha: 0.12),
      dividerColor: outline,
      visualDensity: VisualDensity.standard,
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ModernPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ModernPageTransitionsBuilder(),
          TargetPlatform.linux: ModernPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ModernPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: outline),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        shape: roundedMd,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        labelColor: accent,
        unselectedLabelColor: onSurfaceVariant,
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: text.labelLarge,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        tabAlignment: TabAlignment.fill,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: roundedMd,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 50),
          backgroundColor: accent,
          foregroundColor: scheme.onPrimary,
          shape: roundedMd,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: roundedMd,
          side: BorderSide(color: outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: roundedMd),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: accent,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      // Filled fields with the label floating *inside* the field. An
      // OutlineInputBorder would cut the border and park the floating label
      // on top of the line, which looks broken on multi-line inputs.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        alignLabelWithHint: true,
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.error)
                ? scheme.error
                : states.contains(WidgetState.focused)
                ? accent
                : onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        hintStyle: TextStyle(color: onSurfaceVariant.withValues(alpha: 0.7)),
        contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        border: _fieldBorder(Colors.transparent, 0),
        enabledBorder: _fieldBorder(Colors.transparent, 0),
        disabledBorder: _fieldBorder(Colors.transparent, 0),
        focusedBorder: _fieldBorder(accent, 2),
        errorBorder: _fieldBorder(scheme.error, 1.5),
        focusedErrorBorder: _fieldBorder(scheme.error, 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        selectedColor: accent.withValues(alpha: isDark ? 0.22 : 0.15),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        labelStyle: text.labelMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF262833)
            : const Color(0xFF1C1D22),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: accent,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: outline),
        ),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: onSurfaceVariant.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: outline),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaceHigh),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: outline),
            ),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: accent.withValues(alpha: 0.14),
        linearMinHeight: 5,
        borderRadius: BorderRadius.circular(99),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.onPrimary
              : onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : surfaceHigh,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: accent.withValues(alpha: 0.18),
      ),
    );
  }
}

/// Rounded filled-field border. Uses [UnderlineInputBorder] (which fills the
/// whole rounded rect) so the floating label stays inside the field.
InputBorder _fieldBorder(Color color, double width) => UnderlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.md),
  borderSide: width == 0
      ? BorderSide.none
      : BorderSide(color: color, width: width),
);

/// Fade + gentle slide/scale transition used for pushed routes.
class ModernPageTransitionsBuilder extends PageTransitionsBuilder {
  const ModernPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(exit),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.96).animate(exit),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}
