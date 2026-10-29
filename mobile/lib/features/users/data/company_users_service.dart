import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CompanyMember {
  const CompanyMember({
    required this.uid,
    required this.email,
    required this.role,
    required this.active,
  });

  final String uid;
  final String email;

  /// owner, admin, manager, operator or accounts.
  final String role;
  final bool active;
}

class CompanyUsersException implements Exception {
  const CompanyUsersException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Company user administration (owner/admin). Reads members directly;
/// every change goes through a Cloud Function that re-checks the caller.
abstract interface class CompanyUsersService {
  Stream<List<CompanyMember>> watch(String companyId);

  Future<void> invite({
    required String companyId,
    required String email,
    required String role,
  });

  Future<void> setRole({
    required String companyId,
    required String userId,
    required String role,
  });

  Future<void> setActive({
    required String companyId,
    required String userId,
    required bool active,
  });
}

class CloudCompanyUsersService implements CompanyUsersService {
  CloudCompanyUsersService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<List<CompanyMember>> watch(String companyId) => _db
      .collection('companies/$companyId/companyUsers')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            CompanyMember(
              uid: d.id,
              email: d.data()['email'] as String? ?? '',
              role: d.data()['role'] as String? ?? 'operator',
              active: d.data()['status'] == 'active',
            ),
        ]..sort((a, b) => a.email.compareTo(b.email)),
      );

  Future<void> _call(String name, Map<String, Object?> data) async {
    try {
      await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
    } on FirebaseFunctionsException catch (e) {
      throw CompanyUsersException(switch (e.code) {
        'unavailable' || 'deadline-exceeded' || 'internal' =>
          'Could not reach the server. Connect to the internet and try again.',
        _ => e.message ?? 'The change was refused.',
      });
    } catch (_) {
      throw const CompanyUsersException(
        'Could not reach the server. Connect to the internet and try again.',
      );
    }
  }

  @override
  Future<void> invite({
    required String companyId,
    required String email,
    required String role,
  }) => _call('inviteCompanyUser', {
    'companyId': companyId,
    'email': email,
    'role': role,
  });

  @override
  Future<void> setRole({
    required String companyId,
    required String userId,
    required String role,
  }) => _call('setCompanyUserRole', {
    'companyId': companyId,
    'userId': userId,
    'role': role,
  });

  @override
  Future<void> setActive({
    required String companyId,
    required String userId,
    required bool active,
  }) => _call('setCompanyUserStatus', {
    'companyId': companyId,
    'userId': userId,
    'status': active ? 'active' : 'disabled',
  });
}
