import 'package:flutter/material.dart';

/// Brand palette. Earth-mover yellow on deep graphite: high contrast for
/// outdoor readability. Feature code must not reference these directly —
/// use `Theme.of(context).colorScheme` or [AppStatusColors].
abstract final class AppPalette {
  static const amber = Color(0xFFF5B400);
  static const amberDeep = Color(0xFF7A5900);
  static const graphite = Color(0xFF1C1E21);
  static const graphiteSoft = Color(0xFF2A2D31);
  static const slate = Color(0xFF455A64);
  static const sand = Color(0xFFFFF8EC);

  static const success = Color(0xFF1E8E4E);
  static const warning = Color(0xFFD9730D);
  static const danger = Color(0xFFC62828);
  static const info = Color(0xFF1565C0);
  static const neutral = Color(0xFF6B7178);
}

/// Spacing scale (4-pt grid).
abstract final class AppSpace {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Horizontal page gutter.
  static const page = lg;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

abstract final class AppSize {
  /// Minimum touch target. Larger than the 48dp guideline: field users often
  /// wear gloves or work in bright sunlight.
  static const tapTarget = 52.0;
  static const iconSm = 18.0;
  static const iconMd = 24.0;
  static const iconLg = 40.0;
  static const iconXl = 64.0;

  /// Max content width so forms stay readable on tablets / landscape.
  static const maxContentWidth = 640.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const curve = Curves.easeOutCubic;

  /// Returns [base], or zero when the platform asks for reduced motion.
  static Duration of(BuildContext context, Duration base) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : base;
}

enum StatusTone { success, warning, danger, info, neutral }

/// Semantic status colors exposed through the theme.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.neutral,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color neutral;

  static AppStatusColors of(BuildContext context) =>
      Theme.of(context).extension<AppStatusColors>()!;

  Color forTone(StatusTone tone) => switch (tone) {
    StatusTone.success => success,
    StatusTone.warning => warning,
    StatusTone.danger => danger,
    StatusTone.info => info,
    StatusTone.neutral => neutral,
  };

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? neutral,
  }) => AppStatusColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    info: info ?? this.info,
    neutral: neutral ?? this.neutral,
  );

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}
