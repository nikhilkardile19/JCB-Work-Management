import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/features/sync/data/sync_engine.dart';

bool same(Map<String, dynamic> a, Map<String, dynamic> b) =>
    SyncEngine.sameContent(a, b);

void main() {
  group('SyncEngine.sameContent', () {
    test('map key order does not matter, at any depth', () {
      expect(same({'a': 1, 'b': 2}, {'b': 2, 'a': 1}), isTrue);
      expect(
        same(
          {
            'lines': [
              {'id': 'l1', 'amountPaise': 150000, 'sortOrder': 0},
            ],
          },
          {
            'lines': [
              {'sortOrder': 0, 'amountPaise': 150000, 'id': 'l1'},
            ],
          },
        ),
        isTrue,
      );
    });

    test('numbers compare by value across int and double', () {
      expect(same({'hours': 5}, {'hours': 5.0}), isTrue);
      expect(
        same(
          {
            'lines': [
              {'qty': 800},
            ],
          },
          {
            'lines': [
              {'qty': 800.0},
            ],
          },
        ),
        isTrue,
      );
      expect(same({'hours': 5}, {'hours': 5.5}), isFalse);
      expect(same({'hours': 5}, {'hours': '5'}), isFalse);
    });

    test('lists compare in order and by length', () {
      expect(
        same(
          {
            'lines': [
              {'id': 'l1'},
              {'id': 'l2'},
            ],
          },
          {
            'lines': [
              {'id': 'l2'},
              {'id': 'l1'},
            ],
          },
        ),
        isFalse,
      );
      expect(
        same(
          {
            'tags': [1, 2],
          },
          {
            'tags': [1, 2, 3],
          },
        ),
        isFalse,
      );
    });

    test('different values or nested values differ', () {
      expect(same({'name': 'Patil'}, {'name': 'Shinde'}), isFalse);
      expect(
        same(
          {
            'lines': [
              {'amountPaise': 100},
            ],
          },
          {
            'lines': [
              {'amountPaise': 101},
            ],
          },
        ),
        isFalse,
      );
      expect(
        same(
          {
            'm': {'a': 1},
          },
          {
            'm': [1],
          },
        ),
        isFalse,
      );
    });

    test('a missing key equals null; edit bookkeeping is ignored', () {
      expect(same({'gstin': null}, {}), isTrue);
      expect(
        same(
          {
            'lines': [
              {'id': 'l1', 'note': null},
            ],
          },
          {
            'lines': [
              {'id': 'l1'},
            ],
          },
        ),
        isTrue,
      );
      expect(
        same(
          {'name': 'Patil', 'version': 2, 'updatedAt': 10, 'updatedBy': 'a'},
          {'name': 'Patil', 'version': 3, 'updatedAt': 20, 'updatedBy': 'b'},
        ),
        isTrue,
      );
      // Only at the top level: nested fields with those names still count.
      expect(
        same(
          {
            'lines': [
              {'updatedAt': 1},
            ],
          },
          {
            'lines': [
              {'updatedAt': 2},
            ],
          },
        ),
        isFalse,
      );
    });
  });
}
