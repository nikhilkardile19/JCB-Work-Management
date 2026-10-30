import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/billing/data/invoice_number_service.dart';
import 'package:jcb_work_management/features/company/data/company_remote_source.dart';
import 'package:jcb_work_management/features/company/domain/company.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';
import 'package:jcb_work_management/features/license/data/license_service.dart';
import 'package:jcb_work_management/features/license/data/replacement_service.dart';
import 'package:jcb_work_management/features/users/data/company_users_service.dart';

import '../helpers/fake_http.dart';
import '../helpers/fakes.dart' show profileNamed;

const _company = {
  'id': 'co1',
  'name': 'Sai Earthmovers',
  'contactPerson': 'Ravi Patil',
  'phone': '9876543210',
  'address': 'Plot 12, MIDC, Pune',
  'invoicePrefix': 'JCB',
  'email': null,
  'gstin': null,
  'currency': 'INR',
  'status': 'active',
  'ownerUid': 'u1',
  'createdAt': 1,
};

void main() {
  late ApiHarness h;

  setUp(() async {
    h = ApiHarness();
    await h.signIn();
  });

  group('license', () {
    late HttpLicenseService service;
    setUp(() => service = HttpLicenseService(h.api));

    Future<Map<String, dynamic>> activate() => service.activate(
      companyId: 'co1',
      activationCode: 'JCBW-GOOD-CODE-2026',
      deviceId: testDeviceId,
      deviceModel: 'android 15',
    );

    test('activate and validate return the license state', () async {
      const state = {
        'licenseId': 'l1',
        'licenseStatus': 'active',
        'deviceStatus': 'active',
        'validUntil': 9,
        'maxDevices': 2,
        'serverTime': 1,
      };
      h.http.handler = (r) => const FakeReply(200, state);
      expect(await activate(), state);
      expect(
        await service.validate(companyId: 'co1', deviceId: testDeviceId),
        state,
      );
      final [a, v] = h.http.requests;
      expect('$a', 'POST /companies/co1/license/activate');
      expect(a.json, {
        'activationCode': 'JCBW-GOOD-CODE-2026',
        'deviceId': testDeviceId,
        'deviceModel': 'android 15',
        'platform': 'android',
      });
      expect('$v', 'POST /companies/co1/license/validate');
      expect(v.json, {'deviceId': testDeviceId});
    });

    test('denials map to the same reasons as before', () async {
      Future<Object> failure(FakeReply reply) async {
        h.http.handler = (r) => reply;
        try {
          await activate();
        } catch (e) {
          return e;
        }
        fail('expected a failure');
      }

      Matcher denied(String reason) =>
          isA<LicenseDenied>().having((e) => e.reason, 'reason', reason);

      expect(
        await failure(
          FakeReply.error(409, 'failed_precondition', reason: 'device_limit'),
        ),
        denied('device_limit'),
      );
      expect(
        await failure(FakeReply.error(409, 'failed_precondition')),
        denied('company_inactive'),
      );
      expect(
        await failure(
          FakeReply.error(403, 'permission_denied', reason: 'not_member'),
        ),
        denied('not_member'),
      );
      expect(
        await failure(FakeReply.error(400, 'invalid_argument')),
        denied('invalid_code'),
      );
      expect(
        await failure(FakeReply.error(500, 'internal')),
        isA<LicenseServerUnavailable>(),
      );
      expect(
        await failure(FakeReply.error(409, 'already_exists')),
        isA<LicenseServerUnavailable>(),
      );
      expect(
        await failure(
          FakeReply.error(
            429,
            'resource_exhausted',
            message: 'Too many wrong codes. Try again in an hour.',
          ),
        ),
        isA<LicenseServerUnavailable>().having(
          (e) => e.message,
          'message',
          'Too many wrong codes. Try again in an hour.',
        ),
      );
      h.http.offline = true;
      await expectLater(activate(), throwsA(isA<LicenseServerUnavailable>()));
    });
  });

  group('replacement', () {
    late HttpReplacementService service;
    setUp(() => service = HttpReplacementService(h.api));

    Future<ReplacementState> request() => service.request(
      companyId: 'co1',
      activationCode: 'CODE',
      newDeviceId: testDeviceId,
      newDeviceModel: 'android 15',
      reason: 'Phone lost',
    );

    test('request and status', () async {
      h.http.handler = (r) => switch (r.method) {
        'POST' => const FakeReply(200, {
          'requestId': 'req1',
          'status': 'pending',
        }),
        _ => const FakeReply(200, {
          'requestId': 'req1',
          'status': 'rejected',
          'reviewReason': 'Not a company phone',
        }),
      };
      final sent = await request();
      expect(sent.status, ReplacementStatus.pending);
      expect(sent.requestId, 'req1');
      expect(h.http.requests.single.json, {
        'activationCode': 'CODE',
        'newDeviceId': testDeviceId,
        'newDeviceModel': 'android 15',
        'reason': 'Phone lost',
      });

      final status = await service.status(companyId: 'co1', requestId: 'req1');
      expect(
        '${h.http.requests.last}',
        'GET /companies/co1/device-replacements/req1',
      );
      expect(status.status, ReplacementStatus.rejected);
      expect(status.reviewReason, 'Not a company phone');
    });

    test('already active phone', () async {
      h.http.handler = (r) =>
          const FakeReply(200, {'requestId': null, 'status': 'already_active'});
      expect((await request()).status, ReplacementStatus.alreadyActive);
    });

    test('denials and outages', () async {
      h.http.handler = (r) =>
          FakeReply.error(409, 'failed_precondition', reason: 'invalid_code');
      await expectLater(
        request(),
        throwsA(
          isA<LicenseDenied>().having(
            (e) => e.reason,
            'reason',
            'invalid_code',
          ),
        ),
      );
      // status() only ever reports "unavailable", as the screen expects.
      h.http.handler = (r) => FakeReply.error(403, 'permission_denied');
      await expectLater(
        service.status(companyId: 'co1', requestId: 'req1'),
        throwsA(isA<LicenseServerUnavailable>()),
      );
      h.http.offline = true;
      await expectLater(request(), throwsA(isA<LicenseServerUnavailable>()));
    });
  });

  group('company users', () {
    var members = <Map<String, Object?>>[];
    late HttpCompanyUsersService service;

    setUp(() {
      members = [
        {
          'uid': 'u2',
          'email': 'zed@jcbworks.in',
          'role': 'operator',
          'status': 'active',
        },
        {
          'uid': 'u1',
          'email': 'owner@jcbworks.in',
          'role': 'owner',
          'status': 'active',
        },
      ];
      h.http.handler = (r) {
        if (r.method == 'POST') {
          members.add({
            'uid': 'u3',
            'email': r.json['email'],
            'role': r.json['role'],
            'status': 'active',
          });
          return const FakeReply(200, {'userId': 'u3', 'newUser': true});
        }
        if (r.method == 'PATCH') {
          final m = members.firstWhere((m) => r.path.endsWith('/${m['uid']}'));
          m.addAll(r.json);
          return FakeReply(200, r.json);
        }
        return FakeReply(200, {'items': members});
      };
      service = HttpCompanyUsersService(
        h.api,
        refreshInterval: const Duration(hours: 1),
      );
    });

    Iterable<FakeRequest> reads() => h.http.to('GET', '/companies/co1/members');

    test('fetches at once and again after each change', () async {
      final lists = StreamEvents(service.watch('co1'));
      final first = await lists.next;
      expect(first.map((m) => m.email), [
        'owner@jcbworks.in',
        'zed@jcbworks.in',
      ]);
      expect(first.first.active, isTrue);

      await service.invite(
        companyId: 'co1',
        email: 'new@jcbworks.in',
        role: 'manager',
      );
      expect(
        (await lists.next).map((m) => m.email),
        contains('new@jcbworks.in'),
      );
      expect(h.http.requests.where((r) => r.method == 'POST').single.json, {
        'email': 'new@jcbworks.in',
        'role': 'manager',
      });

      await service.setRole(companyId: 'co1', userId: 'u2', role: 'accounts');
      expect(
        (await lists.next).firstWhere((m) => m.uid == 'u2').role,
        'accounts',
      );

      await service.setActive(companyId: 'co1', userId: 'u2', active: false);
      expect(
        (await lists.next).firstWhere((m) => m.uid == 'u2').active,
        isFalse,
      );
      expect(h.http.requests.where((r) => r.method == 'PATCH').last.json, {
        'status': 'disabled',
      });
      expect(reads(), hasLength(4));

      // Changes to another company don't refresh this list.
      await service.setRole(companyId: 'co2', userId: 'u2', role: 'manager');
      await pumpEventQueue();
      expect(reads(), hasLength(4));
      await lists.cancel();
    });

    test('polls while listened to and stops when cancelled', () async {
      service = HttpCompanyUsersService(
        h.api,
        refreshInterval: const Duration(milliseconds: 20),
      );
      final lists = StreamEvents(service.watch('co1'));
      for (var i = 0; i < 3; i++) {
        await lists.next;
      }
      await lists.cancel();
      final count = reads().length;
      expect(count, greaterThanOrEqualTo(3));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(reads(), hasLength(count));
    });

    test(
      'a failed first load is an error; later failures keep the list',
      () async {
        service = HttpCompanyUsersService(
          h.api,
          refreshInterval: const Duration(milliseconds: 20),
        );
        h.http.offline = true;
        final lists = StreamEvents(service.watch('co1'));
        await expectLater(
          lists.next,
          throwsA(
            isA<CompanyUsersException>().having(
              (e) => e.message,
              'message',
              'Could not reach the server. Connect to the internet and try again.',
            ),
          ),
        );
        h.http.offline = false;
        expect(await lists.next, hasLength(2));
        h.http.offline = true;
        final reads = h.http.requests.length;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(
          h.http.requests.length,
          greaterThan(reads),
          reason: 'still polling',
        );
        expect(lists.errors, hasLength(1), reason: 'only the first failure');
        await lists.cancel();
      },
    );

    test('change errors keep the existing messages', () async {
      Future<String> messageFor(FakeHandler handler) async {
        h.http.handler = handler;
        try {
          await service.invite(
            companyId: 'co1',
            email: 'x@y.in',
            role: 'operator',
          );
        } on CompanyUsersException catch (e) {
          return e.message;
        }
        fail('expected CompanyUsersException');
      }

      expect(
        await messageFor(
          (r) => FakeReply.error(
            409,
            'already_exists',
            message: 'x@y.in is already a member.',
          ),
        ),
        'x@y.in is already a member.',
      );
      expect(
        await messageFor(
          (r) => FakeReply.error(
            429,
            'resource_exhausted',
            message: 'Invite limit reached for today.',
          ),
        ),
        'Invite limit reached for today.',
      );
      expect(
        await messageFor((r) => FakeReply.error(500, 'internal')),
        'Could not reach the server. Connect to the internet and try again.',
      );
      expect(
        await messageFor((r) => throw const Offline()),
        'Could not reach the server. Connect to the internet and try again.',
      );
    });
  });

  group('invoice numbers', () {
    late HttpInvoiceNumberService service;
    setUp(() => service = HttpInvoiceNumberService(h.api));

    Future<String> allocate() => service.allocate(
      companyId: 'co1',
      invoiceId: 'inv1',
      financialYear: '2026-27',
      deviceId: 'phone-9',
    );

    test('allocates as this phone', () async {
      h.http.handler = (r) =>
          const FakeReply(200, {'invoiceNumber': 'JCB/2026-27/0007'});
      expect(await allocate(), 'JCB/2026-27/0007');
      final r = h.http.requests.single;
      expect('$r', 'POST /companies/co1/invoice-numbers');
      expect(r.headers['x-device-id'], 'phone-9');
      expect(r.json, {'invoiceId': 'inv1', 'financialYear': '2026-27'});
    });

    test('failures keep the existing messages', () async {
      Future<String> messageFor(FakeHandler handler) async {
        h.http.handler = handler;
        try {
          await allocate();
        } on InvoiceNumberUnavailable catch (e) {
          return e.message;
        }
        fail('expected InvoiceNumberUnavailable');
      }

      expect(
        await messageFor((r) => FakeReply.error(403, 'permission_denied')),
        "You don't have permission to finalize invoices for this company.",
      );
      expect(
        await messageFor(
          (r) => FakeReply.error(
            409,
            'failed_precondition',
            message: 'This company is not active yet.',
          ),
        ),
        'This company is not active yet.',
      );
      expect(
        await messageFor((r) => FakeReply.error(404, 'not_found')),
        'Invoice numbering is not set up on the server yet.',
      );
      expect(
        await messageFor(
          (r) =>
              FakeReply.error(429, 'resource_exhausted', message: 'Slow down.'),
        ),
        'Slow down.',
      );
      for (final handler in <FakeHandler>[
        (r) => throw const Offline(),
        (r) => FakeReply.error(500, 'internal'),
      ]) {
        expect(
          await messageFor(handler),
          'Could not reach the server. Connect to the internet and try again.',
        );
      }
    });
  });

  group('company remote source', () {
    late HttpCompanyRemoteSource source;
    setUp(() => source = HttpCompanyRemoteSource(h.api));

    test('fetchMemberships maps active memberships', () async {
      h.http.handler = (r) => const FakeReply(200, {
        'items': [
          {'role': 'admin', 'status': 'active', 'company': _company},
          {'role': 'superuser', 'status': 'active', 'company': _company},
        ],
      });
      final [m] = await source.fetchMemberships('u1');
      expect('${h.http.requests.single}', 'GET /me/memberships');
      expect(m.role, CompanyRole.admin);
      expect(m.company.id, 'co1');
      expect(m.company.status, CompanyStatus.active);
      expect(m.company.ownerUid, 'u1');
      expect(m.company.profile.name, 'Sai Earthmovers');
      expect(m.company.profile.currency, 'INR');
    });

    test(
      'fetchMemberships fails, never returns empty, when unreachable',
      () async {
        h.http.offline = true;
        await expectLater(source.fetchMemberships('u1'), throwsA(anything));
        h.http.offline = false;
        h.http.handler = (r) => FakeReply.error(503, 'unavailable');
        await expectLater(source.fetchMemberships('u1'), throwsA(anything));
      },
    );

    test('fetchMemberships refuses to answer for another user', () async {
      h.http.handler = (r) => const FakeReply(200, {'items': <Object>[]});
      await expectLater(
        source.fetchMemberships('someone-else'),
        throwsStateError,
      );
    });

    test('registerCompany posts the profile with the client ID', () async {
      final pending = Map.of(_company)..['status'] = 'pending';
      h.http.handler = (r) => FakeReply(201, pending);
      final company = await source.registerCompany(
        companyId: 'co1',
        uid: 'u1',
        email: 'owner@jcbworks.in',
        profile: profileNamed('Sai Earthmovers'),
      );
      final r = h.http.requests.single;
      expect('$r', 'POST /companies');
      expect(r.json, {
        'id': 'co1',
        'name': 'Sai Earthmovers',
        'contactPerson': 'Ravi Patil',
        'phone': '9876543210',
        'address': 'Plot 12, MIDC, Pune',
        'invoicePrefix': 'JCB',
        'email': null,
        'gstin': null,
      });
      expect(company.status, CompanyStatus.pending);
    });

    test('updateProfile patches the company', () async {
      h.http.handler = (r) => const FakeReply(200, _company);
      await source.updateProfile(
        companyId: 'co1',
        uid: 'u1',
        profile: profileNamed('Sai Earthmovers'),
      );
      final r = h.http.requests.single;
      expect('$r', 'PATCH /companies/co1');
      expect(r.json['name'], 'Sai Earthmovers');
      expect(r.json.containsKey('nameLower'), isFalse);
    });
  });
}
