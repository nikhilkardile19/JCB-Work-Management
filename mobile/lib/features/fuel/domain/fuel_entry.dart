import 'package:flutter/material.dart' show DateUtils;

import '../../company/domain/permissions.dart';
import '../../evidence/photo_evidence.dart';
import '../../work/domain/work_log.dart';

abstract final class FuelMath {
  /// Paise for [litresCl] hundredths of a litre at [pricePerLitrePaise],
  /// rounded half-up to the nearest paisa. Integer-only.
  static int total(int litresCl, int pricePerLitrePaise) =>
      (litresCl * pricePerLitrePaise + 50) ~/ 100;
}

/// Sanity limits that catch typing mistakes (an extra zero).
const maxFuelLitresCl = 200000; // 2,000 L in one fill
const maxPricePerLitrePaise = 50000; // ₹500 per litre

class FuelInput {
  const FuelInput({
    required this.filledAt,
    required this.machineId,
    required this.pumpId,
    required this.litresCl,
    required this.pricePerLitrePaise,
    this.clientId,
    this.siteId,
    this.receipt,
    this.notes,
  });

  final DateTime filledAt;
  final String? machineId;
  final String? pumpId;
  final int? litresCl;
  final int? pricePerLitrePaise;
  final String? clientId;
  final String? siteId;
  final PhotoEvidence? receipt;
  final String? notes;

  int? get totalPaise => litresCl == null || pricePerLitrePaise == null
      ? null
      : FuelMath.total(litresCl!, pricePerLitrePaise!);
}

class FuelView {
  const FuelView({
    required this.id,
    required this.filledAt,
    required this.fuelDate,
    required this.machineId,
    required this.machineName,
    required this.pumpId,
    required this.pumpName,
    required this.litresCl,
    required this.pricePerLitrePaise,
    required this.totalPaise,
    required this.createdBy,
    required this.syncStatus,
    this.clientId,
    this.clientName,
    this.siteId,
    this.siteName,
    this.receipt,
    this.notes,
  });

  final String id;
  final DateTime filledAt;
  final String fuelDate;
  final String machineId;
  final String machineName;
  final String pumpId;
  final String pumpName;
  final String? clientId;
  final String? clientName;
  final String? siteId;
  final String? siteName;
  final int litresCl;
  final int pricePerLitrePaise;
  final int totalPaise;
  final PhotoEvidence? receipt;
  final String? notes;
  final String createdBy;
  final String syncStatus;

  FuelInput toInput() => FuelInput(
    filledAt: filledAt,
    machineId: machineId,
    pumpId: pumpId,
    litresCl: litresCl,
    pricePerLitrePaise: pricePerLitrePaise,
    clientId: clientId,
    siteId: siteId,
    receipt: receipt,
    notes: notes,
  );
}

abstract final class FuelRules {
  /// Blocking validation errors keyed by field.
  static Map<String, String> errors(FuelInput i) => {
    if (i.machineId == null) 'machineId': 'Select a machine',
    if (i.pumpId == null) 'pumpId': 'Select a petrol pump or supplier',
    if (i.litresCl == null)
      'litres': 'Enter the litres filled'
    else if (i.litresCl! <= 0)
      'litres': 'Litres must be more than zero'
    else if (i.litresCl! > maxFuelLitresCl)
      'litres': 'That looks too high for one fill',
    if (i.pricePerLitrePaise == null)
      'price': 'Enter the price per litre'
    else if (i.pricePerLitrePaise! > maxPricePerLitrePaise)
      'price': 'That price per litre looks too high',
    if (i.siteId != null && i.clientId == null)
      'clientId': 'Select the client for this site',
    if (i.filledAt.isAfter(DateTime.now().add(const Duration(minutes: 5))))
      'filledAt': 'Fuel time cannot be in the future',
  };
}

abstract final class FuelPolicy {
  static bool canRecord(CompanyRole r) => r.can(Permission.recordFuel);

  /// Owners/admins can change any entry; others only their own.
  static bool canEdit(CompanyRole r, FuelView e, String uid) =>
      r.can(Permission.manageCompany) ||
      (r.can(Permission.recordFuel) && e.createdBy == uid);
}

class MachineFuel {
  const MachineFuel({
    required this.machineId,
    required this.machineName,
    required this.litresCl,
    required this.totalPaise,
  });

  final String machineId;
  final String machineName;
  final int litresCl;
  final int totalPaise;
}

class FuelSummary {
  const FuelSummary({
    required this.totalPaise,
    required this.litresCl,
    required this.count,
    required this.byMachine,
  });

  static const empty = FuelSummary(
    totalPaise: 0,
    litresCl: 0,
    count: 0,
    byMachine: [],
  );

  final int totalPaise;
  final int litresCl;
  final int count;
  final List<MachineFuel> byMachine;

  /// Weighted average price in paise per litre, or null without fuel.
  int? get averagePricePaise =>
      litresCl == 0 ? null : (totalPaise * 100 + litresCl ~/ 2) ~/ litresCl;
}

enum FuelPeriod {
  thisWeek('This week'),
  thisMonth('This month'),
  lastMonth('Last month');

  const FuelPeriod(this.label);

  final String label;

  /// Inclusive `yyyy-MM-dd` range for [now].
  (String, String) range(DateTime now) {
    final today = DateUtils.dateOnly(now);
    final (from, to) = switch (this) {
      FuelPeriod.thisWeek => (
        today.subtract(Duration(days: today.weekday - 1)),
        today,
      ),
      FuelPeriod.thisMonth => (DateTime(today.year, today.month), today),
      FuelPeriod.lastMonth => (
        DateTime(today.year, today.month - 1),
        DateTime(today.year, today.month, 0),
      ),
    };
    return (WorkLogRules.dateKey(from), WorkLogRules.dateKey(to));
  }
}
