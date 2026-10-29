enum AppEnv { dev, staging, prod }

/// Build-time configuration. Select with `--dart-define=APP_ENV=dev|staging|prod`.
abstract final class AppConfig {
  static const appName = 'JCB Works';

  static const _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static AppEnv get env => AppEnv.values.firstWhere(
    (e) => e.name == _envName,
    orElse: () => AppEnv.dev,
  );

  static bool get isDev => env == AppEnv.dev;

  /// Offline license grace period. PROPOSED — docs/product-decisions.md #5.
  static const offlineGraceDays = 7;

  /// How often the license is re-checked with the server when online.
  static const licenseRevalidateAfter = Duration(hours: 24);

  /// Show a renewal warning this many days before the license ends.
  static const licenseExpiryWarningDays = 14;

  /// Work logs longer than this (hundredths of an hour) need confirmation.
  /// PROPOSED — configurable by the product owner (sprint doc §4.8).
  static const highDailyHours = 1200;

  /// Minimum password length accepted by the login form.
  static const minPasswordLength = 6;
}
