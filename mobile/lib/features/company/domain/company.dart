import 'permissions.dart';

enum CompanyStatus {
  /// Registered by the owner; waiting for developer-admin approval.
  pending,
  active,
  suspended;

  static CompanyStatus parse(String? v) => CompanyStatus.values.firstWhere(
    (s) => s.name == v,
    orElse: () => CompanyStatus.pending,
  );
}

/// Editable company profile fields (sprint doc §4.2).
class CompanyProfile {
  const CompanyProfile({
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.address,
    required this.invoicePrefix,
    this.email,
    this.gstin,
    this.currency = 'INR',
  });

  final String name;
  final String contactPerson;
  final String phone;
  final String address;
  final String invoicePrefix;
  final String? email;
  final String? gstin;
  final String currency;

  Map<String, Object?> toMap() => {
    'name': name,
    // Lower-cased copy for the admin portal's search (checked by rules).
    'nameLower': name.toLowerCase(),
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'address': address,
    'gstin': gstin,
    'invoicePrefix': invoicePrefix,
  };

  static CompanyProfile fromMap(Map<String, Object?> m) => CompanyProfile(
    name: m['name'] as String? ?? '',
    contactPerson: m['contactPerson'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    address: m['address'] as String? ?? '',
    invoicePrefix: m['invoicePrefix'] as String? ?? '',
    email: m['email'] as String?,
    gstin: m['gstin'] as String?,
    currency: m['currency'] as String? ?? 'INR',
  );
}

class Company {
  const Company({
    required this.id,
    required this.profile,
    required this.status,
    required this.ownerUid,
  });

  /// Immutable tenant ID.
  final String id;
  final CompanyProfile profile;
  final CompanyStatus status;
  final String ownerUid;

  String get name => profile.name;
}

/// A signed-in user's membership in one company.
class CompanyMembership {
  const CompanyMembership({required this.company, required this.role});

  final Company company;
  final CompanyRole role;

  String get companyId => company.id;

  bool can(Permission p) => role.can(p);
}
