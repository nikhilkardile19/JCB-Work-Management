import 'package:intl/intl.dart';

/// Money is stored as integer paise; never as floating point.
abstract final class Money {
  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final _pattern = RegExp(r'^\d+(\.\d{1,2})?$');

  /// Parses "1,250.5" → 125050. Returns null for invalid or negative input.
  static int? parse(String input) {
    final t = input.trim().replaceAll(',', '').replaceAll('₹', '').trim();
    if (!_pattern.hasMatch(t)) return null;
    return _fixed2(t);
  }

  /// 125050 → "₹1,250.50"
  static String format(int paise) => _inr.format(paise / 100);

  /// 125050 → "1250.50" (for editing).
  static String toInput(int paise) => _plain(paise);
}

/// Hour-meter readings are stored as integer hundredths of an hour.
abstract final class MeterReading {
  static final _pattern = RegExp(r'^\d+(\.\d{1,2})?$');
  static final _display = NumberFormat('#,##0.##', 'en_IN');

  /// Parses "1234.5" → 123450. Returns null for invalid or negative input.
  static int? parse(String input) {
    final t = input.trim().replaceAll(',', '');
    if (!_pattern.hasMatch(t)) return null;
    return _fixed2(t);
  }

  /// 123450 → "1,234.5 h"
  static String format(int hundredths) =>
      '${_display.format(hundredths / 100)} h';

  static String toInput(int hundredths) {
    final s = _plain(hundredths);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }
}

/// Fuel quantities are stored as integer hundredths of a litre.
abstract final class Litres {
  static final _pattern = RegExp(r'^\d+(\.\d{1,2})?$');
  static final _display = NumberFormat('#,##0.##', 'en_IN');

  /// "25.5" → 2550. Returns null for invalid or negative input.
  static int? parse(String input) {
    final t = input.trim().replaceAll(',', '');
    if (!_pattern.hasMatch(t)) return null;
    return _fixed2(t);
  }

  /// 2550 → "25.5 L"
  static String format(int cl) => '${_display.format(cl / 100)} L';

  static String toInput(int cl) => _plain(cl);
}

/// "12.3" → 1230 using string arithmetic (no float rounding).
int _fixed2(String t) {
  final parts = t.split('.');
  final frac = (parts.length > 1 ? parts[1] : '').padRight(2, '0');
  return int.parse(parts[0]) * 100 + int.parse(frac);
}

String _plain(int v) => '${v ~/ 100}.${(v % 100).toString().padLeft(2, '0')}';
