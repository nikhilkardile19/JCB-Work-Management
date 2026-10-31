enum AppEnv { dev, staging, prod }

/// A build setting is missing or invalid; the app can't start.
class ConfigError implements Exception {
  const ConfigError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Build-time configuration. Select with `--dart-define=APP_ENV=dev|staging|prod`.
abstract final class AppConfig {
  static const appName = 'JCB Works';

  /// Shown in About and support details. Keep in step with `version:` in
  /// pubspec.yaml.
  static const version = '1.0.0';

  static const _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static AppEnv get env => AppEnv.values.firstWhere(
    (e) => e.name == _envName,
    orElse: () => AppEnv.dev,
  );

  static bool get isDev => env == AppEnv.dev;

  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// A server on the developer's machine, as the Android emulator sees it.
  static const devApiBaseUrl = 'http://10.0.2.2:3000/api/v1';

  /// REST API root, without a trailing slash. Select with
  /// `--dart-define=API_BASE_URL=https://…/api/v1`; only dev builds have a
  /// default ([devApiBaseUrl]). Staging and prod must pass an https address.
  /// Throws [ConfigError] otherwise.
  static String get apiBaseUrl {
    final value = _apiBaseUrl.trim().isNotEmpty
        ? _apiBaseUrl.trim()
        : (isDev ? devApiBaseUrl : '');
    if (value.isEmpty) {
      throw ConfigError(
        'This ${env.name} build has no server address. Build it with '
        '--dart-define=API_BASE_URL=https://<host>/api/v1.',
      );
    }
    final uri = Uri.tryParse(value);
    final ok =
        uri != null &&
        uri.host.isNotEmpty &&
        (uri.isScheme('https') || (isDev && uri.isScheme('http')));
    if (!ok) {
      throw ConfigError(
        'API_BASE_URL "$value" is not a valid '
        '${isDev ? 'http(s)' : 'https'} address.',
      );
    }
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

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

  /// Minimum length of a new password (sign-up). Matches the server's
  /// `MIN_PASSWORD_LENGTH`; sign-in keeps [minPasswordLength] for older
  /// accounts.
  static const minNewPasswordLength = 8;
}
