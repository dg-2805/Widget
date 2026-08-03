import 'package:flutter/material.dart';

import '../twilight/twilight_state.dart';

class AppTheme {
  static ThemeData forTwilight(TwilightState state) {
    final brightness = state.phase == TwilightPhase.night ? Brightness.dark : Brightness.light;
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: state.accentColor,
      onPrimary: isLight ? Colors.white : const Color(0xFF1D1720),
      secondary: Color.lerp(state.accentColor, Colors.white, 0.72)!,
      onSecondary: state.onSurfaceColor,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: state.phase == TwilightPhase.night
          ? const Color(0xEE3A659E)
          : state.surfaceColor,
      onSurface: state.onSurfaceColor,
    );
    final textTheme = ThemeData(brightness: brightness).textTheme
        .apply(fontFamily: 'BubbleBobble')
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: state.backgroundBottom,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(26)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFF3F0EC) : const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const StadiumBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
        ),
      ),
      dividerColor: isLight ? const Color(0xFFE8E2DD) : const Color(0xFF303030),
    );
  }

  static bool isDayTime([DateTime? now]) {
    final phase = TwilightState.phaseFor(now ?? DateTime.now());
    return phase == TwilightPhase.morning || phase == TwilightPhase.day;
  }
}
