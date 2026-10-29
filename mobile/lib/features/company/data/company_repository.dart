import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../domain/company.dart';
import '../domain/permissions.dart';
import 'company_remote_source.dart';

/// Company memberships: read from the local cache (works offline), refreshed
/// from the server when reachable.
class CompanyRepository {
  CompanyRepository(this._db, this._remote, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final CompanyRemoteSource _remote;
  final DateTime Function() _clock;

  static String _selectedKey(String uid) => 'selected_company_id:$uid';

  Stream<List<CompanyMembership>> watchMemberships(String uid) =>
      (_db.select(_db.cachedCompanies)
            ..where((t) => t.userId.equals(uid))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch()
          .map((rows) => rows.map(_fromRow).nonNulls.toList());

  /// Replaces the cache for [uid] with the server's view. Throws when the
  /// server can't be reached; the existing cache is left untouched.
  Future<void> refresh(String uid) async {
    final memberships = await _remote.fetchMemberships(uid);
    await _db.transaction(() async {
      await (_db.delete(
        _db.cachedCompanies,
      )..where((t) => t.userId.equals(uid))).go();
      for (final m in memberships) {
        await _upsert(uid, m);
      }
    });
  }

  Future<CompanyMembership> register({
    required String uid,
    required String email,
    required CompanyProfile profile,
  }) async {
    final company = await _remote.registerCompany(
      companyId: const Uuid().v4(),
      uid: uid,
      email: email,
      profile: profile,
    );
    final membership = CompanyMembership(
      company: company,
      role: CompanyRole.owner,
    );
    await _upsert(uid, membership);
    await selectCompany(uid, company.id);
    return membership;
  }

  Future<void> updateProfile({
    required String uid,
    required CompanyMembership membership,
    required CompanyProfile profile,
  }) async {
    await _remote.updateProfile(
      companyId: membership.companyId,
      uid: uid,
      profile: profile,
    );
    final c = membership.company;
    await _upsert(
      uid,
      CompanyMembership(
        company: Company(
          id: c.id,
          profile: profile,
          status: c.status,
          ownerUid: c.ownerUid,
        ),
        role: membership.role,
      ),
    );
  }

  Stream<String?> watchSelectedCompanyId(String uid) =>
      _db.watchSetting(_selectedKey(uid));

  Future<void> selectCompany(String uid, String companyId) =>
      _db.writeSetting(_selectedKey(uid), companyId);

  Future<void> clearSelection(String uid) =>
      _db.deleteSetting(_selectedKey(uid));

  Future<void> _upsert(String uid, CompanyMembership m) {
    final p = m.company.profile;
    return _db
        .into(_db.cachedCompanies)
        .insertOnConflictUpdate(
          CachedCompaniesCompanion.insert(
            userId: uid,
            companyId: m.companyId,
            role: m.role.name,
            status: m.company.status.name,
            ownerUid: m.company.ownerUid,
            name: p.name,
            contactPerson: p.contactPerson,
            phone: p.phone,
            email: Value(p.email),
            address: p.address,
            gstin: Value(p.gstin),
            invoicePrefix: p.invoicePrefix,
            currency: p.currency,
            cachedAt: _clock().toUtc().millisecondsSinceEpoch,
          ),
        );
  }

  static CompanyMembership? _fromRow(CachedCompany r) {
    final role = CompanyRole.parse(r.role);
    if (role == null) return null;
    return CompanyMembership(
      role: role,
      company: Company(
        id: r.companyId,
        status: CompanyStatus.parse(r.status),
        ownerUid: r.ownerUid,
        profile: CompanyProfile(
          name: r.name,
          contactPerson: r.contactPerson,
          phone: r.phone,
          email: r.email,
          address: r.address,
          gstin: r.gstin,
          invoicePrefix: r.invoicePrefix,
          currency: r.currency,
        ),
      ),
    );
  }
}
