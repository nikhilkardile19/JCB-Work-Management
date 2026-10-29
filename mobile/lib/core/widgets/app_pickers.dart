import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDropdownOption<T> {
  const AppDropdownOption(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Dropdown form field used for master selection (client, site, machine…).
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.prefixIcon,
    this.validator,
    this.hint,
  });

  final String label;
  final List<AppDropdownOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final IconData? prefixIcon;
  final FormFieldValidator<T>? validator;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      validator: validator,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
      items: [
        for (final o in options)
          DropdownMenuItem<T>(
            value: o.value,
            child: Text(o.label, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

/// Read-only field that opens the platform date picker.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final FormFieldValidator<DateTime>? validator;

  static final _format = DateFormat('EEE, d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        final current = value ?? field.value;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: current ?? now,
              firstDate: firstDate ?? DateTime(now.year - 5),
              lastDate: lastDate ?? DateTime(now.year + 1, 12, 31),
            );
            if (picked != null) {
              field.didChange(picked);
              onChanged(picked);
            }
          },
          child: InputDecorator(
            isEmpty: current == null,
            decoration: InputDecoration(
              labelText: label,
              errorText: field.errorText,
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(current == null ? '' : _format.format(current)),
          ),
        );
      },
    );
  }
}
