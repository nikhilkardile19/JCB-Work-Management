import '../../../core/utils/units.dart';
import '../../company/domain/company_validators.dart';
import 'master_kind.dart';

/// Upper bounds that catch typos (e.g. an extra digit) without limiting
/// real-world values.
const maxHourlyRatePaise = 10000000; // ₹1,00,000 per hour
const maxMeterReading = 99999999; // 9,99,999.99 hours

/// Validates the raw text a user typed for [field]. Returns an error message
/// or null.
String? validateMasterField(FieldSpec field, String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) {
    if (!field.required) return null;
    return switch (field.type) {
      FieldType.clientRef => 'Select a client',
      FieldType.meter => 'Enter the hour-meter reading',
      _ => 'Enter the ${field.label.toLowerCase()}',
    };
  }
  switch (field.type) {
    case FieldType.text:
    case FieldType.clientRef:
      return t.length > 120 ? 'Keep this under 120 characters' : null;
    case FieldType.multiline:
      return t.length > 1000 ? 'Keep this under 1000 characters' : null;
    case FieldType.code:
      return t.length > 40 ? 'Keep this under 40 characters' : null;
    case FieldType.phone:
      return CompanyValidators.phone(t);
    case FieldType.email:
      return CompanyValidators.optionalEmail(t);
    case FieldType.gstin:
      return CompanyValidators.optionalGstin(t);
    case FieldType.money:
      final v = Money.parse(t);
      if (v == null) return 'Enter an amount like 1500 or 1500.50';
      if (v > maxHourlyRatePaise) return 'That rate looks too high';
      return null;
    case FieldType.meter:
      final v = MeterReading.parse(t);
      if (v == null) return 'Enter hours like 1234 or 1234.5';
      if (v > maxMeterReading) return 'That reading looks too high';
      return null;
  }
}

/// Converts validated raw input into the stored value.
Object? parseMasterField(FieldSpec field, String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  return switch (field.type) {
    FieldType.money => Money.parse(t),
    FieldType.meter => MeterReading.parse(t),
    FieldType.code || FieldType.gstin => t.toUpperCase(),
    _ => t,
  };
}

/// Stored value → editable text.
String toMasterInput(FieldSpec field, Object? value) => switch (value) {
  null => '',
  final int v when field.type == FieldType.money => Money.toInput(v),
  final int v when field.type == FieldType.meter => MeterReading.toInput(v),
  _ => value.toString(),
};

/// Stored value → display text, or null when empty.
String? formatMasterField(FieldSpec field, Object? value) => switch (value) {
  null => null,
  final String s when s.isEmpty => null,
  final int v when field.type == FieldType.money => '${Money.format(v)} / hour',
  final int v when field.type == FieldType.meter => MeterReading.format(v),
  _ => value.toString(),
};
