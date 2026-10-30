/// The REST API answered and refused the request. Built from the error
/// envelope `{error: {code, message, reason?, retryAfterMs?}}`.
class ApiException implements Exception {
  const ApiException(
    this.statusCode,
    this.code,
    this.reason,
    this.message,
    this.body,
  );

  final int statusCode;

  /// Stable error code, e.g. `invalid_argument` or `failed_precondition`.
  final String code;

  /// Machine code the app branches on (license denials, sync refusals,
  /// auth failures); null when the server gave none.
  final String? reason;

  /// User-facing text from the server.
  final String message;

  /// The whole decoded body; the sync conflict adds fields to the envelope.
  final Map<String, dynamic> body;

  @override
  String toString() => message;
}

/// The server can't be reached or can't serve the request right now: no
/// connection, a timeout, a 5xx, rate limiting, or a reply that didn't come
/// from the API (e.g. a captive portal). Trying again later may succeed.
class ApiUnavailable implements Exception {
  const ApiUnavailable(this.message, {this.statusCode, this.retryAfter});

  final String message;

  /// Null when no HTTP response arrived (offline, timeout).
  final int? statusCode;

  /// The server's hint for rate-limited requests.
  final Duration? retryAfter;

  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => message;
}
