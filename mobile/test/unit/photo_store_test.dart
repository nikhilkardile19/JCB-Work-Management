import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/work/data/evidence_services.dart';

void main() {
  late Directory base;
  late Directory camera;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('docs');
    camera = await Directory.systemTemp.createTemp('camera');
  });
  tearDown(() async {
    await base.delete(recursive: true);
    await camera.delete(recursive: true);
  });

  test(
    'keeps photos in app storage under a relative path that survives restart',
    () async {
      final shot = File('${camera.path}/IMG_1.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final store = PhotoStore(baseDir: () async => base);
      final rel = await store.keep(shot, companyId: 'co1', name: 'abc');

      expect(rel, 'evidence/co1/abc.jpg');
      expect(shot.existsSync(), isFalse, reason: 'temp camera file is moved');

      // A new store instance (as after an app restart) resolves the same file.
      final afterRestart = PhotoStore(baseDir: () async => base);
      final f = await afterRestart.resolve(rel);
      expect(f.readAsBytesSync(), [1, 2, 3]);
      expect(f.path.startsWith(base.path), isTrue);
    },
  );

  test('discard deletes the file and tolerates missing files', () async {
    final store = PhotoStore(baseDir: () async => base);
    final rel = await store.keep(
      File('${camera.path}/x.jpg')..writeAsBytesSync([9]),
      companyId: 'c',
      name: 'x',
    );
    await store.discard(rel);
    expect((await store.resolve(rel)).existsSync(), isFalse);
    await expectLater(store.discard(rel), completes);
  });
}
