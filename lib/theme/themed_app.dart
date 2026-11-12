import 'package:atba/config/constants.dart';
import 'package:atba/models/widgets/multi_value_change_observer.dart';
import 'package:atba/theme/app_theme.dart';
import 'package:atba/theme/theme_presets.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

/// The app's single [MaterialApp]. Rebuilds whenever an appearance setting
/// changes (theme mode, light/dark presets, custom colour, font).
///
/// There must be only one MaterialApp: a nested one gets its own Navigator,
/// which made the system back gesture close the app instead of popping pages.
class ThemedApp extends StatelessWidget {
  final Widget home;

  const ThemedApp({super.key, required this.home});

  static const _fallbackSeed = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    // Users who had enabled the old "custom colour" switch keep their colour.
    final legacyCustom =
        Settings.getValue<bool>(Constants.useCustomColorTheme) ?? false;
    final defaultPreset = legacyCustom ? 'custom' : 'dynamic';

    return MultiValueChangeObserver(
      cacheKeysWithDefaultValues: {
        Constants.useTorboxFontFamily: false,
        Constants.theme: 'system',
        Constants.colorTheme: ConversionUtils.stringFromColor(_fallbackSeed),
        Constants.lightThemePreset: defaultPreset,
        Constants.darkThemePreset: defaultPreset,
      },
      builder: (context, values) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final customColor = ConversionUtils.colorFromString(
              values[Constants.colorTheme],
            );
            final lightPreset = ThemePresets.byId(
              values[Constants.lightThemePreset],
            );
            final darkPreset = ThemePresets.byId(
              values[Constants.darkThemePreset],
            );

            ColorScheme schemeFor(ThemePreset p, Brightness b) {
              if (p.usesDynamicColor) {
                final dyn = b == Brightness.light ? lightDynamic : darkDynamic;
                if (dyn != null) return dyn;
                return ColorScheme.fromSeed(
                  seedColor: _fallbackSeed,
                  brightness: b,
                );
              }
              return ColorScheme.fromSeed(
                seedColor: p.usesCustomColor ? customColor : p.seed!,
                brightness: b,
              );
            }

            final fontFamily = values[Constants.useTorboxFontFamily]
                ? 'torbox-dotted-all'
                : null; // null = the device's system font
            final modeIndex = [
              'system',
              'light',
              'dark',
            ].indexOf(values[Constants.theme]);

            return MaterialApp(
              title: 'ATBA+',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(
                seedScheme: schemeFor(lightPreset, Brightness.light),
                brightness: Brightness.light,
                fontFamily: fontFamily,
                preset: lightPreset,
              ),
              darkTheme: AppTheme.build(
                seedScheme: schemeFor(darkPreset, Brightness.dark),
                brightness: Brightness.dark,
                fontFamily: fontFamily,
                preset: darkPreset,
              ),
              themeMode: ThemeMode.values[modeIndex < 0 ? 0 : modeIndex],
              home: home,
            );
          },
        );
      },
    );
  }
}
