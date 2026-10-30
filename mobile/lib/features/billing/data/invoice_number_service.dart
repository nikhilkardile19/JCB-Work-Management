import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// The server couldn't issue a number (offline, not allowed, not deployed).
class InvoiceNumberUnavailable implements Exception {
  const InvoiceNumberUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Issues official invoice numbers. Numbers come from the server so two
/// phones can never issue the same number (product decisions #7–8).
abstract interface class InvoiceNumberService {
  /// Idempotent per [invoiceId]: retrying returns the same number. The
  /// server refuses phones that aren't activated on an active license
  /// ([deviceId] is this phone's installation ID).
  Future<String> allocate({
    required String companyId,
    required String invoiceId,
    required String financialYear,
    required String deviceId,
  });
}

/// `POST /companies/:companyId/invoice-numbers`, sent as this phone.
class HttpInvoiceNumberService implements InvoiceNumberService {
  HttpInvoiceNumberService(this._api);

  final ApiClient _api;

  static const _unreachable =
      'Could not reach the server. Connect to the internet and try again.';

  @override
  Future<String> allocate({
    required String companyId,
    required String invoiceId,
    required String financialYear,
    required String deviceId,
  }) async {
    try {
      final json = await _api.post(
        apiPath(['companies', companyId, 'invoice-numbers']),
        body: {'invoiceId': invoiceId, 'financialYear': financialYear},
        headers: {'X-Device-Id': deviceId},
      );
      return json['invoiceNumber'] as String;
    } catch (e) {
      throw InvoiceNumberUnavailable(messageFor(e));
    }
  }

  /// User-facing message for a failed allocation.
  static String messageFor(Object error) => switch (error) {
    ApiUnavailable(isRateLimited: true) => error.message,
    ApiException(code: 'permission_denied') =>
      "You don't have permission to finalize invoices for this company.",
    ApiException(code: 'not_found') =>
      'Invoice numbering is not set up on the server yet.',
    ApiException(:final message) => message,
    _ => _unreachable,
  };
}
