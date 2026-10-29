import 'package:cloud_functions/cloud_functions.dart';

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

/// Calls the `allocateInvoiceNumber` Cloud Function
/// (firebase/functions/src/invoiceNumbers.ts).
class CloudInvoiceNumberService implements InvoiceNumberService {
  CloudInvoiceNumberService([FirebaseFunctions? functions])
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;

  @override
  Future<String> allocate({
    required String companyId,
    required String invoiceId,
    required String financialYear,
    required String deviceId,
  }) async {
    try {
      final result = await _functions
          .httpsCallable(
            'allocateInvoiceNumber',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
          )
          .call<Map<String, dynamic>>({
            'companyId': companyId,
            'invoiceId': invoiceId,
            'financialYear': financialYear,
            'deviceId': deviceId,
          });
      return result.data['invoiceNumber'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw InvoiceNumberUnavailable(switch (e.code) {
        'unavailable' || 'deadline-exceeded' || 'internal' =>
          'Could not reach the server. Connect to the internet and try again.',
        'permission-denied' =>
          "You don't have permission to finalize invoices for this company.",
        'failed-precondition' => e.message ?? 'This company is not active yet.',
        'resource-exhausted' =>
          e.message ?? 'Too many requests. Wait a little and try again.',
        'not-found' => 'Invoice numbering is not set up on the server yet.',
        _ => e.message ?? 'Could not get an invoice number. Try again.',
      });
    } catch (_) {
      throw const InvoiceNumberUnavailable(
        'Could not reach the server. Connect to the internet and try again.',
      );
    }
  }
}
