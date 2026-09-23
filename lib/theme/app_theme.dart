import 'package:flutter/material.dart';

/// Design-Tokens von MGD-DevOS: ruhiges, flaches Developer-Tool-Design
/// auf Slate-Neutraltönen mit dem Markenrot von Michael Gahn DESIGN als Akzent.
abstract final class Brand {
  static const red = Color(0xFFCD1616);
}

abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class Radii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);

  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : d;
}

/// Zusätzliche semantische Farben, die [ColorScheme] nicht abdeckt.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.sidebar,
    required this.card,
    required this.border,
    required this.muted,
    required this.success,
    required this.warning,
    required this.neutral,
  });

  final Color canvas;
  final Color sidebar;
  final Color card;
  final Color border;
  final Color muted;
  final Color success;
  final Color warning;
  final Color neutral;

  static const light = AppColors(
    canvas: Color(0xFFF6F7F9),
    sidebar: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE3E6EB),
    muted: Color(0xFF526071),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    neutral: Color(0xFF64748B),
  );

  static const dark = AppColors(
    canvas: Color(0xFF0F141C),
    sidebar: Color(0xFF131A24),
    card: Color(0xFF19212D),
    border: Color(0xFF2A3444),
    muted: Color(0xFF9AA6B8),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    neutral: Color(0xFF94A3B8),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      canvas: l(canvas, other.canvas),
      sidebar: l(sidebar, other.sidebar),
      card: l(card, other.card),
      border: l(border, other.border),
      muted: l(muted, other.muted),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      neutral: l(neutral, other.neutral),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// Akzent für Text und Icons: im Dunkelmodus aufgehellt, damit Text
  /// mindestens 4,5:1 Kontrast erreicht. Flächen nutzen weiter `primary`.
  Color get accentText => accentTextFor(Theme.of(this).colorScheme.primary, Theme.of(this).brightness);
}

Color accentTextFor(Color accent, Brightness b) =>
    b == Brightness.dark ? Color.lerp(accent, Colors.white, 0.42)! : accent;

ThemeData buildTheme(Brightness brightness, Color accent) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? AppColors.dark : AppColors.light;
  final fg = isDark ? const Color(0xFFF1F4F8) : const Color(0xFF0F172A);
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: brightness,
  ).copyWith(
    primary: accent,
    onPrimary: Colors.white,
    surface: c.card,
    onSurface: fg,
    onSurfaceVariant: c.muted,
    outline: c.border,
    outlineVariant: c.border,
    surfaceContainerHighest: isDark ? const Color(0xFF222C3A) : const Color(0xFFEEF1F5),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: c.canvas,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
  );
  final text = base.textTheme.apply(bodyColor: fg, displayColor: fg);

  return base.copyWith(
    textTheme: text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: text.bodySmall?.copyWith(color: c.muted),
    ),
    dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
    cardTheme: CardThemeData(
      color: c.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: c.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        foregroundColor: fg,
        side: BorderSide(color: c.border),
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF141B25) : Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: accent, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.card,
      selectedColor: accent.withValues(alpha: isDark ? 0.22 : 0.12),
      checkmarkColor: accentTextFor(accent, brightness),
      side: BorderSide(color: c.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: fg),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent.withValues(alpha: isDark ? 0.22 : 0.12) : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accentTextFor(accent, brightness) : fg,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: c.border)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3444) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter'),
    ),
  );
}
