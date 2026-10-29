import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/data/local/app_database.dart';
import 'package:jcb_work_management/features/company/data/company_repository.dart';
import 'package:jcb_work_management/features/company/domain/permissions.dart';

import '../helpers/pump_app.dart';

void main() {
  late AppDatabase db;
  late FakeCompanyRemote remote;
  late CompanyRepository repo;

  setUp(() {
    db = memoryDatabase();
    remote = FakeCompanyRemote();
    repo = CompanyRepository(db, remote);
  });
  tearDown(() => db.close());

  test('refresh caches memberships for offline use', () async {
    remote.memberships['u1'] = [
      membership('a', 'Alpha'),
      membership('b', 'Beta'),
    ];
    await repo.refresh('u1');
    remote.offline = true;
    final cached = await repo.watchMemberships('u1').first;
    expect(cached.map((m) => m.company.name), ['Alpha', 'Beta']);
    expect(cached.first.company.profile.invoicePrefix, 'JCB');
  });

  test('failed refresh leaves the cache untouched', () async {
    remote.memberships['u1'] = [membership('a', 'Alpha')];
    await repo.refresh('u1');
    remote.offline = true;
    await expectLater(repo.refresh('u1'), throwsException);
    expect(await repo.watchMemberships('u1').first, hasLength(1));
  });

  test('refresh drops companies the user was removed from', () async {
    remote.memberships['u1'] = [
      membership('a', 'Alpha'),
      membership('b', 'Beta'),
    ];
    await repo.refresh('u1');
    remote.memberships['u1'] = [membership('b', 'Beta')];
    await repo.refresh('u1');
    final ids = (await repo.watchMemberships('u1').first).map(
      (m) => m.companyId,
    );
    expect(ids, ['b']);
  });

  test('cache is isolated per user on a shared phone', () async {
    remote.memberships['u1'] = [membership('a', 'Alpha')];
    remote.memberships['u2'] = [membership('z', 'Zeta')];
    await repo.refresh('u1');
    await repo.refresh('u2');
    expect((await repo.watchMemberships('u1').first).single.companyId, 'a');
    expect((await repo.watchMemberships('u2').first).single.companyId, 'z');
    await repo.selectCompany('u1', 'a');
    expect(await repo.watchSelectedCompanyId('u2').first, isNull);
  });

  test(
    'register creates a pending company owned by the user and selects it',
    () async {
      final m = await repo.register(
        uid: 'u1',
        email: 'o@x.in',
        profile: profileNamed('New Co'),
      );
      expect(m.role, CompanyRole.owner);
      expect(m.company.status, CompanyStatus.pending);
      expect(m.company.ownerUid, 'u1');
      expect(m.companyId, hasLength(36)); // UUID v4
      expect(await repo.watchSelectedCompanyId('u1').first, m.companyId);
      expect(
        (await repo.watchMemberships('u1').first).single.company.name,
        'New Co',
      );
    },
  );

  test('register fails cleanly offline and caches nothing', () async {
    remote.offline = true;
    await expectLater(
      repo.register(uid: 'u1', email: 'o@x.in', profile: profileNamed('X')),
      throwsException,
    );
    expect(await repo.watchMemberships('u1').first, isEmpty);
  });

  test('updateProfile updates the cache', () async {
    remote.memberships['u1'] = [membership('a', 'Alpha')];
    await repo.refresh('u1');
    final m = (await repo.watchMemberships('u1').first).single;
    await repo.updateProfile(
      uid: 'u1',
      membership: m,
      profile: profileNamed('Alpha 2'),
    );
    expect(
      (await repo.watchMemberships('u1').first).single.company.name,
      'Alpha 2',
    );
  });
}
