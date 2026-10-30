import 'dart:async';
import 'dart:io';

import 'package:jcb_work_management/features/auth/data/auth_repository.dart';
import 'package:jcb_work_management/features/billing/data/invoice_number_service.dart';
import 'package:jcb_work_management/features/company/data/company_remote_source.dart';
import 'package:jcb_work_management/features/company/domain/company.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/license/data/license_service.dart';
import 'package:jcb_work_management/features/license/data/replacement_service.dart';
import 'package:jcb_work_management/features/users/data/company_users_service.dart';
import 'package:jcb_work_management/features/work/data/evidence_services.dart';
import 'package:jcb_work_management/features/work/domain/work_log.dart';

const wrongPassword = 'wrong-pass';

/// In-memory auth. Any password except [wrongPassword] signs in.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedIn}) : _user = signedIn;

  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();

  String? get currentUid => _user?.uid;
  String? lastResetEmail;

  static AppUser userFor(String email) =>
      AppUser(uid: 'uid-$email', email: email);

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (password == wrongPassword) {
      throw const AuthException('Incorrect email or password.');
    }
    _user = userFor(email.trim().toLowerCase());
    _changes.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    lastResetEmail = email.trim();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _changes.add(null);
  }
}

/// In-memory stand-in for the company API. Set [offline] to make calls fail.
class FakeCompanyRemote implements CompanyRemoteSource {
  final memberships = <String, List<CompanyMembership>>{};
  bool offline = false;
  int fetchCount = 0;

  void _check() {
    if (offline) throw Exception('unavailable');
  }

  void setStatus(String uid, String companyId, CompanyStatus status) {
    memberships[uid] = [
      for (final m in memberships[uid] ?? <CompanyMembership>[])
        m.companyId == companyId
            ? membership(
                m.companyId,
                m.company.name,
                status: status,
                role: m.role,
                ownerUid: m.company.ownerUid,
              )
            : m,
    ];
  }

  @override
  Future<List<CompanyMembership>> fetchMemberships(String uid) async {
    fetchCount++;
    _check();
    return List.of(memberships[uid] ?? const []);
  }

  @override
  Future<Company> registerCompany({
    required String companyId,
    required String uid,
    required String email,
    required CompanyProfile profile,
  }) async {
    _check();
    final company = Company(
      id: companyId,
      profile: profile,
      status: CompanyStatus.pending,
      ownerUid: uid,
    );
    memberships
        .putIfAbsent(uid, () => [])
        .add(CompanyMembership(company: company, role: CompanyRole.owner));
    return company;
  }

  @override
  Future<void> updateProfile({
    required String companyId,
    required String uid,
    required CompanyProfile profile,
  }) async {
    _check();
  }
}

CompanyProfile profileNamed(String name) => CompanyProfile(
  name: name,
  contactPerson: 'Ravi Patil',
  phone: '9876543210',
  address: 'Plot 12, MIDC, Pune',
  invoicePrefix: 'JCB',
);

CompanyMembership membership(
  String id,
  String name, {
  CompanyStatus status = CompanyStatus.active,
  CompanyRole role = CompanyRole.owner,
  String ownerUid = 'owner',
}) => CompanyMembership(
  role: role,
  company: Company(
    id: id,
    profile: profileNamed(name),
    status: status,
    ownerUid: ownerUid,
  ),
);

/// Camera stand-in: returns a fake file, or simulates denial/cancel.
class FakePhotoCapture implements PhotoCaptureService {
  bool denied = false;
  bool cancel = false;
  int taken = 0;

  @override
  Future<File?> capture() async {
    if (denied) throw const CameraPermissionDenied();
    if (cancel) return null;
    taken++;
    return File('fake_capture_$taken.jpg');
  }
}

class FakeLocation implements LocationService {
  LocationStatus status = LocationStatus.denied;
  bool settingsOpened = false;

  /// Simulates a phone where location permission hasn't been asked yet.
  bool needsPrompt = false;
  int requests = 0;

  @override
  Future<bool> needsPermissionPrompt() async => needsPrompt;

  @override
  Future<LocationFix> current() async {
    requests++;
    return status == LocationStatus.captured
        ? const LocationFix(
            LocationStatus.captured,
            lat: 18.5912,
            lng: 73.7389,
            accuracy: 12,
          )
        : LocationFix(status);
  }

  @override
  Future<void> openSettings() async => settingsOpened = true;
}

/// In-memory photo store (no file IO inside widget tests).
class FakePhotoStore extends PhotoStore {
  final kept = <String>{};
  final discarded = <String>{};

  @override
  Future<String> keep(
    File source, {
    required String companyId,
    required String name,
  }) async {
    final rel = 'evidence/$companyId/$name.jpg';
    kept.add(rel);
    return rel;
  }

  @override
  Future<File> resolve(String relativePath) async =>
      File('/nonexistent/$relativePath');

  @override
  Future<void> discard(String relativePath) async {
    kept.remove(relativePath);
    discarded.add(relativePath);
  }
}

/// Server numbering stand-in: sequential per company/FY, idempotent per
/// invoice, can simulate being offline.
class FakeInvoiceNumbers implements InvoiceNumberService {
  bool offline = false;
  final issued = <String, String>{};
  final _seq = <String, int>{};
  final deviceIds = <String>{};

  @override
  Future<String> allocate({
    required String companyId,
    required String invoiceId,
    required String financialYear,
    required String deviceId,
  }) async {
    deviceIds.add(deviceId);
    if (offline) {
      throw const InvoiceNumberUnavailable(
        'Could not reach the server. Connect to the internet and try again.',
      );
    }
    return issued[invoiceId] ??= () {
      final key = '$companyId/$financialYear';
      final n = (_seq[key] ?? 0) + 1;
      _seq[key] = n;
      return 'JCB/$financialYear/${n.toString().padLeft(4, '0')}';
    }();
  }
}

const validActivationCode = 'JCBW-GOOD-CODE-2026';

/// License server stand-in. Accepts [validActivationCode]; other codes are
/// refused. Set [deny] to force a refusal reason, [offline] to fail.
class FakeLicenseService implements LicenseService {
  bool offline = false;
  String? deny;
  int validUntil = DateTime.utc(2027, 3, 31).millisecondsSinceEpoch;
  String licenseStatus = 'active';
  String deviceStatus = 'active';
  int activations = 0;
  int validations = 0;

  Map<String, dynamic> _state() => {
    'licenseId': 'lic1',
    'licenseStatus': licenseStatus,
    'deviceStatus': deviceStatus,
    'validUntil': validUntil,
    'maxDevices': 2,
  };

  @override
  Future<Map<String, dynamic>> activate({
    required String companyId,
    required String activationCode,
    required String deviceId,
    required String deviceModel,
  }) async {
    if (offline) throw const LicenseServerUnavailable();
    if (deny != null) throw LicenseDenied(deny!, 'Refused: $deny');
    if (activationCode.replaceAll(' ', '').toUpperCase() !=
        validActivationCode) {
      throw const LicenseDenied(
        'invalid_code',
        'That activation code is not valid for this company.',
      );
    }
    activations++;
    return _state();
  }

  @override
  Future<Map<String, dynamic>> validate({
    required String companyId,
    required String deviceId,
  }) async {
    if (offline) throw const LicenseServerUnavailable();
    validations++;
    return _state();
  }
}

/// Replacement queue stand-in; tests flip [decision] to simulate the admin.
class FakeReplacementService implements ReplacementService {
  final requests = <String, Map<String, String>>{};
  String decision = 'pending';
  String? reviewReason;

  @override
  Future<ReplacementState> request({
    required String companyId,
    required String activationCode,
    required String newDeviceId,
    required String newDeviceModel,
    required String reason,
  }) async {
    if (activationCode.replaceAll(' ', '').toUpperCase() !=
        validActivationCode) {
      throw const LicenseDenied(
        'invalid_code',
        'That activation code is not valid for this company.',
      );
    }
    final id = 'req${requests.length + 1}';
    requests[id] = {'deviceId': newDeviceId, 'reason': reason};
    decision = 'pending';
    return ReplacementState(ReplacementStatus.pending, requestId: id);
  }

  @override
  Future<ReplacementState> status({
    required String companyId,
    required String requestId,
  }) async => ReplacementState(
    ReplacementStatus.parse(decision),
    requestId: requestId,
    reviewReason: reviewReason,
  );
}

/// Company users stand-in mirroring the server's checks.
class FakeCompanyUsersService implements CompanyUsersService {
  FakeCompanyUsersService(List<CompanyMember> initial) : members = [...initial];

  final List<CompanyMember> members;
  final _changes = StreamController<List<CompanyMember>>.broadcast();

  void _emit() => _changes.add(List.of(members));

  @override
  Stream<List<CompanyMember>> watch(String companyId) async* {
    yield List.of(members);
    yield* _changes.stream;
  }

  @override
  Future<void> invite({
    required String companyId,
    required String email,
    required String role,
  }) async {
    if (members.any((m) => m.email == email && m.active)) {
      throw CompanyUsersException('$email is already a member.');
    }
    members.add(
      CompanyMember(uid: 'uid-$email', email: email, role: role, active: true),
    );
    _emit();
  }

  @override
  Future<void> setRole({
    required String companyId,
    required String userId,
    required String role,
  }) async {
    final i = members.indexWhere((m) => m.uid == userId);
    members[i] = CompanyMember(
      uid: userId,
      email: members[i].email,
      role: role,
      active: members[i].active,
    );
    _emit();
  }

  @override
  Future<void> setActive({
    required String companyId,
    required String userId,
    required bool active,
  }) async {
    final i = members.indexWhere((m) => m.uid == userId);
    members[i] = CompanyMember(
      uid: userId,
      email: members[i].email,
      role: members[i].role,
      active: active,
    );
    _emit();
  }
}
