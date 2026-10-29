import 'package:flutter_test/flutter_test.dart';
import 'package:jcb_work_management/core/utils/units.dart';
import 'package:jcb_work_management/features/masters/domain/master_kind.dart';
import 'package:jcb_work_management/features/masters/domain/master_validators.dart';

void main() {
  group('Money', () {
    test('parses rupees to paise without float error', () {
      expect(Money.parse('1500'), 150000);
      expect(Money.parse('1,250.5'), 125050);
      expect(Money.parse('₹ 0.07'), 7);
      expect(Money.parse('19.99'), 1999); // 19.99 * 100 is 1998.999… in floats
      expect(Money.parse('1.234'), isNull);
      expect(Money.parse('-5'), isNull);
      expect(Money.parse('abc'), isNull);
    });

    test('formats in Indian style', () {
      expect(Money.format(12345678), '₹1,23,456.78');
      expect(Money.toInput(150000), '1500.00');
    });
  });

  group('MeterReading', () {
    test('parses hours to hundredths', () {
      expect(MeterReading.parse('1234'), 123400);
      expect(MeterReading.parse('1234.5'), 123450);
      expect(MeterReading.parse('0.01'), 1);
      expect(MeterReading.parse('12.345'), isNull);
    });

    test('formats', () {
      expect(MeterReading.format(123450), '1,234.5 h');
      expect(MeterReading.toInput(123400), '1234');
      expect(MeterReading.toInput(123450), '1234.50');
    });
  });

  group('master field validation', () {
    const machine = MasterKind.machines;
    test('required fields', () {
      expect(validateMasterField(machine.field('name'), ' '), isNotNull);
      expect(
        validateMasterField(machine.field('initialMeterReading'), ''),
        'Enter the hour-meter reading',
      );
      expect(
        validateMasterField(MasterKind.sites.field('clientId'), null),
        'Select a client',
      );
      expect(
        validateMasterField(machine.field('registrationNumber'), ''),
        isNull,
      );
    });

    test('typed fields', () {
      final rate = MasterKind.sites.field('defaultHourlyRatePaise');
      expect(validateMasterField(rate, '1500'), isNull);
      expect(validateMasterField(rate, '15.555'), isNotNull);
      expect(validateMasterField(rate, '200000'), contains('too high'));
      expect(
        validateMasterField(machine.field('initialMeterReading'), '1000000'),
        contains('too high'),
      );
      expect(
        validateMasterField(MasterKind.clients.field('phone'), '123'),
        isNotNull,
      );
      expect(
        validateMasterField(
          MasterKind.clients.field('gstin'),
          '27ABCDE1234F1Z5',
        ),
        isNull,
      );
    });

    test('parse, edit and display round-trip', () {
      final rate = MasterKind.sites.field('defaultHourlyRatePaise');
      final reg = machine.field('registrationNumber');
      expect(parseMasterField(rate, '1,500.5'), 150050);
      expect(parseMasterField(reg, ' mh12ab1234 '), 'MH12AB1234');
      expect(parseMasterField(reg, '  '), isNull);
      expect(toMasterInput(rate, 150050), '1500.50');
      expect(formatMasterField(rate, 150050), '₹1,500.50 / hour');
      expect(
        formatMasterField(machine.field('initialMeterReading'), 123450),
        '1,234.5 h',
      );
      expect(formatMasterField(reg, ''), isNull);
    });

    test('every kind has a required name and valid slugs', () {
      for (final k in MasterKind.values) {
        expect(k.field('name').required, isTrue, reason: k.name);
        expect(MasterKind.fromSlug(k.slug), k);
        for (final s in [...k.searchKeys, ...k.subtitleKeys]) {
          expect(
            k.fields.any((f) => f.key == s),
            isTrue,
            reason: '${k.name}.$s',
          );
        }
      }
      expect(MasterKind.fromSlug('nope'), isNull);
    });
  });
}
