import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/company.dart';
import '../domain/permissions.dart';

/// Server-side company data. Firestore implementation below; tests use a fake.
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

class FirestoreCompanyRemoteSource implements CompanyRemoteSource {
  FirestoreCompanyRemoteSource(this._db);

  final FirebaseFirestore _db;

  static const _server = GetOptions(source: Source.server);

  DocumentReference<Map<String, dynamic>> _company(String id) =>
      _db.collection('companies').doc(id);

  @override
  Future<List<CompanyMembership>> fetchMemberships(String uid) async {
    final members = await _db
        .collectionGroup('companyUsers')
        .where('uid', isEqualTo: uid)
        .get(_server);
    final result = <CompanyMembership>[];
    for (final m in members.docs) {
      final role = CompanyRole.parse(m.data()['role'] as String?);
      if (role == null || m.data()['status'] != 'active') continue;
      final companyId = m.reference.parent.parent!.id;
      final snap = await _company(companyId).get(_server);
      final data = snap.data();
      if (data == null) continue;
      result.add(
        CompanyMembership(company: _toCompany(snap.id, data), role: role),
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
    final batch = _db.batch()
      ..set(_company(companyId), {
        ...profile.toMap(),
        'id': companyId,
        'currency': profile.currency,
        'status': CompanyStatus.pending.name,
        'ownerUid': uid,
        'createdBy': uid,
        'updatedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      })
      ..set(_company(companyId).collection('companyUsers').doc(uid), {
        'uid': uid,
        'companyId': companyId,
        'email': email,
        'role': CompanyRole.owner.name,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
    return Company(
      id: companyId,
      profile: profile,
      status: CompanyStatus.pending,
      ownerUid: uid,
    );
  }

  @override
  Future<void> updateProfile({
    required String companyId,
    required String uid,
    required CompanyProfile profile,
  }) => _company(companyId).update({
    ...profile.toMap(),
    'updatedBy': uid,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  static Company _toCompany(String id, Map<String, dynamic> d) => Company(
    id: id,
    profile: CompanyProfile.fromMap(d),
    status: CompanyStatus.parse(d['status'] as String?),
    ownerUid: d['ownerUid'] as String? ?? '',
  );
}
