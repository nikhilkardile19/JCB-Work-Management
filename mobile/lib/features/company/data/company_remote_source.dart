import '../../../core/network/api_client.dart';
import '../domain/company.dart';
import '../domain/permissions.dart';

/// Server-side company data. REST implementation below; tests use a fake.
abstract interface class CompanyRemoteSource {
  /// Active memberships of [uid], with their companies. Must fail (not return
  /// an empty list) when the server can't be reached.
  Future<List<CompanyMembership>> fetchMemberships(String uid);

  /// Creates a `pending` company with [uid] as owner, atomically.
  Future<Company> registerCompany({
    required String companyId,
    required String uid,
    required String email,
    required CompanyProfile profile,
  });

  Future<void> updateProfile({
    required String companyId,
    required String uid,
    required CompanyProfile profile,
  });
}

/// `GET /me/memberships`, `POST /companies`, `PATCH /companies/:id`.
class HttpCompanyRemoteSource implements CompanyRemoteSource {
  HttpCompanyRemoteSource(this._api);

  final ApiClient _api;

  @override
  Future<List<CompanyMembership>> fetchMemberships(String uid) async {
    final json = await _api.get('/me/memberships');
    // Never cache one user's companies under another's ID.
    if (_api.currentUserId != uid) {
      throw StateError('The signed-in user changed.');
    }
    final result = <CompanyMembership>[];
    for (final item in (json['items'] as List).cast<Json>()) {
      final role = CompanyRole.parse(item['role'] as String?);
      if (role == null || item['status'] != 'active') continue;
      result.add(
        CompanyMembership(
          company: _toCompany(item['company'] as Json),
          role: role,
        ),
      );
    }
    return result;
  }

  @override
  Future<Company> registerCompany({
    required String companyId,
    required String uid,
    required String email,
    required CompanyProfile profile,
  }) async {
    // Idempotent per ID: a retry after a lost reply returns the same company.
    final json = await _api.post(
      '/companies',
      body: {..._body(profile), 'id': companyId},
    );
    return _toCompany(json);
  }

  @override
  Future<void> updateProfile({
    required String companyId,
    required String uid,
    required CompanyProfile profile,
  }) => _api.patch(apiPath(['companies', companyId]), body: _body(profile));

  /// The contract's `CompanyProfile`; the server sets the rest.
  static Json _body(CompanyProfile p) => {
    'name': p.name,
    'contactPerson': p.contactPerson,
    'phone': p.phone,
    'address': p.address,
    'invoicePrefix': p.invoicePrefix,
    'email': p.email,
    'gstin': p.gstin,
  };

  static Company _toCompany(Json d) => Company(
    id: d['id'] as String,
    profile: CompanyProfile.fromMap(d),
    status: CompanyStatus.parse(d['status'] as String?),
    ownerUid: d['ownerUid'] as String? ?? '',
  );
}
