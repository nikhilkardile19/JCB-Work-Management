/// Company profile validation. Keep in sync with the server's company
/// profile rules (`docs/migration/api-contract.md`).
abstract final class CompanyValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _gstin = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
  );
  static final _prefix = RegExp(r'^[A-Z0-9-]{1,10}$');

  static String? name(String? v) {
    final t = v?.trim() ?? '';
    if (t.length < 2) return 'Enter the company name';
    if (t.length > 120) return 'Keep the name under 120 characters';
    return null;
  }

  static String? contactPerson(String? v) =>
      (v?.trim() ?? '').isEmpty ? 'Enter a contact person' : null;

  /// Accepts Indian mobile/landline numbers with optional +91, spaces, dashes.
  static String? phone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (digits.isEmpty) return 'Enter a phone number';
    if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(digits)) {
      return 'Enter a valid phone number, e.g. 98765 43210';
    }
    return null;
  }

  static String? optionalEmail(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    return _email.hasMatch(t) ? null : 'Enter a valid email address';
  }

  static String? address(String? v) =>
      (v?.trim() ?? '').length < 5 ? 'Enter the company address' : null;

  static String? optionalGstin(String? v) {
    final t = v?.trim().toUpperCase() ?? '';
    if (t.isEmpty) return null;
    return _gstin.hasMatch(t)
        ? null
        : 'GSTIN must be 15 characters, e.g. 27ABCDE1234F1Z5';
  }

  static String? invoicePrefix(String? v) {
    final t = v?.trim().toUpperCase() ?? '';
    if (t.isEmpty) return 'Enter an invoice prefix, e.g. JCB';
    return _prefix.hasMatch(t)
        ? null
        : 'Use up to 10 letters, numbers or dashes';
  }
}
