import 'package:flutter/material.dart';

enum FieldType {
  text,
  multiline,
  phone,
  email,
  gstin,

  /// Upper-cased identifier (registration number, employee code).
  code,

  /// Rupees, stored as paise.
  money,

  /// Hour-meter reading, stored as hundredths of an hour.
  meter,

  /// Reference to a client record.
  clientRef,
}

/// One field of a master record. [key] is the Drift/Dart column name.
class FieldSpec {
  const FieldSpec(
    this.key,
    this.label,
    this.icon, {
    this.type = FieldType.text,
    this.required = false,
    this.helper,
  });

  final String key;
  final String label;
  final IconData icon;
  final FieldType type;
  final bool required;
  final String? helper;

  bool get isInt => type == FieldType.money || type == FieldType.meter;
}

const _notes = FieldSpec(
  'notes',
  'Notes',
  Icons.notes_outlined,
  type: FieldType.multiline,
);

/// Master data types (sprint doc §4.3–4.7).
enum MasterKind {
  clients(
    slug: 'clients',
    plural: 'Clients',
    singular: 'Client',
    icon: Icons.groups_outlined,
    emptyMessage: 'Add the customers you bill for machine work.',
    fields: [
      FieldSpec('name', 'Client name', Icons.business_outlined, required: true),
      FieldSpec('contactPerson', 'Contact person', Icons.person_outline),
      FieldSpec('phone', 'Phone', Icons.phone_outlined, type: FieldType.phone),
      FieldSpec('email', 'Email', Icons.alternate_email, type: FieldType.email),
      FieldSpec(
        'billingAddress',
        'Billing address',
        Icons.place_outlined,
        type: FieldType.multiline,
      ),
      FieldSpec(
        'gstin',
        'GSTIN',
        Icons.receipt_outlined,
        type: FieldType.gstin,
      ),
      _notes,
    ],
    searchKeys: ['name', 'contactPerson', 'phone'],
    subtitleKeys: ['contactPerson', 'phone'],
  ),
  sites(
    slug: 'sites',
    plural: 'Sites',
    singular: 'Site',
    icon: Icons.location_on_outlined,
    emptyMessage: 'Add the work sites where your machines operate.',
    fields: [
      FieldSpec(
        'clientId',
        'Client',
        Icons.groups_outlined,
        type: FieldType.clientRef,
        required: true,
      ),
      FieldSpec(
        'name',
        'Site name',
        Icons.location_on_outlined,
        required: true,
      ),
      FieldSpec(
        'address',
        'Address / location',
        Icons.place_outlined,
        type: FieldType.multiline,
      ),
      FieldSpec(
        'defaultHourlyRatePaise',
        'Default hourly rate (₹)',
        Icons.currency_rupee,
        type: FieldType.money,
        helper: 'Suggested on invoices; can be changed per invoice.',
      ),
      FieldSpec('contactPerson', 'Site contact', Icons.person_outline),
      FieldSpec('phone', 'Phone', Icons.phone_outlined, type: FieldType.phone),
      _notes,
    ],
    searchKeys: ['name', 'address'],
    subtitleKeys: ['address'],
  ),
  machines(
    slug: 'machines',
    plural: 'Machines',
    singular: 'Machine',
    icon: Icons.agriculture_outlined,
    emptyMessage:
        'Add each JCB or earthmover with its current hour-meter reading.',
    fields: [
      FieldSpec(
        'name',
        'Machine name / number',
        Icons.agriculture_outlined,
        required: true,
      ),
      FieldSpec(
        'registrationNumber',
        'Registration number',
        Icons.pin_outlined,
        type: FieldType.code,
      ),
      FieldSpec('model', 'Type / model', Icons.category_outlined),
      FieldSpec(
        'serialNumber',
        'Serial / chassis number',
        Icons.qr_code_2,
        type: FieldType.code,
      ),
      FieldSpec(
        'initialMeterReading',
        'Initial hour-meter reading',
        Icons.speed,
        type: FieldType.meter,
        required: true,
        helper: 'The reading shown on the meter today, in hours.',
      ),
      _notes,
    ],
    searchKeys: ['name', 'registrationNumber', 'model'],
    subtitleKeys: ['registrationNumber', 'model'],
  ),
  operators(
    slug: 'operators',
    plural: 'Operators',
    singular: 'Operator',
    icon: Icons.badge_outlined,
    emptyMessage: 'Add the operators who run your machines (optional).',
    fields: [
      FieldSpec('name', 'Operator name', Icons.person_outline, required: true),
      FieldSpec('phone', 'Phone', Icons.phone_outlined, type: FieldType.phone),
      FieldSpec(
        'code',
        'Employee / reference code',
        Icons.tag,
        type: FieldType.code,
      ),
      _notes,
    ],
    searchKeys: ['name', 'phone', 'code'],
    subtitleKeys: ['code', 'phone'],
  ),
  petrolPumps(
    slug: 'petrol-pumps',
    plural: 'Petrol pumps',
    singular: 'Petrol pump',
    icon: Icons.local_gas_station_outlined,
    emptyMessage: 'Add the pumps or suppliers where you buy fuel.',
    fields: [
      FieldSpec(
        'name',
        'Pump / supplier name',
        Icons.local_gas_station_outlined,
        required: true,
      ),
      FieldSpec('phone', 'Phone', Icons.phone_outlined, type: FieldType.phone),
      FieldSpec(
        'address',
        'Address',
        Icons.place_outlined,
        type: FieldType.multiline,
      ),
      _notes,
    ],
    searchKeys: ['name', 'address'],
    subtitleKeys: ['address', 'phone'],
  );

  const MasterKind({
    required this.slug,
    required this.plural,
    required this.singular,
    required this.icon,
    required this.emptyMessage,
    required this.fields,
    required this.searchKeys,
    required this.subtitleKeys,
  });

  final String slug;
  final String plural;
  final String singular;
  final IconData icon;
  final String emptyMessage;
  final List<FieldSpec> fields;
  final List<String> searchKeys;
  final List<String> subtitleKeys;

  static MasterKind? fromSlug(String? slug) =>
      MasterKind.values.where((k) => k.slug == slug).firstOrNull;

  FieldSpec field(String key) => fields.firstWhere((f) => f.key == key);
}

/// A master record as a map of Dart field names → values, plus typed access
/// to the shared columns.
class MasterRecord {
  const MasterRecord(this.kind, this.values, {this.clientName});

  final MasterKind kind;
  final Map<String, Object?> values;

  /// For sites: the linked client's name.
  final String? clientName;

  String get id => values['id']! as String;
  String get name => values['name']! as String;
  bool get isActive => values['isActive']! as bool;
  String get syncStatus => values['syncStatus']! as String;
  int get updatedAt => values['updatedAt']! as int;
  int get version => values['version']! as int;
  String? get clientId => values['clientId'] as String?;

  Object? operator [](String key) => values[key];
}
